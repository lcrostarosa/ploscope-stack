"""
Metrics collection module for Celery Worker.

This module provides Prometheus metrics for monitoring the Celery worker
including task processing, queue status, and system metrics.
"""

import threading
import time
from typing import Any, Dict

from celery import Celery
from celery.events import EventReceiver
from celery.events.state import State
from core.utils.logging_utils import get_enhanced_logger
from prometheus_client import Counter, Gauge, Histogram, generate_latest, start_http_server

logger = get_enhanced_logger(__name__)

# Task Metrics
TASKS_TOTAL = Counter("celery_tasks_total", "Total number of tasks processed", ["task_name", "status"])

TASK_DURATION = Histogram("celery_task_duration_seconds", "Task execution duration in seconds", ["task_name"])

TASK_QUEUE_SIZE = Gauge("celery_queue_size", "Number of tasks in queue", ["queue_name"])

# Worker Metrics
WORKER_ACTIVE_TASKS = Gauge("celery_worker_active_tasks", "Number of active tasks per worker", ["worker_name"])

WORKER_PROCESSED_TASKS = Counter(
    "celery_worker_processed_tasks_total", "Total tasks processed by worker", ["worker_name"]
)

# System Metrics
WORKER_MEMORY_USAGE = Gauge("celery_worker_memory_usage_bytes", "Memory usage of worker in bytes")

WORKER_CPU_USAGE = Gauge("celery_worker_cpu_usage_percent", "CPU usage of worker in percentage")

# Business Metrics
SPOT_SIMULATIONS_PROCESSED = Counter("spot_simulations_processed_total", "Total spot simulations processed", ["status"])

SOLVER_ANALYSES_PROCESSED = Counter("solver_analyses_processed_total", "Total solver analyses processed", ["status"])

# Metrics server
_metrics_server = None
_metrics_thread = None


def start_metrics_server(port: int = 8000) -> None:
    """Start the Prometheus metrics server."""
    global _metrics_server, _metrics_thread

    if _metrics_server is not None:
        logger.warning("Metrics server already running")
        return

    try:
        _metrics_server = start_http_server(port)
        logger.info("Prometheus metrics server started on port %d", port)
    except Exception as e:
        logger.error("Failed to start metrics server: %s", e)


def stop_metrics_server() -> None:
    """Stop the Prometheus metrics server."""
    global _metrics_server

    if _metrics_server is not None:
        try:
            _metrics_server.shutdown()
            _metrics_server = None
            logger.info("Prometheus metrics server stopped")
        except Exception as e:
            logger.error("Failed to stop metrics server: %s", e)


def update_system_metrics() -> None:
    """Update system metrics like memory and CPU usage."""
    try:
        import psutil

        # Memory usage
        memory_info = psutil.virtual_memory()
        WORKER_MEMORY_USAGE.set(memory_info.used)

        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        WORKER_CPU_USAGE.set(cpu_percent)

    except ImportError:
        logger.warning("psutil not available for system metrics")
    except Exception as e:
        logger.error("Failed to update system metrics: %s", e)


def track_task_execution(task_name: str, duration: float, status: str) -> None:
    """Track task execution metrics."""
    try:
        TASKS_TOTAL.labels(task_name=task_name, status=status).inc()
        TASK_DURATION.labels(task_name=task_name).observe(duration)
    except Exception as e:
        logger.error("Failed to track task execution: %s", e)


def track_spot_simulation(status: str) -> None:
    """Track spot simulation processing."""
    try:
        SPOT_SIMULATIONS_PROCESSED.labels(status=status).inc()
    except Exception as e:
        logger.error("Failed to track spot simulation: %s", e)


def track_solver_analysis(status: str) -> None:
    """Track solver analysis processing."""
    try:
        SOLVER_ANALYSES_PROCESSED.labels(status=status).inc()
    except Exception as e:
        logger.error("Failed to track solver analysis: %s", e)


def get_metrics_response() -> str:
    """Generate Prometheus metrics response."""
    try:
        # Update dynamic metrics
        update_system_metrics()

        # Generate metrics
        return generate_latest().decode("utf-8")
    except Exception as e:
        logger.error("Failed to generate metrics: %s", e)
        return ""


def get_health_response() -> Dict[str, Any]:
    """Generate health check response."""
    try:
        health_data = {
            "status": "healthy",
            "timestamp": time.time(),
            "services": {
                "celery_worker": "healthy",
                "metrics_server": "healthy" if _metrics_server is not None else "unhealthy",
            },
        }

        return health_data
    except Exception as e:
        logger.error("Health check failed: %s", e)
        return {"status": "unhealthy", "timestamp": time.time(), "error": str(e)}


def get_ready_response() -> Dict[str, Any]:
    """Generate readiness check response."""
    try:
        readiness_data = {
            "status": "ready",
            "timestamp": time.time(),
            "checks": {
                "celery_worker": "ready",
                "metrics_server": "ready" if _metrics_server is not None else "not_ready",
            },
        }

        return readiness_data
    except Exception as e:
        logger.error("Readiness check failed: %s", e)
        return {"status": "not_ready", "timestamp": time.time(), "error": str(e)}


