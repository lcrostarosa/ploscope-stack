from unittest.mock import MagicMock, patch

import pytest
from flask import Flask, g

from core.utils.logging_utils import (
    get_client_ip,
    get_enhanced_logger,
    get_request_info,
    log_error_with_context,
    setup_request_context,
    update_user_context,
)


@pytest.fixture
def app():
    """Create a test Flask app."""
    app = Flask(__name__)
    return app


@pytest.fixture
def client(app):
    """Create a test client."""
    return app.test_client()


class TestEnhancedLogging:
    """Test enhanced logging functionality."""

    def test_setup_request_context(self, app):
        """Test that request context is set up correctly."""
        with app.test_request_context(
            "/test",
            headers={
                "X-Request-ID": "test-123",
                "User-Agent": "Test Browser/1.0",
                "Referer": "https://example.com",
            },
        ):
            setup_request_context()

            assert g.request_id == "test-123"
            # In test context, remote_addr might be "Unknown" instead of "127.0.0.1"
            assert g.client_ip in ["127.0.0.1", "Unknown"]
            assert g.user_id == "Anonymous"
            assert g.user_agent == "Test Browser/1.0"
            assert g.referer == "https://example.com"

    def test_generate_request_id_when_not_provided(self, app):
        """Test that request ID is generated when not provided."""
        with app.test_request_context("/test"):
            setup_request_context()

            assert g.request_id is not None
            assert len(g.request_id) == 8  # Short UUID

    def test_update_user_context(self, app):
        """Test that user context is updated correctly."""
        with app.test_request_context("/test"):
            setup_request_context()
            update_user_context("user123")

            assert g.user_id == "user123"

    def test_update_user_context_with_none(self, app):
        """Test that user context handles None values."""
        with app.test_request_context("/test"):
            setup_request_context()
            update_user_context(None)

            assert g.user_id == "Anonymous"

    def test_get_client_ip_with_forwarded_for(self, app):
        """Test IP extraction with X-Forwarded-For header."""
        with app.test_request_context("/test", headers={"X-Forwarded-For": "192.168.1.1, 10.0.0.1"}):
            ip = get_client_ip()
            assert ip == "192.168.1.1"

    def test_get_client_ip_with_real_ip(self, app):
        """Test IP extraction with X-Real-IP header."""
        with app.test_request_context("/test", headers={"X-Real-IP": "192.168.1.2"}):
            ip = get_client_ip()
            assert ip == "192.168.1.2"

    def test_get_client_ip_fallback(self, app):
        """Test IP extraction fallback to remote_addr."""
        with app.test_request_context("/test"):
            ip = get_client_ip()
            # In test context, remote_addr might be "Unknown" instead of "127.0.0.1"
            assert ip in ["127.0.0.1", "Unknown"]

    def test_get_request_info(self, app):
        """Test comprehensive request info extraction."""
        with app.test_request_context(
            "/test?param=value",
            headers={"Content-Type": "application/json"},
        ):
            info = get_request_info()

            assert info["method"] == "GET"
            assert info["path"] == "/test"
            assert info["content_type"] == "application/json"
            assert info["args"]["param"] == "value"

    def test_user_agent_truncation(self, app):
        """Test that long User Agents are truncated."""
        long_user_agent = "A" * 150  # 150 characters
        with app.test_request_context("/test", headers={"User-Agent": long_user_agent}):
            setup_request_context()

            assert len(g.user_agent) == 100  # Truncated to 100 chars
            assert g.user_agent.endswith("...")

    def test_get_enhanced_logger(self, app):
        """Test that enhanced logger includes context."""
        with app.test_request_context(
            "/test",
            headers={
                "X-Request-ID": "test-456",
                "User-Agent": "Test Logger/1.0",
            },
        ):
            setup_request_context()
            logger = get_enhanced_logger("test_logger")

            # The logger should have the enhanced _log method
            assert hasattr(logger, "_log")
            assert logger._log != logger.__class__._log

    @patch("core.utils.logging_utils.logging.getLogger")
    def test_log_error_with_context(self, mock_get_logger, app):
        """Test error logging with context."""
        mock_logger = MagicMock()
        mock_get_logger.return_value = mock_logger

        with app.test_request_context("/test"):
            setup_request_context()
            error = ValueError("Test error")

            log_error_with_context(error, {"custom_field": "test_value"})

            # Verify logger.error was called with exc_info=True
            mock_logger.error.assert_called_once()
            call_args = mock_logger.error.call_args
            assert call_args[1]["exc_info"] is True
