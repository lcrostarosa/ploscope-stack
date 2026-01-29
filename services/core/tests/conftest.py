"""Test configuration and fixtures for plosolver_core tests.

This module provides fixtures and configuration for plosolver_core unit tests.
"""

import os
import sys
from unittest.mock import Mock

import pytest
from flask import Flask, jsonify, request

from core.equity.calculator import calculate_double_board_stats, categorize_hand_strength, simulate_equity
from core.services.card_service import str_to_cards
from core.services.showdown_service import resolve_showdown_payouts
from core.utils.evaluator_utils import evaluate_plo_hand

# Add the src directory to the Python path so we can import core modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))


# Database models removed - core package no longer includes database functionality
# JobStatus and JobType would be defined in the application layer

# Try to import the app factory from backend
try:
    from backend.app import create_app
except ImportError:
    # If we can't import from backend, create a minimal Flask app
    def create_app(config_name="testing"):  # pylint: disable=unused-argument
        """Create a minimal Flask app for testing purposes.

        Args:
            config_name: Configuration name (unused, kept for compatibility)

        Returns:
            Flask: Configured Flask application for testing
        """
        flask_app = Flask(__name__)
        flask_app.config["TESTING"] = True
        flask_app.config["SECRET_KEY"] = "test-secret-key"
        # Database configuration removed - core package no longer includes database functionality

        def _process_single_board_simulation(hands, top_board, num_iterations):
            """Process single board equity simulation."""
            equity, tie_percent = simulate_equity(hands, top_board, num_iterations)

            results = []
            for i, hand in enumerate(hands):
                hand_int = str_to_cards(hand)
                board_int = str_to_cards(top_board) if top_board else []

                if len(board_int) >= 3:
                    score = evaluate_plo_hand(hand_int, board_int)
                    category = categorize_hand_strength(score)
                else:
                    category = "Preflop"

                results.append(
                    {
                        "player_number": i + 1,
                        "equity": equity[i] if i < len(equity) else 0,
                        "tie_percent": tie_percent[i] if i < len(tie_percent) else 0,
                        "hand_category": category,
                    }
                )

            return results

        def _process_double_board_simulation(hands, top_board, bottom_board, num_iterations):
            """Process double board equity simulation."""
            chop_both, scoop_both, split_top, split_bottom = calculate_double_board_stats(
                hands, top_board, bottom_board, num_iterations
            )

            results = []
            for i, hand in enumerate(hands):
                hand_int = str_to_cards(hand)
                top_board_int = str_to_cards(top_board) if top_board else []
                bottom_board_int = str_to_cards(bottom_board) if bottom_board else []

                top_category = "Preflop"
                bottom_category = "Preflop"

                if len(top_board_int) >= 3:
                    top_score = evaluate_plo_hand(hand_int, top_board_int)
                    top_category = categorize_hand_strength(top_score)

                if len(bottom_board_int) >= 3:
                    bottom_score = evaluate_plo_hand(hand_int, bottom_board_int)
                    bottom_category = categorize_hand_strength(bottom_score)

                results.append(
                    {
                        "player_number": i + 1,
                        "chop_both": chop_both[i] if i < len(chop_both) else 0,
                        "scoop_both": scoop_both[i] if i < len(scoop_both) else 0,
                        "split_top": split_top[i] if i < len(split_top) else 0,
                        "split_bottom": split_bottom[i] if i < len(split_bottom) else 0,
                        "top_hand_category": top_category,
                        "bottom_hand_category": bottom_category,
                    }
                )

            return results

        # Add mock API routes for testing
        @flask_app.route("/api/simulated-equity", methods=["POST"])
        def mock_simulated_equity():
            try:
                data = request.get_json()
                if not data:
                    return jsonify({"error": "Invalid JSON"}), 400

                players = data.get("players", [])
                top_board = data.get("topBoard", [])
                bottom_board = data.get("bottomBoard", [])
                num_iterations = data.get("num_iterations", 100)

                if not players:
                    return jsonify({"error": "No players provided"}), 400

                # Extract hands from players
                hands = [player.get("cards", []) for player in players]

                # Process simulation based on board type
                if not bottom_board:
                    results = _process_single_board_simulation(hands, top_board, num_iterations)
                else:
                    results = _process_double_board_simulation(hands, top_board, bottom_board, num_iterations)

                return jsonify(results)

            except (ValueError, TypeError, KeyError) as e:
                return jsonify({"error": str(e)}), 500

        @flask_app.route("/api/resolve-showdown", methods=["POST"])
        def mock_resolve_showdown():
            try:
                data = request.get_json()
                if not data:
                    return jsonify({"error": "Invalid JSON"}), 400

                players = data.get("players", [])
                top_board = data.get("topBoard", [])
                bottom_board = data.get("bottomBoard", [])
                player_invested = data.get("playerInvested", [])
                folded_players = data.get("foldedPlayers", [])

                if not players or not top_board or not bottom_board:
                    return jsonify({"error": "Missing required data"}), 400

                # Resolve showdown
                payouts, details = resolve_showdown_payouts(
                    players, top_board, bottom_board, player_invested, folded_players
                )

                return jsonify({"payouts": payouts, "details": details})

            except (ValueError, TypeError, KeyError) as e:
                return jsonify({"error": str(e)}), 500

        return flask_app


