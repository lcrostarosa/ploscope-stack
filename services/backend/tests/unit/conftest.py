"""
Unit test configuration and fixtures.
"""

from unittest.mock import Mock, patch

import pytest
from flask import Flask, request
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager

from src.backend.models.enums import JobStatus, JobType

# Try to import core module, skip if not available
try:
    import core
    import core.services as services
    from core.services import solver_engine

    from src.backend.routes_http import core_routes

    services.solver_engine = solver_engine

    # Note: Do not modify sys.path to point at local plosolver_core source.
    # Tests must import the installed `plosolver_core` package as an external dependency.
    CORE_AVAILABLE = True
except ImportError:
    # Core module not available, create mock objects
    core = Mock()
    services = Mock()
    core_routes = Mock()
    CORE_AVAILABLE = False


# Create Flask extensions for testing
bcrypt = Bcrypt()


# Flask app configuration for testing
@pytest.fixture
def app():
    """Configure the Flask app for testing."""
    print("Creating Flask app fixture...")

    # Create a simple Flask app for testing
    app = Flask(__name__)
    app.config.update(
        {
            "TESTING": True,
            "SECRET_KEY": "test-secret-key",
            "JWT_SECRET_KEY": "test-jwt-secret-key",
            "JWT_ACCESS_TOKEN_EXPIRES": False,
        }
    )

    JWTManager(app)

    # Mock the profile manager
    app.profile_manager = Mock()
    app.profile_manager.get_all_profiles.return_value = {
        "fish": Mock(to_dict=lambda: {"name": "fish"}),
        "loose_aggressive": Mock(to_dict=lambda: {"name": "loose_aggressive"}),
        "loose_passive": Mock(to_dict=lambda: {"name": "loose_passive"}),
        "maniac": Mock(to_dict=lambda: {"name": "maniac"}),
        "nit": Mock(to_dict=lambda: {"name": "nit"}),
        "tight_aggressive": Mock(to_dict=lambda: {"name": "tight_aggressive"}),
        "tight_passive": Mock(to_dict=lambda: {"name": "tight_passive"}),
    }
    app.profile_manager.add_custom_profile.return_value = True
    app.profile_manager.save_custom_profiles.return_value = None
    app.profile_manager.delete_custom_profile.return_value = True

    # Store the original get_all_profiles method for tests to override
    app._original_get_all_profiles = app.profile_manager.get_all_profiles

    # Add a simple health check route
    @app.route("/api/health")
    def health_check():
        return {"status": "healthy"}, 200

    # Add player profiles routes_http
    @app.route("/api/player-profiles", methods=["GET"])
    def get_player_profiles():
        try:
            profiles = app.profile_manager.get_all_profiles()
            return {k: v.to_dict() for k, v in profiles.items()}, 200
        except Exception:
            return {"error": "Failed to get player profiles"}, 500

    @app.route("/api/player-profiles", methods=["POST"])
    def create_custom_profile():
        data = request.get_json()
        if not data or "name" not in data:
            return {"error": "Missing required field: name"}, 400

        # Check for duplicate name
        profiles = app.profile_manager.get_all_profiles()
        if data["name"] in profiles:
            return {"error": "Profile name already exists"}, 400

        # Create profile
        profile = Mock()
        profile.to_dict = lambda: data
        app.profile_manager.add_custom_profile(profile)
        return {"message": "Profile created successfully", "profile": data}, 201

    @app.route("/api/player-profiles/<profile_name>", methods=["DELETE"])
    def delete_custom_profile(profile_name):
        profiles = app.profile_manager.get_all_profiles()
        if profile_name not in profiles:
            return {"error": "Profile not found"}, 404

        # Don't allow deletion of predefined profiles
        predefined = ["fish", "loose_aggressive", "loose_passive", "maniac", "nit", "tight_aggressive", "tight_passive"]
        if profile_name in predefined:
            return {"error": "Cannot delete predefined profile"}, 400

        app.profile_manager.delete_custom_profile(profile_name)
        return {"message": "Profile deleted successfully"}, 200

    # Add credits route
    @app.route("/api/credits", methods=["GET", "OPTIONS"])
    def get_user_credits():
        return {"credits": 100, "total_credits": 1000, "tier": "free"}, 200

    # Add simulate vs profiles route
    @app.route("/api/simulate-vs-profiles", methods=["POST"])
    def simulate_vs_profiles():
        data = request.get_json()
        if not data or "hero_cards" not in data:
            return {"error": "Missing hero_cards"}, 400

        # Mock simulation result
        return {"equity": {"hero": 0.65, "villain": 0.35}, "iterations": 1000, "solve_time": 1.23}, 200

    print(f"Created Flask app: {app.name}")
    return app


@pytest.fixture
def client(app):
    """Create a test client for the Flask app."""
    return app.test_client()


