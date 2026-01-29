"""
RabbitMQ service for handling message queue operations and connectivity checks.

This module provides functionality for connecting to RabbitMQ, checking connectivity,
and managing message queue operations for the PLOSolver backend.
"""

import os
from typing import Optional

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


class RabbitMQService:
    """Service class for RabbitMQ operations and connectivity management."""

    def __init__(self):
        """Initialize RabbitMQ service with configuration from environment variables."""
        self.host = os.getenv("RABBITMQ_HOST", "localhost")
        self.port = int(os.getenv("RABBITMQ_PORT", "5672"))
        self.username = os.getenv("RABBITMQ_USERNAME", "guest")
        self.password = os.getenv("RABBITMQ_PASSWORD", "guest")
        self.vhost = os.getenv("RABBITMQ_VHOST", "/")

    def check_connectivity(self) -> bool:
        """
        Check if RabbitMQ is accessible before starting the app.

        Returns:
            bool: True if RabbitMQ is accessible, False otherwise
        """
        logger.info("Testing RabbitMQ connectivity...")
        try:
            import pika

            logger.info("Connecting to RabbitMQ: %s:%s", self.host, self.port)
            credentials = pika.PlainCredentials(self.username, self.password)
            parameters = pika.ConnectionParameters(
                host=self.host, port=self.port, virtual_host=self.vhost, credentials=credentials
            )
            connection = pika.BlockingConnection(parameters)
            connection.close()
            logger.info("RabbitMQ connectivity verified")
            return True
        except Exception as e:  # noqa: BLE001 - broad except acceptable for connectivity check
            logger.error("RabbitMQ connectivity check failed: %s", e)
            logger.error("Application cannot start without RabbitMQ connection")
            return False

    def get_connection_parameters(self) -> Optional[object]:
        """
        Get RabbitMQ connection parameters for use in other parts of the application.

        Returns:
            pika.ConnectionParameters or None if pika is not available
        """
        try:
            import pika

            credentials = pika.PlainCredentials(self.username, self.password)
            return pika.ConnectionParameters(
                host=self.host, port=self.port, virtual_host=self.vhost, credentials=credentials
            )
        except ImportError:
            logger.error("pika library not available for RabbitMQ operations")
            return None

    def get_connection(self) -> Optional[object]:
        """
        Get a RabbitMQ connection for use in other parts of the application.

        Returns:
            pika.BlockingConnection or None if connection fails
        """
        try:
            import pika

            parameters = self.get_connection_parameters()
            if parameters:
                return pika.BlockingConnection(parameters)
            return None
        except Exception as e:  # noqa: BLE001 - broad except acceptable for connection creation
            logger.error("Failed to create RabbitMQ connection: %s", e)
            return None

    def health_check(self) -> dict:
        """
        Perform a health check on RabbitMQ connectivity.

        Returns:
            dict: Health status information with 'status' key
        """
        try:
            is_connected = self.check_connectivity()
            return {
                "status": "healthy" if is_connected else "unhealthy",
                "host": self.host,
                "port": self.port,
                "vhost": self.vhost,
                "connected": is_connected,
            }
        except Exception as e:
            logger.error("Health check failed: %s", e)
            return {
                "status": "unhealthy",
                "host": self.host,
                "port": self.port,
                "vhost": self.vhost,
                "connected": False,
                "error": str(e),
            }


# Global instance for easy access
rabbitmq_service = RabbitMQService()


def check_rabbitmq_connectivity() -> bool:
    """
    Convenience function to check RabbitMQ connectivity.

    This function maintains backward compatibility with the original
    check_rabbitmq_connectivity function in main.py.

    Returns:
        bool: True if RabbitMQ is accessible, False otherwise
    """
    return rabbitmq_service.check_connectivity()


def get_message_queue_service():
    """
    Get the message queue service instance.

    This function provides backward compatibility with the old core library
    get_message_queue_service function.

    Returns:
        RabbitMQService: The global RabbitMQ service instance
    """
    return rabbitmq_service
