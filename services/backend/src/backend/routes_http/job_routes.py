from datetime import datetime, timedelta

from core.services.websocket_service import broadcast_job_update
from flask import Blueprint, jsonify, request

from src.backend.database import db
from src.backend.models.enums import JobStatus, JobType
from src.backend.models.job import Job
from src.backend.models.user_credit import UserCredit
from src.backend.services.job_service import create_job
from src.backend.services.rabbitmq_service import get_message_queue_service

from ..utils.auth_utils import auth_required, get_enhanced_logger, log_user_action

# Create blueprint for job routes_http
job_routes = Blueprint("jobs", __name__)
logger = get_enhanced_logger(__name__)

# Initialize queue service
queue_service = get_message_queue_service()
queue_config = {
    "spot_queue": "spot_jobs",
    "solver_queue": "solver_jobs",
    "provider": "rabbitmq",
}


def get_or_create_user_credits(user):
    """Get or create user credit record"""
    if not user.credit_info:
        credit_info = UserCredit(user_id=user.id)
        db.session.add(credit_info)
        db.session.commit()
        return credit_info
    return user.credit_info


@job_routes.route("/", methods=["POST", "OPTIONS"])
@auth_required
def submit_job():
    """Submit a new job for processing"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Validate required fields
        if "job_type" not in data or "input_data" not in data:
            return jsonify({"error": "Missing required fields"}), 400

        user = request.current_user

        # Parse job type
        try:
            parsed_job_type = JobType(data["job_type"])
            logger.info(f"Successfully parsed job_type: {parsed_job_type}")
        except ValueError:
            logger.error(f"Invalid job_type value: {data['job_type']}")
            return jsonify({"error": "Invalid job type"}), 400

        # Validate input_data for spot_simulation
        if parsed_job_type == JobType.SPOT_SIMULATION:
            if (
                "iterations" not in data["input_data"]
                or not isinstance(data["input_data"]["iterations"], int)
                or data["input_data"]["iterations"] <= 0
            ):
                return (
                    jsonify({"error": "Iterations must be a positive integer for spot simulation"}),
                    400,
                )

        # Check user credits
        credit_info = get_or_create_user_credits(user)

        if not credit_info.can_use_credit(user.subscription_tier, parsed_job_type.value):
            remaining = credit_info.get_remaining_credits(user.subscription_tier)
            return (
                jsonify(
                    {
                        "error": "Insufficient credits",
                        "message": "You have reached your job limit for your subscription tier.",
                        "credits_info": remaining,
                    }
                ),
                429,
            )

        # Submit job to Celery using the new job service
        # Calculate estimated_duration for spot simulation jobs
        estimated_duration = None
        if parsed_job_type == JobType.SPOT_SIMULATION:
            input_data = data["input_data"]
            simulation_runs = input_data.get("iterations", 10000)
            max_hand_combinations = input_data.get("max_hand_combinations", 10000)
            num_players = len(input_data.get("players", [])) if "players" in input_data else 2
            base_time_per_1k = 2  # seconds per 1000 runs
            player_factor = max(1, num_players * 0.5)
            combination_factor = min(max_hand_combinations / 10000, 5)  # Cap at 5x
            estimated_duration = int((simulation_runs / 1000) * base_time_per_1k * player_factor * combination_factor)
            estimated_duration = max(10, min(estimated_duration, 600))

        job_data = {
            "job_type": parsed_job_type.value,
            # Removed 'created_at': job.created_at.isoformat(),  # This was referencing an undefined variable
            "input_data": data["input_data"],
        }

        # Create job using Celery-based service
        created_job = create_job(job_data, user.id)

        if created_job:
            # Use the credit only if successfully submitted
            credit_info.use_credit()
            db.session.commit()

            # Notify user via WebSocket about new/active job status (non-blocking best-effort)
            try:
                status_value = created_job.status.value if getattr(created_job, "status", None) else "QUEUED"
                progress_value = getattr(created_job, "progress_percentage", 0) or 0
                broadcast_job_update(created_job.id, user.id, {"status": status_value, "progress": progress_value})
            except Exception:
                logger.debug("WebSocket broadcast failed for job submission", exc_info=True)

            log_user_action(
                "JOB_SUBMITTED",
                user.id,
                {
                    "job_id": created_job.id,
                    "job_type": parsed_job_type.value,
                    "estimated_duration": estimated_duration,
                },
            )

            return (
                jsonify(
                    {
                        "message": "Job submitted successfully",
                        "job": created_job.to_dict(),
                        "credits_info": credit_info.get_remaining_credits(user.subscription_tier),
                    }
                ),
                201,
            )
        else:
            # Failed to submit job
            return jsonify({"error": "Failed to submit job for processing"}), 500

    except Exception as e:
        logger.error(f"Error submitting job: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Failed to submit job"}), 500


@job_routes.route("/", methods=["GET", "OPTIONS"])
@auth_required
def get_user_jobs():
    """Get all jobs for the current user"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user

        # Get query parameters
        status_filter = request.args.get("status")
        job_type_filter = request.args.get("job_type")
        limit = min(int(request.args.get("limit", 50)), 100)  # Max 100 jobs
        offset = int(request.args.get("offset", 0))

        # Build query
        query = Job.query.filter_by(user_id=user.id)

        if status_filter:
            try:
                status = JobStatus(status_filter)
                query = query.filter(Job.status == status)
            except ValueError:
                return jsonify({"error": "Invalid status filter"}), 400

        if job_type_filter:
            try:
                job_type = JobType(job_type_filter)
                query = query.filter(Job.job_type == job_type)
            except ValueError:
                return jsonify({"error": "Invalid job type filter"}), 400

        # Get jobs with pagination
        jobs = query.order_by(Job.created_at.desc()).offset(offset).limit(limit).all()
        total_jobs = query.count()

        # Get credit info
        credit_info = get_or_create_user_credits(user)

        return (
            jsonify(
                {
                    "jobs": [job.to_summary_dict() for job in jobs],
                    "total": total_jobs,
                    "limit": limit,
                    "offset": offset,
                    "credits_info": credit_info.get_remaining_credits(user.subscription_tier),
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(f"Error retrieving jobs: {str(e)}")
        return jsonify({"error": "Failed to retrieve jobs"}), 500


@job_routes.route("/<job_id>", methods=["GET", "OPTIONS"])
@auth_required
def get_job(job_id):
    """Get a specific job by ID"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user
        job = Job.query.filter_by(id=job_id, user_id=user.id).first()

        if not job:
            return jsonify({"error": "Job not found"}), 404

        return jsonify({"job": job.to_dict()}), 200

    except Exception as e:
        logger.error(f"Error retrieving job: {str(e)}")
        return jsonify({"error": "Failed to retrieve job"}), 500


@job_routes.route("/<job_id>/details", methods=["GET", "OPTIONS"])
@auth_required
def get_job_details(job_id):
    """Get full job details including input_data and result_data"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user
        job = Job.query.filter_by(id=job_id, user_id=user.id).first()

        if not job:
            return jsonify({"error": "Job not found"}), 404

        return jsonify({"job": job.to_dict()}), 200

    except Exception as e:
        logger.error(f"Error retrieving job details: {str(e)}")
        return jsonify({"error": "Failed to retrieve job details"}), 500


@job_routes.route("/<job_id>/cancel", methods=["POST", "OPTIONS"])
@auth_required
def cancel_job(job_id):
    """Cancel a running job."""
    job = Job.query.get(job_id)

    if not job:
        return jsonify({"error": "Job not found"}), 404

    if job.user_id != request.current_user.id:
        return jsonify({"error": "You are not authorized to cancel this job"}), 403

    if job.status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
        return (
            jsonify({"message": f"Job is already in a terminal state ({job.status.value}) and cannot be cancelled."}),
            200,
        )

    job.status = JobStatus.CANCELLED
    db.session.commit()

    # Notify user via WebSocket about cancellation (best-effort)
    try:
        broadcast_job_update(
            job.id,
            job.user_id,
            {"status": JobStatus.CANCELLED.value, "progress": 100},
        )
    except Exception:
        logger.debug("WebSocket broadcast failed for job cancellation", exc_info=True)

    # Notify user via WebSocket
    # send_job_update(
    #     job.user_id, {"job_id": job.id, "status": "CANCELLED", "progress": 100}
    # )
    # user_actions.log_action(
    #     "JOB_CANCELLED", user_id=request.current_user.id, job_id=job.id
    # )

    return jsonify({"message": "Job cancelled successfully"}), 200


@job_routes.route("/credits", methods=["GET", "OPTIONS"])
@auth_required
def get_user_credits():
    """Get user's credit information"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user
        credit_info = get_or_create_user_credits(user)

        return (
            jsonify(
                {
                    "credits_info": credit_info.to_dict(user.subscription_tier),
                    "subscription_tier": user.subscription_tier,
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(f"Error retrieving credits: {str(e)}")
        return jsonify({"error": "Failed to retrieve credit information"}), 500


@job_routes.route("/queue-stats", methods=["GET", "OPTIONS"])
@auth_required
def get_queue_stats():
    """Get queue statistics (admin/debugging)"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        # Only show to admin users or in development
        user = request.current_user
        if user.subscription_tier not in ["ELITE"] and not user.email.endswith("@plosolver.com"):
            return jsonify({"error": "Access denied"}), 403

        stats = {
            "spot_queue": queue_service.get_queue_attributes(queue_config["spot_queue"]),
            "solver_queue": queue_service.get_queue_attributes(queue_config["solver_queue"]),
            "provider": queue_config["provider"],
            "health": queue_service.health_check(),
        }

        return jsonify({"queue_stats": stats}), 200

    except Exception as e:
        logger.error(f"Error retrieving queue stats: {str(e)}")
        return jsonify({"error": "Failed to retrieve queue statistics"}), 500


@job_routes.route("/recent", methods=["GET", "OPTIONS"])
@auth_required
def get_recent_jobs():
    """Get recent jobs for dashboard display"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user

        # Get jobs from the last 24 hours
        since = datetime.utcnow() - timedelta(hours=24)
        recent_jobs = (
            Job.query.filter(Job.user_id == user.id, Job.created_at >= since)
            .order_by(Job.created_at.desc())
            .limit(10)
            .all()
        )

        # Get active jobs (queued or processing)
        active_jobs = (
            Job.query.filter(
                Job.user_id == user.id,
                Job.status.in_([JobStatus.QUEUED, JobStatus.PROCESSING]),
            )
            .order_by(Job.created_at.desc())
            .all()
        )

        # Get credit info
        credit_info = get_or_create_user_credits(user)

        return (
            jsonify(
                {
                    "recent_jobs": [job.to_summary_dict() for job in recent_jobs],
                    "active_jobs": [job.to_summary_dict() for job in active_jobs],
                    "credits_info": credit_info.get_remaining_credits(user.subscription_tier),
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(f"Error retrieving recent jobs: {str(e)}")
        return jsonify({"error": "Failed to retrieve recent jobs"}), 500