@pytest.fixture(autouse=True, scope="function")
def block_real_db_access(monkeypatch):
    """Block all real database access and mock SQLAlchemy components."""

    # Mock the entire SQLAlchemy db object at the import level
    mock_db = Mock()
    mock_session = Mock()

    # Create a mock query that returns mock data
    mock_query = Mock()
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.filter_by = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=None)
    mock_query.all = Mock(return_value=[])
    mock_query.count = Mock(return_value=0)
    mock_query.limit = Mock(return_value=mock_query)
    mock_query.offset = Mock(return_value=mock_query)
    mock_query.order_by = Mock(return_value=mock_query)
    mock_query.delete = Mock()

    # Mock session operations
    mock_session.add = Mock()
    mock_session.commit = Mock()
    mock_session.rollback = Mock()
    mock_session.close = Mock()
    mock_session.query = Mock(return_value=mock_query)
    mock_session.delete = Mock()
    mock_session.flush = Mock()
    mock_session.execute = Mock()
    mock_session.scalar = Mock()

    # Mock the db object completely
    mock_db.session = mock_session
    mock_db.create_all = Mock()
    mock_db.drop_all = Mock()
    mock_db.engine = Mock()

    # Mock at the core.models level. Some code imports `from core.models.base import db`
    # so we patch both `core.models` and `core.models.base` consistently.
    if CORE_AVAILABLE:
        try:
            monkeypatch.setattr(core.models, "db", mock_db, raising=False)
        except Exception:
            pass
        try:
            from core.models import base as _base

            monkeypatch.setattr(_base, "db", mock_db, raising=False)
        except Exception:
            pass

        # Patch where db is referenced inside backend routes_http for safety
        try:
            monkeypatch.setattr(core_routes, "db", mock_db, raising=False)
            mock_credit_instance = Mock()
            mock_credit_instance.get_remaining_credits = Mock(
                return_value={"credits": 100, "total_credits": 1000, "tier": "free"}
            )
        except Exception:
            pass


@pytest.fixture(autouse=True, scope="function")
def mock_request_context():
    """Provide a mock request context for tests that need it."""
    app = Flask(__name__)
    with app.test_request_context():
        yield


# ============================================================================
# UNIT TEST FIXTURES (Mocked Database)
# ============================================================================


# ============================================================================
# MOCKED MODEL FACTORIES
# ============================================================================


class MockUserFactory:
    """Factory for creating mock User objects."""

    @staticmethod
    def create(**kwargs):
        """Create a mock User object."""
        user = Mock()
        user.id = kwargs.get("id", 1)
        user.email = kwargs.get("email", "test@example.com")
        user.username = kwargs.get("username", "testuser")
        user.first_name = kwargs.get("first_name", "Test")
        user.last_name = kwargs.get("last_name", "User")
        user.password = kwargs.get("password", "hashed_password")
        user.is_admin = kwargs.get("is_admin", False)
        user.subscription_tier = kwargs.get("subscription_tier", "free")
        user.credits = kwargs.get("credits", 100)
        user.created_at = kwargs.get("created_at", "2023-01-01T00:00:00Z")
        user.updated_at = kwargs.get("updated_at", "2023-01-01T00:00:00Z")

        # Mock methods
        user.check_password = Mock(return_value=True)
        user.to_dict = Mock(
            return_value={
                "id": user.id,
                "email": user.email,
                "username": user.username,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "is_admin": user.is_admin,
                "subscription_tier": user.subscription_tier,
                "credits": user.credits,
            }
        )

        return user


class MockSpotFactory:
    """Factory for creating mock Spot objects."""

    @staticmethod
    def create(**kwargs):
        """Create a mock Spot object."""
        spot = Mock()
        spot.id = kwargs.get("id", 1)
        spot.name = kwargs.get("name", "Test Spot")
        spot.description = kwargs.get("description", "Test description")
        spot.top_board = kwargs.get("top_board", ["Ah", "Ks", "Qd"])
        spot.bottom_board = kwargs.get("bottom_board", ["2c", "3h", "4s"])
        spot.players = kwargs.get("players", [[], []])
        spot.user_id = kwargs.get("user_id", 1)
        spot.user = kwargs.get("user", MockUserFactory.create())
        spot.created_at = kwargs.get("created_at", "2023-01-01T00:00:00Z")
        spot.updated_at = kwargs.get("updated_at", "2023-01-01T00:00:00Z")

        # Mock methods
        spot.to_dict = Mock(
            return_value={
                "id": spot.id,
                "name": spot.name,
                "description": spot.description,
                "top_board": spot.top_board,
                "bottom_board": spot.bottom_board,
                "players": spot.players,
                "user_id": spot.user_id,
                "created_at": spot.created_at,
                "updated_at": spot.updated_at,
            }
        )

        return spot


