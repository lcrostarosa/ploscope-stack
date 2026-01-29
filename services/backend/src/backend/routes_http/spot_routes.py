import json
from random import sample

from core.equity.calculator import calculate_double_board_stats, simulate_estimated_equity
from core.services.game_utils import normalize_player_data
from flask import Blueprint, jsonify, request

from src.backend.database import db
from src.backend.models.job import Job, JobStatus
from src.backend.models.spot import Spot
from src.backend.models.user_credit import UserCredit
from src.backend.services.job_service import create_job

from ..utils.auth_utils import auth_required, get_enhanced_logger, log_user_action

# Create blueprint for spot routes
spot_routes = Blueprint("spots", __name__)
logger = get_enhanced_logger(__name__)


@spot_routes.route("/", methods=["POST", "OPTIONS"])
@auth_required
def save_spot():
    """Save a new spot with its configuration and results"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        try:
            data = request.get_json()
        except Exception as e:
            logger.error(f"JSON parsing error: {str(e)}")
            return jsonify({"error": "Invalid JSON data"}), 400

        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Validate required fields
        required_fields = ["name", "top_board", "bottom_board", "players"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Validate that name is not empty
        if not data["name"] or not data["name"].strip():
            return jsonify({"error": "Name cannot be empty"}), 400

        # Validate board and player data
        if not isinstance(data["top_board"], list) or not isinstance(data["bottom_board"], list):
            return jsonify({"error": "Boards must be provided as lists"}), 400

        if not isinstance(data["players"], list) or not all(isinstance(p, list) for p in data["players"]):
            return (
                jsonify({"error": "Players must be a list of lists"}),
                400,
            )

        # Get current user
        user = request.current_user

        # Create new spot
        spot = Spot(
            user_id=user.id,
            name=data["name"],
            description=data.get("description"),
            top_board=data["top_board"],
            bottom_board=data["bottom_board"],
            players=data["players"],
            simulation_runs=data.get("simulation_runs", 10000),
            max_hand_combinations=data.get("max_hand_combinations", 10000),
        )

        # If results are provided, save them
        if "results" in data:
            spot.results = data["results"]

        db.session.add(spot)
        db.session.commit()

        log_user_action("SPOT_SAVED", user.id, {"spot_name": spot.name})

        return (
            jsonify({"message": "Spot saved successfully", "spot": spot.to_dict()}),
            201,
        )

    except Exception as e:
        logger.error(f"Error saving spot: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Failed to save spot"}), 500


@spot_routes.route("/", methods=["GET", "OPTIONS"])
@auth_required
def get_spots():
    """Get all spots for the current user"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user
        spots = Spot.query.filter_by(user_id=user.id).order_by(Spot.created_at.desc()).all()

        return jsonify({"spots": [spot.to_dict() for spot in spots]}), 200

    except Exception as e:
        logger.error(f"Error retrieving spots: {str(e)}")
        return jsonify({"error": "Failed to retrieve spots"}), 500


@spot_routes.route("/<spot_id>", methods=["GET", "OPTIONS"])
@auth_required
def get_spot(spot_id):
    """Get a specific spot by ID"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user
        spot = Spot.query.filter_by(id=spot_id, user_id=user.id).first()

        if not spot:
            return jsonify({"error": "Spot not found"}), 404

        return jsonify({"spot": spot.to_dict()}), 200

    except Exception as e:
        logger.error(f"Error retrieving spot: {str(e)}")
        return jsonify({"error": "Failed to retrieve spot"}), 500


@spot_routes.route("/<spot_id>", methods=["PUT", "OPTIONS"])
@auth_required
def update_spot(spot_id):
    """Update a spot's configuration or results"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        user = request.current_user
        spot = Spot.query.filter_by(id=spot_id, user_id=user.id).first()

        if not spot:
            return jsonify({"error": "Spot not found"}), 404

        # Update allowed fields
        if "name" in data:
            spot.name = data["name"]
        if "description" in data:
            spot.description = data["description"]
        if "top_board" in data:
            spot.top_board = data["top_board"]
        if "bottom_board" in data:
            spot.bottom_board = data["bottom_board"]
        if "players" in data:
            spot.players = data["players"]
        if "simulation_runs" in data:
            spot.simulation_runs = data["simulation_runs"]
        if "max_hand_combinations" in data:
            spot.max_hand_combinations = data["max_hand_combinations"]
        if "results" in data:
            spot.results = data["results"]

        db.session.commit()

        log_user_action("SPOT_UPDATED", user.id, {"spot_name": spot.name})

        return (
            jsonify({"message": "Spot updated successfully", "spot": spot.to_dict()}),
            200,
        )

    except Exception as e:
        logger.error(f"Error updating spot: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Failed to update spot"}), 500


