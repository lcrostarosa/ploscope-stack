"""WebSocket service for real-time job status updates.

Handles WebSocket connections and broadcasts job updates to connected clients.
"""

import os
import threading
import time

# Database models removed - core package no longer includes database functionality
from core.utils.logging_utils import get_enhanced_logger
from flask import has_request_context, request
from flask_jwt_extended import decode_token
from flask_socketio import SocketIO, emit, join_room, leave_room

logger = get_enhanced_logger(__name__)

# Global SocketIO instance
socketio = None

# Store authenticated users by session ID to persist authentication across events
# This approach works with server-side sessions and scales horizontally
authenticated_users = {}

# Track job subscriptions per user to prevent duplicates
user_job_subscriptions = {}

# Rate limiting for subscriptions (prevent rapid-fire subscriptions)
subscription_rate_limits = {}


def init_socketio(app):
    """Initialize SocketIO with the Flask app."""
    global socketio

    # Get CORS origins from configuration
    cors_origins = app.config.get(
        "WEBSOCKET_CORS_ORIGINS",
        [
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://localhost:3001",
            "http://127.0.0.1:3001",
            "http://localhost",
            "http://127.0.0.1",
            "http://*.ngrok-free.app",
            "https://ploscope.com",
            "http://frontend",
        ],
    )

    # Determine async mode based on environment
    # Prefer eventlet everywhere except in explicit test environments
    if os.getenv("NODE_ENV") == "test" or os.getenv("ENVIRONMENT") == "test" or os.getenv("TESTING") == "true":
        async_mode = "threading"
        logger.info("Initializing SocketIO with threading async mode for tests")
    else:
        async_mode = "eventlet"
        logger.info("Initializing SocketIO with eventlet async mode")

    # Initialize SocketIO with appropriate configuration
    socketio = SocketIO(
        app,
        cors_allowed_origins=cors_origins,
        async_mode=async_mode,
        logger=True,
        engineio_logger=True,
        ping_timeout=60,
        ping_interval=25,
    )

    # Register event handlers
    register_socket_events(socketio)

    return socketio


