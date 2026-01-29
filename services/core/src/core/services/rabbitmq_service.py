"""RabbitMQ service for PLOSolver.

This module provides a service for interacting with RabbitMQ message broker.
It handles message publishing, consuming, and queue management.
"""

import json
import os
import threading
import time
from typing import Any, Optional

import pika

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


class RabbitMQService:
    """Service for RabbitMQ message broker operations."""

    def __init__(self, auto_init: bool = False):
        """Initialize RabbitMQ service.

        Args:
            auto_init: Whether to automatically initialize queues on startup.
        """
        self.host = os.getenv("RABBITMQ_HOST", "localhost")
        self.port = int(os.getenv("RABBITMQ_PORT", "5672"))
        self.username = os.getenv("RABBITMQ_USERNAME", "plosolver")
        self.password = os.getenv("RABBITMQ_PASSWORD", "dev_password_2024")
        self.vhost = os.getenv("RABBITMQ_VHOST", "/plosolver")

        # Queue names from environment
        self.spot_queue = os.getenv("RABBITMQ_SPOT_QUEUE", "spot-processing")
        self.solver_queue = os.getenv("RABBITMQ_SOLVER_QUEUE", "solver-processing")

        # Thread-local storage for connections
        self._local = threading.local()

        # Initialize queues if requested
        if auto_init:
            self._initialize_queues()

    def _get_connection(self):
        """Get or create a RabbitMQ connection."""
        if not hasattr(self._local, "connection") or self._local.connection.is_closed:
            credentials = pika.PlainCredentials(self.username, self.password)
            parameters = pika.ConnectionParameters(
                host=self.host,
                port=self.port,
                virtual_host=self.vhost,
                credentials=credentials,
                heartbeat=600,
                blocked_connection_timeout=300,
            )
            self._local.connection = pika.BlockingConnection(parameters)
        return self._local.connection

    def _get_channel(self):
        """Get or create a RabbitMQ channel."""
        if not hasattr(self._local, "channel") or self._local.channel.is_closed:
            connection = self._get_connection()
            self._local.channel = connection.channel()
        return self._local.channel

    def _initialize_queues(self):
        """Initialize required queues and dead letter queues."""
        try:
            channel = self._get_channel()

            # Declare main queues with dead letter queues
            for queue_name in [self.spot_queue, self.solver_queue]:
                dlq_name = f"{queue_name}-dlq"

                # Declare dead letter queue
                channel.queue_declare(queue=dlq_name, durable=True)

                # Declare main queue with dead letter exchange
                channel.queue_declare(
                    queue=queue_name,
                    durable=True,
                    arguments={
                        "x-dead-letter-exchange": "",
                        "x-dead-letter-routing-key": dlq_name,
                        "x-message-ttl": 300000,  # 5 minutes
                    },
                )

            logger.info("RabbitMQ queues initialized successfully")

        except Exception as e:
            logger.error("Failed to initialize RabbitMQ queues: %s", e)
            raise

    def send_message(self, queue_name: str, message: dict[str, Any], delay_seconds: Optional[int] = None) -> bool:
        """Send a message to a RabbitMQ queue.

        Args:
            queue_name: Name of the queue to send the message to.
            message: Message data to send.
            delay_seconds: Optional delay in seconds before message becomes available.

        Returns:
            True if message was sent successfully, False otherwise.
        """
        try:
            channel = self._get_channel()

            # Prepare message properties
            properties = pika.BasicProperties(
                delivery_mode=2,  # Make message persistent
                content_type="application/json",
            )

            # Add delay if specified
            if delay_seconds:
                properties.headers = {"x-delay": delay_seconds * 1000}

            # Publish message
            channel.basic_publish(exchange="", routing_key=queue_name, body=json.dumps(message), properties=properties)

            logger.debug("Message sent to queue %s: %s", queue_name, message)
            return True

        except Exception as e:
            logger.error("Failed to send message to queue %s: %s", queue_name, e)
            return False

    def receive_messages(self, queue_name: str, max_messages: int = 10) -> list[dict[str, Any]]:
        """Receive messages from a RabbitMQ queue.

        Args:
            queue_name: Name of the queue to receive messages from.
            max_messages: Maximum number of messages to receive.

        Returns:
            List of received messages with metadata.
        """
        messages = []

        try:
            channel = self._get_channel()

            for _ in range(max_messages):
                method, properties, body = channel.basic_get(queue=queue_name, auto_ack=False)

                if method is None:
                    # No more messages
                    break

                try:
                    # Parse message body
                    message_data = json.loads(body.decode("utf-8"))

                    # Check if message is already in enhanced format
                    if isinstance(message_data, dict) and "Body" in message_data:
                        # Message is already in enhanced format, use it directly
                        enhanced_message = message_data
                        enhanced_message["ReceiptHandle"] = f"{method.delivery_tag}:{queue_name}"
                    else:
                        # Create enhanced message format from raw data
                        enhanced_message = {
                            "Body": message_data,
                            "MessageAttributes": {
                                "SentTimestamp": properties.timestamp if properties.timestamp else 0,
                                "SenderId": properties.app_id if properties.app_id else "unknown",
                                "ApproximateFirstReceiveTimestamp": None,
                                "ApproximateReceiveCount": 0,
                            },
                            "MD5OfBody": "",
                            "MessageId": properties.message_id if properties.message_id else f"{method.delivery_tag}",
                            "ReceiptHandle": f"{method.delivery_tag}:{queue_name}",
                        }

                    messages.append(enhanced_message)

                except json.JSONDecodeError:
                    logger.warning("Invalid JSON in message from queue %s, skipping", queue_name)
                    # Acknowledge invalid message to remove it from queue
                    channel.basic_ack(delivery_tag=method.delivery_tag)
                    continue

        except Exception as e:
            logger.error("Failed to receive messages from queue %s: %s", queue_name, e)

        return messages

    def delete_message(self, queue_name: str, receipt_handle: str) -> bool:
        """Delete a message from a RabbitMQ queue.

        Args:
            queue_name: Name of the queue.
            receipt_handle: Receipt handle of the message to delete.

        Returns:
            True if message was deleted successfully, False otherwise.
        """
        try:
            # Parse delivery tag from receipt handle
            delivery_tag = int(receipt_handle.split(":")[0])

            channel = self._get_channel()
            channel.basic_ack(delivery_tag)

            logger.debug("Message %s acknowledged from queue %s", delivery_tag, queue_name)
            return True

        except Exception as e:
            logger.error("Failed to delete message %s from queue %s: %s", receipt_handle, queue_name, e)
            return False

    def get_queue_attributes(self, queue_name: str) -> dict[str, Any]:
        """Get attributes of a RabbitMQ queue.

        Args:
            queue_name: Name of the queue.

        Returns:
            Dictionary containing queue attributes.
        """
        try:
            channel = self._get_channel()
            method = channel.queue_declare(queue=queue_name, passive=True)

            attributes = {
                "ApproximateNumberOfMessages": method.method.message_count,
                "ApproximateNumberOfMessagesNotVisible": 0,  # RabbitMQ doesn't have this concept
                "CreatedTimestamp": 0,  # RabbitMQ doesn't provide creation timestamp
                "LastModifiedTimestamp": 0,  # RabbitMQ doesn't provide modification timestamp
                "QueueArn": f"arn:rabbitmq:{queue_name}",  # Mock ARN for compatibility
                "VisibilityTimeout": 30,  # Default visibility timeout
                "MessageRetentionPeriod": 1209600,  # 14 days in seconds
                "MaximumMessageSize": 262144,  # 256KB
                "DelaySeconds": 0,
                "ReceiveMessageWaitTimeSeconds": 0,
            }

            return attributes

        except Exception as e:
            logger.error("Failed to get attributes for queue %s: %s", queue_name, e)
            return {}

    def change_message_visibility(self, queue_name: str, receipt_handle: str, visibility_timeout: int) -> bool:
        """Change message visibility timeout.

        Note: RabbitMQ doesn't support changing visibility timeout for individual messages.
        This method exists for compatibility with SQS-like interfaces.

        Args:
            queue_name: Name of the queue.
            receipt_handle: Receipt handle of the message.
            visibility_timeout: New visibility timeout in seconds.

        Returns:
            Always returns True for compatibility.
        """
        logger.debug("Message visibility change requested for %s in queue %s", receipt_handle, queue_name)
        # RabbitMQ doesn't support this operation, but we return True for compatibility
        return True

    def health_check(self) -> dict[str, Any]:
        """Perform a health check on the RabbitMQ connection.

        Returns:
            Dictionary containing health status and details.
        """
        try:
            connection = self._get_connection()
            channel = self._get_channel()

            # Check if connection and channel are open
            if connection.is_closed or channel.is_closed:
                return {
                    "status": "unhealthy",
                    "error": "Connection or channel is closed",
                    "timestamp": int(time.time() * 1000),
                }

            return {
                "status": "healthy",
                "timestamp": int(time.time() * 1000),
                "connection_info": {"host": self.host, "port": self.port, "vhost": self.vhost},
            }

        except Exception as e:
            return {"status": "unhealthy", "error": str(e), "timestamp": int(time.time() * 1000)}

    def close(self):
        """Close RabbitMQ connections."""
        try:
            if hasattr(self._local, "channel") and not self._local.channel.is_closed:
                self._local.channel.close()

            if hasattr(self._local, "connection") and not self._local.connection.is_closed:
                self._local.connection.close()

            logger.info("RabbitMQ connections closed")

        except Exception as e:
            logger.error("Error closing RabbitMQ connections: %s", e)
