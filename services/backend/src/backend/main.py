"""
Main entry point for PLOSolver Backend.

This module provides a unified entry point that runs both the Flask REST API
and the gRPC server in parallel. It combines all functionality into a single
executable file.
"""

import os

from src.backend.services.websocket_service import init_socketio as init_websocket_service


# Load Docker secrets before any other imports (especially before eventlet patch)
def _load_secret(env_key: str, secret_name: str) -> None:
    if os.getenv(env_key):
        return
    secret_path = f"/run/secrets/{secret_name}"
    try:
        with open(secret_path, "r", encoding="utf-8") as fh:
            value = fh.read().strip()
            if value:
                os.environ[env_key] = value
    except FileNotFoundError:
        pass


_secrets_map = {
    "DATABASE_URL": "database_url",
    "SECRET_KEY": "secret_key",
    "JWT_SECRET_KEY": "jwt_secret_key",
    "RABBITMQ_HOST": "rabbitmq_host",
    "RABBITMQ_PORT": "rabbitmq_port",
    "RABBITMQ_USERNAME": "rabbitmq_username",
    "RABBITMQ_PASSWORD": "rabbitmq_password",
    "RABBITMQ_VHOST": "rabbitmq_vhost",
    "GOOGLE_CLIENT_ID": "google_client_id",
    "GOOGLE_CLIENT_SECRET": "google_client_secret",
    "WEBSOCKET_CORS_ORIGINS": "websocket_cors_origins",
    "STRIPE_SECRET_KEY": "stripe_secret_key",
    "STRIPE_PUBLISHABLE_KEY": "stripe_publishable_key",
    "STRIPE_WEBHOOK_SECRET": "stripe_webhook_secret",
}

for k, v in _secrets_map.items():
    _load_secret(k, v)


# Decide on eventlet patching as early as possible
_flask_env = os.getenv("FLASK_ENV", "development").lower()
_environment = os.getenv("ENVIRONMENT", "development").lower()
_node_env = os.getenv("NODE_ENV", "development").lower()
_testing = os.getenv("TESTING", "false").lower() == "true"
_should_patch_eventlet = (
    (_flask_env in ["production", "staging"] or _environment in ["production", "staging"])
    and _node_env != "test"
    and not _testing
)

if _should_patch_eventlet:
    import eventlet

    # Patch before importing threading, time, grpc, flask, etc.
    eventlet.monkey_patch()

import sys
import threading
import time
from concurrent import futures
from pathlib import Path

import grpc
from core.utils.logging_utils import get_enhanced_logger
from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from grpc_reflection.v1alpha import reflection
from sqlalchemy import create_engine, text

from config import config

# Import core compatibility before any core imports
from src.backend.database import bcrypt, db
from src.backend.protos import (
    auth_pb2,
    auth_pb2_grpc,
    core_pb2,
    core_pb2_grpc,
    job_pb2,
    job_pb2_grpc,
    solver_pb2,
    solver_pb2_grpc,
)
from src.backend.routes_grpc import AuthServiceServicer, CoreServiceServicer, JobServiceServicer, SolverServiceServicer
from src.backend.routes_http.auth_routes import auth_routes
from src.backend.routes_http.core_routes import core_routes
from src.backend.routes_http.discourse_routes import discourse_routes
from src.backend.routes_http.docs_routes import docs_bp
from src.backend.routes_http.hand_history_routes import hand_history_bp
from src.backend.routes_http.job_routes import job_routes
from src.backend.routes_http.metrics_routes import metrics_bp
from src.backend.routes_http.solver_routes import solver_routes
from src.backend.routes_http.spot_routes import spot_routes
from src.backend.routes_http.subscription_routes import subscription_bp
from src.backend.routes_http.telemetry_routes import telemetry_routes
from src.backend.services.rabbitmq_service import check_rabbitmq_connectivity
from src.backend.utils.rate_limiter import init_rate_limiter

backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

parent_path = backend_path.parent
sys.path.insert(0, str(parent_path))

