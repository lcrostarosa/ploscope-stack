"""
Solver routes_http for PLOSolver.

This module provides solver-related endpoints including spot analysis,
hand bucketing, and player profiles.
"""
import uuid

from flask import Blueprint, jsonify, request

from src.backend.services.job_service import create_job, get_job_status

from ..utils.auth_utils import auth_required, get_enhanced_logger

logger = get_enhanced_logger(__name__)

solver_routes = Blueprint("solver", __name__)


@solver_routes.route("/config", methods=["GET"])
def get_solver_config():
    """Get solver configuration settings."""
    try:
        config = {
            "max_players": 6,
            "supported_game_types": ["plo", "plo_bomb_pot"],
            "default_stack_size": 100,
            "min_stack_size": 10,
            "max_stack_size": 1000,
            "supported_positions": ["UTG", "HJ", "CO", "BTN", "SB", "BB"],
            "supported_board_textures": ["paired", "monotone", "rainbow", "two_tone"],
            "solver_engines": ["cfr", "fictitious_play"],
            "accuracy_levels": ["fast", "medium", "high", "tournament"],
        }
        return jsonify(config), 200
    except Exception as e:
        logger.error(f"Error getting solver config: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/hand-buckets", methods=["GET"])
def get_hand_buckets():
    """Get pre-computed hand buckets for analysis."""
    try:
        # Basic hand bucket classifications for PLO
        hand_buckets = {
            "premium": {
                "description": "Premium PLO hands",
                "examples": ["AAKK", "AAJJ", "AAQQ", "KKQQ"],
                "equity_range": "65-85%",
                "play_frequency": "100%",
            },
            "strong": {
                "description": "Strong PLO hands",
                "examples": ["AAKJ", "AAJT", "KKJT", "QQJT"],
                "equity_range": "55-65%",
                "play_frequency": "85-95%",
            },
            "medium": {
                "description": "Medium strength PLO hands",
                "examples": ["AJTX", "KQJ9", "JT98", "T987"],
                "equity_range": "45-55%",
                "play_frequency": "60-80%",
            },
            "marginal": {
                "description": "Marginal PLO hands",
                "examples": ["A234", "KJ32", "QT54", "9876"],
                "equity_range": "35-45%",
                "play_frequency": "20-40%",
            },
            "weak": {
                "description": "Weak PLO hands",
                "examples": ["2345", "J432", "T532", "8432"],
                "equity_range": "20-35%",
                "play_frequency": "0-20%",
            },
        }
        return jsonify(hand_buckets), 200
    except Exception as e:
        logger.error(f"Error getting hand buckets: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/player-profiles", methods=["GET"])
def get_solver_player_profiles():
    """Get available player profiles for solver analysis."""
    try:
        # Return basic player profiles
        basic_profiles = {
            "tight_aggressive": {
                "name": "Tight Aggressive",
                "description": "Plays few hands but plays them aggressively",
                "vpip": 22,
                "pfr": 18,
                "aggression_factor": 3.5,
                "fold_to_3bet": 70,
            },
            "loose_aggressive": {
                "name": "Loose Aggressive",
                "description": "Plays many hands aggressively",
                "vpip": 35,
                "pfr": 28,
                "aggression_factor": 4.0,
                "fold_to_3bet": 55,
            },
            "tight_passive": {
                "name": "Tight Passive",
                "description": "Plays few hands and plays them passively",
                "vpip": 18,
                "pfr": 12,
                "aggression_factor": 1.8,
                "fold_to_3bet": 85,
            },
            "loose_passive": {
                "name": "Loose Passive",
                "description": "Plays many hands but plays them passively",
                "vpip": 45,
                "pfr": 15,
                "aggression_factor": 1.2,
                "fold_to_3bet": 60,
            },
        }
        return jsonify(basic_profiles), 200
    except Exception as e:
        logger.error(f"Error getting solver player profiles: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/player-profiles", methods=["POST"])
