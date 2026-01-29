"""Unit tests for WebSocket service functionality."""

from unittest.mock import Mock, patch

import pytest
from flask import Flask

from core.services.websocket_service import broadcast_job_completion, broadcast_job_update, get_socketio, init_socketio


class TestWebSocketService:
    """Test WebSocket service functionality."""

    @pytest.fixture
    def app(self):
        """Create test Flask app."""
        app = Flask(__name__)
        app.config["TESTING"] = True
        app.config["SECRET_KEY"] = "test-secret"
        return app

    @pytest.fixture
    def mock_socketio(self):
        """Mock SocketIO instance."""
        mock_socketio = Mock()
        mock_socketio.emit = Mock()
        return mock_socketio

    def test_init_socketio(self, app):
        """Test SocketIO initialization."""
        with patch("core.services.websocket_service.SocketIO") as mock_socketio_class:
            mock_socketio_instance = Mock()
            mock_socketio_class.return_value = mock_socketio_instance

            result = init_socketio(app)

            # Verify SocketIO was created with correct parameters
            mock_socketio_class.assert_called_once()
            call_args = mock_socketio_class.call_args
            assert call_args[0][0] == app  # First argument should be the Flask app

            # Verify event handlers were registered
            mock_socketio_instance.on.assert_called()

            # Verify result is the socketio instance
            assert result == mock_socketio_instance

    def test_broadcast_job_update_with_socketio(self, mock_socketio):
        """Test broadcasting job updates when SocketIO is available."""
        with (
            patch("core.services.websocket_service.socketio", mock_socketio),
            patch("flask.has_request_context", return_value=False),
        ):
            job_id = 123
            user_id = 456
            update_data = {
                "status": "processing",
                "progress_percentage": 50,
                "progress_message": "Processing...",
            }

            broadcast_job_update(job_id, user_id, update_data)

            # Verify emit was called twice (job room and user room)
            assert mock_socketio.emit.call_count == 2

            # Check job-specific room emit
            job_room_call = mock_socketio.emit.call_args_list[0]
            assert job_room_call[0][0] == "job_update"
            assert job_room_call[0][1] == update_data
            assert job_room_call[1]["room"] == f"job_{job_id}"

            # Check user room emit
            user_room_call = mock_socketio.emit.call_args_list[1]
            assert user_room_call[0][0] == "job_list_update"
            assert user_room_call[0][1] == {"job_id": job_id, "update": update_data}
            assert user_room_call[1]["room"] == f"user_{user_id}"

    def test_broadcast_job_update_without_socketio(self):
        """Test broadcasting job updates when SocketIO is not available."""
        with patch("core.services.websocket_service.socketio", None):
            # Should not raise an exception
            broadcast_job_update(123, 456, {"status": "processing"})

    def test_broadcast_job_completion_with_socketio(self, mock_socketio):
        """Test broadcasting job completion when SocketIO is available."""
        with (
            patch("core.services.websocket_service.socketio", mock_socketio),
            patch("flask.has_request_context", return_value=False),
        ):
            job_id = 123
            user_id = 456
            completion_data = {
                "status": "completed",
                "progress_percentage": 100,
                "result_data": {"results": []},
            }

            broadcast_job_completion(job_id, user_id, completion_data)

            # Verify emit was called once for user room
            mock_socketio.emit.assert_called_once_with(
                "job_completed",
                {"job_id": job_id, "completion_data": completion_data},
                room=f"user_{user_id}",
            )

    def test_broadcast_job_completion_without_socketio(self):
        """Test broadcasting job completion when SocketIO is not available."""
        with patch("core.services.websocket_service.socketio", None):
            # Should not raise an exception
            broadcast_job_completion(123, 456, {"status": "completed"})

    def test_get_socketio(self, mock_socketio):
        """Test getting SocketIO instance."""
        with patch("core.services.websocket_service.socketio", mock_socketio):
            result = get_socketio()
            assert result == mock_socketio

    def test_get_socketio_none(self):
        """Test getting SocketIO instance when not initialized."""
        with patch("core.services.websocket_service.socketio", None):
            result = get_socketio()
            assert result is None

    @patch("core.services.websocket_service.logger")
    def test_broadcast_job_update_exception_handling(self, mock_logger, mock_socketio):
        """Test exception handling in broadcast_job_update."""
        mock_socketio.emit.side_effect = Exception("Test error")

        with (
            patch("core.services.websocket_service.socketio", mock_socketio),
            patch("flask.has_request_context", return_value=False),
        ):
            broadcast_job_update(123, 456, {"status": "processing"})

            # Verify debug errors were logged for emit failures (inner try-catch blocks)
            # The emit calls are wrapped in individual try-catch blocks that log as debug
            assert mock_logger.debug.call_count >= 1
            debug_calls = [str(call) for call in mock_logger.debug.call_args_list]
            emit_error_logged = any("Error emitting" in call for call in debug_calls)
            assert emit_error_logged, f"Expected emit error to be logged in debug calls: {debug_calls}"

    @patch("core.services.websocket_service.logger")
    def test_broadcast_job_completion_exception_handling(self, mock_logger, mock_socketio):
        """Test exception handling in broadcast_job_completion."""
        mock_socketio.emit.side_effect = Exception("Test error")

        with (
            patch("core.services.websocket_service.socketio", mock_socketio),
            patch("flask.has_request_context", return_value=False),
        ):
            broadcast_job_completion(123, 456, {"status": "completed"})

            # Verify debug errors were logged for emit failures (inner try-catch blocks)
            # The emit calls are wrapped in individual try-catch blocks that log as debug
            assert mock_logger.debug.call_count >= 1
            debug_calls = [str(call) for call in mock_logger.debug.call_args_list]
            emit_error_logged = any("Error emitting" in call for call in debug_calls)
            assert emit_error_logged, f"Expected emit error to be logged in debug calls: {debug_calls}"
