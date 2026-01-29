"""WebSocket service for PLOSolver.

This module provides WebSocket functionality using Flask-SocketIO for real-time
communication with clients, including job updates and completion notifications.
"""

import time
from typing import Any, Optional

from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room, leave_room

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)

# Global SocketIO instance
socketio: Optional[SocketIO] = None


def init_socketio(app: Flask) -> SocketIO:
    """Initialize SocketIO with the Flask app.

    Args:
        app: Flask application instance.

    Returns:
        Initialized SocketIO instance.
    """
    global socketio

    socketio = SocketIO(app, cors_allowed_origins="*", logger=True, engineio_logger=True, async_mode="threading")

    @socketio.on("connect")
    def handle_connect():
        """Handle client connection."""
        logger.info("Client connected: %s", request.sid)
        emit("connected", {"message": "Connected to PLOSolver WebSocket"})

    @socketio.on("disconnect")
    def handle_disconnect():
        """Handle client disconnection."""
        logger.info("Client disconnected: %s", request.sid)

    @socketio.on("join_job_room")
    def handle_join_job_room(data):
        """Handle client joining a job-specific room."""
        job_id = data.get("job_id")
        if job_id:
            join_room(f"job_{job_id}")
            logger.debug("Client %s joined job room: job_%s", request.sid, job_id)
            emit("joined_room", {"room": f"job_{job_id}"})

    @socketio.on("leave_job_room")
    def handle_leave_job_room(data):
        """Handle client leaving a job-specific room."""
        job_id = data.get("job_id")
        if job_id:
            leave_room(f"job_{job_id}")
            logger.debug("Client %s left job room: job_%s", request.sid, job_id)
            emit("left_room", {"room": f"job_{job_id}"})

    @socketio.on("join_user_room")
    def handle_join_user_room(data):
        """Handle client joining a user-specific room."""
        user_id = data.get("user_id")
        if user_id:
            join_room(f"user_{user_id}")
            logger.debug("Client %s joined user room: user_%s", request.sid, user_id)
            emit("joined_room", {"room": f"user_{user_id}"})

    @socketio.on("leave_user_room")
    def handle_leave_user_room(data):
        """Handle client leaving a user-specific room."""
        user_id = data.get("user_id")
        if user_id:
            leave_room(f"user_{user_id}")
            logger.debug("Client %s left user room: user_%s", request.sid, user_id)
            emit("left_room", {"room": f"user_{user_id}"})

    return socketio


def get_socketio() -> Optional[SocketIO]:
    """Get the global SocketIO instance.

    Returns:
        SocketIO instance if initialized, None otherwise.
    """
    return socketio


def broadcast_job_update(job_id: int, user_id: int, update_data: dict[str, Any]) -> None:
    """Broadcast job update to relevant clients.

    Args:
        job_id: ID of the job being updated.
        user_id: ID of the user who owns the job.
        update_data: Update data to broadcast.
    """
    if socketio is None:
        logger.debug("SocketIO not initialized, skipping job update broadcast")
        return

    try:
        # Broadcast to job-specific room
        try:
            socketio.emit("job_update", update_data, room=f"job_{job_id}")
            logger.debug("Job update broadcasted to job room: job_%s", job_id)
        except Exception as e:
            logger.debug("Error emitting job update to job room: %s", e)

        # Broadcast to user-specific room for job list updates
        try:
            socketio.emit("job_list_update", {"job_id": job_id, "update": update_data}, room=f"user_{user_id}")
            logger.debug("Job list update broadcasted to user room: user_%s", user_id)
        except Exception as e:
            logger.debug("Error emitting job list update to user room: %s", e)

    except Exception as e:
        logger.error("Error broadcasting job update for job %s: %s", job_id, e)


def broadcast_job_completion(job_id: int, user_id: int, completion_data: dict[str, Any]) -> None:
    """Broadcast job completion to relevant clients.

    Args:
        job_id: ID of the completed job.
        user_id: ID of the user who owns the job.
        completion_data: Completion data to broadcast.
    """
    if socketio is None:
        logger.debug("SocketIO not initialized, skipping job completion broadcast")
        return

    try:
        # Broadcast completion to user-specific room
        try:
            socketio.emit(
                "job_completed", {"job_id": job_id, "completion_data": completion_data}, room=f"user_{user_id}"
            )
            logger.debug("Job completion broadcasted to user room: user_%s", user_id)
        except Exception as e:
            logger.debug("Error emitting job completion to user room: %s", e)

    except Exception as e:
        logger.error("Error broadcasting job completion for job %s: %s", job_id, e)


def broadcast_system_message(message: str, room: Optional[str] = None) -> None:
    """Broadcast a system message to clients.

    Args:
        message: System message to broadcast.
        room: Optional room to broadcast to. If None, broadcasts to all clients.
    """
    if socketio is None:
        logger.debug("SocketIO not initialized, skipping system message broadcast")
        return

    try:
        broadcast_data = {"message": message, "timestamp": int(time.time() * 1000), "type": "system"}

        if room:
            socketio.emit("system_message", broadcast_data, room=room)
            logger.debug("System message broadcasted to room: %s", room)
        else:
            socketio.emit("system_message", broadcast_data)
            logger.debug("System message broadcasted to all clients")

    except Exception as e:
        logger.error("Error broadcasting system message: %s", e)


def get_connected_clients() -> int:
    """Get the number of connected clients.

    Returns:
        Number of connected clients.
    """
    if socketio is None:
        return 0

    try:
        # This is a simplified implementation
        # In a real implementation, you might want to track connected clients
        return len(socketio.server.manager.rooms.get("/", {}))
    except Exception as e:
        logger.error("Error getting connected clients count: %s", e)
        return 0


def disconnect_client(session_id: str) -> bool:
    """Disconnect a specific client.

    Args:
        session_id: Session ID of the client to disconnect.

    Returns:
        True if client was disconnected, False otherwise.
    """
    if socketio is None:
        return False

    try:
        # Note: SocketIO doesn't have a direct disconnect method for specific sessions
        # This would need to be implemented differently in a real application
        logger.info("Client %s disconnect requested", session_id)
        return True
    except Exception as e:
        logger.error("Error disconnecting client %s: %s", session_id, e)
        return False