@spot_routes.route("/<spot_id>", methods=["DELETE", "OPTIONS"])
@auth_required
def delete_spot(spot_id):
    """Delete a spot"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user
        spot = Spot.query.filter_by(id=spot_id, user_id=user.id).first()

        if not spot:
            return jsonify({"error": "Spot not found"}), 404

        db.session.delete(spot)
        db.session.commit()

        log_user_action("SPOT_DELETED", user.id, {"spot_name": spot.name})

        return jsonify({"message": "Spot deleted successfully"}), 200

    except Exception as e:
        logger.error(f"Error deleting spot: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Failed to delete spot"}), 500


@spot_routes.route("/simulate", methods=["POST", "OPTIONS"])
@auth_required
def submit_spot_simulation():
    """Submit a spot for asynchronous simulation"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Validate required fields
        required_fields = ["top_board", "bottom_board", "players"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Get current user
        user = request.current_user

        # Check if user already has active jobs (queued or processing)
        active_jobs = Job.query.filter(
            Job.user_id == user.id,
            Job.status.in_([JobStatus.QUEUED, JobStatus.PROCESSING]),
        ).all()

        if active_jobs:
            return (
                jsonify(
                    {
                        "error": "Job already in progress",
                        "message": (
                            "You already have an active job running. "
                            "Please wait for it to complete before submitting a new one."
                        ),
                        "active_job_id": active_jobs[0].id,
                    }
                ),
                409,
            )  # Conflict status code

        # Check if user has credits
        if not user.credit_info:
            credit_info = UserCredit(user_id=user.id)
            db.session.add(credit_info)
            db.session.commit()
        else:
            credit_info = user.credit_info

        if not credit_info.can_use_credit(user.subscription_tier, "spot"):
            remaining = credit_info.get_remaining_credits(user.subscription_tier)
            return (
                jsonify(
                    {
                        "error": "Insufficient credits",
                        "message": "You have reached your spot simulation limit for your subscription tier.",
                        "credits_info": remaining,
                    }
                ),
                429,
            )

        # Prepare input data for the job
        input_data = {
            "top_board": data["top_board"],
            "bottom_board": data["bottom_board"],
            "players": data["players"],
            "simulation_runs": data.get("simulation_runs", 10000),
            "max_hand_combinations": data.get("max_hand_combinations", 10000),
            "spot_name": data.get("name", "Untitled Spot"),
            "spot_description": data.get("description"),
            "from_spot_mode": data.get("from_spot_mode", False),
        }

        # Estimate processing time (enhanced based on simulation parameters)
        simulation_runs = input_data.get("simulation_runs", 10000)
        max_hand_combinations = input_data.get("max_hand_combinations", 10000)
        num_players = len(input_data.get("players", []))

        # More accurate estimation based on actual parameters
        # Base time per 1000 simulation runs
        base_time_per_1k = 2  # seconds per 1000 runs

        # Adjust for number of players (more players = more calculations)
        player_factor = max(1, num_players * 0.5)

        # Adjust for hand combinations (more combinations = more time)
        combination_factor = min(max_hand_combinations / 10000, 5)  # Cap at 5x

        # Calculate estimated duration
        estimated_duration = int((simulation_runs / 1000) * base_time_per_1k * player_factor * combination_factor)

        # Clamp to reasonable bounds (10 seconds to 10 minutes)
        estimated_duration = max(10, min(estimated_duration, 600))

        # Create job using the new Celery-based job service
        job_data = {
            "job_type": "SPOT_SIMULATION",
            "input_data": input_data,
        }

        job = create_job(job_data, user.id)

        if job:
            # Use the credit and commit the job
            credit_info.use_credit()
            db.session.commit()

            log_user_action(
                "SPOT_SIMULATION_SUBMITTED",
                user.id,
                {
                    "job_id": job.id,
                    "spot_name": input_data["spot_name"],
                    "estimated_duration": estimated_duration,
                },
            )

            return (
                jsonify(
                    {
                        "message": "Spot simulation submitted successfully",
                        "job": job.to_dict(),
                        "credits_info": credit_info.get_remaining_credits(user.subscription_tier),
                    }
                ),
                201,
            )
        else:
            # Failed to create job, rollback the transaction
            db.session.rollback()

            return (
                jsonify({"error": "Failed to submit spot simulation for processing"}),
                500,
            )

    except Exception as e:
        logger.error(f"Error submitting spot simulation: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Failed to submit spot simulation"}), 500