# ============================================================================
# FLASK APPLICATION FIXTURES
# ============================================================================


@pytest.fixture(scope="function")
def app():
    """Function-wide test Flask application with mocked database."""
    # Create app with testing configuration
    test_app = create_app("testing")

    # Configure app for testing
    test_app.config["TESTING"] = True
    test_app.config["WTF_CSRF_ENABLED"] = False
    # Database configuration removed - core package no longer includes database functionality

    # Database initialization removed - core package no longer includes database functionality
    with test_app.app_context():
        yield test_app


@pytest.fixture(scope="function")
def client(app):  # pylint: disable=redefined-outer-name
    """A test client for the app."""
    return app.test_client()


# ============================================================================
# DATABASE MOCK FIXTURES
# ============================================================================


@pytest.fixture(scope="function")
def mock_db_session():
    """Mock database session for unit tests."""
    mock_session = Mock()
    mock_session.add = Mock()
    mock_session.commit = Mock()
    mock_session.rollback = Mock()
    mock_session.query = Mock()
    mock_session.flush = Mock()
    mock_session.close = Mock()
    return mock_session


@pytest.fixture(scope="function")
def mock_db_query():
    """Mock database query for unit tests."""
    mock_query = Mock()
    mock_query.filter_by = Mock(return_value=mock_query)
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=None)
    mock_query.all = Mock(return_value=[])
    mock_query.count = Mock(return_value=0)
    mock_query.delete = Mock(return_value=0)
    return mock_query


# ============================================================================
# MODEL MOCK FIXTURES
# ============================================================================


@pytest.fixture(scope="function")
def mock_user():
    """Mock User model for unit tests."""
    user = Mock()
    user.id = "test_user_id"
    user.email = "test@example.com"
    user.password_hash = "mock_password_hash"
    user.is_active = True
    user.created_at = "2023-01-01T00:00:00Z"
    user.updated_at = "2023-01-01T00:00:00Z"
    user.is_oauth = False
    user.oauth_provider = None
    user.oauth_id = None
    user.display_name = "Test User"
    user.first_name = "Test"
    user.last_name = "User"
    user.to_dict = Mock(
        return_value={
            "id": user.id,
            "email": user.email,
            "is_active": user.is_active,
            "display_name": user.display_name,
        }
    )
    return user


@pytest.fixture(scope="function")
def mock_job():
    """Mock Job model for unit tests."""
    job = Mock()
    job.id = "test_job_id"
    job.user_id = "test_user_id"
    job.job_type = "SPOT_SIMULATION"  # Mock job type
    job.status = "QUEUED"  # Mock job status
    job.input_data = {"test": "data"}
    job.output_data = None
    job.error_message = None
    job.created_at = "2023-01-01T00:00:00Z"
    job.updated_at = "2023-01-01T00:00:00Z"
    job.queue_message_id = None
    job.estimated_duration = None
    job.actual_duration = None
    job.to_dict = Mock(
        return_value={
            "id": job.id,
            "user_id": job.user_id,
            "job_type": job.job_type,
            "status": job.status,
            "input_data": job.input_data,
        }
    )
    return job


