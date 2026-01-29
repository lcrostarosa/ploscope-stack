"""Enhanced logging utilities for the PLOSolver application."""

import logging
import os
import time
import uuid
from functools import wraps

from flask import g, request  # current_app


# Configure enhanced logging
def setup_enhanced_logging():
    """Configure logging with request tracking and PII protection."""
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    # Enhanced log format with request ID, IP, User Agent, and other context
    log_format = (
        "%(asctime)s - %(name)s - %(levelname)s - "
        "[ReqID:%(request_id)s] [IP:%(client_ip)s] [UserID:%(user_id)s] "
        "[UserAgent:%(user_agent)s] [Referer:%(referer)s] - %(message)s"
    )

    # Custom formatter that handles missing context gracefully
    class EnhancedFormatter(logging.Formatter):
        def format(self, record):
            # Add default values if not present
            if not hasattr(record, "request_id"):
                try:
                    record.request_id = getattr(g, "request_id", "N/A")
                except RuntimeError:
                    # Outside application context
                    record.request_id = "N/A"
            if not hasattr(record, "client_ip"):
                try:
                    record.client_ip = getattr(g, "client_ip", "N/A")
                except RuntimeError:
                    # Outside application context
                    record.client_ip = "N/A"
            if not hasattr(record, "user_id"):
                try:
                    record.user_id = getattr(g, "user_id", "N/A")
                except RuntimeError:
                    # Outside application context
                    record.user_id = "N/A"
            if not hasattr(record, "user_agent"):
                try:
                    record.user_agent = getattr(g, "user_agent", "N/A")
                except RuntimeError:
                    # Outside application context
                    record.user_agent = "N/A"
            if not hasattr(record, "referer"):
                try:
                    record.referer = getattr(g, "referer", "N/A")
                except RuntimeError:
                    # Outside application context
                    record.referer = "N/A"
            return super().format(record)

    # Setup logging handlers
    handlers = [logging.StreamHandler()]

    # Add file handler if log file is specified
    log_file = os.getenv("BACKEND_LOGS", "./logs/backend.log")
    if log_file:
        # Ensure log directory exists
        log_dir = os.path.dirname(log_file)
        if log_dir and not os.path.exists(log_dir):
            try:
                os.makedirs(log_dir, exist_ok=True)
            except Exception:
                pass  # If we can't create the directory, just skip file logging

        try:
            file_handler = logging.FileHandler(log_file)
            handlers.append(file_handler)
        except Exception:
            # If file logging fails, just use console logging
            pass

    logging.basicConfig(level=getattr(logging, log_level), handlers=handlers)

    # Apply custom formatter to all handlers
    formatter = EnhancedFormatter(log_format)
    for handler in logging.root.handlers:
        handler.setFormatter(formatter)

    # Reduce noise from Flask and other libraries
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("pika").setLevel(logging.WARNING)
    logging.getLogger("pika.adapters").setLevel(logging.WARNING)
    logging.getLogger("pika.channel").setLevel(logging.WARNING)
    logging.getLogger("pika.callback").setLevel(logging.WARNING)

    # Reduce SQLAlchemy logging verbosity - suppress INFO messages
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.dialects").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.orm").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy").setLevel(logging.WARNING)

    # Additional SQLAlchemy loggers that may produce INFO messages
    logging.getLogger("sqlalchemy.engine.Engine").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool.Pool").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool.impl").setLevel(logging.WARNING)

    return logging.getLogger(__name__)


def cleanup_logging_handlers():
    """Clean up logging handlers to prevent I/O errors on shutdown."""
    try:
        root_logger = logging.getLogger()
        for handler in root_logger.handlers[:]:  # Copy the list to avoid modification during iteration
            try:
                # Only close file handlers, keep console handlers
                if isinstance(handler, logging.FileHandler):
                    handler.close()
                    root_logger.removeHandler(handler)
            except Exception:
                pass  # Ignore errors when closing handlers
    except Exception:
        pass  # Ignore any logging cleanup errors


def generate_request_id():
    """Generate a unique request ID."""
    return str(uuid.uuid4())[:8]  # Short UUID for readability


def get_client_ip():
    """Extract client IP address from request headers."""
    # Check for forwarded IP first (for reverse proxies)
    if request.headers.get("X-Forwarded-For"):
        return request.headers.get("X-Forwarded-For").split(",")[0].strip()
    elif request.headers.get("X-Real-IP"):
        return request.headers.get("X-Real-IP")
    else:
        return request.remote_addr or "Unknown"


def get_request_info():
    """Get comprehensive request information for debugging."""
    return {
        "method": request.method,
        "url": request.url,
        "path": request.path,
        "endpoint": request.endpoint,
        "headers": dict(request.headers),
        "args": dict(request.args),
        "content_type": request.content_type,
        "content_length": request.content_length,
        "is_secure": request.is_secure,
        "host": request.host,
        "host_url": request.host_url,
        "base_url": request.base_url,
        "url_root": request.url_root,
    }


def setup_request_context():
    """Setup request context with ID, IP, User Agent, Referer, and user info."""
    # Use frontend-provided request ID if available, otherwise generate one
    frontend_request_id = request.headers.get("X-Request-ID")
    g.request_id = frontend_request_id or generate_request_id()
    g.client_ip = get_client_ip()
    g.user_id = "Anonymous"  # Will be updated when user is authenticated

    # Capture User Agent and Referer for debugging and monitoring
    g.user_agent = request.headers.get("User-Agent", "Unknown")
    g.referer = request.headers.get("Referer", "Direct")

    # Truncate User Agent if too long for logging
    if len(g.user_agent) > 100:
        g.user_agent = g.user_agent[:97] + "..."