def register_socket_events(socketio_instance):
    """Register WebSocket event handlers."""

    @socketio_instance.on("connect")
    def handle_connect():
        """Handle client connection."""
        try:
            session_id = getattr(request, "sid", None)
            if session_id:
                logger.info(f"Client connected: {session_id}")
                try:
                    emit("connected", {"status": "connected", "sid": session_id})
                except Exception as emit_error:
                    logger.debug(f"Error emitting connect event: {emit_error}")
            else:
                logger.info("Client connected (no session ID available)")
        except Exception as e:
            logger.debug(f"Error in connect handler: {e}")
            # Don't raise the exception to prevent Werkzeug errors

    @socketio_instance.on("disconnect")
    def handle_disconnect():
        """Handle client disconnection."""
        try:
            # Safely get the session ID, handling cases where request.sid might not be available
            session_id = getattr(request, "sid", None)
            if session_id:
                logger.info(f"Client disconnected: {session_id}")
                # Clean up any user-specific rooms and global mapping
                user_id = authenticated_users.pop(session_id, None)
                if user_id:
                    try:
                        leave_room(f"user_{user_id}")
                        # Clean up job subscriptions for this user
                        if user_id in user_job_subscriptions:
                            del user_job_subscriptions[user_id]
                        # Clean up rate limiting data for this user
                        keys_to_remove = [
                            key for key in subscription_rate_limits.keys() if key.startswith(f"{user_id}_")
                        ]
                        for key in keys_to_remove:
                            del subscription_rate_limits[key]
                    except Exception as e:
                        logger.debug(f"Error leaving room for user {user_id}: {e}")
            else:
                logger.info("Client disconnected (no session ID available)")
        except Exception as e:
            logger.debug(f"Error in disconnect handler: {e}")
            # Don't raise the exception to prevent Werkzeug errors

    @socketio_instance.on("authenticate")
    def handle_authentication(data):
        """Authenticate WebSocket connection with JWT token."""
        try:
            token = data.get("token")
            if not token:
                try:
                    emit("auth_error", {"error": "No token provided"})
                except Exception as emit_error:
                    logger.debug(f"Error emitting auth_error event: {emit_error}")
                return

            # Decode and validate JWT token
            decoded_token = decode_token(token)
            # The identity is stored in the 'sub' field for flask-jwt-extended
            user_id = decoded_token.get("sub")

            # In a database-free core package, user validation would be handled
            # by the application layer. For now, we just verify the JWT is valid.
            logger.debug(f"WebSocket authentication successful for user: {user_id}")

            # Store user info in request context and global mapping
            request.user_id = user_id
            request.user = None  # No user object without database
            authenticated_users[request.sid] = user_id

            # Join user-specific room for job updates
            join_room(f"user_{user_id}")

            logger.info(f"User {user_id} authenticated via WebSocket (SID: {request.sid})")
            try:
                emit(
                    "authenticated",
                    {
                        "status": "authenticated",
                        "user_id": user_id,
                        "message": "Successfully authenticated",
                    },
                )
            except Exception as emit_error:
                logger.debug(f"Error emitting authenticated event: {emit_error}")

        except Exception as e:
            logger.error(f"WebSocket authentication error: {str(e)}")
            logger.error(f"Token data: {data}")
            try:
                emit("auth_error", {"error": "Authentication failed"})
            except Exception as emit_error:
                logger.debug(f"Error emitting auth_error event: {emit_error}")

    @socketio_instance.on("subscribe_job")
    def handle_job_subscription(data):
        """Subscribe to updates for a specific job."""
        try:
            # Check authentication from global mapping
            user_id = authenticated_users.get(request.sid)
            if not user_id:
                try:
                    emit("subscription_error", {"error": "Not authenticated"})
                except Exception as emit_error:
                    logger.debug(f"Error emitting subscription_error event: {emit_error}")
                return

            job_id = data.get("job_id")
            if not job_id:
                try:
                    emit("subscription_error", {"error": "No job ID provided"})
                except Exception as emit_error:
                    logger.debug(f"Error emitting subscription_error event: {emit_error}")
                return

            # Rate limiting: prevent rapid-fire subscriptions
            current_time = time.time()
            user_rate_key = f"{user_id}_{job_id}"
            last_subscription_time = subscription_rate_limits.get(user_rate_key, 0)

            if current_time - last_subscription_time < 1.0:  # 1 second cooldown
                logger.warning(f"Rate limit exceeded for user {user_id} subscribing to job {job_id}")
                try:
                    emit(
                        "subscription_error",
                        {"error": "Rate limit exceeded, please wait before resubscribing"},
                    )
                except Exception as emit_error:
                    logger.debug(f"Error emitting subscription_error event: {emit_error}")
                return

            subscription_rate_limits[user_rate_key] = current_time

            # Check if user is already subscribed to this job
            user_subs = user_job_subscriptions.get(user_id, set())
            if job_id in user_subs:
                logger.debug(f"User {user_id} already subscribed to job {job_id}, skipping duplicate subscription")
                try:
                    emit(
                        "job_subscribed",
                        {
                            "job_id": job_id,
                            "status": "already_subscribed",
                            "message": "Already subscribed to this job",
                        },
                    )
                except Exception as emit_error:
                    logger.debug(f"Error emitting job_subscribed event: {emit_error}")
                return

            # In a database-free core package, job validation would be handled
            # by the application layer. For now, we just log the subscription.
            logger.debug(f"Job subscription request for job {job_id} by user {user_id}")

            # Join job-specific room
            room_name = f"job_{job_id}"
            join_room(room_name)

            # Track the subscription
            if user_id not in user_job_subscriptions:
                user_job_subscriptions[user_id] = set()
            user_job_subscriptions[user_id].add(job_id)

            logger.info(f"User {user_id} subscribed to job {job_id}")
            try:
                emit(
                    "job_subscribed",
                    {
                        "job_id": job_id,
                        "status": "subscribed",
                        "current_status": None,  # Job status would be fetched from database in full implementation
                        "progress": 0,  # Progress would be fetched from database in full implementation
                    },
                )
            except Exception as emit_error:
                logger.debug(f"Error emitting job_subscribed event: {emit_error}")

        except Exception as e:
            logger.error(f"Job subscription error: {str(e)}")
            try:
                emit("subscription_error", {"error": "Subscription failed"})
            except Exception as emit_error:
                logger.debug(f"Error emitting subscription_error event: {emit_error}")

    @socketio_instance.on("unsubscribe_job")
    def handle_job_unsubscription(data):
        """Unsubscribe from updates for a specific job."""
        try:
            user_id = authenticated_users.get(request.sid)
            if not user_id:
                return

            job_id = data.get("job_id")
            if job_id:
                room_name = f"job_{job_id}"
                leave_room(room_name)

                # Remove from tracking
                user_subs = user_job_subscriptions.get(user_id, set())
                user_subs.discard(job_id)
                if not user_subs and user_id in user_job_subscriptions:
                    del user_job_subscriptions[user_id]

                logger.info(f"User {user_id} unsubscribed from job {job_id}")
                try:
                    emit("job_unsubscribed", {"job_id": job_id})
                except Exception as emit_error:
                    logger.debug(f"Error emitting job_unsubscribed event: {emit_error}")
        except Exception as e:
            logger.error(f"Job unsubscription error: {str(e)}")


