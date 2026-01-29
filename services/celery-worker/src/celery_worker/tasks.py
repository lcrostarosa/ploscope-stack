"""Celery tasks for PLO computations.

Core library imports are loaded with fallback handling to avoid import-time
failures during linting or test discovery when the `core` package may not be
on PYTHONPATH.
"""

from datetime import datetime
from typing import Optional
from urllib.parse import urlparse as _urlparse

from celery.exceptions import Reject
from core.equity import calculate_double_board_stats, simulate_estimated_equity
from core.solver import GameState, get_solver
from core.utils.logging_utils import get_enhanced_logger
from sqlalchemy import create_engine as _create_engine
from sqlalchemy.orm import scoped_session as _scoped_session
from sqlalchemy.orm import sessionmaker as _sessionmaker

from .celery_app import celery
from .models.enums import JobStatus
from .models.job import Job
from .services import database_service as ds
from .services.database_service import get_db_session as _adapter_get_db_session
from .services.database_service import log_solver_solution

# Configure logging
logger = get_enhanced_logger(__name__)


def get_db_session():
    """Return process-wide scoped_session from the database singleton.

    For test compatibility, we inject overridable callables from this module
    into the database service module so tests can patch `tasks.create_engine`,
    `tasks.sessionmaker`, `tasks.scoped_session`, and `tasks.urlparse`.
    """
    try:
        # If tests patched these names on this module, prefer patched versions
        create_engine_override = globals().get("create_engine", _create_engine)
        sessionmaker_override = globals().get("sessionmaker", _sessionmaker)
        scoped_session_override = globals().get("scoped_session", _scoped_session)
        urlparse_override = globals().get("urlparse", _urlparse)

        # Inject into database_service module
        ds.create_engine = create_engine_override  # type: ignore[attr-defined]
        ds.sessionmaker = sessionmaker_override  # type: ignore[attr-defined]
        ds.scoped_session = scoped_session_override  # type: ignore[attr-defined]
        ds.urlparse = urlparse_override  # type: ignore[attr-defined]
    except Exception:
        # Non-fatal; proceed without injection
        pass

    return _adapter_get_db_session()


