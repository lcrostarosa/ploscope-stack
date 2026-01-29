"""
Integration test configuration and fixtures for PLOSolver.

This module provides fixtures and configuration for integration tests
that require Docker containers (PostgreSQL, RabbitMQ).
"""

import os
import socket
import subprocess
import sys
import time
from contextlib import contextmanager
from typing import Any, Dict

import docker
import factory
import psycopg2
import pytest
import requests

# Import models
from flask_sqlalchemy import SQLAlchemy

from ..models.hand_history import HandHistory
from ..models.job import Job
from ..models.parsed_hand import ParsedHand
from ..models.solver_solution import SolverSolution
from ..models.spot import Spot
from ..models.user import User
from ..models.user_credit import UserCredit
from ..models.user_session import UserSession

db = SQLAlchemy()

from factory.alchemy import SQLAlchemyModelFactory
from faker import Faker

from src.backend.models.enums import JobStatus, JobType

from ..services.rabbitmq_service import RabbitMQService
from ..utils.auth_utils import create_user_tokens

# Add backend directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Minimal local app factory to avoid depending on plosolver_core.app in tests
from flask import Flask
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager

# Import routes_grpc
from ..services.job_service import start_job_processors, stop_job_processors

bcrypt = Bcrypt()


def create_app(config_name: str = "testing") -> Flask:
    app = Flask(__name__)
    app.config.update(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": os.getenv(
                "DATABASE_URL",
                "postgresql://testuser:testpassword@localhost:5432/plosolver",
            ),
            "SQLALCHEMY_TRACK_MODIFICATIONS": False,
            "JWT_SECRET_KEY": "integration-test-jwt",
        }
    )
    with app.app_context():
        db.init_app(app)
        bcrypt.init_app(app)
        JWTManager(app)
    return app