logger = get_enhanced_logger(__name__)

# Track gRPC startup to avoid duplicate starts
_grpc_started = False
_grpc_thread = None


def create_flask_app():
    """Create a Flask application with all routes_http registered."""
    app = Flask(__name__)

    # Get configuration based on environment
    config_name = os.getenv("FLASK_ENV", "development")
    app.config.from_object(config[config_name])

    # Initialize the configuration
    config[config_name].init_app(app)
    print("🔍 Configuration initialization complete")

    # Configure CORS to handle preflight requests properly
    # This prevents authentication errors on OPTIONS requests
    cors_origins = app.config.get("CORS_ORIGINS", [])
    if not cors_origins:
        # Fallback to default origins if not configured
        cors_origins = [
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://localhost:3001",
            "http://127.0.0.1:3001",
            "http://localhost",
            "http://127.0.0.1",
            "https://ploscope.com",
            "http://frontend",
        ]

    CORS(
        app,
        origins=cors_origins,
        allow_headers=["Content-Type", "Authorization", "X-Requested-With"],
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
        supports_credentials=True,
        automatic_options=True,
    )

    print("🔧 CORS configuration initialized")

    # Set global timeout configuration
    app.config["PERMANENT_SESSION_LIFETIME"] = 300  # 5 minutes
    app.config["SEND_FILE_MAX_AGE_DEFAULT"] = 300  # 5 minutes

    # Initialize database and encryption extensions
    db.init_app(app)
    bcrypt.init_app(app)

    JWTManager(app)

    # Register blueprints with URL prefixes
    app.register_blueprint(core_routes, url_prefix="/api")
    app.register_blueprint(auth_routes, url_prefix="/api/auth")
    app.register_blueprint(job_routes, url_prefix="/api/jobs")
    app.register_blueprint(solver_routes, url_prefix="/api/solver")
    app.register_blueprint(hand_history_bp, url_prefix="/api/hand-history")
    app.register_blueprint(spot_routes, url_prefix="/api/spots")
    app.register_blueprint(subscription_bp, url_prefix="/api/subscription")
    app.register_blueprint(telemetry_routes, url_prefix="/api/telemetry")
    app.register_blueprint(docs_bp, url_prefix="/api/docs")
    app.register_blueprint(discourse_routes, url_prefix="/api/discourse")

    # Register metrics routes_http (no prefix for direct access)
    app.register_blueprint(metrics_bp)

    # Initialize WebSocket (Socket.IO) service
    try:
        init_websocket_service(app)
        print("✅ WebSocket service initialized")
    except Exception as ws_error:  # noqa: BLE001 - broad except acceptable at process boundary
        print(f"⚠️ WebSocket service initialization failed: {ws_error}")

    # Initialize rate limiter
    try:
        init_rate_limiter(app)
        print("✅ Rate limiter initialized")
    except Exception as rl_error:  # noqa: BLE001 - broad except acceptable at process boundary
        print(f"⚠️ Rate limiter initialization failed: {rl_error}")

    return app


def create_grpc_server() -> grpc.Server:
    """Create and configure the gRPC server."""

    # Get configuration for max workers
    config_name = os.getenv("FLASK_ENV", "development")
    current_config = config[config_name]
    max_workers = getattr(current_config, "MAX_CONCURRENT_JOBS", 10)

    # Create server
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=max_workers))

    print("🔧 Registering gRPC routes_grpc...")

    # Add routes_grpc (fail fast if registration fails)
    auth_pb2_grpc.add_AuthServiceServicer_to_server(AuthServiceServicer(), server)
    print("✅ AuthService registered")

    solver_pb2_grpc.add_SolverServiceServicer_to_server(SolverServiceServicer(), server)
    print("✅ SolverService registered")

    job_pb2_grpc.add_JobServiceServicer_to_server(JobServiceServicer(), server)
    print("✅ JobService registered")

    core_pb2_grpc.add_CoreServiceServicer_to_server(CoreServiceServicer(), server)
    print("✅ CoreService registered")

    # Add reflection service
    SERVICE_NAMES = (
        auth_pb2.DESCRIPTOR.services_by_name["AuthService"].full_name,
        solver_pb2.DESCRIPTOR.services_by_name["SolverService"].full_name,
        job_pb2.DESCRIPTOR.services_by_name["JobService"].full_name,
        core_pb2.DESCRIPTOR.services_by_name["CoreService"].full_name,
        reflection.SERVICE_NAME,
    )
    print(f"📋 Service names for reflection: {SERVICE_NAMES}")
    reflection.enable_server_reflection(SERVICE_NAMES, server)
    print("✅ Reflection service enabled")

    return server


