"""Celery service for PLOSolver.

This module handles Celery task submission and integration with the existing job system. It provides a clean interface
for submitting jobs to Celery workers.
"""

import os
import urllib.parse

# import logging
from typing import Any, Optional

from celery import Celery

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)

# Global Celery app instance
_celery_app = None


def get_celery_app() -> Celery:
    """Get or create the Celery app instance."""
    global _celery_app

    if _celery_app is None:
        broker_url = os.environ.get("CELERY_BROKER_URL")
        if not broker_url:
            rabbit_user = os.environ.get("RABBITMQ_USERNAME", "plosolver")
            rabbit_pass = os.environ.get("RABBITMQ_PASSWORD", "dev_password_2024")
            rabbit_host = os.environ.get("RABBITMQ_HOST", "rabbitmq")
            rabbit_port = os.environ.get("RABBITMQ_PORT", "5672")
            rabbit_vhost = os.environ.get("RABBITMQ_VHOST", "/plosolver")
            vhost_enc = (
                urllib.parse.quote(rabbit_vhost.lstrip("/"))
                if rabbit_vhost.startswith("/")
                else urllib.parse.quote(rabbit_vhost)
            )
            broker_url = (
                f"amqp://{rabbit_user}:{rabbit_pass}@{rabbit_host}:{rabbit_port}/%2F{vhost_enc}"
                if rabbit_vhost.startswith("/")
                else f"amqp://{rabbit_user}:{rabbit_pass}@{rabbit_host}:{rabbit_port}/{vhost_enc}"
            )
        backend_url = os.environ.get("CELERY_RESULT_BACKEND", "rpc://")
        _celery_app = Celery("plosolver_backend", broker=broker_url, backend=backend_url)

        _celery_app.conf.update(
            task_serializer="json",
            accept_content=["json"],
            result_serializer="json",
            timezone="UTC",
            enable_utc=True,
            # Task routing
            task_routes={
                "tasks.process_spot_simulation": {"queue": "spot-processing"},
                "tasks.process_solver_analysis": {"queue": "solver-processing"},
            },
            # Result backend settings
            result_expires=3600,  # 1 hour
            # Broker settings
            broker_connection_retry_on_startup=True,
        )

    return _celery_app


def submit_spot_simulation_task(job_id: str) -> Optional[str]:
    """Submit a spot simulation task to Celery.

    Args:
        job_id: The ID of the job to process

    Returns:
        The Celery task ID if successful, None otherwise
    """
    try:
        celery_app = get_celery_app()

        # Submit the task using Celery's task routing
        task = celery_app.send_task("tasks.process_spot_simulation", args=[job_id])

        logger.info(f"Submitted spot simulation task for job {job_id}, task ID: {task.id}")
        return task.id

    except Exception as e:
        logger.exception(f"Failed to submit spot simulation task for job {job_id}: {str(e)}")
        return None


def submit_solver_analysis_task(job_id: str) -> Optional[str]:
    """Submit a solver analysis task to Celery.

    Args:
        job_id: The ID of the job to process

    Returns:
        The Celery task ID if successful, None otherwise
    """
    try:
        celery_app = get_celery_app()

        # Submit the task using Celery's task routing
        task = celery_app.send_task("tasks.process_solver_analysis", args=[job_id])

        logger.info(f"Submitted solver analysis task for job {job_id}, task ID: {task.id}")
        return task.id

    except Exception as e:
        logger.exception(f"Failed to submit solver analysis task for job {job_id}: {str(e)}")
        return None


def get_task_status(task_id: str) -> Optional[dict[str, Any]]:
    """Get the status of a Celery task.

    Args:
        task_id: The Celery task ID

    Returns:
        Task status information or None if not found
    """
    try:
        celery_app = get_celery_app()

        # Get task result
        result = celery_app.AsyncResult(task_id)

        status_info = {
            "task_id": task_id,
            "status": result.status,
            "ready": result.ready(),
        }

        if result.ready():
            if result.successful():
                status_info["result"] = result.result
            else:
                status_info["error"] = str(result.info)

        return status_info

    except Exception as e:
        logger.exception(f"Failed to get task status for {task_id}: {str(e)}")
        return None


def cancel_task(task_id: str) -> bool:
    """Cancel a Celery task.

    Args:
        task_id: The Celery task ID

    Returns:
        True if task was cancelled successfully, False otherwise
    """
    try:
        celery_app = get_celery_app()

        # Revoke the task
        celery_app.control.revoke(task_id, terminate=True)

        logger.info(f"Cancelled task {task_id}")
        return True

    except Exception as e:
        logger.exception(f"Failed to cancel task {task_id}: {str(e)}")
        return False