@celery.task(bind=True, max_retries=3)
def process_spot_simulation(self, job_id: str):
    """Process a spot simulation job using Celery."""
    task_id = getattr(self.request, "id", "unknown")
    logger.info("Starting spot simulation for job %s (task %s)", job_id, task_id)

    # Add debugging for potential crash points
    logger.info("DEBUG: About to import database modules")

    try:
        logger.info("DEBUG: Creating database session")
        db_session = get_db_session()
        logger.info("DEBUG: Getting database session")
        session = db_session()
        logger.info("DEBUG: Database setup completed successfully")
    except Exception as e:
        logger.error("DEBUG: Database setup failed: %s", str(e))
        raise

    try:
        # Debug logging for job_id
        logger.info("Job ID type: %s, value: %s", type(job_id), job_id)

        # Handle case where entire request object is passed instead of just job_id
        if isinstance(job_id, dict):
            logger.warning("Received entire request object instead of job_id, extracting from args")
            if "args" in job_id and len(job_id["args"]) > 0:
                job_id = job_id["args"][0]
                logger.info("Extracted job_id from request args: %s", job_id)
            else:
                logger.error("Request object does not contain valid args: %s", job_id)
                raise ValueError("Invalid request object format - no args found")

        # Ensure job_id is a string
        if not isinstance(job_id, str):
            logger.error("job_id is not a string: %s (type: %s)", job_id, type(job_id))
            raise ValueError(f"job_id must be a string, got {type(job_id)}")

        # Get job using SQLAlchemy session (avoid adapter method that returns None)
        job_optional: Optional[Job] = session.get(Job, job_id)
        if job_optional is None:
            logger.error("Job with ID %s not found in the database.", job_id)
            raise ValueError(f"Job with ID {job_id} not found in the database")
        job: Job = job_optional

        logger.info("Found job %s with status %s", job.id, job.status.value)

        if job.status == JobStatus.CANCELLED:
            logger.info("Job %s has been cancelled.", job.id)
            return {"status": "cancelled"}

        # Update job status to processing
        job.start_processing()
        logger.info("Updated job %s status to PROCESSING", job.id)
        # Persist to database
        try:
            session.add(job)
            session.commit()
        except Exception as commit_error:
            session.rollback()
            logger.error("Failed to commit PROCESSING status for job %s: %s", job.id, commit_error)

        # Get input data
        input_data = job.input_data
        if not input_data:
            raise ValueError("No input data provided")

        # Update progress - starting
        job.update_progress(5, "Initializing simulation...")

        # Check if this is a double board PLO simulation
        if "top_board" in input_data and "bottom_board" in input_data:
            # Double board PLO simulation
            hands = input_data["players"]
            top_board = input_data["top_board"]
            bottom_board = input_data["bottom_board"]
            simulation_runs = input_data.get("simulation_runs", 10000)

            # Update progress - preparing data
            job.update_progress(15, "Preparing simulation data...")
            try:
                session.add(job)
                session.commit()
            except Exception as commit_error:
                session.rollback()
                logger.error("Failed to commit progress 15%% for job %s: %s", job.id, commit_error)

            # Convert hands to the format expected by calculate_double_board_stats
            if isinstance(hands, list) and len(hands) > 0 and isinstance(hands[0], dict):
                # Convert from dict format to list of card lists
                hand_cards = []
                for hand in hands:
                    if "cards" in hand:
                        hand_cards.append(hand["cards"])
                    else:
                        # If no 'cards' key, assume the dict itself contains the card data
                        hand_cards.append(list(hand.values())[:4])  # Take first 4 values as cards
                hands = hand_cards

            # Update progress - calculating double board stats
            job.update_progress(25, "Calculating double board statistics...")
            try:
                session.add(job)
                session.commit()
            except Exception as commit_error:
                session.rollback()
                logger.error("Failed to commit progress 25%% for job %s: %s", job.id, commit_error)

            # Calculate double board statistics using core
            logger.info("DEBUG: About to call calculate_double_board_stats")
            try:
                (
                    chop_both_counts,
                    scoop_both_counts,
                    split_top_counts,
                    split_bottom_counts,
                ) = calculate_double_board_stats(
                    hands=hands,
                    top_board=top_board,
                    bottom_board=bottom_board,
                    num_iterations=simulation_runs,
                )
                logger.info("DEBUG: calculate_double_board_stats completed successfully")
            except Exception as e:
                logger.error("DEBUG: calculate_double_board_stats failed: %s", str(e))
                raise

            # Convert raw counts to decimal percentages for frontend display
            chop_both_percent = [(count / simulation_runs) for count in chop_both_counts]
            scoop_both_percent = [(count / simulation_runs) for count in scoop_both_counts]
            split_top_percent = [(count / simulation_runs) for count in split_top_counts]
            split_bottom_percent = [(count / simulation_runs) for count in split_bottom_counts]

            # Update progress - processing results
            job.update_progress(90, "Processing results...")
            try:
                session.add(job)
                session.commit()
            except Exception as commit_error:
                session.rollback()
                logger.error("Failed to commit progress 90%% for job %s: %s", job.id, commit_error)

            # Build detailed results for each player
            results = []
            for i, hand in enumerate(hands):
                # Calculate equity for each board using simulate_estimated_equity
                num_random_opponents = 1

                # Calculate equity for top board
                if top_board:
                    logger.info("DEBUG: About to call simulate_estimated_equity for top board")
                    try:
                        (
                            top_estimated_equity,
                            _,
                            top_stats,
                            top_breakdown,
                            top_opponent_breakdown,
                        ) = simulate_estimated_equity(
                            hand,
                            top_board,
                            num_iterations=simulation_runs,
                            folded_cards=[],
                            max_hand_combinations=5,
                            num_opponents=num_random_opponents,
                        )
                        logger.info("DEBUG: simulate_estimated_equity for top board completed")
                    except Exception as e:
                        logger.error("DEBUG: simulate_estimated_equity for top board failed: %s", str(e))
                        raise
                else:
                    (
                        top_estimated_equity,
                        _,
                        top_stats,
                        top_breakdown,
                        top_opponent_breakdown,
                    ) = simulate_estimated_equity(
                        hand,
                        [],
                        num_iterations=simulation_runs,
                        folded_cards=[],
                        max_hand_combinations=5,
                        num_opponents=num_random_opponents,
                    )

                # Calculate equity for bottom board
                if bottom_board:
                    (
                        bottom_estimated_equity,
                        _,
                        bottom_stats,
                        bottom_breakdown,
                        bottom_opponent_breakdown,
                    ) = simulate_estimated_equity(
                        hand,
                        bottom_board,
                        num_iterations=simulation_runs,
                        folded_cards=[],
                        max_hand_combinations=5,
                        num_opponents=num_random_opponents,
                    )
                else:
                    (
                        bottom_estimated_equity,
                        _,
                        bottom_stats,
                        bottom_breakdown,
                        bottom_opponent_breakdown,
                    ) = simulate_estimated_equity(
                        hand,
                        [],
                        num_iterations=simulation_runs,
                        folded_cards=[],
                        max_hand_combinations=5,
                        num_opponents=num_random_opponents,
                    )

                # Build the result object for this player
                results.append(
                    {
                        "player_number": i + 1,
                        "cards": hand,
                        "top_estimated_equity": top_estimated_equity / 100,
                        "top_actual_equity": top_estimated_equity / 100,
                        "bottom_estimated_equity": bottom_estimated_equity / 100,
                        "bottom_actual_equity": bottom_estimated_equity / 100,
                        # Whole hand analysis
                        "chop_both_boards": (chop_both_percent[i] if i < len(chop_both_percent) else 0.0),
                        "scoop_both_boards": (scoop_both_percent[i] if i < len(scoop_both_percent) else 0.0),
                        "split_top": (split_top_percent[i] if i < len(split_top_percent) else 0.0),
                        "split_bottom": (split_bottom_percent[i] if i < len(split_bottom_percent) else 0.0),
                        "simulation_runs": simulation_runs,
                        "known_opponents": len(hands) - 1,
                        "random_opponents": num_random_opponents,
                        "top_detailed_stats": top_stats,
                        "bottom_detailed_stats": bottom_stats,
                        "top_hand_breakdown": top_breakdown,
                        "bottom_hand_breakdown": bottom_breakdown,
                        "top_opponent_breakdown": top_opponent_breakdown,
                        "bottom_opponent_breakdown": bottom_opponent_breakdown,
                    }
                )

            # Store results
            job.complete_job(results)
            try:
                session.add(job)
                session.commit()
            except Exception as commit_error:
                session.rollback()
                logger.error("Failed to commit COMPLETED status for job %s: %s", job.id, commit_error)

            logger.info("Spot simulation completed for job %s", job.id)
            return {"status": "completed", "result": results}

        else:
            # Single board simulation (legacy format)
            logger.warning("Single board simulation not yet implemented for job %s", job.id)
            job.fail_job("Single board simulation not yet implemented")
            try:
                session.add(job)
                session.commit()
            except Exception as commit_error:
                session.rollback()
                logger.error("Failed to commit FAILED status for job %s: %s", job.id, commit_error)
            return {
                "status": "failed",
                "error": "Single board simulation not yet implemented",
            }

    except Exception as e:
        logger.exception("Error in spot simulation for job %s: %s", job_id, str(e))

        # Determine retry/backoff behavior
        current_retries = getattr(self.request, "retries", 0)
        max_retries = getattr(self, "max_retries", 3) or 3

        # If we have remaining retries, requeue with exponential backoff
        if current_retries < (max_retries - 1):
            backoff_seconds = min(600, 2 ** max(1, current_retries))
            logger.warning(
                "Retrying job %s (attempt %s/%s) in %s seconds",
                job_id,
                current_retries + 1,
                max_retries,
                backoff_seconds,
            )
            raise self.retry(exc=e, countdown=backoff_seconds)

        # Final failure: update job then reject without requeue to DLQ
        try:
            if "job" in locals():
                job.fail_job(str(e))
                try:
                    session.add(job)
                    session.commit()
                except Exception as inner_commit_error:
                    session.rollback()
                    logger.error("Failed to commit FAILED status for job %s: %s", job_id, inner_commit_error)
        except Exception as commit_error:
            logger.error("Failed to update job %s with error: %s", job_id, commit_error)

        raise Reject(str(e), requeue=False) from e

    finally:
        db_session.remove()


