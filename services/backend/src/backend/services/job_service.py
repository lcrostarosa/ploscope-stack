import os
import uuid
from datetime import datetime
from urllib.parse import quote_plus

from celery import Celery
from core.utils.logging_utils import get_enhanced_logger
from kombu import Exchange, Queue

from ..database import db
from ..models.enums import JobStatus, JobType
from ..models.job import Job

logger = get_enhanced_logger(__name__)


def _get_celery_app():
    """Get or create Celery app instance for sending tasks."""
    rabbitmq_user = os.getenv("RABBITMQ_USERNAME", "plosolver")
    rabbitmq_pass = os.getenv("RABBITMQ_PASSWORD", "dev_password_2024")
    rabbitmq_host = os.getenv("RABBITMQ_HOST", "localhost")
    rabbitmq_port = os.getenv("RABBITMQ_PORT", "5672")
    rabbitmq_vhost = os.getenv("RABBITMQ_VHOST", "/")
    spot_queue_name = os.getenv("RABBITMQ_SPOT_QUEUE", "spot-processing")
    solver_queue_name = os.getenv("RABBITMQ_SOLVER_QUEUE", "solver-processing")

    # URL encode the vhost (e.g., /plosolver -> %2Fplosolver)
    vhost_encoded = quote_plus(rabbitmq_vhost)

    broker_url = f"amqp://{rabbitmq_user}:{rabbitmq_pass}@{rabbitmq_host}:{rabbitmq_port}/{vhost_encoded}"

    app = Celery(broker=broker_url)

    # Define exchanges using environment variables
    main_exchange_name = os.getenv("RABBITMQ_MAIN_EXCHANGE", "plosolver.main")
    dlq_exchange_name = os.getenv("RABBITMQ_DLQ_EXCHANGE", "plosolver.dlq")
    plosolver_exchange = Exchange(main_exchange_name, type="direct", durable=True, auto_declare=False)
    plosolver_dlx_exchange = Exchange(dlq_exchange_name, type="direct", durable=True, auto_declare=False)

    # Get DLQ names from env
    spot_dlq_name = os.getenv("RABBITMQ_SPOT_DLQ", "spot-processing-dlq")
    solver_dlq_name = os.getenv("RABBITMQ_SOLVER_DLQ", "solver-processing-dlq")

    # Define queues explicitly (don't auto-declare, they already exist with DLX)
    app.conf.update(
        # 🧱 Prevent Celery from creating or modifying queues
        task_create_missing_queues=False,
        # Set a default queue (Celery requires one)
        task_default_queue=spot_queue_name,
        task_default_exchange=main_exchange_name,
        task_default_exchange_type="direct",
        # Explicit queue definitions — note `auto_declare=False` and queue_arguments for DLX
        task_queues=(
            # Main processing queues on plosolver exchange
            Queue(
                spot_queue_name,
                exchange=plosolver_exchange,
                routing_key=spot_queue_name,
                queue_arguments={
                    "x-dead-letter-exchange": dlq_exchange_name,
                    "x-dead-letter-routing-key": spot_dlq_name,
                    "x-max-retries": 3,
                },
                auto_declare=False,
            ),
            Queue(
                solver_queue_name,
                exchange=plosolver_exchange,
                routing_key=solver_queue_name,
                queue_arguments={
                    "x-dead-letter-exchange": dlq_exchange_name,
                    "x-dead-letter-routing-key": solver_dlq_name,
                    "x-max-retries": 3,
                },
                auto_declare=False,
            ),
            # DLQ queues on plosolver-dlx exchange
            Queue(
                spot_dlq_name,
                exchange=plosolver_dlx_exchange,
                routing_key=spot_dlq_name,
                queue_arguments={
                    "x-message-ttl": 1209600000,  # 14 days in milliseconds
                },
                auto_declare=False,
            ),
            Queue(
                solver_dlq_name,
                exchange=plosolver_dlx_exchange,
                routing_key=solver_dlq_name,
                queue_arguments={
                    "x-message-ttl": 1209600000,  # 14 days in milliseconds
                },
                auto_declare=False,
            ),
        ),
        # 🛑 Don't let Kombu declare queues/exchanges automatically
        broker_transport_options={
            # Passive = only check if queue exists; fail if not
            "confirm_publish": True,
        },
    )

    return app


