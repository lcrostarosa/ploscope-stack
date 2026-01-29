import json
import logging
import os
from datetime import datetime

from flask import g  # request

# import uuid


class JSONFormatter(logging.Formatter):
    """JSON formatter for structured logging with ELK stack."""

    def format(self, record):
        # Create base log entry
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Add request context if available
        try:
            log_entry.update(
                {
                    "request_id": getattr(g, "request_id", "N/A"),
                    "ip": getattr(g, "client_ip", "N/A"),
                    "user_id": getattr(g, "user_id", "N/A"),
                    "user_agent": getattr(g, "user_agent", "N/A"),
                    "referer": getattr(g, "referer", "N/A"),
                }
            )
        except RuntimeError:
            # Outside Flask application context
            log_entry.update(
                {
                    "request_id": "N/A",
                    "ip": "N/A",
                    "user_id": "N/A",
                    "user_agent": "N/A",
                    "referer": "N/A",
                }
            )

        # Add exception info if present
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        # Add extra fields if present
        if hasattr(record, "extra_fields"):
            log_entry.update(record.extra_fields)

        return json.dumps(log_entry)


def setup_json_logging():
    """Setup JSON logging for ELK stack integration."""
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    # Create logs directory if it doesn't exist
    # Use environment variable or default to local path
    log_dir = os.getenv("LOG_DIR", "./logs")
    os.makedirs(log_dir, exist_ok=True)

    # Setup JSON formatter
    json_formatter = JSONFormatter()

    # Create handlers
    handlers = []

    # Console handler (for development)
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(json_formatter)
    handlers.append(console_handler)

    # File handler for ELK stack
    file_handler = logging.FileHandler(f"{log_dir}/application.log")
    file_handler.setFormatter(json_formatter)
    handlers.append(file_handler)

    # Configure root logger
    logging.basicConfig(
        level=getattr(logging, log_level),
        handlers=handlers,
        format=None,  # We're using custom formatters
    )

    # Reduce noise from third-party libraries
    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("pika").setLevel(logging.WARNING)
    logging.getLogger("elasticsearch").setLevel(logging.WARNING)

    return logging.getLogger(__name__)


def get_json_logger(name):
    """Get a logger configured for JSON output."""
    return logging.getLogger(name)


def log_with_context(level, message, **kwargs):
    """Log a message with additional context fields."""
    logger = get_json_logger("plosolver")

    # Create a log record with extra fields
    record = logger.makeRecord(logger.name, level, "", 0, message, (), None)
    record.extra_fields = kwargs

    logger.handle(record)