class DockerComposeTestEnvironment:
    """Manages Docker Compose routes_grpc for integration testing."""

    def __init__(self):
        self.compose_file = "../../docker-compose-test.yml"
        self.project_name = "plosolver-test"
        # Add client attribute for compatibility
        self.client = docker.from_env()
        self.services_started = False

    def start_services(self):
        """Start test routes_grpc using docker-compose."""
        if self.services_started:
            return

        # Check if we're running in integration test mode with existing Docker environment
        if os.getenv("CONTAINER_ENV") == "docker":
            print("✅ Using existing Docker environment from run_tests.sh")
            self.services_started = True
            return

        print("🚀 Starting test routes_grpc with docker-compose...")

        # Stop any existing routes_grpc first
        self.stop_services()

        # Start routes_grpc
        result = subprocess.run(
            [
                "docker-compose",
                "-f",
                self.compose_file,
                "-p",
                self.project_name,
                "--profile",
                "bootstrap",
                "up",
                "-d",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(f"Failed to start docker-compose routes_grpc: {result.stderr}")

        print("✅ Docker-compose routes_grpc started")

        # Wait for routes_grpc to be healthy
        self._wait_for_services_ready()
        self.services_started = True

    def stop_services(self):
        """Stop test routes_grpc."""
        print("🛑 Stopping test routes_grpc...")
        subprocess.run(
            [
                "docker-compose",
                "-f",
                self.compose_file,
                "-p",
                self.project_name,
                "--profile",
                "bootstrap",
                "down",
                "-v",
            ],
            capture_output=True,
        )
        print("✅ Test routes_grpc stopped")

    def _wait_for_services_ready(self, timeout: int = 120):
        """Wait for all routes_grpc to be healthy."""
        print("🔄 Waiting for routes_grpc to be ready...")
        start_time = time.time()

        while time.time() - start_time < timeout:
            try:
                # Check RabbitMQ
                rabbitmq_ready = self._check_rabbitmq_ready()
                postgres_ready = self._check_postgres_ready()

                if rabbitmq_ready and postgres_ready:
                    print("✅ All routes_grpc are ready!")
                    return

                print(f"🔄 Services not ready yet... (RabbitMQ: {rabbitmq_ready}, PostgreSQL: {postgres_ready})")
                time.sleep(5)

            except Exception as e:
                print(f"⚠️ Error checking service readiness: {e}")
                time.sleep(5)

        raise TimeoutError(f"Services did not become ready within {timeout} seconds")

    def _check_rabbitmq_ready(self) -> bool:
        """Check if RabbitMQ is ready."""
        try:
            response = requests.get(
                "http://localhost:15673/api/overview",
                auth=("test_user", "test_password"),
                timeout=5,
            )
            return response.status_code == 200
        except Exception:
            return False

    def _check_postgres_ready(self) -> bool:
        """Check if PostgreSQL is ready."""
        try:
            conn = psycopg2.connect(
                host="localhost",
                port=5433,
                database="test_plosolver",
                user="test_user",
                password="test_password",
            )
            conn.close()
            return True
        except Exception:
            return False

    def get_rabbitmq_info(self) -> Dict[str, Any]:
        """Get RabbitMQ connection information."""
        # Check if we're using existing Docker environment
        if os.getenv("CONTAINER_ENV") == "docker":
            return {
                "host": os.getenv("RABBITMQ_HOST", "localhost"),
                "amqp_port": int(os.getenv("RABBITMQ_PORT", "5672")),
                "management_port": 15672,
                "username": os.getenv("RABBITMQ_USERNAME", "plosolver"),
                "password": os.getenv("RABBITMQ_PASSWORD", "dev_password_2024"),
                "vhost": os.getenv("RABBITMQ_VHOST", "/plosolver"),
            }
        else:
            return {
                "host": "localhost",
                "amqp_port": 5672,
                "management_port": 15672,
                "username": "plosolver",
                "password": "dev_password_2024",
                "vhost": "/plosolver",
            }

    def get_postgres_info(self) -> Dict[str, Any]:
        """Get PostgreSQL connection information."""
        # Check if we're using existing Docker environment
        if os.getenv("CONTAINER_ENV") == "docker":
            # Parse DATABASE_URL to get connection details
            db_url = os.getenv(
                "DATABASE_URL",
                "postgresql://testuser:testpassword@localhost:5432/plosolver",
            )
            import urllib.parse

            parsed = urllib.parse.urlparse(db_url)
            return {
                "host": parsed.hostname or "localhost",
                "port": parsed.port or 5432,
                "username": parsed.username or "testuser",
                "password": parsed.password or "testpassword",
                "database": parsed.path.lstrip("/") or "plosolver",
            }
        else:
            return {
                "host": "localhost",
                "port": 5432,
                "username": "testuser",
                "password": "testpassword",
                "database": "plosolver",
            }

    def cleanup(self):
        """Clean up all test routes_grpc."""
        self.stop_services()


@pytest.fixture(scope="session")
def docker_env(request):
    """Session-scoped Docker Compose test environment."""
    env = DockerComposeTestEnvironment()
    env.start_services()
    yield env
    env.cleanup()


@pytest.fixture(scope="session")
def rabbitmq_container(request):
    """Session-scoped RabbitMQ container for all integration tests."""
    env = request.getfixturevalue("docker_env")
    container_info = env.get_rabbitmq_info()
    yield container_info


@pytest.fixture(scope="session")
def postgres_container(request):
    """Session-scoped PostgreSQL container for all integration tests."""
    env = request.getfixturevalue("docker_env")
    container_info = env.get_postgres_info()
    yield container_info


@pytest.fixture(scope="session")
def test_database_schema(postgres_container):
    """Session-scoped database schema creation - runs once for all tests."""
    # Create a minimal app just for schema creation
    app = create_app("testing")
    app.config.update(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": (
                f"postgresql://{postgres_container['username']}:"
                f"{postgres_container['password']}@localhost:"
                f"{postgres_container['port']}/{postgres_container['database']}"
            ),
            "SQLALCHEMY_TRACK_MODIFICATIONS": False,
        }
    )

    with app.app_context():
        # Check if we're using existing Docker environment with pre-migrated database
        if os.getenv("CONTAINER_ENV") == "docker":
            # Database is already migrated by db-migrate service, just verify tables exist
            inspector = db.inspect(db.engine)
            tables = inspector.get_table_names()
            print(f"✅ Using existing database schema for {postgres_container['database']}")
            print(f"📋 Existing tables: {tables}")

            # Verify essential tables exist
            required_tables = ["users", "spots", "jobs", "solver_solutions"]
            missing_tables = [table for table in required_tables if table not in tables]
            if missing_tables:
                raise RuntimeError(f"Missing required tables: {missing_tables}")
        else:
            # Create all tables once for the entire test session
            db.create_all()

            # Verify tables were created
            inspector = db.inspect(db.engine)
            tables = inspector.get_table_names()
            print(f"✅ Session database schema created for {postgres_container['database']}")
            print(f"📋 Created tables: {tables}")

        yield
        # Cleanup happens in docker_app fixture


