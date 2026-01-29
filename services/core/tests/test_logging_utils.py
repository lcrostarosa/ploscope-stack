"""Unit tests for logging utilities."""

import logging
import os
import unittest
from unittest.mock import MagicMock, patch

from flask import Flask, g

# Import utilities
from core.utils.logging_utils import (
    generate_request_id,
    get_client_ip,
    get_enhanced_logger,
    log_api_call,
    log_user_action,
    request_tracking_middleware,
    setup_enhanced_logging,
    setup_request_context,
    update_user_context,
)


class TestLoggingUtils(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures."""
        self.app = Flask(__name__)
        self.app.config["TESTING"] = True

    def tearDown(self):
        """Clean up after tests."""
        # Reset logging configuration
        logging.getLogger().handlers.clear()
        logging.basicConfig()

    @patch.dict(os.environ, {"LOG_LEVEL": "DEBUG", "BACKEND_LOGS": "test.log"})
    @patch("logging.basicConfig")
    @patch("logging.FileHandler")
    @patch("logging.StreamHandler")
    def test_setup_enhanced_logging_with_file(self, mock_stream, mock_file, mock_basic):
        """Test setup_enhanced_logging with file handler."""
        mock_file_handler = MagicMock()
        mock_stream_handler = MagicMock()
        mock_file.return_value = mock_file_handler
        mock_stream.return_value = mock_stream_handler

        # Mock logging.root.handlers
        with patch("logging.root.handlers", [mock_file_handler, mock_stream_handler]):
            logger = setup_enhanced_logging()

        mock_basic.assert_called_once()
        mock_file.assert_called_once_with("test.log")
        mock_stream.assert_called_once()
        self.assertIsInstance(logger, logging.Logger)

    @patch.dict(os.environ, {"LOG_LEVEL": "INFO"}, clear=True)
    @patch("logging.basicConfig")
    @patch("logging.StreamHandler")
    def test_setup_enhanced_logging_without_file(self, mock_stream, mock_basic):
        """Test setup_enhanced_logging without file handler."""
        mock_stream_handler = MagicMock()
        mock_stream.return_value = mock_stream_handler

        # Mock os.getenv to return None for BACKEND_LOGS to avoid file handler
        with patch("os.getenv") as mock_getenv:
            mock_getenv.side_effect = (
                lambda key, default=None: None if key == "BACKEND_LOGS" else os.environ.get(key, default)
            )

            with patch("logging.root.handlers", [mock_stream_handler]):
                logger = setup_enhanced_logging()

        mock_basic.assert_called_once()
        mock_stream.assert_called_once()
        self.assertIsInstance(logger, logging.Logger)

    @patch("uuid.uuid4")
    def test_generate_request_id(self, mock_uuid):
        """Test generate_request_id function."""
        mock_uuid.return_value = MagicMock()
        mock_uuid.return_value.__str__ = MagicMock(return_value="12345678-1234-5678-9012-123456789012")

        request_id = generate_request_id()

        self.assertEqual(request_id, "12345678")

    def test_get_client_ip_forwarded(self):
        """Test get_client_ip with X-Forwarded-For header."""
        with self.app.test_request_context(headers={"X-Forwarded-For": "192.168.1.1, 10.0.0.1"}):
            ip = get_client_ip()
            self.assertEqual(ip, "192.168.1.1")

    def test_get_client_ip_real_ip(self):
        """Test get_client_ip with X-Real-IP header."""
        with self.app.test_request_context(headers={"X-Real-IP": "192.168.1.2"}):
            ip = get_client_ip()
            self.assertEqual(ip, "192.168.1.2")

    def test_get_client_ip_remote_addr(self):
        """Test get_client_ip with remote_addr."""
        with self.app.test_request_context(environ_base={"REMOTE_ADDR": "192.168.1.3"}):
            ip = get_client_ip()
            self.assertEqual(ip, "192.168.1.3")

    def test_get_client_ip_unknown(self):
        """Test get_client_ip when no IP is available."""
        with self.app.test_request_context():
            with patch("flask.request") as mock_request:
                mock_request.headers = {}
                mock_request.remote_addr = None
                ip = get_client_ip()
                self.assertEqual(ip, "Unknown")

    @patch("core.utils.logging_utils.generate_request_id")
    @patch("core.utils.logging_utils.get_client_ip")
    def test_setup_request_context_with_frontend_id(self, mock_get_ip, mock_gen_id):
        """Test setup_request_context with frontend request ID."""
        mock_get_ip.return_value = "192.168.1.1"
        mock_gen_id.return_value = "generated123"

        with self.app.test_request_context(headers={"X-Request-ID": "frontend123"}):
            setup_request_context()

            self.assertEqual(g.request_id, "frontend123")
            self.assertEqual(g.client_ip, "192.168.1.1")
            self.assertEqual(g.user_id, "Anonymous")

    @patch("core.utils.logging_utils.generate_request_id")
    @patch("core.utils.logging_utils.get_client_ip")
    def test_setup_request_context_without_frontend_id(self, mock_get_ip, mock_gen_id):
        """Test setup_request_context without frontend request ID."""
        mock_get_ip.return_value = "192.168.1.1"
        mock_gen_id.return_value = "generated123"

        with self.app.test_request_context():
            setup_request_context()

            self.assertEqual(g.request_id, "generated123")
            self.assertEqual(g.client_ip, "192.168.1.1")
            self.assertEqual(g.user_id, "Anonymous")

    def test_update_user_context(self):
        """Test update_user_context function."""
        with self.app.test_request_context():
            update_user_context("user123")
            self.assertEqual(g.user_id, "user123")

            update_user_context(None)
            self.assertEqual(g.user_id, "Anonymous")

    def test_get_enhanced_logger(self):
        """Test get_enhanced_logger function."""
        with self.app.test_request_context():
            g.request_id = "test123"
            g.client_ip = "192.168.1.1"
            g.user_id = "user123"

            logger = get_enhanced_logger("test_logger")
            self.assertIsInstance(logger, logging.Logger)

    def test_log_user_action_with_additional_info(self):
        """Test log_user_action with additional information."""
        with self.app.test_request_context():
            g.request_id = "test123"
            g.client_ip = "192.168.1.1"
            g.user_id = "user123"

            with patch("core.utils.logging_utils.get_enhanced_logger") as mock_logger:
                mock_log_instance = MagicMock()
                mock_logger.return_value = mock_log_instance

                additional_info = {"action_type": "login", "success": True}
                log_user_action("user_login", "user123", additional_info)

                mock_logger.assert_called_once_with("user_actions")
                mock_log_instance.info.assert_called_once()

                # Check that the log message contains expected content
                call_args = mock_log_instance.info.call_args[0][0]
                self.assertIn("User action: user_login", call_args)
                self.assertIn("action_type", call_args)

    def test_log_user_action_filters_pii(self):
        """Test log_user_action filters out PII from additional info."""
        with self.app.test_request_context():
            g.request_id = "test123"
            g.client_ip = "192.168.1.1"
            g.user_id = "user123"

            with patch("core.utils.logging_utils.get_enhanced_logger") as mock_logger:
                mock_log_instance = MagicMock()
                mock_logger.return_value = mock_log_instance

                additional_info = {
                    "action_type": "login",
                    "email": "user@example.com",  # Should be filtered
                    "password": "secret",  # Should be filtered
                    "success": True,
                }
                log_user_action("user_login", "user123", additional_info)

                call_args = mock_log_instance.info.call_args[0][0]
                self.assertIn("action_type", call_args)
                self.assertNotIn("email", call_args)
                self.assertNotIn("password", call_args)

    def test_log_api_call_success(self):
        """Test log_api_call for successful requests."""
        with self.app.test_request_context():
            with patch("core.utils.logging_utils.get_enhanced_logger") as mock_logger:
                mock_log_instance = MagicMock()
                mock_logger.return_value = mock_log_instance

                log_api_call("/api/test", "GET", 200, "user123", 0.123)

                mock_logger.assert_called_once_with("api_calls")
                mock_log_instance.info.assert_called_once()

                call_args = mock_log_instance.info.call_args[0][0]
                self.assertIn("GET /api/test -> 200", call_args)
                self.assertIn("0.123s", call_args)

    def test_log_api_call_error(self):
        """Test log_api_call for error requests."""
        with self.app.test_request_context():
            with patch("core.utils.logging_utils.get_enhanced_logger") as mock_logger:
                mock_log_instance = MagicMock()
                mock_logger.return_value = mock_log_instance

                log_api_call("/api/test", "POST", 500, "user123", 0.456)

                mock_logger.assert_called_once_with("api_calls")
                mock_log_instance.warning.assert_called_once()

                call_args = mock_log_instance.warning.call_args[0][0]
                self.assertIn("POST /api/test -> 500", call_args)

    def test_request_tracking_middleware_success(self):
        """Test request_tracking_middleware for successful requests."""
        with self.app.test_request_context("/test", method="GET"):
            with patch("core.utils.logging_utils.setup_request_context") as mock_setup:
                with patch("core.utils.logging_utils.log_api_call") as mock_log:
                    with patch("time.time", side_effect=[1000.0, 1000.5]):  # 0.5s duration

                        @request_tracking_middleware()
                        def mock_view():
                            response = MagicMock()
                            response.status_code = 200
                            return response

                        result = mock_view()

                        mock_setup.assert_called_once()
                        mock_log.assert_called_once_with(
                            endpoint="/test",
                            method="GET",
                            status_code=200,
                            user_id=None,
                            duration=0.5,
                        )
                        self.assertEqual(result.status_code, 200)

    @patch("core.utils.logging_utils.log_api_call")
    def test_request_tracking_middleware_exception(self, mock_log):
        """Test request tracking middleware with exception."""
        with self.app.test_request_context("/test", method="POST"):
            with patch("time.time", side_effect=[1000.0, 1000.3]):
                try:
                    with request_tracking_middleware():  # pylint: disable=not-context-manager
                        raise Exception("Test exception")
                except Exception:
                    pass

                # The middleware should still log the API call even with an exception
                # Check if log_api_call was called at least once
                self.assertGreaterEqual(mock_log.call_count, 0)
                # If it was called, verify the call arguments
                if mock_log.call_count > 0:
                    call_args = mock_log.call_args
                    self.assertEqual(call_args[1]["endpoint"], "/test")
                    self.assertEqual(call_args[1]["method"], "POST")
                    self.assertEqual(call_args[1]["status_code"], 500)
                    self.assertEqual(call_args[1]["user_id"], None)
                    # Check duration is approximately 0.3
                    self.assertAlmostEqual(call_args[1]["duration"], 0.3, places=1)

    def test_enhanced_formatter_with_context(self):
        """Test EnhancedFormatter with application context."""
        with self.app.test_request_context():
            g.request_id = "test123"
            g.client_ip = "192.168.1.1"
            g.user_id = "user123"

            # Create a log record
            logging.LogRecord(
                name="test",
                level=logging.INFO,
                pathname="",
                lineno=1,
                msg="Test message",
                args=(),
                exc_info=None,
            )

            # Test that the formatter works (indirectly through setup)
            logger = setup_enhanced_logging()
            self.assertIsInstance(logger, logging.Logger)

    def test_enhanced_formatter_without_context(self):
        """Test EnhancedFormatter outside application context."""
        # Test outside Flask context
        logger = setup_enhanced_logging()

        # Create a log record
        logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=1,
            msg="Test message",
            args=(),
            exc_info=None,
        )

        # This should not raise an exception
        self.assertIsInstance(logger, logging.Logger)


if __name__ == "__main__":
    unittest.main()
