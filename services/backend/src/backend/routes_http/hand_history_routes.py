import os
import queue
import threading

from core.services.hand_history_parser import HandHistoryParser, calculate_file_hash, is_plo_hand
from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity
from werkzeug.utils import secure_filename

from src.backend.core_compatibility import ParsedHand
from src.backend.database import db
from src.backend.models.hand_history import HandHistory
from src.backend.utils.auth_utils import auth_required, get_enhanced_logger, log_user_action

logger = get_enhanced_logger(__name__)

# Create blueprint
hand_history_bp = Blueprint("hand_history", __name__)

# Configuration
ALLOWED_EXTENSIONS = {"txt", "log", "xml"}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB
UPLOAD_FOLDER = os.path.join(os.getcwd(), "uploads", "hand_histories")

# Ensure upload directory exists
try:
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
except PermissionError:
    # Fallback to /tmp if we don't have permission for current directory
    UPLOAD_FOLDER = "/tmp/uploads/hand_histories"
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Background processing queue
processing_queue = queue.Queue()
processing_thread = None


def allowed_file(filename):
    """Check if file extension is allowed"""
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


def start_background_processor():
    """Start the background processing thread"""
    global processing_thread
    if processing_thread is None or not processing_thread.is_alive():
        processing_thread = threading.Thread(target=process_hand_histories_worker, daemon=True)
        processing_thread.start()
        logger.info("Hand history background processor started")


def process_hand_histories_worker():
    """Background worker to process uploaded hand histories"""
    parser = HandHistoryParser()

    # Add safety limits to prevent runaway processes
    max_iterations = 86400  # 24 hours worth of processing
    iteration_count = 0

    while iteration_count < max_iterations:
        try:
            # Get next item from queue (blocks until available)
            hand_history_id = processing_queue.get(timeout=1)

            with current_app.app_context():
                process_single_hand_history(hand_history_id, parser)
                processing_queue.task_done()

            iteration_count += 1

        except queue.Empty:
            continue
        except Exception as e:
            logger.error(f"Error in background processor: {e}")
            continue