@pytest.fixture(scope="function")
def docker_app(rabbitmq_container, postgres_container, test_database_schema, request):
    """Function-scoped Flask app configured for Docker integration tests."""
    # Configure app to use Docker Compose containers
    app = create_app("testing")

    # Update configuration for Docker containers
    app.config.update(
        {
            "TESTING": True,
            "SECRET_KEY": "docker-test-secret-key",
            "JWT_SECRET_KEY": "docker-test-jwt-secret-key",
            "SQLALCHEMY_DATABASE_URI": (
                f"postgresql://{postgres_container['username']}:"
                f"{postgres_container['password']}@localhost:"
                f"{postgres_container['port']}/{postgres_container['database']}"
            ),
            "SQLALCHEMY_TRACK_MODIFICATIONS": False,
            "WTF_CSRF_ENABLED": False,
            "SERVER_NAME": "localhost",
            # RabbitMQ configuration
            "QUEUE_PROVIDER": "rabbitmq",
            "RABBITMQ_HOST": rabbitmq_container["host"],
            "RABBITMQ_PORT": rabbitmq_container["amqp_port"],
            "RABBITMQ_USERNAME": rabbitmq_container["username"],
            "RABBITMQ_PASSWORD": rabbitmq_container["password"],
            "RABBITMQ_VHOST": rabbitmq_container["vhost"],
            "RABBITMQ_SPOT_QUEUE": "test-spot-processing",
            "RABBITMQ_SOLVER_QUEUE": "test-solver-processing",
        }
    )

    with app.app_context():
        start_job_processors(app)
        # SQLAlchemy is already initialized in create_app()
        # Schema is already created by test_database_schema fixture
        # Just ensure we're using the same database
        yield app
        try:
            # Clean up any test data but keep schema
            db.session.remove()
            db.engine.dispose()  # Dispose of engine to clean up connections
            stop_job_processors()
            print("🧹 Test data cleaned up")
        except Exception as e:
            print(f"⚠️ Error cleaning up test data: {e}")


@pytest.fixture(scope="function")
def docker_client(docker_app, request):
    """Function-scoped test client for Docker integration tests."""
    return docker_app.test_client()


@pytest.fixture(scope="function")
def docker_db_session(docker_app, request):
    """Function-scoped database session for Docker tests."""
    with docker_app.app_context():
        # Use the shared singleton session from core.models.base
        session = db.session

        # Store the session for cleanup
        request.addfinalizer(lambda: db.session.remove())

        yield session


@pytest.fixture(scope="function")
def cleanup_database(docker_app, request):
    """Function-scoped cleanup fixture that clears the database between tests."""
    with docker_app.app_context():
        yield

        # Clean up database after each test
        try:
            db.session.rollback()

            # Delete in order to respect foreign key constraints
            # Delete child tables first
            db.session.query(UserCredit).delete()
            db.session.query(UserSession).delete()
            db.session.query(SolverSolution).delete()
            db.session.query(HandHistory).delete()
            db.session.query(ParsedHand).delete()
            db.session.query(Job).delete()
            db.session.query(Spot).delete()
            db.session.query(User).delete()

            db.session.commit()
        except Exception as e:
            print(f"⚠️ Error during database cleanup: {e}")
            try:
                db.session.rollback()
            except Exception as rollback_error:
                print(f"⚠️ Error rolling back during cleanup: {rollback_error}")
        finally:
            # Always clean up the session
            try:
                db.session.remove()
            except Exception as cleanup_error:
                print(f"⚠️ Error removing session during cleanup: {cleanup_error}")


# ============================================================================
# FACTORIES (Work for both unit and Docker tests)
# ============================================================================

fake = Faker()