@spot_routes.route("/run", methods=["POST", "OPTIONS"])
@auth_required
def run_spot_simulation():
    """
    Run immediate spot simulation.
    Allows calculation of equity for specific known hands against a configurable number of random opponents.
    """
    # Handle preflight requests
    if request.method == "OPTIONS":
        return jsonify({"message": "OK"})

    # Log request details for debugging
    logger.info(f"Received spot simulation request from origin: {request.headers.get('Origin', 'No Origin header')}")
    logger.debug(f"Request headers: {dict(request.headers)}")

    data = request.json
    logger.info("Received spot simulation request")
    logger.debug(f"Request data: {json.dumps(data, indent=2)}")

    players = data.get("players", [])  # Known players (hero + known opponents)
    top_board = data.get("topBoard", [])
    bottom_board = data.get("bottomBoard", [])
    num_random_opponents = data.get("numRandomOpponents", 1)
    # Reduce default iterations for faster performance
    simulation_runs = data.get("simulationRuns", 500)  # Reduced from 1000
    folded_cards = data.get("foldedCards", [])  # Cards that were folded and should be excluded
    # max_hand_combinations = data.get("maxHandCombinations", 10000)
    # Add quick mode option
    # quick_mode = data.get("quick_mode", True)  # Enable quick mode by default
    opponent_hand_combinations = data.get("opponent_hand_combinations", [])

    # Cards that are already in play and cannot be part of random hands
    pre_excluded_cards = set(c for c in folded_cards if c)
    pre_excluded_cards.update(c for c in top_board if c)
    pre_excluded_cards.update(c for c in bottom_board if c)

    if not players:
        logger.warning("No players with complete card sets found. Running fully random simulation.")
        num_players = 1 + num_random_opponents

        all_cards = [
            rank + suit
            for rank in [
                "2",
                "3",
                "4",
                "5",
                "6",
                "7",
                "8",
                "9",
                "T",
                "J",
                "Q",
                "K",
                "A",
            ]
            for suit in ["h", "d", "c", "s"]
        ]
        used_cards = pre_excluded_cards.copy()
        random_players = []
        for i in range(num_players):
            available_cards = [c for c in all_cards if c not in used_cards]
            player_cards = sample(available_cards, 4)
            used_cards.update(player_cards)
            random_players.append({"player_number": i + 1, "cards": player_cards})
        known_players = random_players
    else:
        # For spot mode, we allow empty boards (simulation will complete them)
        logger.info(
            f"Starting spot simulation with {simulation_runs} runs against {num_random_opponents} random opponents"
        )
        logger.debug(f"Known players: {len(players)}, Top board: {top_board}, Bottom board: {bottom_board}")

    results = []
    try:
        # Normalize player data to consistent dictionary format
        players = normalize_player_data(players)

        # Enhanced logic: Handle known opponents vs random opponents
        known_players = []
        for player in players:
            # Check if all cards are filled in (not empty, not "RANDOM")
            if all((card or "").strip() and (card or "").strip().upper() != "RANDOM" for card in player["cards"]):
                known_players.append(player)
            else:
                logger.debug(f"Player {player['player_number']} has incomplete cards, treating as random opponent")

        if not known_players:
            logger.warning("No players with complete card sets found. Running fully random simulation.")
            num_players = 1 + num_random_opponents

            all_cards = [
                rank + suit
                for rank in [
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "T",
                    "J",
                    "Q",
                    "K",
                    "A",
                ]
                for suit in ["h", "d", "c", "s"]
            ]
            used_cards = pre_excluded_cards.copy()
            random_players = []
            for i in range(num_players):
                available_cards = [c for c in all_cards if c not in used_cards]
                player_cards = sample(available_cards, 4)
                used_cards.update(player_cards)
                random_players.append({"player_number": i + 1, "cards": player_cards})
            known_players = random_players

        # Calculate total opponents (known + random)
        total_known_opponents = len(known_players) - 1  # Subtract 1 for hero
        additional_random_opponents = max(0, num_random_opponents - total_known_opponents)

        logger.info(
            f"Simulation setup: {len(known_players)} known players, "
            f"{additional_random_opponents} additional random opponents"
        )
        logger.debug(f"Folded cards to exclude: {folded_cards}")

        # Initialize double board analysis variables
        chop_both_percent = [0.0] * len(known_players)
        scoop_both_percent = [0.0] * len(known_players)
        split_top_percent = [0.0] * len(known_players)
        split_bottom_percent = [0.0] * len(known_players)

        # Only calculate double board stats if both boards are present
        if top_board and bottom_board:
            logger.debug("Calculating double board statistics...")
            hands = [player["cards"] for player in known_players]
            (
                chop_both_counts,
                scoop_both_counts,
                split_top_counts,
                split_bottom_counts,
            ) = calculate_double_board_stats(hands, top_board, bottom_board, num_iterations=simulation_runs)

            # Convert raw counts to decimal percentages for frontend display
            chop_both_percent = [(count / simulation_runs) for count in chop_both_counts]
            scoop_both_percent = [(count / simulation_runs) for count in scoop_both_counts]
            split_top_percent = [(count / simulation_runs) for count in split_top_counts]
            split_bottom_percent = [(count / simulation_runs) for count in split_bottom_counts]

        for i, player in enumerate(known_players):
            hand_combos = opponent_hand_combinations[i] if i < len(opponent_hand_combinations) else 5
            if top_board:
                (
                    top_estimated_equity,
                    _,
                    top_stats,
                    top_breakdown,
                    top_opponent_breakdown,
                ) = simulate_estimated_equity(
                    player["cards"],
                    top_board,
                    num_iterations=simulation_runs,
                    folded_cards=folded_cards,
                    max_hand_combinations=hand_combos,
                    num_opponents=num_random_opponents,
                )
            else:
                (
                    top_estimated_equity,
                    _,
                    top_stats,
                    top_breakdown,
                    top_opponent_breakdown,
                ) = simulate_estimated_equity(
                    player["cards"],
                    [],
                    num_iterations=simulation_runs,
                    folded_cards=folded_cards,
                    max_hand_combinations=hand_combos,
                    num_opponents=num_random_opponents,
                )

            if bottom_board:
                (
                    bottom_estimated_equity,
                    _,
                    bottom_stats,
                    bottom_breakdown,
                    bottom_opponent_breakdown,
                ) = simulate_estimated_equity(
                    player["cards"],
                    bottom_board,
                    num_iterations=simulation_runs,
                    folded_cards=folded_cards,
                    max_hand_combinations=hand_combos,
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
                    player["cards"],
                    [],
                    num_iterations=simulation_runs,
                    folded_cards=folded_cards,
                    max_hand_combinations=hand_combos,
                    num_opponents=num_random_opponents,
                )

            results.append(
                {
                    "player_number": player["player_number"],
                    "cards": player["cards"],
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
                    "known_opponents": len(known_players) - 1,
                    "random_opponents": additional_random_opponents,
                    "top_detailed_stats": top_stats,
                    "bottom_detailed_stats": bottom_stats,
                    "top_hand_breakdown": top_breakdown,
                    "bottom_hand_breakdown": bottom_breakdown,
                    "top_opponent_breakdown": top_opponent_breakdown,
                    "bottom_opponent_breakdown": bottom_opponent_breakdown,
                }
            )

        logger.info(f"Spot simulation completed successfully for {len(results)} results")
        logger.debug(f"Results: {json.dumps(results, indent=2)}")

        return jsonify(results)

    except Exception as e:
        logger.error(f"Error during spot simulation: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error during spot simulation"}), 500