def process_single_hand_history(hand_history_id: str, parser: HandHistoryParser):
    """Process a single hand history file"""
    try:
        # Get hand history record
        hand_history = HandHistory.query.get(hand_history_id)
        if not hand_history:
            logger.error(f"Hand history {hand_history_id} not found")
            return

        # Update status to processing
        hand_history.status = "processing"
        db.session.commit()

        # Read file content
        file_path = os.path.join(UPLOAD_FOLDER, f"{hand_history_id}.txt")
        if not os.path.exists(file_path):
            hand_history.status = "failed"
            hand_history.error_message = "File not found"
            db.session.commit()
            return

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Parse the file
        parsed_hands, errors = parser.parse_file(content, hand_history.filename)

        if errors:
            hand_history.error_message = "; ".join(errors[:5])  # Store first 5 errors

        # Filter for PLO hands only
        plo_hands = [hand for hand in parsed_hands if is_plo_hand(hand.game_type)]

        hand_history.total_hands = len(plo_hands)

        if not plo_hands:
            hand_history.status = "completed"
            hand_history.error_message = "No PLO hands found in file"
            db.session.commit()
            return

        # Save parsed hands to database
        session_results = []
        earliest_time = None
        latest_time = None

        for i, parsed_hand in enumerate(plo_hands):
            try:
                # Create ParsedHand record
                db_hand = ParsedHand(
                    hand_history_id=hand_history_id,
                    user_id=hand_history.user_id,
                    hand_id=parsed_hand.hand_id,
                    hand_datetime=parsed_hand.datetime,
                    game_type=parsed_hand.game_type,
                )

                # Set additional fields
                db_hand.table_name = parsed_hand.table_name
                db_hand.stakes = parsed_hand.stakes
                db_hand.max_players = parsed_hand.max_players
                db_hand.hero_cards = parsed_hand.hero_cards
                db_hand.board_cards = parsed_hand.board_cards
                db_hand.pot_size = parsed_hand.pot_size
                db_hand.hero_result = parsed_hand.hero_result
                db_hand.showdown_reached = parsed_hand.showdown_reached

                # Convert players and actions to JSON
                db_hand.players = [
                    {
                        "name": p.name,
                        "seat": p.seat,
                        "stack": p.stack,
                        "is_hero": p.is_hero,
                    }
                    for p in parsed_hand.players
                ]

                db_hand.actions = [
                    {
                        "player": a.player,
                        "action_type": a.action_type,
                        "amount": a.amount,
                        "street": a.street,
                    }
                    for a in parsed_hand.actions
                ]

                db.session.add(db_hand)

                # Track session statistics
                if parsed_hand.hero_result is not None:
                    session_results.append(parsed_hand.hero_result)

                # Track time range
                if earliest_time is None or parsed_hand.datetime < earliest_time:
                    earliest_time = parsed_hand.datetime
                if latest_time is None or parsed_hand.datetime > latest_time:
                    latest_time = parsed_hand.datetime

                # Update progress
                hand_history.processed_hands = i + 1
                if (i + 1) % 100 == 0:  # Commit every 100 hands
                    db.session.commit()

            except Exception as e:
                logger.error(f"Error saving hand {parsed_hand.hand_id}: {e}")
                continue

        # Calculate session summary
        if session_results:
            hand_history.total_profit = sum(session_results)

            # Calculate BB/100 if we have stakes info
            if hand_history.total_hands > 0:
                # Try to extract big blind from first hand's stakes
                first_hand = plo_hands[0]
                stakes_parts = first_hand.stakes.replace("$", "").split("/")
                if len(stakes_parts) == 2:
                    try:
                        big_blind = float(stakes_parts[1])
                        hand_history.bb_per_100 = (
                            (hand_history.total_profit / big_blind) / hand_history.total_hands * 100
                        )
                    except ValueError:
                        pass

        hand_history.session_start = earliest_time
        hand_history.session_end = latest_time
        hand_history.status = "completed"

        db.session.commit()

        # Clean up uploaded file
        try:
            os.remove(file_path)
        except OSError:
            pass

        logger.info(f"Successfully processed hand history {hand_history_id}: {hand_history.total_hands} hands")

    except Exception as e:
        logger.error(f"Error processing hand history {hand_history_id}: {e}")

        # Update status to failed
        try:
            hand_history = HandHistory.query.get(hand_history_id)
            if hand_history:
                hand_history.status = "failed"
                hand_history.error_message = str(e)
                db.session.commit()
        except Exception:
            pass


@hand_history_bp.route("/api/hand-histories/upload", methods=["POST"])
@auth_required
def upload_hand_history():
    """Upload a hand history file for processing"""
    try:
        user_id = get_jwt_identity()

        # Check if file is present
        if "file" not in request.files:
            return jsonify({"error": "No file uploaded"}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "No file selected"}), 400

        if not file or not allowed_file(file.filename):
            return jsonify({"error": "Invalid file type. Allowed: txt, log, xml"}), 400

        # Check file size
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)

        if file_size > MAX_FILE_SIZE:
            return (
                jsonify({"error": f"File too large. Maximum size: {MAX_FILE_SIZE // (1024 * 1024)}MB"}),
                400,
            )

        # Read file content
        content = file.read().decode("utf-8", errors="ignore")

        if not content.strip():
            return jsonify({"error": "File is empty or unreadable"}), 400

        # Calculate file hash to prevent duplicates
        file_hash = calculate_file_hash(content)

        # Check for existing file
        existing = HandHistory.query.filter_by(user_id=user_id, file_hash=file_hash).first()

        if existing:
            return (
                jsonify(
                    {
                        "error": "This file has already been uploaded",
                        "existing_id": existing.id,
                    }
                ),
                409,
            )

        # Detect poker site
        parser = HandHistoryParser()
        poker_site = parser.detect_site(content)

        # Create hand history record
        filename = secure_filename(file.filename)
        hand_history = HandHistory(
            user_id=user_id,
            filename=filename,
            file_hash=file_hash,
            poker_site=poker_site,
        )

        db.session.add(hand_history)
        db.session.commit()

        # Save file for processing
        file_path = os.path.join(UPLOAD_FOLDER, f"{hand_history.id}.txt")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)

        # Add to processing queue
        processing_queue.put(hand_history.id)

        # Start background processor if not running
        start_background_processor()

        log_user_action(
            user_id,
            "hand_history_upload",
            {"filename": filename, "file_size": file_size, "poker_site": poker_site},
        )

        return (
            jsonify(
                {
                    "id": hand_history.id,
                    "filename": filename,
                    "poker_site": poker_site,
                    "status": "uploading",
                    "message": "File uploaded successfully. Processing will begin shortly.",
                }
            ),
            201,
        )

    except Exception as e:
        logger.error(f"Error uploading hand history: {e}")
        return jsonify({"error": "Failed to upload file"}), 500