class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "commit"

    email = factory.Faker("email")
    username = factory.Faker("user_name")
    first_name = factory.Faker("first_name")
    last_name = factory.Faker("last_name")
    password = factory.LazyFunction(lambda: "test_password")
    is_admin = False
    subscription_tier = "FREE"


class SpotFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Spot
        sqlalchemy_session_persistence = "commit"

    name = factory.Faker("sentence", nb_words=3)
    description = factory.Faker("paragraph")
    top_board = factory.LazyFunction(lambda: ["Ah", "Ks", "Qd"])
    bottom_board = factory.LazyFunction(lambda: ["2c", "3h", "4s"])
    players = factory.LazyFunction(lambda: [[], []])
    user_id = factory.SelfAttribute("user.id")
    user = factory.SubFactory(UserFactory)


class JobFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Job
        sqlalchemy_session_persistence = "commit"

    job_type = factory.Iterator([JobType.SPOT_SIMULATION, JobType.SOLVER_ANALYSIS])
    input_data = factory.LazyFunction(dict)
    user_id = factory.SelfAttribute("user.id")
    user = factory.SubFactory(UserFactory)
    status = factory.Iterator(
        [
            JobStatus.QUEUED,
            JobStatus.PROCESSING,
            JobStatus.COMPLETED,
            JobStatus.FAILED,
            JobStatus.CANCELLED,
        ]
    )


class SolverSolutionFactory(SQLAlchemyModelFactory):
    class Meta:
        model = SolverSolution
        sqlalchemy_session_persistence = "commit"

    name = factory.Faker("word")
    description = factory.Faker("text", max_nb_chars=100)
    user_id = factory.SelfAttribute("user.id")
    user = factory.SubFactory(UserFactory)
    iterations = 1000
    solve_time = 5.23
    game_state = factory.LazyFunction(
        lambda: {
            "ranges": {"player1": "AA,KK,QQ", "player2": "AK,AQ,AJ"},
            "board": ["As", "2s", "3h"],
            "pot_size": 200,
            "bet_size": 50,
        }
    )
    solution = factory.LazyFunction(
        lambda: {
            "equity": {"player1": 0.65, "player2": 0.35},
            "actions": ["fold", "call", "raise"],
        }
    )


# ============================================================================
# FACTORY FIXTURES (Work for both unit and Docker tests)
# ============================================================================


@pytest.fixture
def user_factory(docker_app, test_database_schema, request):
    """User factory that uses the same database session as the Flask app."""
    with docker_app.app_context():
        UserFactory._meta.sqlalchemy_session = db.session
        yield UserFactory


@pytest.fixture
def spot_factory(docker_app, test_database_schema, request):
    """Spot factory that uses the same database session as the Flask app."""
    with docker_app.app_context():
        SpotFactory._meta.sqlalchemy_session = db.session
        yield SpotFactory


@pytest.fixture
def job_factory(docker_app, test_database_schema, request):
    """Job factory that uses the same database session as the Flask app."""
    with docker_app.app_context():
        JobFactory._meta.sqlalchemy_session = db.session
        yield JobFactory


@pytest.fixture
def solver_solution_factory(docker_app, request):
    """Solver solution factory that uses the same database session as the Flask app."""
    with docker_app.app_context():
        SolverSolutionFactory._meta.sqlalchemy_session = db.session
        yield SolverSolutionFactory


# ============================================================================
# MODEL FIXTURES (Work for both unit and Docker tests)
# ============================================================================


@pytest.fixture
def user(docker_app, test_database_schema, user_factory):
    """Create a user in the same database context as the Flask app."""
    with docker_app.app_context():
        return user_factory()


@pytest.fixture
def docker_user(docker_app):
    """Create and commit a user in the same app context/session as the Flask app."""
    with docker_app.app_context():
        user = User(
            email="testuser@example.com",
            username="testuser",
            password_hash="$2b$12$testhash",
            first_name="Test",
            last_name="User",
            is_active=True,
        )
        db.session.add(user)
        db.session.commit()
        return user


@pytest.fixture
def spot(docker_app, test_database_schema, spot_factory, user):
    """Create a spot in the same database context as the Flask app."""
    with docker_app.app_context():
        return spot_factory(user=user)