@celery.task(bind=True, max_retries=3)
def process_solver_analysis(self, job_id: str):
    """Process a solver analysis job using Celery."""
    task_id = getattr(self.request, "id", "unknown")
    logger.info("Starting solver analysis for job %s (task %s)", job_id, task_id)

    # Core symbols are now imported directly at module level

    db_session = get_db_session()
    session = db_session()

    try:
        # Debug logging for job_id
        logger.info("Job ID type: %s, value: %s", type(job_id), job_id)

        # Handle case where entire request object is passed instead of just job_id
        if isinstance(job_id, dict):
            logger.warning("Received entire request object instead of job_id, extracting from args")
            if "args" in job_id and len(job_id["args"]) > 0:
                job_id = job_id["args"][0]
                logger.info("Extracted job_id from request args: %s", job_id)
            else:
                logger.error("Request object does not contain valid args: %s", job_id)
                raise ValueError("Invalid request object format - no args found")

        # Ensure job_id is a string
        if not isinstance(job_id, str):
            logger.error("job_id is not a string: %s (type: %s)", job_id, type(job_id))
            raise ValueError(f"job_id must be a string, got {type(job_id)}")

        # Get job using SQLAlchemy session (avoid adapter method that returns None)
        job_optional: Optional[Job] = session.get(Job, job_id)
        if job_optional is None:
            logger.error("Job with ID %s not found in the database.", job_id)
            raise ValueError(f"Job with ID {job_id} not found in the database")
        job: Job = job_optional

        logger.info("Found job %s with status %s", job.id, job.status.value)

        if job.status == JobStatus.CANCELLED:
            logger.info("Job %s has been cancelled.", job.id)
            return {"status": "cancelled"}

        # Update job status to processing
        job.start_processing()
        logger.info("Updated job %s status to PROCESSING", job.id)

        # Get input data
        input_data = job.input_data
        if not input_data:
            logger.error("Job %s has no input data", job.id)
            raise ValueError("No input data provided")

        logger.debug("Job %s input data keys: %s", job.id, list(input_data.keys()))

        # Update progress
        logger.debug("Updating job %s progress to 10%%", job.id)
        job.update_progress(10, "Initializing solver...")

        # Create game state - handle both wrapped and unwrapped formats
        if "game_state" in input_data:
            # Legacy format with game_state wrapper
            game_state_data = input_data["game_state"]
            logger.debug("Job %s using legacy game_state format", job.id)
        else:
            # Direct format
            game_state_data = input_data
            logger.debug("Job %s using direct game_state format", job.id)

        # Convert game state data to GameState object
        try:
            # Filter out only valid GameState parameters
            valid_gamestate_params = {
                "player_position",
                "active_players",
                "board",
                "pot_size",
                "current_bet",
                "stack_sizes",
                "betting_history",
                "street",
                "player_ranges",
                "board2",
                "num_boards",
                "num_cards",
                "hero_cards",
                "opponents",
                "board_selection_mode",
            }

            filtered_game_state_data = {
                key: value for key, value in game_state_data.items() if key in valid_gamestate_params
            }

            logger.debug("Job %s filtered game state keys: %s", job.id, list(filtered_game_state_data.keys()))
            game_state = GameState(**filtered_game_state_data)
            logger.debug("Job %s successfully created GameState object", job.id)
        except (ValueError, TypeError) as e:
            logger.error("Job %s failed to create GameState: %s", job.id, str(e))
            raise ValueError("Invalid game state data: %s" % str(e)) from e

        # Update progress
        logger.debug("Updating job %s progress to 30%%", job.id)
        job.update_progress(30, "Running solver analysis...")

        # Get solver instance from core
        solver = get_solver()
        logger.debug("Job %s got solver instance", job.id)

        # Run solver analysis
        logger.debug("Job %s starting solver analysis", job.id)
        solve_started_at = datetime.utcnow()
        solution = solver.solve_spot(game_state)
        solve_time_seconds: Optional[float] = None
        try:
            solve_time_seconds = (datetime.utcnow() - solve_started_at).total_seconds()
        except (ValueError, TypeError):
            # Non-fatal; leave as None to use model default
            solve_time_seconds = None
        logger.debug("Job %s completed solver analysis", job.id)

        # Update progress
        logger.debug("Updating job %s progress to 80%%", job.id)
        job.update_progress(80, "Processing results...")
        try:
            session.add(job)
            session.commit()
        except Exception as commit_error:
            session.rollback()
            logger.error("Failed to commit progress 80%% for job %s: %s", job.id, commit_error)

        # Store solution using core adapter
        try:
            log_solver_solution(
                user_id=job.user_id,
                name="Solver solution for job %s" % job.id,
                game_state=filtered_game_state_data,
                solution=solution,
                solve_time=solve_time_seconds,
                description="Auto-saved result for job %s" % job.id,
            )
            logger.debug("Job %s created SolverSolution", job.id)
        except (ValueError, AttributeError) as e:
            logger.error("Job %s failed to create SolverSolution: %s", job.id, str(e))
            # Don't fail the job if we can't store the solution

        # Update job with results
        job.complete_job(
            {
                "solution": solution,
                "game_state_hash": game_state.to_hash(),
            }
        )
        try:
            session.add(job)
            session.commit()
        except Exception as commit_error:
            session.rollback()
            logger.error("Failed to commit COMPLETED status for job %s: %s", job.id, commit_error)

        logger.info("Solver analysis completed for job %s", job.id)
        return {"status": "completed", "solution": solution}

    except Exception as e:
        logger.exception("Error in solver analysis for job %s: %s", job_id, str(e))

        current_retries = getattr(self.request, "retries", 0)
        max_retries = getattr(self, "max_retries", 3) or 3

        if current_retries < (max_retries - 1):
            backoff_seconds = min(600, 2 ** max(1, current_retries))
            logger.warning(
                "Retrying job %s (attempt %s/%s) in %s seconds",
                job_id,
                current_retries + 1,
                max_retries,
                backoff_seconds,
            )
            raise self.retry(exc=e, countdown=backoff_seconds)

        try:
            if "job" in locals():
                job.fail_job(str(e))
                try:
                    session.add(job)
                    session.commit()
                except Exception as inner_commit_error:
                    session.rollback()
                    logger.error("Failed to commit FAILED status for job %s: %s", job_id, inner_commit_error)
        except Exception as commit_error:
            logger.error("Failed to update job %s with error: %s", job_id, commit_error)

        raise Reject(str(e), requeue=False) from e

    finally:
        db_session.remove()