@auth_required
def create_solver_player_profile():
    """Create a new player profile for solver analysis."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Validate required fields
        required_fields = ["name", "description"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # For now, just return success - can be extended to save to database
        profile_id = str(uuid.uuid4())
        return (
            jsonify(
                {
                    "id": profile_id,
                    "message": "Profile created successfully",
                    "profile": data,
                }
            ),
            201,
        )
    except Exception as e:
        logger.error(f"Error creating solver player profile: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/saved-solutions", methods=["GET"])
@auth_required
def get_saved_solutions():
    """Get saved solver solutions for the current user."""
    try:
        # For now, return empty list - can be extended to load from database
        saved_solutions = []
        return jsonify(saved_solutions), 200
    except Exception as e:
        logger.error(f"Error getting saved solutions: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/saved-solutions/<solution_id>", methods=["GET"])
@auth_required
def get_saved_solution(solution_id):
    """Get a specific saved solution by ID."""
    try:
        # For now, return not found - can be extended to load from database
        return jsonify({"error": "Solution not found"}), 404
    except Exception as e:
        logger.error(f"Error getting saved solution: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/saved-solutions/<solution_id>", methods=["DELETE"])
@auth_required
def delete_saved_solution(solution_id):
    """Delete a saved solution by ID."""
    try:
        # For now, return success - can be extended to delete from database
        return jsonify({"message": "Solution deleted successfully"}), 200
    except Exception as e:
        logger.error(f"Error deleting saved solution: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/solve", methods=["POST"])
@auth_required
def solve_spot():
    """Submit a new solver job."""
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Input validation - prevent malicious payloads
        if not isinstance(data, dict):
            return jsonify({"error": "Invalid data format"}), 400

        # Limit payload size to prevent DoS
        if len(str(data)) > 100000:  # 100KB limit
            return jsonify({"error": "Payload too large"}), 400

        # Support legacy payload that wraps everything inside a gameState key
        if "gameState" in data:
            # Unwrap legacy format
            game_state = data["gameState"]
            # Merge into root level for easier handling
            data.update(game_state)

        # After possible unwrap, validate required fields
        required_fields = ["players", "board", "pot_size", "stack_sizes"]

        # Backwards-compat: auto-generate 'players' from hero_cards/opponents if missing
        if "players" not in data:
            hero_cards = data.get("hero_cards") or []
            opponents = data.get("opponents") or []

            # Convert hero and each opponent entry into unified player dict
            players_generated = []
            if hero_cards:
                players_generated.append({"cards": hero_cards})

            # Opponent entries may include specific_cards OR profile
            for opp in opponents:
                if opp is None:
                    continue
                if opp.get("specific_cards"):
                    players_generated.append({"cards": opp["specific_cards"]})
                else:
                    # If opponent is profile-based, we still add placeholder so indexes align
                    players_generated.append({"profile": opp.get("profile")})

            if players_generated:
                data["players"] = players_generated

        for field in required_fields:
            if field not in data or data[field] is None:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Create job
        logger = get_enhanced_logger(__name__)
        logger.debug(f"/solve called by user {request.current_user.id} with data: {data}")

        job_data = {
            "job_type": "SOLVER_ANALYSIS",
            "input_data": data,
        }

        job = create_job(job_data, request.current_user.id)
        if not job:
            logger.error("create_job returned None or False")
            return jsonify({"error": "Failed to create job"}), 500

        logger.info(f"Solver job created: {job.id} for user {request.current_user.id}")
        return jsonify({"job": {"id": job.id, "status": job.status.value}}), 201

    except Exception as e:
        logger.error(f"Error creating solver job: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/status/<job_id>", methods=["GET"])
@auth_required
def get_solver_status(job_id):
    """Get the status of a solver job."""
    try:
        status = get_job_status(job_id, request.current_user.id)
        if status is None:
            return jsonify({"error": "Job not found"}), 404

        return jsonify(status), 200

    except Exception as e:
        logger.error(f"Error getting solver status: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500


@solver_routes.route("/results/<job_id>", methods=["GET"])
@auth_required
def get_solver_results(job_id):
    """Get the results of a completed solver job."""
    try:
        status = get_job_status(job_id, request.current_user.id)
        if status is None:
            return jsonify({"error": "Job not found"}), 404

        if status.get("status") != "completed":
            return jsonify({"error": "Job not completed"}), 400

        return jsonify(status.get("results", {})), 200

    except Exception as e:
        logger.error(f"Error getting solver results: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500
