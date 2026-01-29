import os

from celery import Celery
from core.utils.logging_utils import get_enhanced_logger
from kombu import Exchange, Queue

from celery_worker.redis import check_redis_connection

from .services.database_service import check_database_connection
from .services.rabbitmq_service import get_broker_url

# Configure logging
logger = get_enhanced_logger(__name__)


def make_celery():
    broker_url = get_broker_url()
    backend_url = os.environ.get("CELERY_RESULT_BACKEND", "rpc://")

    # Get queue and exchange names from environment
    # Hardcode queue names to avoid environment variable issues
    spot_queue = "spot-processing"
    solver_queue = "solver-processing"
    spot_dlq = "spot-processing-dlq"
    solver_dlq = "solver-processing-dlq"

    logger.info("Using hardcoded queue names: spot_queue='%s', solver_queue='%s'", spot_queue, solver_queue)

    main_exchange_name = os.environ.get("RABBITMQ_MAIN_EXCHANGE", "plosolver.main").strip()
    dlx_exchange_name = os.environ.get("RABBITMQ_DLQ_EXCHANGE", "plosolver.dlq").strip()
    main_exchange_type = os.environ.get("RABBITMQ_MAIN_EXCHANGE_TYPE", "direct")
    dlx_exchange_type = os.environ.get("RABBITMQ_DLQ_EXCHANGE_TYPE", "direct")

    # Define exchanges without declaration to avoid mismatches with pre-created exchanges
    main_exchange = Exchange(
        main_exchange_name,
        type=main_exchange_type,
        durable=True,
        passive=True,
        no_declare=True,
    )
    dlx_exchange = Exchange(
        dlx_exchange_name,
        type=dlx_exchange_type,
        durable=True,
        passive=True,
        no_declare=True,
    )

    celery_app = Celery(
        "celery_worker",
        broker=broker_url,
        backend=backend_url,
        include=["celery_worker.tasks"],
    )
    celery_app.conf.update(
        task_serializer="json",
        accept_content=["json"],
        result_serializer="json",
        timezone="UTC",
        enable_utc=True,
        # Task routing
        task_routes={
            "celery_worker.tasks.process_spot_simulation": {"queue": spot_queue},
            "celery_worker.tasks.process_solver_analysis": {"queue": solver_queue},
        },
        # Do not create or modify queues/exchanges automatically
        task_create_missing_queues=False,
        # Provide defaults to align with existing broker configuration
        task_default_queue=spot_queue,
        task_default_exchange=main_exchange_name,
        task_default_exchange_type=main_exchange_type,
        # Task settings
        task_acks_late=True,
        # Don't ack on failure/timeouts; let message be requeued or dead-lettered
        task_acks_on_failure_or_timeout=False,
        task_reject_on_worker_lost=True,
        worker_prefetch_multiplier=2,  # Increased from 1 for better throughput
        task_time_limit=1800,  # 30 minutes hard timeout
        task_soft_time_limit=1500,  # 25 minutes soft timeout
        # Result backend settings
        result_expires=3600,  # 1 hour
        result_compression="gzip",  # Compress large results
        # Broker settings
        broker_connection_retry_on_startup=True,
        broker_connection_retry=True,
        broker_connection_max_retries=10,
        broker_pool_limit=20,  # Connection pool size
        broker_heartbeat=300,  # 5 minutes heartbeat
        task_always_eager=False,
        task_eager_propagates=True,
        worker_direct=False,
        task_queues=[
            # Main queues on plosolver exchange with DLX to plosolver-dlx
            Queue(
                spot_queue,
                exchange=main_exchange,
                routing_key="spot.*",
                queue_arguments={
                    "x-dead-letter-exchange": dlx_exchange_name,
                    "x-dead-letter-routing-key": spot_dlq,
                },
                durable=True,
                no_declare=True,
            ),
            Queue(
                solver_queue,
                exchange=main_exchange,
                routing_key="solver.*",
                queue_arguments={
                    "x-dead-letter-exchange": dlx_exchange_name,
                    "x-dead-letter-routing-key": solver_dlq,
                },
                durable=True,
                no_declare=True,
            ),
            # DLQ queues on plosolver-dlx exchange
            Queue(
                spot_dlq,
                exchange=dlx_exchange,
                routing_key=spot_dlq,
                durable=True,
                no_declare=True,
            ),
            Queue(
                solver_dlq,
                exchange=dlx_exchange,
                routing_key=solver_dlq,
                durable=True,
                no_declare=True,
            ),
        ],
        broker_transport_options={
            "confirm_publish": True,
            "max_retries": 5,  # Increased retries
            "interval_start": 0.1,  # Faster initial retry
            "interval_step": 0.5,  # Longer steps
            "interval_max": 2.0,  # Higher max interval
            "priority_steps": list(range(10)),
        },
    )

    check_redis_connection(backend_url)

    # Only check database connection if not in test environment
    if os.environ.get("TESTING", "").lower() != "true":
        check_database_connection()

    return celery_app


celery = make_celery()
