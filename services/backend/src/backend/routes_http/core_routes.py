"""
Core routes_http for PLOSolver.

This module provides core application endpoints including health checks,
player profiles, and equity calculations.
"""

import json
import os
import signal
from datetime import datetime

from core.equity.calculator import simulate_equity
from core.services.equity_service import (
    calculate_double_board_stats,
    categorize_hand_strength,
    get_enhanced_logger,
    simulate_estimated_equity,
)
from core.services.game_utils import calculate_exploits_vs_profile, normalize_player_data
from core.services.player_profiles import PlayerProfile
from core.services.showdown_service import resolve_showdown_payouts
from core.utils.card_utils import str_to_cards
from core.utils.evaluator_utils import evaluate_plo_best_hand
from flask import Blueprint, current_app, jsonify, request
from sqlalchemy import text

from src.backend.database import db
from src.backend.models.job import Job
from src.backend.models.user_credit import UserCredit
from src.backend.services.rabbitmq_service import get_message_queue_service

from ..utils.auth_utils import auth_required

logger = get_enhanced_logger(__name__)

core_routes = Blueprint("core", __name__)


@core_routes.route("/test", methods=["GET"])
def test_route():
    """Simple test route to verify Flask routing is working"""
    print("🧪 TEST ROUTE CALLED - Flask routing is working!")
    logger.info("🧪 Test route called - Flask routing is working!")
    return jsonify({"message": "Test route working", "timestamp": datetime.utcnow().isoformat()}), 200


@core_routes.route("/simple", methods=["GET"])
def simple_route():
    """Ultra-simple route with no dependencies"""
    print("🎯 SIMPLE ROUTE CALLED - No Flask extensions used!")
    return "Simple route working!", 200