@pytest.fixture(scope="function")
def mock_spot():
    """Mock Spot model for unit tests."""
    spot = Mock()
    spot.id = "test_spot_id"
    spot.user_id = "test_user_id"
    spot.name = "Test Spot"
    spot.game_state = {"test": "game_state"}
    spot.results = {"test": "results"}
    spot.created_at = "2023-01-01T00:00:00Z"
    spot.updated_at = "2023-01-01T00:00:00Z"
    spot.description = "Test spot description"
    spot.to_dict = Mock(
        return_value={
            "id": spot.id,
            "user_id": spot.user_id,
            "name": spot.name,
            "game_state": spot.game_state,
            "results": spot.results,
        }
    )
    return spot


@pytest.fixture(scope="function")
def mock_solver_solution():
    """Mock SolverSolution model for unit tests."""
    solution = Mock()
    solution.id = "test_solution_id"
    solution.user_id = "test_user_id"
    solution.name = "Test Solution"
    solution.game_state = {"test": "game_state"}
    solution.solution = {"test": "solution"}
    solution.solve_time = 1.5
    solution.created_at = "2023-01-01T00:00:00Z"
    solution.updated_at = "2023-01-01T00:00:00Z"
    solution.description = "Test solution description"
    solution.to_dict = Mock(
        return_value={
            "id": solution.id,
            "user_id": solution.user_id,
            "name": solution.name,
            "game_state": solution.game_state,
            "solution": solution.solution,
        }
    )
    return solution


# ============================================================================
# SAMPLE DATA FIXTURES
# ============================================================================


@pytest.fixture(scope="function")
def sample_spot_results():
    """Sample spot simulation results for testing."""
    return {
        "players": [
            {
                "player_number": 1,
                "cards": ["Ah", "Kh", "Qh", "Jh"],
                "equity": 85.5,
                "win_count": 855,
                "tie_count": 0,
                "loss_count": 145,
                "hand_breakdown": {
                    "Straight Flush": 50,
                    "Four of a Kind": 100,
                    "Full House": 200,
                    "Flush": 300,
                    "Straight": 150,
                    "Three of a Kind": 50,
                    "Two Pair": 5,
                    "One Pair": 0,
                    "High Card": 0,
                },
            },
            {
                "player_number": 2,
                "cards": ["2c", "3c", "4c", "5c"],
                "equity": 14.5,
                "win_count": 145,
                "tie_count": 0,
                "loss_count": 855,
                "hand_breakdown": {
                    "Straight Flush": 10,
                    "Four of a Kind": 5,
                    "Full House": 10,
                    "Flush": 20,
                    "Straight": 50,
                    "Three of a Kind": 30,
                    "Two Pair": 15,
                    "One Pair": 5,
                    "High Card": 0,
                },
            },
        ],
        "board": {"top": ["Th", "9h", "8h"], "bottom": ["7s", "6s", "5s"]},
        "num_iterations": 1000,
        "simulation_time": 0.15,
    }


@pytest.fixture(scope="function")
def sample_multiple_opponents_results():
    """Sample spot simulation results with multiple opponents for testing."""
    return {
        "players": [
            {
                "player_number": 1,
                "cards": ["Ah", "Kh", "Qh", "Jh"],
                "equity": 60.5,
                "win_count": 605,
                "tie_count": 0,
                "loss_count": 395,
            },
            {
                "player_number": 2,
                "cards": ["As", "Ks", "Qs", "Js"],
                "equity": 25.0,
                "win_count": 250,
                "tie_count": 0,
                "loss_count": 750,
            },
            {
                "player_number": 3,
                "cards": ["2c", "3c", "4c", "5c"],
                "equity": 14.5,
                "win_count": 145,
                "tie_count": 0,
                "loss_count": 855,
            },
        ],
        "board": {"top": ["Th", "9h", "8h"], "bottom": ["7s", "6s", "5s"]},
        "num_iterations": 1000,
        "simulation_time": 0.25,
    }