def run_flask_server(app, host: str = "0.0.0.0", port: int = 5001):
    """Run the Flask server in a separate thread."""
    print(f"🚀 Starting Flask REST API server on {host}:{port}")
    app.run(host=host, port=port, debug=app.config.get("DEBUG", False), use_reloader=False)


def check_database_connectivity():
    """Check if database is accessible before starting the app."""
    print("🔍 Testing database connectivity...")
    try:
        db_url = os.getenv("DATABASE_URL")
        if not db_url:
            raise ValueError("DATABASE_URL environment variable not set")

        print(f"📡 Connecting to database: {db_url.split('@')[1] if '@' in db_url else 'unknown'}")
        engine = create_engine(db_url)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1")).fetchone()
        print("✅ Database connectivity verified")
        return True
    except Exception as e:
        print(f"❌ Database connectivity check failed: {e}")
        print("💥 Application cannot start without database connection")
        return False


def run_grpc_server(server, host: str = "0.0.0.0", port: int = 50051):
    """Run the gRPC server in a separate thread."""
    server.add_insecure_port(f"{host}:{port}")
    print(f"🚀 Starting gRPC server on {host}:{port}")
    server.start()
    server.wait_for_termination()


def main():
    """Main entry point that runs both Flask and gRPC servers."""
    print("🎯 PLOSolver Backend - Starting unified server...")

    # Check critical service connectivity first
    print("🔍 Verifying critical service connectivity...")

    if not check_database_connectivity():
        print("💥 Exiting due to database connectivity failure")
        sys.exit(1)

    if not check_rabbitmq_connectivity():
        print("💥 Exiting due to RabbitMQ connectivity failure")
        sys.exit(1)

    print("✅ All critical routes_grpc are accessible")

    # Create Flask app
    print("🔧 Creating Flask application...")
    flask_app = create_flask_app()

    # Create gRPC server
    print("🔧 Creating gRPC server...")
    grpc_server = create_grpc_server()

    # Get configuration
    config_name = os.getenv("FLASK_ENV", "development")
    current_config = config[config_name]

    # Get ports from configuration or environment
    flask_port = int(os.getenv("FLASK_PORT", "5001"))
    grpc_port = int(os.getenv("GRPC_PORT", "50051"))
    host = os.getenv("HOST", "0.0.0.0")

    # Log configuration info
    print(f"🔧 Using configuration: {config_name}")
    print(f"🔧 Debug mode: {current_config.DEBUG}")
    print(f"🔧 Log level: {current_config.LOG_LEVEL}")

    # Start Flask server in a separate thread
    flask_thread = threading.Thread(target=run_flask_server, args=(flask_app, host, flask_port), daemon=True)
    flask_thread.start()

    # Start gRPC server in a separate thread
    grpc_thread = threading.Thread(target=run_grpc_server, args=(grpc_server, host, grpc_port), daemon=True)
    grpc_thread.start()

    print("✅ Both servers started successfully!")
    print(f"📡 REST API: http://{host}:{flask_port}")
    print(f"📡 gRPC API: {host}:{grpc_port}")
    print("🔄 Press Ctrl+C to stop both servers")

    try:
        # Keep the main thread alive
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Shutting down servers...")
        grpc_server.stop(0)
        print("✅ Servers stopped successfully")


if __name__ == "__main__":
    main()