@core_routes.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint for container monitoring - Environment variable hot reloading test"""
    print("🚨 HEALTH CHECK FUNCTION CALLED - THIS SHOULD APPEAR IMMEDIATELY")
    logger.info("🚨 HEALTH CHECK FUNCTION CALLED - THIS SHOULD APPEAR IMMEDIATELY")

    def timeout_handler(signum, frame):
        logger.error("⏰ Health check request timed out after 10 seconds")
        raise TimeoutError("Health check request timed out")

    # Set a 10-second timeout for the entire health check
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(10)

    try:
        logger.info("🔍 Health check endpoint called - starting health checks")

        database_status = "unhealthy"
        rabbitmq_status = "unhealthy"

        # Check database connectivity with minimal session usage
        logger.info("🔍 Starting database health check...")
        try:
            # Use a direct engine connection to avoid session issues
            # Wrap in app context to avoid "Working outside of application context" error
            logger.info("🔍 Creating app context for database check...")
            with current_app.app_context():
                logger.info("🔍 App context created, accessing db.engine...")
                engine = db.engine
                logger.info(f"🔍 Engine obtained: {type(engine)}")

                logger.info("🔍 Opening database connection...")
                with engine.begin() as connection:
                    logger.info("🔍 Connection opened, executing SELECT 1...")
                    result = connection.execute(text("SELECT 1"))
                    logger.info("🔍 Query executed, fetching result...")
                    result.fetchone()
                    logger.info("🔍 Result fetched successfully")
            database_status = "healthy"
            logger.info("✅ Database health check completed successfully")
        except Exception as e:
            logger.error(f"❌ Database health check failed: {str(e)}")
            logger.error(f"❌ Exception type: {type(e)}")
            import traceback

            logger.error(f"❌ Full traceback: {traceback.format_exc()}")
            database_status = "unhealthy"

        # Check RabbitMQ connectivity
        logger.info("🔍 Starting RabbitMQ health check...")
        try:
            # Wrap in app context to avoid "Working outside of application context" error
            logger.info("🔍 Creating app context for RabbitMQ check...")
            with current_app.app_context():
                logger.info("🔍 App context created, getting message queue service...")
                queue_manager = get_message_queue_service()
                logger.info(f"🔍 Queue manager obtained: {type(queue_manager)}")

                if queue_manager and hasattr(queue_manager, "health_check"):
                    logger.info("🔍 Calling queue manager health check...")
                    health = queue_manager.health_check()
                    logger.info(f"🔍 Health check result: {health}")
                    rabbitmq_status = "connected" if health.get("status") == "healthy" else "disconnected"
                else:
                    logger.warning("⚠️ Queue manager or health_check method not available")
                    rabbitmq_status = "disconnected"
            logger.info("✅ RabbitMQ health check completed successfully")
        except Exception as e:
            logger.error(f"❌ RabbitMQ health check failed: {str(e)}")
            logger.error(f"❌ Exception type: {type(e)}")
            import traceback

            logger.error(f"❌ Full traceback: {traceback.format_exc()}")
            rabbitmq_status = "error"

        # Get environment info for debugging
        logger.info("🔍 Gathering environment info...")
        env_info = {
            "FLASK_ENV": os.environ.get("FLASK_ENV", "not_set"),
            "NODE_ENV": os.environ.get("NODE_ENV", "not_set"),
            "ENVIRONMENT": os.environ.get("ENVIRONMENT", "not_set"),
            "TESTING": os.environ.get("TESTING", "not_set"),
        }
        logger.info(f"🔍 Environment info gathered: {env_info}")

        logger.info("🔍 Building response data...")
        response_data = {
            "status": "healthy" if database_status == "healthy" else "unhealthy",
            "timestamp": datetime.utcnow().isoformat(),
            "routes_grpc": {
                "database": database_status,
                "rabbitmq": rabbitmq_status,
            },
            "environment": env_info,
        }
        logger.info(f"🔍 Response data built: {response_data}")

        status_code = 200 if database_status == "healthy" else 503
        logger.info(f"🔍 Returning response with status code: {status_code}")
        logger.info("✅ Health check endpoint completed successfully")

        # Cancel the alarm since we're about to return successfully
        signal.alarm(0)

        return jsonify(response_data), status_code

    except TimeoutError as e:
        logger.error(f"⏰ Health check timed out: {e}")
        signal.alarm(0)  # Cancel the alarm
        return (
            jsonify(
                {
                    "status": "timeout",
                    "error": "Health check request timed out after 10 seconds",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
            408,
        )  # Request Timeout
    except Exception as e:
        logger.error(f"❌ Unexpected error in health check: {e}")
        signal.alarm(0)  # Cancel the alarm
        import traceback

        logger.error(f"❌ Full traceback: {traceback.format_exc()}")
        return (
            jsonify({"status": "error", "error": str(e), "timestamp": datetime.utcnow().isoformat()}),
            500,
        )  # Internal Server Error


@core_routes.route("/.well-known/acme-challenge/<token>", methods=["GET"])
def acme_challenge(token):
    """Handle ACME challenge for Let's Encrypt certificate generation"""
    try:
        # This endpoint is used by Let's Encrypt to verify domain ownership
        # The token is provided by Let's Encrypt and should be returned as-is
        # In a real implementation, you might want to validate the token
        # For now, we'll just return it as a simple challenge response

        logger.info(f"ACME challenge request for token: {token}")

        # For HTTP-01 challenge, we need to return the token as-is
        # This is the simplest form of ACME challenge validation
        response = current_app.response_class(response=token, status=200, mimetype="text/plain")

        # Add CORS headers for the challenge
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "*"

        return response

    except Exception as e:
        logger.error(f"ACME challenge error: {str(e)}")
        return jsonify({"error": "ACME challenge failed"}), 500


@core_routes.route("/player-profiles", methods=["GET"])
def get_player_profiles():
    """Get all available player profiles"""
    try:
        profiles = current_app.profile_manager.get_all_profiles()
        profile_data = {}

        for key, profile in profiles.items():
            profile_data[key] = profile.to_dict()

        return jsonify(profile_data), 200
    except Exception as e:
        logger.error(f"Error getting player profiles: {str(e)}")
        return jsonify({"error": "Failed to get player profiles"}), 500


@core_routes.route("/player-profiles", methods=["POST"])
def create_custom_profile():
    """Create a new custom player profile"""
    try:
        data = request.get_json()

        # Validate required fields
        required_fields = [
            "name",
            "description",
            "hand_range_tightness",
            "preflop_aggression",
            "flop_aggression",
            "turn_aggression",
            "river_aggression",
            "bluff_frequency",
            "value_bet_frequency",
            "fold_to_pressure",
            "threeb_frequency",
            "fourb_frequency",
            "cbet_frequency",
            "check_call_frequency",
            "donk_bet_frequency",
            "bet_sizing_aggression",
            "positional_awareness",
            "slow_play_frequency",
            "tilt_resistance",
        ]

        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Create profile
        profile = PlayerProfile.from_dict(data)

        # Add to manager
        if current_app.profile_manager.add_custom_profile(profile):
            # Save to file
            current_app.profile_manager.save_custom_profiles("custom_profiles.json")
            return (
                jsonify(
                    {
                        "message": "Profile created successfully",
                        "profile": profile.to_dict(),
                    }
                ),
                201,
            )
        else:
            return (
                jsonify({"error": "Profile name already exists or conflicts with predefined profile"}),
                400,
            )

    except Exception as e:
        logger.error(f"Error creating custom profile: {str(e)}")
        return jsonify({"error": "Failed to create profile"}), 500


