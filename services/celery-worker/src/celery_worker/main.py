#!/usr/bin/env python3
"""
Celery Worker Launcher (module entrypoint)
Starts the Celery worker with proper configuration for development and production.
"""

import os
import sys

from core.utils.logging_utils import get_enhanced_logger

from .celery_app import celery

# Configure logging
logger = get_enhanced_logger(__name__)


def main() -> None:
    """Main entry point for the Celery worker."""
    try:
        # Get concurrency from environment or default to reasonable value
        concurrency = os.environ.get("CELERY_WORKER_CONCURRENCY", "2")

        # Select worker pool
        pool = os.environ.get("CELERY_WORKER_POOL")
        # On macOS, default to threads to avoid fork/objc crashes
        if not pool and sys.platform == "darwin":
            pool = "threads"
        # Set fork safety override for macOS environments if not already set
        if sys.platform == "darwin" and not os.environ.get("OBJC_DISABLE_INITIALIZE_FORK_SAFETY"):
            os.environ["OBJC_DISABLE_INITIALIZE_FORK_SAFETY"] = "YES"

        # Get queue names - hardcode to avoid environment variable issues
        spot_queue = "spot-processing"
        solver_queue = "solver-processing"
        queues = f"{spot_queue},{solver_queue}"

        logger.info("Starting Celery worker with concurrency: %s", concurrency)
        if pool:
            logger.info("Using Celery worker pool: %s", pool)
        else:
            logger.info("Using Celery default worker pool")
        logger.info("Environment: %s", os.environ.get("ENVIRONMENT", "development"))
        logger.info("Queues: %s", queues)

        # Start the worker
        args = [
            "worker",
            "--loglevel=info",
            f"--concurrency={concurrency}",
            f"--queues={queues}",
        ]
        if pool:
            args.append(f"--pool={pool}")
        celery.worker_main(args)

    except ImportError as e:
        logger.error("Failed to import celery app: %s", e)
        sys.exit(1)
    except Exception as e:
        logger.error("Failed to start Celery worker: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