@hand_history_bp.route("/api/hand-histories", methods=["GET"])
@auth_required
def get_hand_histories():
    """Get list of user's hand histories"""
    try:
        user_id = get_jwt_identity()

        # Query parameters
        page = request.args.get("page", 1, type=int)
        per_page = min(request.args.get("per_page", 20, type=int), 100)
        status = request.args.get("status")

        # Build query
        query = HandHistory.query.filter_by(user_id=user_id)

        if status:
            query = query.filter_by(status=status)

        # Order by most recent first
        query = query.order_by(HandHistory.created_at.desc())

        # Paginate
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)

        hand_histories = [hh.to_dict() for hh in pagination.items]

        return jsonify(
            {
                "hand_histories": hand_histories,
                "pagination": {
                    "page": pagination.page,
                    "pages": pagination.pages,
                    "per_page": pagination.per_page,
                    "total": pagination.total,
                },
            }
        )

    except Exception as e:
        logger.error(f"Error getting hand histories: {e}")
        return jsonify({"error": "Failed to retrieve hand histories"}), 500


@hand_history_bp.route("/api/hand-histories/<hand_history_id>", methods=["GET"])
@auth_required
def get_hand_history(hand_history_id):
    """Get details of a specific hand history"""
    try:
        user_id = get_jwt_identity()

        hand_history = HandHistory.query.filter_by(id=hand_history_id, user_id=user_id).first()

        if not hand_history:
            return jsonify({"error": "Hand history not found"}), 404

        return jsonify(hand_history.to_dict())

    except Exception as e:
        logger.error(f"Error getting hand history {hand_history_id}: {e}")
        return jsonify({"error": "Failed to retrieve hand history"}), 500


@hand_history_bp.route("/api/hand-histories/<hand_history_id>/hands", methods=["GET"])
@auth_required
def get_parsed_hands(hand_history_id):
    """Get parsed hands from a hand history"""
    try:
        user_id = get_jwt_identity()

        # Verify ownership
        hand_history = HandHistory.query.filter_by(id=hand_history_id, user_id=user_id).first()

        if not hand_history:
            return jsonify({"error": "Hand history not found"}), 404

        # Query parameters
        page = request.args.get("page", 1, type=int)
        per_page = min(request.args.get("per_page", 50, type=int), 200)

        # Get parsed hands
        query = ParsedHand.query.filter_by(hand_history_id=hand_history_id)
        query = query.order_by(ParsedHand.hand_datetime.desc())

        pagination = query.paginate(page=page, per_page=per_page, error_out=False)

        hands = [hand.to_dict() for hand in pagination.items]

        return jsonify(
            {
                "hands": hands,
                "pagination": {
                    "page": pagination.page,
                    "pages": pagination.pages,
                    "per_page": pagination.per_page,
                    "total": pagination.total,
                },
            }
        )

    except Exception as e:
        logger.error(f"Error getting parsed hands for {hand_history_id}: {e}")
        return jsonify({"error": "Failed to retrieve hands"}), 500


