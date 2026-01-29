"""
Telemetry service for handling anonymous usage analytics.

This module provides functionality for processing and logging telemetry data
from the frontend when users opt into Usage Analytics.
"""

import json
from datetime import datetime
from typing import Any, Dict

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


def build_safe_telemetry_log(data: Dict[str, Any], request) -> str:
    """
    Build a safe telemetry log entry from request data.

    This function sanitizes the incoming data to ensure no PII is logged
    and creates a structured log entry for telemetry purposes.

    Args:
        data: The telemetry data from the frontend
        request: The Flask request object

    Returns:
        str: A sanitized log entry string
    """
    try:
        # Extract safe metadata from request
        safe_metadata = {
            "timestamp": datetime.utcnow().isoformat(),
            "user_agent": request.headers.get("User-Agent", "")[:100],  # Truncate to prevent log spam
            "content_type": request.headers.get("Content-Type", ""),
            "origin": request.headers.get("Origin", ""),
            "referer": request.headers.get("Referer", "")[:100],  # Truncate
        }

        # Sanitize the telemetry data
        safe_data = _sanitize_telemetry_data(data)

        # Create the log entry
        log_entry = {"type": "telemetry", "metadata": safe_metadata, "data": safe_data}

        return json.dumps(log_entry, separators=(",", ":"))

    except Exception as e:
        logger.error(f"Failed to build telemetry log: {e}")
        # Return a minimal safe log entry
        return json.dumps(
            {"type": "telemetry", "timestamp": datetime.utcnow().isoformat(), "error": "log_build_failed"}
        )


def _sanitize_telemetry_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Sanitize telemetry data to remove any potential PII.

    Args:
        data: Raw telemetry data

    Returns:
        Dict[str, Any]: Sanitized data
    """
    if not isinstance(data, dict):
        return {"error": "invalid_data_type"}

    # Fields that are safe to keep
    safe_fields = {
        "event_type",
        "event_name",
        "event_category",
        "event_action",
        "page_url",
        "page_title",
        "session_id",
        "user_id_hash",
        "timestamp",
        "version",
        "build",
        "environment",
    }

    # Fields to exclude (potential PII)
    excluded_fields = {
        "email",
        "username",
        "name",
        "phone",
        "address",
        "ip_address",
        "user_id",
        "session_token",
        "auth_token",
        "password",
    }

    sanitized = {}

    for key, value in data.items():
        # Skip excluded fields
        if key.lower() in excluded_fields:
            continue

        # Only include safe fields or fields that don't look like PII
        if key.lower() in safe_fields or not _looks_like_pii(key, value):
            sanitized[key] = _sanitize_value(value)

    return sanitized


def _looks_like_pii(key: str, value: Any) -> bool:
    """
    Check if a key-value pair looks like it might contain PII.

    Args:
        key: The field name
        value: The field value

    Returns:
        bool: True if it looks like PII
    """
    if not isinstance(value, str):
        return False

    key_lower = key.lower()

    # Check for common PII patterns
    pii_indicators = [
        "@",  # Email-like
        "password",
        "token",
        "secret",
        "key",  # Auth-related
        "ssn",
        "social",
        "credit",
        "card",  # Financial
        "address",
        "street",
        "city",
        "zip",  # Location
    ]

    for indicator in pii_indicators:
        if indicator in key_lower or indicator in value.lower():
            return True

    return False


def _sanitize_value(value: Any) -> Any:
    """
    Sanitize a value to ensure it's safe for logging.

    Args:
        value: The value to sanitize

    Returns:
        Any: The sanitized value
    """
    if isinstance(value, str):
        # Truncate long strings to prevent log spam
        if len(value) > 500:
            return value[:500] + "...[truncated]"
        return value
    elif isinstance(value, (dict, list)):
        # Recursively sanitize nested structures
        if isinstance(value, dict):
            return {k: _sanitize_value(v) for k, v in value.items()}
        else:
            return [_sanitize_value(item) for item in value[:10]]  # Limit list size
    else:
        return value