@core_routes.route("/player-profiles/<profile_name>", methods=["DELETE"])
def delete_custom_profile(profile_name):
    """Delete a custom player profile"""
    try:
        if current_app.profile_manager.remove_custom_profile(profile_name):
            current_app.profile_manager.save_custom_profiles("custom_profiles.json")
            return jsonify({"message": "Profile deleted successfully"}), 200
        else:
            return (
                jsonify({"error": "Profile not found or cannot delete predefined profile"}),
                404,
            )

    except Exception as e:
        logger.error(f"Error deleting custom profile: {str(e)}")
        return jsonify({"error": "Failed to delete profile"}), 500


@core_routes.route("/credits", methods=["GET", "OPTIONS"])
@auth_required
def get_user_credits():
    """Get current user's credit information"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user

        # Get or create credit info (robust to missing relationship attribute in tests)
        credit_info = getattr(user, "credit_info", None)
        if not credit_info:
            credit_info = UserCredit(user_id=user.id)
            try:
                db.session.add(credit_info)
                db.session.commit()
            except Exception:
                # In unit tests, db may be a mock without full behavior
                pass
            # attach to user for subsequent calls in this request
            try:
                setattr(user, "credit_info", credit_info)
            except Exception:
                pass

        return (
            jsonify({"credits_info": credit_info.get_remaining_credits(user.subscription_tier)}),
            200,
        )

    except Exception as e:
        logger.error(f"Get credits error: {str(e)}", exc_info=True)
        return jsonify({"error": "Failed to get credit information"}), 500


@core_routes.route("/simulated-equity", methods=["POST", "OPTIONS"])
def calculate_equity():
    # Handle preflight requests
    if request.method == "OPTIONS":
        return jsonify({"message": "OK"})

    # Log request details for debugging
    logger.info(f"Received request from origin: {request.headers.get('Origin', 'No Origin header')}")
    logger.debug(f"Request headers: {dict(request.headers)}")

    data = request.json
    logger.info(f"Received equity calculation request for {len(data.get('players', []))} players")
    logger.debug(f"Request data: {json.dumps(data, indent=2)}")

    players = data.get("players", [])
    top_board = data.get("topBoard", [])
    bottom_board = data.get("bottomBoard", [])
    # Reduce default iterations for faster performance
    num_iterations = data.get("num_iterations", 10000)  # Reduced from 10000
    # Add option to skip detailed calculations for faster results
    quick_mode = data.get("quick_mode", True)  # Enable quick mode by default

    # Cards that are already in play and cannot be part of random hands
    pre_excluded_cards = set(c for c in bottom_board if c)
    pre_excluded_cards.update(c for c in top_board if c)

    if not players:
        logger.error("Missing players in request")
        return jsonify({"error": "Missing players"}), 400

    if not top_board:
        logger.error("Missing top board in request")
        return jsonify({"error": "Missing top board"}), 400

    if not bottom_board:
        logger.error("Missing bottom board in request")
        return jsonify({"error": "Missing bottom board"}), 400

    # Add board length validation
    if top_board and len(top_board) > 5:
        return jsonify({"error": "Top board cannot have more than 5 cards"}), 400
    if bottom_board and len(bottom_board) > 5:
        return jsonify({"error": "Bottom board cannot have more than 5 cards"}), 400

    logger.info(f"Starting equity simulation with {num_iterations} iterations (quick_mode={quick_mode})")
    logger.debug(f"Top board: {top_board}, Bottom board: {bottom_board}")

    # Normalize player data to consistent dictionary format
    players = normalize_player_data(players)
    hands = [player["cards"] for player in players]

    try:
        # Calculate actual equity (considering all players' cards)
        logger.debug("Calculating actual equity for top board...")
        top_actual_equity, top_tie_percent = simulate_equity(
            hands, top_board, num_iterations=num_iterations, double_board=False
        )

        logger.debug("Calculating actual equity for bottom board...")
        bottom_actual_equity, bottom_tie_percent = simulate_equity(
            hands, bottom_board, num_iterations=num_iterations, double_board=False
        )

        # Calculate double board statistics
        logger.debug("Calculating double board statistics...")
        (
            chop_both_counts,
            scoop_both_counts,
            split_top_counts,
            split_bottom_counts,
        ) = calculate_double_board_stats(hands, top_board, bottom_board, num_iterations=num_iterations)

        # Convert raw counts to decimal percentages for frontend display
        chop_both_percent = [(count / num_iterations) for count in chop_both_counts]
        scoop_both_percent = [(count / num_iterations) for count in scoop_both_counts]
        split_top_percent = [(count / num_iterations) for count in split_top_counts]
        split_bottom_percent = [(count / num_iterations) for count in split_bottom_counts]

        results = []
        for i, player in enumerate(players):
            result_data = {
                "player_number": player["player_number"],
                "cards": player["cards"],
                "top_actual_equity": top_actual_equity[i],
                "bottom_actual_equity": bottom_actual_equity[i],
                # Whole hand analysis
                "chop_both_boards": chop_both_percent[i],
                "scoop_both_boards": scoop_both_percent[i],
                "split_top": split_top_percent[i],
                "split_bottom": split_bottom_percent[i],
            }

            if not quick_mode:
                # Only calculate estimated equity when detailed analysis is requested
                logger.debug(f"Calculating estimated equity for player {player['player_number']}...")
                top_estimated_equity, _, _, _, _ = simulate_estimated_equity(
                    player["cards"],
                    top_board,
                    num_iterations=num_iterations,
                    num_opponents=7,
                )
                bottom_estimated_equity, _, _, _, _ = simulate_estimated_equity(
                    player["cards"],
                    bottom_board,
                    num_iterations=num_iterations,
                    num_opponents=7,
                )
                result_data["top_estimated_equity"] = top_estimated_equity / 100
                result_data["bottom_estimated_equity"] = bottom_estimated_equity / 100
            else:
                # Use actual equity as estimated equity in quick mode
                result_data["top_estimated_equity"] = top_actual_equity[i] / 100
                result_data["bottom_estimated_equity"] = bottom_actual_equity[i] / 100

            # Compute best-hand category and used cards per board
            try:
                hole_treys = str_to_cards(player["cards"])  # validation handled earlier
                top_treys = str_to_cards(top_board)
                bottom_treys = str_to_cards(bottom_board)

                if len(top_treys) >= 3:
                    top_score, top_hole_used, top_board_used = evaluate_plo_best_hand(hole_treys, top_treys)
                    result_data["top_hand_category"] = categorize_hand_strength(top_score)
                    result_data["top_hand_used_hole"] = top_hole_used
                    result_data["top_hand_used_board"] = top_board_used
                else:
                    result_data["top_hand_category"] = "TBD"

                if len(bottom_treys) >= 3:
                    (
                        bottom_score,
                        bottom_hole_used,
                        bottom_board_used,
                    ) = evaluate_plo_best_hand(hole_treys, bottom_treys)
                    result_data["bottom_hand_category"] = categorize_hand_strength(bottom_score)
                    result_data["bottom_hand_used_hole"] = bottom_hole_used
                    result_data["bottom_hand_used_board"] = bottom_board_used
                else:
                    result_data["bottom_hand_category"] = "TBD"
            except Exception as e:
                logger.error(f"Failed to compute hand categories: {e}")
                result_data.setdefault("top_hand_category", "TBD")
                result_data.setdefault("bottom_hand_category", "TBD")

            results.append(result_data)

        logger.info(f"Equity calculation completed successfully for {len(players)} players")
        logger.debug(f"Results: {json.dumps(results, indent=2)}")

        return jsonify(results)

    except Exception as e:
        logger.error(f"Error during equity calculation: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error during calculation"}), 500


@core_routes.route("/simulate-vs-profiles", methods=["POST"])
def simulate_vs_profiles():
    """Simulate hero vs specific player profiles"""
    try:
        data = request.get_json()

        # Validate input
        hero_cards = data.get("hero_cards")
        opponent_profiles = data.get("opponent_profiles", [])
        top_board = data.get("top_board", [])
        bottom_board = data.get("bottom_board", [])
        num_iterations = data.get("num_iterations", 10000)

        if not hero_cards or len(hero_cards) != 4:
            return jsonify({"error": "Hero cards must be exactly 4 cards"}), 400

        if not opponent_profiles:
            opponent_profiles = ["random"] * 7  # Default to random opponents

        # For now, we'll calculate basic equity against the profiles
        # This is a simplified version - in a full implementation, you'd want to
        # adjust the simulation based on each profile's playing style

        results = []

        # Calculate estimated equity for hero
        hero_top_equity, _, hero_top_stats, _, _ = simulate_estimated_equity(
            hero_cards,
            top_board,
            num_iterations=num_iterations,
            num_opponents=len(opponent_profiles),
        )
        hero_bottom_equity, _, hero_bottom_stats, _, _ = simulate_estimated_equity(
            hero_cards,
            bottom_board,
            num_iterations=num_iterations,
            num_opponents=len(opponent_profiles),
        )

        results.append(
            {
                "player_type": "hero",
                "cards": hero_cards,
                "top_equity": hero_top_equity / 100,
                "bottom_equity": hero_bottom_equity / 100,
                "top_detailed_stats": hero_top_stats,
                "bottom_detailed_stats": hero_bottom_stats,
                "profiles_faced": opponent_profiles,
            }
        )

        # Add profile-specific analysis
        profile_analysis = {}
        for i, profile_name in enumerate(opponent_profiles):
            if profile_name != "random":
                profile = current_app.profile_manager.get_profile(profile_name)
                if profile:
                    # Calculate suggested exploits based on profile
                    exploits = calculate_exploits_vs_profile(profile, hero_top_equity, hero_bottom_equity)
                    profile_analysis[f"opponent_{i + 1}"] = {
                        "profile": profile.to_dict(),
                        "suggested_exploits": exploits,
                    }

        results.append({"profile_analysis": profile_analysis, "simulation_runs": num_iterations})

        return jsonify(results), 200

    except Exception as e:
        logger.error(f"Error in profile simulation: {str(e)}")
        return jsonify({"error": "Failed to simulate vs profiles"}), 500


@core_routes.route("/resolve-showdown", methods=["POST", "OPTIONS"])
def resolve_showdown():
    """Resolve a double-board showdown with side pots and return per-player payouts.

    Request body:
    {
      "players": [{ "player_number": 1, "cards": ["Ah","Kd","Qc","Js"] }, ...],
      "topBoard": ["..","..","..","..",".."],
      "bottomBoard": ["..","..","..","..",".."],
      "playerInvested": [int, ...],
      "foldedPlayers": [indices]
    }
    """
    if request.method == "OPTIONS":
        return jsonify({"message": "OK"})

    try:
        data = request.get_json() or {}
        players = data.get("players", [])
        top_board = data.get("topBoard", [])
        bottom_board = data.get("bottomBoard", [])
        player_invested = data.get("playerInvested", [])
        folded_players = data.get("foldedPlayers", [])

        if not isinstance(players, list) or not players:
            return jsonify({"error": "players is required"}), 400
        if not isinstance(top_board, list) or len(top_board) < 3:
            return jsonify({"error": "topBoard must have at least 3 cards"}), 400
        if not isinstance(bottom_board, list) or len(bottom_board) < 3:
            return jsonify({"error": "bottomBoard must have at least 3 cards"}), 400
        if not isinstance(player_invested, list) or not player_invested:
            return jsonify({"error": "playerInvested is required"}), 400

        payouts, details = resolve_showdown_payouts(
            players=players,
            top_board=top_board,
            bottom_board=bottom_board,
            player_invested=player_invested,
            folded_players=folded_players or [],
        )

        return jsonify({"payouts": payouts, "details": details}), 200
    except Exception as e:
        logger.error(f"Error resolving showdown: {e}", exc_info=True)
        return jsonify({"error": "Failed to resolve showdown"}), 500


@core_routes.route("/jobs", methods=["GET", "OPTIONS"])
@auth_required
def get_user_jobs():
    """Get all jobs for the current user"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user

        # Get all jobs for the user
        jobs = Job.query.filter_by(user_id=user.id).order_by(Job.created_at.desc()).all()

        return jsonify({"jobs": [job.to_dict() for job in jobs]}), 200

    except Exception as e:
        logger.error(f"Get user jobs error: {str(e)}")
        return jsonify({"error": "Failed to get user jobs"}), 500