class MockJobFactory:
    """Factory for creating mock Job objects."""

    @staticmethod
    def create(**kwargs):
        """Create a mock Job object."""
        job = Mock()
        job.id = kwargs.get("id", 1)
        job.job_type = kwargs.get("job_type", JobType.SPOT_SIMULATION)
        job.status = kwargs.get("status", JobStatus.QUEUED)
        job.input_data = kwargs.get("input_data", {})
        job.result_data = kwargs.get("result_data", {})
        job.user_id = kwargs.get("user_id", 1)
        job.user = kwargs.get("user", MockUserFactory.create())
        job.created_at = kwargs.get("created_at", "2023-01-01T00:00:00Z")
        job.updated_at = kwargs.get("updated_at", "2023-01-01T00:00:00Z")
        job.completed_at = kwargs.get("completed_at", None)

        # Mock methods
        job.to_dict = Mock(
            return_value={
                "id": job.id,
                "job_type": job.job_type.value,
                "status": job.status.value,
                "input_data": job.input_data,
                "result_data": job.result_data,
                "user_id": job.user_id,
                "created_at": job.created_at,
                "updated_at": job.updated_at,
                "completed_at": job.completed_at,
            }
        )

        return job


# ============================================================================
# FIXTURES FOR MOCKED OBJECTS
# ============================================================================


@pytest.fixture
def mock_user():
    """Create a mock user for testing."""
    return MockUserFactory.create()


@pytest.fixture
def mock_spot(mock_user):
    """Create a mock spot for testing."""
    return MockSpotFactory.create(user_id=mock_user.id, user=mock_user)


@pytest.fixture
def mock_job(mock_user):
    """Create a mock job for testing."""
    return MockJobFactory.create(user_id=mock_user.id, user=mock_user)


@pytest.fixture
def mock_auth_headers(mock_user):
    """Create mock authentication headers."""
    # Mock the token creation using the installed package namespace
    with patch("plosolver_core.utils.auth_utils.create_user_tokens") as mock_create_tokens:
        mock_create_tokens.return_value = ("mock_access_token", "mock_refresh_token")
        return {"Authorization": "Bearer mock_access_token"}


@pytest.fixture
def mock_simulation_results():
    """Mock simulation results for testing."""
    return {
        "equity": {"player1": 0.65, "player2": 0.35},
        "actions": ["fold", "call", "raise"],
        "iterations": 1000,
        "solve_time": 5.23,
        "status": "completed",
    }


# ============================================================================
# DATABASE MOCKING FIXTURES
# ============================================================================


@pytest.fixture
def mock_db_query():
    """Mock database query operations."""
    mock_query = Mock()

    # Mock filter operations
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.filter_by = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=None)
    mock_query.all = Mock(return_value=[])
    mock_query.count = Mock(return_value=0)
    mock_query.limit = Mock(return_value=mock_query)
    mock_query.offset = Mock(return_value=mock_query)
    mock_query.order_by = Mock(return_value=mock_query)

    return mock_query


@pytest.fixture
def mock_user_query(mock_user):
    """Mock user database query."""
    mock_query = Mock()
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.filter_by = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=mock_user)
    mock_query.all = Mock(return_value=[mock_user])
    mock_query.count = Mock(return_value=1)

    return mock_query


@pytest.fixture
def mock_spot_query(mock_spot):
    """Mock spot database query."""
    mock_query = Mock()
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.filter_by = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=mock_spot)
    mock_query.all = Mock(return_value=[mock_spot])
    mock_query.count = Mock(return_value=1)

    return mock_query


@pytest.fixture
def mock_job_query(mock_job):
    """Mock job database query."""
    mock_query = Mock()
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.filter_by = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=mock_job)
    mock_query.all = Mock(return_value=[mock_job])
    mock_query.count = Mock(return_value=1)

    return mock_query


# ============================================================================
# SERVICE MOCKING FIXTURES
# ============================================================================


@pytest.fixture
def mock_rabbitmq_service():
    """Mock RabbitMQ service."""
    mock_service = Mock()
    mock_service.publish_message = Mock(return_value=True)
    mock_service.consume_messages = Mock(return_value=[])
    mock_service.is_connected = Mock(return_value=True)
    mock_service.connect = Mock(return_value=True)
    mock_service.disconnect = Mock()

    return mock_service


@pytest.fixture
def mock_job_service():
    """Mock job service."""
    mock_service = Mock()
    mock_service.submit_job = Mock(return_value={"job_id": 1, "status": "queued"})
    mock_service.get_job_status = Mock(return_value="completed")
    mock_service.cancel_job = Mock(return_value=True)
    mock_service.get_user_jobs = Mock(return_value=[])

    return mock_service


@pytest.fixture
def mock_solver_engine():
    """Mock solver engine."""
    mock_engine = Mock()
    mock_engine.solve = Mock(
        return_value={
            "equity": {"player1": 0.65, "player2": 0.35},
            "actions": ["fold", "call", "raise"],
            "iterations": 1000,
            "solve_time": 5.23,
        }
    )
    mock_engine.validate_game_state = Mock(return_value=True)

    return mock_engine
