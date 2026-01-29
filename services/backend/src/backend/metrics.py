"""
Metrics collection module for PLOSolver Backend.

This module provides Prometheus metrics for monitoring the backend application
including HTTP requests, database connections, and business metrics.
"""

import time
from functools import wraps
from typing import Any, Callable

from core.utils.logging_utils import get_enhanced_logger
from flask import Response, g, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest
from sqlalchemy import text

from src.backend.database import db

logger = get_enhanced_logger(__name__)

# HTTP Metrics
HTTP_REQUESTS_TOTAL = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint", "status_code"])

HTTP_REQUEST_DURATION = Histogram(
    "http_request_duration_seconds", "HTTP request duration in seconds", ["method", "endpoint"]
)

# Database Metrics
DATABASE_CONNECTIONS_ACTIVE = Gauge("database_connections_active", "Number of active database connections")

DATABASE_QUERY_DURATION = Histogram(
    "database_query_duration_seconds", "Database query duration in seconds", ["query_type"]
)

# Business Metrics
USER_REGISTRATIONS_TOTAL = Counter("user_registrations_total", "Total user registrations")

API_CALLS_TOTAL = Counter("api_calls_total", "Total API calls", ["endpoint", "status"])

SOLVER_JOBS_TOTAL = Counter("solver_jobs_total", "Total solver jobs processed", ["status"])

SPOT_SIMULATIONS_TOTAL = Counter("spot_simulations_total", "Total spot simulations processed", ["status"])

# System Metrics
ACTIVE_CONNECTIONS = Gauge("active_connections", "Number of active connections")

MEMORY_USAGE = Gauge("memory_usage_bytes", "Memory usage in bytes")

CPU_USAGE = Gauge("cpu_usage_percent", "CPU usage percentage")


def track_request_duration(func: Callable) -> Callable:
    """Decorator to track request duration for metrics."""

    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            duration = time.time() - start_time
            if hasattr(g, "endpoint"):
                HTTP_REQUEST_DURATION.labels(method=request.method, endpoint=g.endpoint).observe(duration)

    return wrapper


def track_database_query(query_type: str = "unknown"):
    """Decorator to track database query duration."""

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            start_time = time.time()
            try:
                result = func(*args, **kwargs)
                return result
            finally:
                duration = time.time() - start_time
                DATABASE_QUERY_DURATION.labels(query_type=query_type).observe(duration)

        return wrapper

    return decorator


def update_database_connections():
    """Update the active database connections metric."""
    try:
        # Get connection pool info
        engine = db.get_engine()
        pool = engine.pool
        DATABASE_CONNECTIONS_ACTIVE.set(pool.size())
    except Exception as e:
        logger.warning("Failed to update database connections metric: %s", e)


def update_system_metrics():
    """Update system metrics like memory and CPU usage."""
    try:
        import psutil

        # Memory usage
        memory_info = psutil.virtual_memory()
        MEMORY_USAGE.set(memory_info.used)

        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        CPU_USAGE.set(cpu_percent)
    except ImportError:
        logger.warning("psutil not available for system metrics")
    except Exception as e:
        logger.warning("Failed to update system metrics: %s", e)


def get_metrics_response() -> Response:
    """Generate Prometheus metrics response."""
    try:
        # Update dynamic metrics
        update_database_connections()
        update_system_metrics()

        # Generate metrics
        metrics_data = generate_latest()
        return Response(metrics_data, mimetype=CONTENT_TYPE_LATEST)
    except Exception as e:
        logger.error("Failed to generate metrics: %s", e)
        return Response("", status=500)


def get_health_response() -> dict:
    """Generate health check response."""
    try:
        # Check database connectivity
        db_status = "healthy"
        try:
            db.session.execute(text("SELECT 1")).fetchone()
        except Exception as e:
            db_status = f"unhealthy: {str(e)}"
            logger.error("Database health check failed: %s", e)

        # Check other routes_grpc
        health_data = {
            "status": "healthy" if db_status == "healthy" else "unhealthy",
            "timestamp": time.time(),
            "routes_grpc": {"database": db_status, "api": "healthy"},
        }

        return health_data
    except Exception as e:
        logger.error("Health check failed: %s", e)
        return {"status": "unhealthy", "timestamp": time.time(), "error": str(e)}