def update_user_context(user_id):
    """Update the user context for the current request."""
    g.user_id = user_id or "Anonymous"


def get_enhanced_logger(name):
    """Get a logger with enhanced context information."""
    logger = logging.getLogger(name)

    # Check if logger has already been enhanced to avoid recursion
    if hasattr(logger, "_is_enhanced"):
        return logger

    # Create a custom log method that includes context
    original_log = logger._log

    def enhanced_log(level, msg, args, exc_info=None, extra=None, stack_info=False):
        if extra is None:
            extra = {}

        # Add context information, fallback to 'N/A' if Flask context is unavailable
        try:
            request_id = getattr(g, "request_id", "N/A")
            client_ip = getattr(g, "client_ip", "N/A")
            user_id = getattr(g, "user_id", "N/A")
            user_agent = getattr(g, "user_agent", "N/A")
            referer = getattr(g, "referer", "N/A")
        except Exception:
            request_id = client_ip = user_id = user_agent = referer = "N/A"

        extra.update(
            {
                "request_id": request_id,
                "client_ip": client_ip,
                "user_id": user_id,
                "user_agent": user_agent,
                "referer": referer,
            }
        )

        return original_log(level, msg, args, exc_info, extra, stack_info)

    logger._log = enhanced_log
    logger._is_enhanced = True
    return logger


def log_user_action(action, user_id=None, additional_info=None):
    """Log user actions with standard format and no PII."""
    logger = get_enhanced_logger("user_actions")

    log_data = {
        "action": action,
        "user_id": user_id or getattr(g, "user_id", "Anonymous"),
        "request_id": getattr(g, "request_id", "N/A"),
        "ip": getattr(g, "client_ip", "N/A"),
    }

    if additional_info:
        log_data.update(additional_info)

    # Convert to string for logging (no PII should be in additional_info)
    log_message = f"User action: {action}"
    if additional_info:
        safe_info = {
            k: v for k, v in additional_info.items() if k not in ["email", "password", "token", "personal_info"]
        }
        if safe_info:
            log_message += f" | Additional info: {safe_info}"

    logger.info(log_message)


def log_api_call(endpoint, method, status_code, user_id=None, duration=None):
    """Log API calls with standard format."""
    logger = get_enhanced_logger("api_calls")

    log_message = f"API call: {method} {endpoint} -> {status_code}"
    if duration:
        log_message += f" ({duration:.3f}s)"

    if status_code >= 400:
        logger.warning(log_message)
    else:
        logger.info(log_message)


def log_detailed_request(include_headers=False, include_args=False):
    """Log detailed request information for debugging purposes."""
    logger = get_enhanced_logger("request_details")

    request_info = get_request_info()

    # Always log basic info
    basic_info = {
        "method": request_info["method"],
        "url": request_info["url"],
        "endpoint": request_info["endpoint"],
        "content_type": request_info["content_type"],
        "content_length": request_info["content_length"],
        "is_secure": request_info["is_secure"],
    }

    log_message = f"Detailed request: {basic_info}"

    # Conditionally include headers and args
    if include_headers:
        # Filter out sensitive headers
        safe_headers = {
            k: v
            for k, v in request_info["headers"].items()
            if k.lower() not in ["authorization", "cookie", "x-api-key", "x-auth-token"]
        }
        log_message += f" | Headers: {safe_headers}"

    if include_args:
        log_message += f" | Args: {request_info['args']}"

    logger.debug(log_message)


def log_error_with_context(error, context=None):
    """Log errors with enhanced context information."""
    logger = get_enhanced_logger("errors")

    error_info = {
        "error_type": type(error).__name__,
        "error_message": str(error),
        "request_id": getattr(g, "request_id", "N/A"),
        "client_ip": getattr(g, "client_ip", "N/A"),
        "user_id": getattr(g, "user_id", "N/A"),
        "user_agent": getattr(g, "user_agent", "N/A"),
        "endpoint": request.endpoint if request else "N/A",
        "method": request.method if request else "N/A",
        "url": request.url if request else "N/A",
    }

    if context:
        error_info.update(context)

    log_message = f"Error: {error_info['error_type']}: {error_info['error_message']}"
    if context:
        log_message += f" | Context: {context}"

    logger.error(log_message, exc_info=True)


def request_tracking_middleware():
    """Flask middleware to track requests and add context."""

    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            # Setup request context
            setup_request_context()

            # Get start time for duration calculation
            start_time = time.time()

            try:
                # Execute the request
                response = f(*args, **kwargs)
                status_code = getattr(response, "status_code", 200)

                # Log the API call
                duration = time.time() - start_time
                log_api_call(
                    endpoint=request.endpoint or request.path,
                    method=request.method,
                    status_code=status_code,
                    user_id=getattr(g, "user_id", None),
                    duration=duration,
                )

                return response

            except Exception:
                # Log error
                duration = time.time() - start_time
                log_api_call(
                    endpoint=request.endpoint or request.path,
                    method=request.method,
                    status_code=500,
                    user_id=getattr(g, "user_id", None),
                    duration=duration,
                )
                raise

        return wrapper

    return decorator