@hand_history_bp.route("/api/hand-histories/<hand_history_id>/analysis", methods=["GET"])
@auth_required
def get_hand_history_analysis(hand_history_id):
    """Get analysis and statistics for a hand history"""
    try:
        user_id = get_jwt_identity()

        # Verify ownership
        hand_history = HandHistory.query.filter_by(id=hand_history_id, user_id=user_id).first()

        if not hand_history:
            return jsonify({"error": "Hand history not found"}), 404

        if hand_history.status != "completed":
            return jsonify({"error": "Hand history not yet processed"}), 400

        # Get all hands for analysis
        hands = ParsedHand.query.filter_by(hand_history_id=hand_history_id).all()

        if not hands:
            return jsonify({"error": "No hands found"}), 404

        # Calculate statistics
        total_hands = len(hands)
        hands_with_results = [h for h in hands if h.hero_result is not None]

        stats = {
            "total_hands": total_hands,
            "hands_played": len(hands_with_results),
            "total_profit": sum(h.hero_result for h in hands_with_results),
            "win_rate": (
                len([h for h in hands_with_results if h.hero_result > 0]) / len(hands_with_results)
                if hands_with_results
                else 0
            ),
            "average_pot": (
                sum(h.pot_size for h in hands if h.pot_size) / len([h for h in hands if h.pot_size])
                if any(h.pot_size for h in hands)
                else 0
            ),
            "showdown_rate": len([h for h in hands if h.showdown_reached]) / total_hands,
            "bb_per_100": hand_history.bb_per_100,
        }

        # Breakdown by stakes
        stakes_breakdown = {}
        for hand in hands:
            stakes = hand.stakes or "Unknown"
            if stakes not in stakes_breakdown:
                stakes_breakdown[stakes] = {
                    "hands": 0,
                    "profit": 0.0,
                    "hands_played": 0,
                }
            stakes_breakdown[stakes]["hands"] += 1
            if hand.hero_result is not None:
                stakes_breakdown[stakes]["profit"] += hand.hero_result
                stakes_breakdown[stakes]["hands_played"] += 1

        # Hourly breakdown
        hourly_breakdown = {}
        for hand in hands_with_results:
            hour = hand.hand_datetime.hour
            if hour not in hourly_breakdown:
                hourly_breakdown[hour] = {"hands": 0, "profit": 0.0}
            hourly_breakdown[hour]["hands"] += 1
            hourly_breakdown[hour]["profit"] += hand.hero_result

        return jsonify(
            {
                "hand_history": hand_history.to_dict(),
                "statistics": stats,
                "stakes_breakdown": stakes_breakdown,
                "hourly_breakdown": hourly_breakdown,
            }
        )

    except Exception as e:
        logger.error(f"Error getting analysis for {hand_history_id}: {e}")
        return jsonify({"error": "Failed to generate analysis"}), 500


@hand_history_bp.route("/api/hand-histories/<hand_history_id>", methods=["DELETE"])
@auth_required
def delete_hand_history(hand_history_id):
    """Delete a hand history and all associated data"""
    try:
        user_id = get_jwt_identity()

        hand_history = HandHistory.query.filter_by(id=hand_history_id, user_id=user_id).first()

        if not hand_history:
            return jsonify({"error": "Hand history not found"}), 404

        # Delete associated parsed hands
        ParsedHand.query.filter_by(hand_history_id=hand_history_id).delete()

        # Delete hand history
        db.session.delete(hand_history)
        db.session.commit()

        # Clean up any remaining files
        file_path = os.path.join(UPLOAD_FOLDER, f"{hand_history_id}.txt")
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
        except OSError:
            pass

        log_user_action(
            user_id,
            "hand_history_delete",
            {"hand_history_id": hand_history_id, "filename": hand_history.filename},
        )

        return jsonify({"message": "Hand history deleted successfully"})

    except Exception as e:
        logger.error(f"Error deleting hand history {hand_history_id}: {e}")
        return jsonify({"error": "Failed to delete hand history"}), 500


hand_history_routes = hand_history_bp
