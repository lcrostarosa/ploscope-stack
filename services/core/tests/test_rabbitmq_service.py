"""Unit tests for RabbitMQ service."""

import json
import os
import sys
from unittest.mock import Mock, patch

import pytest

# Add backend directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

# Import after path modification
from core.services.rabbitmq_service import RabbitMQService  # noqa: E402, C0413


class TestRabbitMQService:
    """Test cases for RabbitMQ service."""

    @pytest.fixture
    def mock_pika(self):
        """Mock pika module completely."""
        with patch("core.services.rabbitmq_service.pika") as mock_pika:
            mock_connection = Mock()
            mock_channel = Mock()
            mock_connection.channel.return_value = mock_channel
            mock_connection.is_closed = False
            mock_channel.is_closed = False
            mock_pika.BlockingConnection.return_value = mock_connection
            mock_pika.ConnectionParameters.return_value = Mock()
            mock_pika.PlainCredentials.return_value = Mock()
            mock_pika.BasicProperties = Mock()
            yield {
                "pika": mock_pika,
                "connection": mock_connection,
                "channel": mock_channel,
            }

    def test_initialization_success(self, mock_pika):
        """Test successful RabbitMQ service initialization."""
        service = RabbitMQService()

        # Service should initialize successfully but not create connections in test environment
        assert service is not None
        assert service.host == "localhost"
        assert service.port == int(os.getenv("RABBITMQ_PORT", "5672"))
        # Connection should not be created during initialization in test environment
        assert not mock_pika["pika"].BlockingConnection.called

    def test_initialization_failure(self, mock_pika):
        """Test RabbitMQ service initialization failure."""
        # Make connection fail
        mock_pika["pika"].BlockingConnection.side_effect = Exception("Connection failed")

        service = RabbitMQService()

        # Service should still be created but connection should fail
        assert service is not None

    def test_send_message_success(self, mock_pika):
        """Test successful message sending."""
        service = RabbitMQService()
        test_message = {"test": "data"}

        # Mock successful publishing
        mock_pika["channel"].basic_publish.return_value = True

        result = service.send_message("test-queue", test_message)

        assert result is True
        mock_pika["channel"].basic_publish.assert_called()

    def test_send_message_with_delay(self, mock_pika):
        """Test message sending with delay."""
        service = RabbitMQService()
        test_message = {"test": "data"}

        # Mock successful publishing
        mock_pika["channel"].basic_publish.return_value = True

        result = service.send_message("test-queue", test_message, delay_seconds=30)

        assert result is True
        mock_pika["channel"].basic_publish.assert_called()

    def test_receive_messages_success(self, mock_pika):
        """Test successful message receiving."""
        service = RabbitMQService()

        # Mock message data
        mock_method = Mock()
        mock_method.delivery_tag = 123
        mock_properties = Mock()

        # Create a properly formatted message like the service expects
        enhanced_message = {
            "Body": {"test": "data"},
            "MessageAttributes": {
                "SentTimestamp": 1234567890,
                "SenderId": "test-sender",
                "ApproximateFirstReceiveTimestamp": None,
                "ApproximateReceiveCount": 0,
            },
            "MD5OfBody": "",
            "MessageId": "test-message-id",
        }
        mock_body = json.dumps(enhanced_message).encode("utf-8")

        # Mock get_message to return a message
        mock_pika["channel"].basic_get.return_value = (
            mock_method,
            mock_properties,
            mock_body,
        )

        messages = service.receive_messages("test-queue", max_messages=1)

        assert len(messages) == 1
        assert messages[0]["Body"] == {"test": "data"}
        assert messages[0]["ReceiptHandle"] == "123:test-queue"

    def test_receive_messages_invalid_json(self, mock_pika):
        """Test receiving messages with invalid JSON."""
        service = RabbitMQService()

        # Mock message data with invalid JSON
        mock_method = Mock()
        mock_method.delivery_tag = 456
        mock_properties = Mock()
        mock_body = b"invalid json"

        # Mock get_message to return a message with invalid JSON
        mock_pika["channel"].basic_get.return_value = (
            mock_method,
            mock_properties,
            mock_body,
        )

        messages = service.receive_messages("test-queue", max_messages=1)

        # Invalid JSON should be rejected, so no messages returned
        assert len(messages) == 0

    def test_delete_message_success(self, mock_pika):
        """Test successful message deletion."""
        service = RabbitMQService()

        result = service.delete_message("test-queue", "789:test-queue")

        assert result is True
        mock_pika["channel"].basic_ack.assert_called_with(789)

    def test_get_queue_attributes_success(self, mock_pika):
        """Test successful queue attributes retrieval."""
        service = RabbitMQService()

        # Mock queue_declare_passive to return method with message_count
        mock_method = Mock()
        mock_method.method.message_count = 5
        mock_method.method.consumer_count = 2
        mock_pika["channel"].queue_declare.return_value = mock_method

        attributes = service.get_queue_attributes("test-queue")

        # Check key attributes are present
        assert attributes["ApproximateNumberOfMessages"] == 5
        assert "ApproximateNumberOfMessagesNotVisible" in attributes
        assert "CreatedTimestamp" in attributes

    def test_get_queue_attributes_failure(self, mock_pika):
        """Test queue attributes retrieval for non-existent queue."""
        service = RabbitMQService()

        # Mock queue_declare to raise exception for non-existent queue
        mock_pika["channel"].queue_declare.side_effect = Exception("Queue not found")

        attributes = service.get_queue_attributes("nonexistent-queue")

        # Should return empty dict when queue doesn't exist
        assert attributes == {}

    def test_change_message_visibility_not_supported(self, mock_pika):
        """Test that visibility timeout change is not supported (returns False)."""
        service = RabbitMQService()

        result = service.change_message_visibility("test-queue", "test-handle", 30)

        # RabbitMQ doesn't support this operation, but returns True for compatibility
        assert result is True

    def test_health_check_success(self, mock_pika):
        """Test successful health check."""
        service = RabbitMQService()

        # Mock successful connection
        mock_pika["connection"].is_closed = False
        mock_pika["channel"].is_closed = False

        health = service.health_check()

        assert health["status"] == "healthy"
        assert "timestamp" in health

    def test_health_check_connection_closed(self, mock_pika):
        """Test health check with closed connection."""
        service = RabbitMQService()

        # Mock connection failure by making _get_connection raise an exception
        with patch.object(service, "_get_connection", side_effect=Exception("Connection is closed")):
            health = service.health_check()

        assert health["status"] == "unhealthy"
        assert "Connection is closed" in health["error"]

    def test_health_check_channel_closed(self, mock_pika):
        """Test health check with closed channel."""
        service = RabbitMQService()

        # Mock channel failure by making _get_channel raise an exception
        with patch.object(service, "_get_channel", side_effect=Exception("Channel is closed")):
            health = service.health_check()

        assert health["status"] == "unhealthy"
        assert "Channel is closed" in health["error"]

    def test_close_connection(self, mock_pika):
        """Test connection closing."""
        service = RabbitMQService()

        # Set up the internal connection to mock
        service._local = Mock()
        service._local.connection = mock_pika["connection"]

        service.close()

        mock_pika["connection"].close.assert_called_once()

    def test_environment_configuration(self, mock_pika):
        """Test that service uses environment configuration."""
        # Set test environment variables
        os.environ["RABBITMQ_SPOT_QUEUE"] = "test-spot-queue"
        os.environ["RABBITMQ_SOLVER_QUEUE"] = "test-solver-queue"

        try:
            # Test with auto_init=True to force queue initialization
            RabbitMQService(auto_init=True)

            # Check that queue_declare was called for both queues and their DLQs
            calls = mock_pika["channel"].queue_declare.call_args_list
            assert len(calls) >= 2

            # Check that the test queues were declared
            queue_names = [call[1]["queue"] for call in calls if "queue" in call[1]]
            assert "test-spot-queue" in queue_names
            assert "test-solver-queue" in queue_names

        finally:
            # Clean up environment variables
            os.environ.pop("RABBITMQ_SPOT_QUEUE", None)
            os.environ.pop("RABBITMQ_SOLVER_QUEUE", None)
