"""
Metrics routes_http for PLOSolver Backend.

This module provides endpoints for Prometheus metrics and health checks.
"""

import time

from core.utils.logging_utils import get_enhanced_logger
from flask import Blueprint, g, request

from src.backend.metrics import API_CALLS_TOTAL, HTTP_REQUESTS_TOTAL, get_health_response, get_metrics_response

logger = get_enhanced_logger(__name__)

# Create blueprint
metrics_bp = Blueprint("metrics", __name__)


@metrics_bp.before_request
def before_request():
    """Set endpoint for metrics tracking."""
    g.endpoint = request.endpoint


@metrics_bp.after_request
def after_request(response):
    """Track request metrics after response."""
    try:
        HTTP_REQUESTS_TOTAL.labels(
            method=request.method, endpoint=request.endpoint or "unknown", status_code=response.status_code
        ).inc()

        API_CALLS_TOTAL.labels(
            endpoint=request.endpoint or "unknown", status="success" if response.status_code < 400 else "error"
        ).inc()
    except Exception as e:
        logger.warning("Failed to track request metrics: %s", e)

    return response


@metrics_bp.route("/metrics")
def metrics():
    """Prometheus metrics endpoint."""
    logger.debug("Metrics endpoint accessed")
    return get_metrics_response()


@metrics_bp.route("/health")
def health():
    """Health check endpoint."""
    logger.debug("Health check endpoint accessed")
    health_data = get_health_response()

    status_code = 200 if health_data.get("status") == "healthy" else 503
    return health_data, status_code


@metrics_bp.route("/ready")
def ready():
    """Readiness check endpoint."""
    logger.debug("Readiness check endpoint accessed")

    # Check if the application is ready to serve requests
    try:
        # Basic readiness checks
        readiness_data = {"status": "ready", "timestamp": time.time(), "checks": {"database": "ready", "api": "ready"}}

        return readiness_data, 200
    except Exception as e:
        logger.error("Readiness check failed: %s", e)
        return {"status": "not_ready", "timestamp": time.time(), "error": str(e)}, 503