def broadcast_job_update(job_id, user_id, update_data):
    """Broadcast job update to all clients subscribed to this job."""
    try:
        # Check if we're in an HTTP request context - if so, defer the emission
        if has_request_context():
            logger.debug(f"Deferring job update broadcast for job {job_id} - in HTTP request context")
            # Schedule the emission for after the request completes

            def deferred_emit():
                try:
                    if socketio:
                        room_name = f"job_{job_id}"
                        user_room = f"user_{user_id}"

                        # Send to job-specific room
                        try:
                            socketio.emit("job_update", update_data, room=room_name)
                        except Exception as emit_error:
                            logger.debug(f"Error emitting job_update to room {room_name}: {emit_error}")

                        # Also send to user's general room for job list updates
                        try:
                            socketio.emit(
                                "job_list_update",
                                {"job_id": job_id, "update": update_data},
                                room=user_room,
                            )
                        except Exception as emit_error:
                            logger.debug(f"Error emitting job_list_update to room {user_room}: {emit_error}")

                        logger.debug(f"Broadcasted job update for job {job_id} to user {user_id}")
                except Exception as e:
                    logger.error(f"Error in deferred job update broadcast: {str(e)}")

            # Use a timer to defer the emission
            timer = threading.Timer(0.1, deferred_emit)
            timer.daemon = True
            timer.start()
            return

        # Normal WebSocket emission outside of HTTP request context
        if socketio:
            room_name = f"job_{job_id}"
            user_room = f"user_{user_id}"

            # Send to job-specific room
            try:
                socketio.emit("job_update", update_data, room=room_name)
            except Exception as emit_error:
                logger.debug(f"Error emitting job_update to room {room_name}: {emit_error}")

            # Also send to user's general room for job list updates
            try:
                socketio.emit(
                    "job_list_update",
                    {"job_id": job_id, "update": update_data},
                    room=user_room,
                )
            except Exception as emit_error:
                logger.debug(f"Error emitting job_list_update to room {user_room}: {emit_error}")

            logger.debug(f"Broadcasted job update for job {job_id} to user {user_id}")
        else:
            logger.warning("SocketIO not initialized, cannot broadcast job update")

    except Exception as e:
        logger.error(f"Error broadcasting job update: {str(e)}")


def broadcast_job_completion(job_id, user_id, completion_data):
    """Broadcast job completion to user."""
    try:
        # Check if we're in an HTTP request context - if so, defer the emission
        if has_request_context():
            logger.debug(f"Deferring job completion broadcast for job {job_id} - in HTTP request context")
            # Schedule the emission for after the request completes

            def deferred_emit():
                try:
                    if socketio:
                        user_room = f"user_{user_id}"

                        try:
                            socketio.emit(
                                "job_completed",
                                {"job_id": job_id, "completion_data": completion_data},
                                room=user_room,
                            )
                        except Exception as emit_error:
                            logger.debug(f"Error emitting job_completed to room {user_room}: {emit_error}")

                        logger.info(f"Broadcasted job completion for job {job_id} to user {user_id}")
                except Exception as e:
                    logger.error(f"Error in deferred job completion broadcast: {str(e)}")

            # Use a timer to defer the emission
            timer = threading.Timer(0.1, deferred_emit)
            timer.daemon = True
            timer.start()
            return

        # Normal WebSocket emission outside of HTTP request context
        if socketio:
            user_room = f"user_{user_id}"

            try:
                socketio.emit(
                    "job_completed",
                    {"job_id": job_id, "completion_data": completion_data},
                    room=user_room,
                )
            except Exception as emit_error:
                logger.debug(f"Error emitting job_completed to room {user_room}: {emit_error}")

            logger.info(f"Broadcasted job completion for job {job_id} to user {user_id}")
        else:
            logger.warning("SocketIO not initialized, cannot broadcast job completion")

    except Exception as e:
        logger.error(f"Error broadcasting job completion: {str(e)}")


def get_socketio():
    """Get the global SocketIO instance."""
    return socketio


init_websocket_service = init_socketio