celery_app = _get_celery_app()


def create_job(job_data, user_id):
    """Create a new job and submit it to Celery for processing."""
    logger.info(f"Creating job for user {user_id}")
    logger.debug(f"Job data: {job_data}")

    try:
        # Determine job type based on the data
        job_type_raw = job_data.get("job_type", "SOLVER_ANALYSIS")
        input_data = job_data.get("input_data", job_data)

        logger.debug(f"Creating job for user {user_id} with job_type={job_type_raw} and input_data={input_data}")

        # Convert job_type to JobType enum, case-insensitive, allow enum or string
        if isinstance(job_type_raw, JobType):
            job_type_enum = job_type_raw
            # job_type_str = job_type_enum.name  # unused
        elif isinstance(job_type_raw, str):
            try:
                job_type_enum = JobType[job_type_raw.upper()]
                # job_type_str = job_type_raw.upper()  # unused
            except KeyError:
                logger.error(f"Invalid job type: {job_type_raw}")
                return None
        else:
            logger.error(f"Invalid job type format: {type(job_type_raw)}")
            return None

        # Create job record
        job = Job(
            user_id=user_id,
            job_type=job_type_enum,
            input_data=input_data,
        )

        db.session.add(job)
        db.session.flush()  # Get the job ID without committing

        # Send task to Celery via RabbitMQ using Kombu directly
        try:
            # Determine task name and queue based on job type
            if job_type_enum == JobType.SPOT_SIMULATION:
                task_name = "celery_worker.tasks.process_spot_simulation"
                queue_name = os.getenv("RABBITMQ_SPOT_QUEUE", "spot-processing")
            else:  # SOLVER_ANALYSIS
                task_name = "celery_worker.tasks.process_solver_analysis"
                queue_name = os.getenv("RABBITMQ_SOLVER_QUEUE", "solver-processing")

            # Generate task ID
            task_id = str(uuid.uuid4())

            # Create Celery task message in proper format
            task_message = {
                "id": task_id,
                "task": task_name,
                "args": [str(job.id)],
                "kwargs": {},
                "retries": 0,
                "eta": None,
            }

            celery_app.send_task(task_name, args=(task_message,), queue=queue_name)

            # Store the Celery task ID
            job.queue_message_id = task_id
            db.session.commit()

            logger.info(f"Job {job.id} sent to Celery task {task_id} on queue {queue_name}")
            return job

        except Exception as e:
            logger.exception(f"Failed to send job {job.id} to Celery: {e}")
            db.session.rollback()
            return None

    except Exception as e:
        logger.exception(f"Error creating job: {str(e)}")
        db.session.rollback()
        return None


def get_job_status(job_id, user_id):
    """Get the status of a job."""
    try:
        job = Job.query.filter_by(id=job_id, user_id=user_id).first()
        if not job:
            return None

        status_data = {
            "id": job.id,
            "status": job.status.value,
            "progress_percentage": job.progress_percentage,
            "progress_message": job.progress_message,
            "created_at": job.created_at.isoformat() if job.created_at else None,
            "started_at": job.started_at.isoformat() if job.started_at else None,
            "completed_at": job.completed_at.isoformat() if job.completed_at else None,
            "estimated_duration": job.estimated_duration,
            "actual_duration": job.actual_duration,
        }

        if job.result_data:
            status_data["results"] = job.result_data

        if job.error_message:
            status_data["error"] = job.error_message

        return status_data

    except Exception as e:
        logger.exception(f"Error getting job status: {str(e)}")
        return None


def cancel_job(job_id, user_id):
    """Cancel a job."""
    try:
        job = Job.query.filter_by(id=job_id, user_id=user_id).first()
        if not job:
            return False

        # Update job status to cancelled
        # Note: The Celery worker should check job status before processing
        job.status = JobStatus.CANCELLED
        job.completed_at = datetime.utcnow()
        db.session.commit()

        logger.info(f"Job {job_id} cancelled by user {user_id}")
        return True

    except Exception as e:
        logger.exception(f"Error cancelling job: {str(e)}")
        return False