@pytest.fixture
def auth_headers(app, docker_app, user, request):
    """Auth headers - works with both unit and Docker tests."""
    try:
        if request.node.get_closest_marker("docker"):
            test_app = docker_app
        else:
            test_app = app
    except AttributeError:
        # Fallback to unit test app
        test_app = app

    with test_app.app_context():
        with test_app.test_request_context():
            # Ensure user is bound to the session
            db.session.add(user)
            db.session.refresh(user)
            access_token, _ = create_user_tokens(user.id)
            headers = {"Authorization": f"Bearer {access_token}"}
            return headers


@pytest.fixture
def docker_auth_headers(docker_app, docker_user, request):
    """Auth headers specifically for Docker tests."""
    with docker_app.app_context():
        with docker_app.test_request_context():
            # Ensure the user is committed to the database
            db.session.commit()
            access_token, _ = create_user_tokens(docker_user.id)
            headers = {"Authorization": f"Bearer {access_token}"}
            return headers


# Alias fixture for tests that expect 'app' but are running in Docker context
@pytest.fixture
def app(docker_app, request):
    """Alias for docker_app to support tests that expect 'app' fixture."""
    if request.node.get_closest_marker("docker") or request.node.get_closest_marker("integration"):
        return docker_app
    else:
        # This should not happen in integration tests, but provide fallback
        pytest.skip("This test requires Docker integration test setup")


@pytest.fixture
def mock_simulation_results():
    """Provides mock results for a simulation."""
    return {
        "equities": {"Hero": 0.65, "Opponent_1": 0.35},
        "win_percentages": {"Hero": 0.60, "Opponent_1": 0.30, "Tie": 0.10},
        "hand_combinations_processed": 1000,
    }


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================


@contextmanager
def docker_test_context():
    """Context manager for Docker integration tests."""
    # This can be used for additional Docker-specific setup/teardown
    yield


@pytest.fixture
def rabbitmq_service():
    """Create RabbitMQ service for testing"""
    try:
        service = RabbitMQService()

        # Quick cleanup of any leftover messages (limit to 1 message per queue)
        queues_to_clean = ["spot-processing", "solver-processing"]
        for queue in queues_to_clean:
            try:
                # Only clean 1 message per queue to avoid delays
                messages = service.receive_messages(queue, max_messages=1, wait_time_seconds=0.1)
                for message in messages:
                    service.delete_message(queue, message["ReceiptHandle"])
            except Exception:
                pass  # Queue might not exist or be empty

        yield service

        # Quick cleanup after test (limit to 1 message per queue)
        for queue in queues_to_clean:
            try:
                # Only clean 1 message per queue to avoid delays
                messages = service.receive_messages(queue, max_messages=1, wait_time_seconds=0.1)
                for message in messages:
                    service.delete_message(queue, message["ReceiptHandle"])
            except Exception:
                pass  # Queue might not exist or be empty

        service.close()
    except Exception as e:
        pytest.skip(f"RabbitMQ not available: {e}")


# Fast-fail check for Postgres availability (only for non-Docker environments)
def check_postgres_availability():
    """Check if PostgreSQL is available, but skip in Docker environments."""
    # Skip the check if we're in a Docker container or if DATABASE_URL points to a Docker service
    if os.getenv("CONTAINER_ENV") == "docker" or "test-postgres" in os.getenv("DATABASE_URL", ""):
        return True

    POSTGRES_HOST = os.getenv("POSTGRES_HOST", "localhost")
    POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", "5432"))
    try:
        with socket.create_connection((POSTGRES_HOST, POSTGRES_PORT), timeout=3):
            return True
    except Exception:
        raise RuntimeError(
            f"PostgreSQL is not available at {POSTGRES_HOST}:{POSTGRES_PORT}. "
            "Integration tests require a running Postgres instance."
        )


# Skip the check since we now start Docker containers before tests
# The test runner ensures PostgreSQL and RabbitMQ are available


# Unified client fixture that works for both unit and integration tests
@pytest.fixture
def client(docker_app, request):
    """Test client - works with both unit and Docker tests."""
    if request.node.get_closest_marker("docker") or request.node.get_closest_marker("integration"):
        return docker_app.test_client()
    else:
        # This should not happen in integration tests, but provide fallback
        pytest.skip("This test requires Docker integration test setup")
