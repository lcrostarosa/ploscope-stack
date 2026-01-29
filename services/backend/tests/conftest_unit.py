"""
Unit test configuration and fixtures.

This module provides fixtures and configuration for unit tests
that use mocked dependencies.
"""

import os
import sys
from unittest.mock import Mock, patch

import pytest

# Add backend directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from core.models.job import Job
from core.models.solver_solution import SolverSolution
from core.models.spot import Spot
from core.models.user import User

# Import app factory
from backend.main import create_flask_app as create_app
from src.backend.models.enums import JobStatus, JobType

# ============================================================================
# UNIT TEST FIXTURES (Mocked Database)
# ============================================================================


@pytest.fixture(scope="function")
def app():
    """Function-wide test `Flask` application with mocked database."""
    # Create app with testing configuration
    app = create_app("testing")

    # Mock the database session
    with patch("core.models.db") as mock_db_session:
        # Mock the database session
        mock_db_session.session.return_value = mock_db_session
        yield app


@pytest.fixture(scope="function")
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture(scope="function")
def mock_db_session():
    """Mock database session for unit tests."""
    mock_session = Mock()

    # Mock common database operations
    mock_session.add = Mock()
    mock_session.commit = Mock()
    mock_session.rollback = Mock()
    mock_session.close = Mock()
    mock_session.remove = Mock()

    # Mock query operations
    mock_query = Mock()
    mock_session.query = Mock(return_value=mock_query)

    return mock_session


# ============================================================================
# MOCKED MODEL FACTORIES
# ============================================================================


class MockUserFactory:
    """Factory for creating mock User objects."""

    @staticmethod
    def create(**kwargs):
        """Create a mock User object."""
        user = Mock(spec=User)
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
        spot = Mock(spec=Spot)
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
        job = Mock(spec=Job)
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


class MockSolverSolutionFactory:
    """Factory for creating mock SolverSolution objects."""

    @staticmethod
    def create(**kwargs):
        """Create a mock SolverSolution object."""
        solution = Mock(spec=SolverSolution)
        solution.id = kwargs.get("id", 1)
        solution.name = kwargs.get("name", "Test Solution")
        solution.description = kwargs.get("description", "Test description")
        solution.user_id = kwargs.get("user_id", 1)
        solution.user = kwargs.get("user", MockUserFactory.create())
        solution.iterations = kwargs.get("iterations", 1000)
        solution.solve_time = kwargs.get("solve_time", 5.23)
        solution.game_state = kwargs.get(
            "game_state",
            {
                "ranges": {"player1": "AA,KK,QQ", "player2": "AK,AQ,AJ"},
                "board": ["As", "2s", "3h"],
                "pot_size": 200,
                "bet_size": 50,
            },
        )
        solution.solution = kwargs.get(
            "solution",
            {
                "equity": {"player1": 0.65, "player2": 0.35},
                "actions": ["fold", "call", "raise"],
            },
        )
        solution.created_at = kwargs.get("created_at", "2023-01-01T00:00:00Z")
        solution.updated_at = kwargs.get("updated_at", "2023-01-01T00:00:00Z")

        # Mock methods
        solution.to_dict = Mock(
            return_value={
                "id": solution.id,
                "name": solution.name,
                "description": solution.description,
                "user_id": solution.user_id,
                "iterations": solution.iterations,
                "solve_time": solution.solve_time,
                "game_state": solution.game_state,
                "solution": solution.solution,
                "created_at": solution.created_at,
                "updated_at": solution.updated_at,
            }
        )

        return solution


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
def mock_solver_solution(mock_user):
    """Create a mock solver solution for testing."""
    return MockSolverSolutionFactory.create(user_id=mock_user.id, user=mock_user)


@pytest.fixture
def mock_auth_headers(mock_user):
    """Create mock authentication headers."""
    # Mock the token creation
    with patch("utils.auth_utils.create_user_tokens") as mock_create_tokens:
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


# ============================================================================
# UTILITY FIXTURES
# ============================================================================


@pytest.fixture
def mock_request_context():
    """Mock Flask request context."""
    mock_request = Mock()
    mock_request.headers = {}
    mock_request.json = {}
    mock_request.method = "GET"
    mock_request.url = "http://localhost:5001/api/test"

    return mock_request


@pytest.fixture
def mock_response():
    """Mock Flask response."""
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json = {}
    mock_response.headers = {}

    return mock_response