class CeleryMetricsCollector:
    """Collector for Celery-specific metrics."""

    def __init__(self, celery_app: Celery):
        self.celery_app = celery_app
        self.state = State()
        self._running = False
        self._thread = None

    def start(self) -> None:
        """Start collecting Celery metrics."""
        if self._running:
            logger.warning("Metrics collector already running")
            return

        self._running = True
        self._thread = threading.Thread(target=self._collect_metrics, daemon=True)
        self._thread.start()
        logger.info("Celery metrics collector started")

    def stop(self) -> None:
        """Stop collecting Celery metrics."""
        self._running = False
        if self._thread:
            self._thread.join(timeout=5)
        logger.info("Celery metrics collector stopped")

    def _collect_metrics(self) -> None:
        """Collect metrics from Celery events."""
        try:
            with self.celery_app.connection() as connection:
                receiver = EventReceiver(
                    connection,
                    handlers={
                        "task-sent": self._on_task_sent,
                        "task-received": self._on_task_received,
                        "task-started": self._on_task_started,
                        "task-succeeded": self._on_task_succeeded,
                        "task-failed": self._on_task_failed,
                        "task-revoked": self._on_task_revoked,
                        "worker-online": self._on_worker_online,
                        "worker-offline": self._on_worker_offline,
                    },
                )

                while self._running:
                    try:
                        receiver.capture(limit=1, timeout=1)
                    except Exception as e:
                        logger.warning("Error capturing Celery events: %s", e)
                        time.sleep(1)

        except Exception as e:
            logger.error("Failed to start Celery metrics collection: %s", e)

    def _on_task_sent(self, event: Dict[str, Any]) -> None:
        """Handle task-sent event."""
        try:
            event.get("name", "unknown")
            queue = event.get("queue", "unknown")
            TASK_QUEUE_SIZE.labels(queue_name=queue).inc()
        except Exception as e:
            logger.warning("Error handling task-sent event: %s", e)

    def _on_task_received(self, event: Dict[str, Any]) -> None:
        """Handle task-received event."""
        try:
            event.get("name", "unknown")
            worker = event.get("hostname", "unknown")
            WORKER_ACTIVE_TASKS.labels(worker_name=worker).inc()
        except Exception as e:
            logger.warning("Error handling task-received event: %s", e)

    def _on_task_started(self, event: Dict[str, Any]) -> None:
        """Handle task-started event."""
        try:
            event.get("name", "unknown")
            event.get("hostname", "unknown")
            # Task is now active
        except Exception as e:
            logger.warning("Error handling task-started event: %s", e)

    def _on_task_succeeded(self, event: Dict[str, Any]) -> None:
        """Handle task-succeeded event."""
        try:
            task_name = event.get("name", "unknown")
            worker = event.get("hostname", "unknown")
            duration = event.get("runtime", 0)

            TASKS_TOTAL.labels(task_name=task_name, status="success").inc()
            TASK_DURATION.labels(task_name=task_name).observe(duration)
            WORKER_ACTIVE_TASKS.labels(worker_name=worker).dec()
            WORKER_PROCESSED_TASKS.labels(worker_name=worker).inc()
        except Exception as e:
            logger.warning("Error handling task-succeeded event: %s", e)

    def _on_task_failed(self, event: Dict[str, Any]) -> None:
        """Handle task-failed event."""
        try:
            task_name = event.get("name", "unknown")
            worker = event.get("hostname", "unknown")
            duration = event.get("runtime", 0)

            TASKS_TOTAL.labels(task_name=task_name, status="failure").inc()
            TASK_DURATION.labels(task_name=task_name).observe(duration)
            WORKER_ACTIVE_TASKS.labels(worker_name=worker).dec()
        except Exception as e:
            logger.warning("Error handling task-failed event: %s", e)

    def _on_task_revoked(self, event: Dict[str, Any]) -> None:
        """Handle task-revoked event."""
        try:
            task_name = event.get("name", "unknown")
            worker = event.get("hostname", "unknown")

            TASKS_TOTAL.labels(task_name=task_name, status="revoked").inc()
            WORKER_ACTIVE_TASKS.labels(worker_name=worker).dec()
        except Exception as e:
            logger.warning("Error handling task-revoked event: %s", e)

    def _on_worker_online(self, event: Dict[str, Any]) -> None:
        """Handle worker-online event."""
        try:
            worker = event.get("hostname", "unknown")
            logger.info("Worker %s came online", worker)
        except Exception as e:
            logger.warning("Error handling worker-online event: %s", e)

    def _on_worker_offline(self, event: Dict[str, Any]) -> None:
        """Handle worker-offline event."""
        try:
            worker = event.get("hostname", "unknown")
            logger.info("Worker %s went offline", worker)
        except Exception as e:
            logger.warning("Error handling worker-offline event: %s", e)
