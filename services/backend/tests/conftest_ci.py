"""
CI-specific test configuration and fixtures.

This module provides fixtures for integration tests that work with
GitHub Actions routes_grpc (PostgreSQL and RabbitMQ) instead of Docker containers.
"""
import os
import sys

import pytest
from core.utils.logging_utils import get_enhanced_logger

from backend.models.enums import JobType
from backend.models.job import Job
from backend.models.solver_solution import SolverSolution
from backend.models.spot import Spot
from src.backend.database import db
from src.backend.main import create_flask_app as create_app
from src.backend.models.user import User

from ..services.rabbitmq_service import RabbitMQService
from ..utils.auth_utils import create_access_token

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

logger = get_enhanced_logger(__name__)


@pytest.fixture(scope="session")
def ci_rabbitmq_container():
    """Session-scoped RabbitMQ container info for CI routes_grpc."""
    # Return connection info for CI RabbitMQ service
    container_info = {
        "host": "localhost",
        "amqp_port": 5672,
        "management_port": 15672,
        "username": "plosolver",
        "password": "dev_password_2024",
        "vhost": "/plosolver",
    }
    yield container_info


@pytest.fixture(scope="session")
def ci_postgres_container():
    """Session-scoped PostgreSQL container info for CI routes_grpc."""
    # Return connection info for CI PostgreSQL service
    container_info = {
        "host": "localhost",
        "port": 5432,
        "username": "testuser",
        "password": "testpassword",
        "database": "testdb",
    }
    yield container_info


@pytest.fixture(scope="session")
def ci_test_database_schema(ci_postgres_container):
    """Session-scoped database schema creation for CI tests."""
    # Create a minimal app just for schema creation
    app = create_app("testing")
    app.config.update(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": (
                f"postgresql://{ci_postgres_container['username']}:"
                f"{ci_postgres_container['password']}@localhost:"
                f"{ci_postgres_container['port']}/{ci_postgres_container['database']}"
            ),
            "SQLALCHEMY_TRACK_MODIFICATIONS": False,
        }
    )

    with app.app_context():
        # Create all tables once for the entire test session
        db.create_all()

        # Verify tables were created
        inspector = db.inspect(db.engine)
        tables = inspector.get_table_names()
        print(f"✅ CI Session database schema created for {ci_postgres_container['database']}")
        print(f"📋 Created tables: {tables}")

        yield
        # Cleanup happens in ci_app fixture


@pytest.fixture(scope="function")
def ci_app(ci_rabbitmq_container, ci_postgres_container, ci_test_database_schema, request):
    """Function-scoped Flask app configured for CI integration tests."""
    # Configure app to use CI routes_grpc
    app = create_app("testing")

    # Update configuration for CI routes_grpc
    app.config.update(
        {
            "TESTING": True,
            "SECRET_KEY": "ci-test-secret-key",
            "JWT_SECRET_KEY": "ci-test-jwt-secret-key",
            "SQLALCHEMY_DATABASE_URI": (
                f"postgresql://{ci_postgres_container['username']}:"
                f"{ci_postgres_container['password']}@localhost:"
                f"{ci_postgres_container['port']}/{ci_postgres_container['database']}"
            ),
            "SQLALCHEMY_TRACK_MODIFICATIONS": False,
            "WTF_CSRF_ENABLED": False,
            "SERVER_NAME": "localhost",
            # RabbitMQ configuration
            "QUEUE_PROVIDER": "rabbitmq",
            "RABBITMQ_HOST": ci_rabbitmq_container["host"],
            "RABBITMQ_PORT": ci_rabbitmq_container["amqp_port"],
            "RABBITMQ_USERNAME": ci_rabbitmq_container["username"],
            "RABBITMQ_PASSWORD": ci_rabbitmq_container["password"],
        }
    )

    with app.app_context():
        # SQLAlchemy is already initialized in create_app()
        # Schema is already created by ci_test_database_schema fixture
        # Just ensure we're using the same database
        yield app
        try:
            # Clean up any test data but keep schema
            db.session.remove()
            print("🧹 CI Test data cleaned up")
        except Exception as e:
            print(f"⚠️ Error cleaning up CI test data: {e}")


@pytest.fixture(scope="function")
def ci_client(ci_app, request):
    """Function-scoped test client for CI integration tests."""
    return ci_app.test_client()


@pytest.fixture(scope="function")
def ci_db_session(ci_app, request):
    """Function-scoped database session for CI integration tests."""
    with ci_app.app_context():
        yield db.session
        db.session.rollback()


# Re-export the existing fixtures for compatibility
@pytest.fixture(scope="session")
def rabbitmq_container(ci_rabbitmq_container):
    """Alias for ci_rabbitmq_container for compatibility with existing tests."""
    return ci_rabbitmq_container


@pytest.fixture(scope="session")
def postgres_container(ci_postgres_container):
    """Alias for ci_postgres_container for compatibility with existing tests."""
    return ci_postgres_container


@pytest.fixture(scope="session")
def test_database_schema(ci_test_database_schema):
    """Alias for ci_test_database_schema for compatibility with existing tests."""
    return ci_test_database_schema


@pytest.fixture(scope="function")
def docker_app(ci_app):
    """Alias for ci_app for compatibility with existing tests."""
    return ci_app


@pytest.fixture(scope="function")
def docker_client(ci_client):
    """Alias for ci_client for compatibility with existing tests."""
    return ci_client


@pytest.fixture(scope="function")
def docker_db_session(ci_db_session):
    """Alias for ci_db_session for compatibility with existing tests."""
    return ci_db_session


@pytest.fixture
def rabbitmq_service():
    """Create RabbitMQ service for testing"""
    try:
        service = RabbitMQService()

        # Test the connection
        try:
            service.connection.process_data_events(time_limit=1)
            logger.info("✅ RabbitMQ service connection successful")
        except Exception as e:
            logger.error(f"❌ RabbitMQ service connection failed: {e}")
            pytest.skip(f"RabbitMQ service not available: {e}")

        # Quick cleanup of any leftover messages (limit to 1 message per queue)
        queues_to_clean = ["spot-processing", "solver-processing"]
        for queue in queues_to_clean:
            try:
                # Only clean 1 message per queue to avoid delays
                messages = service.receive_messages(queue, max_messages=1, wait_time_seconds=0.1)
                for message in messages:
                    service.delete_message(queue, message["ReceiptHandle"])
                    logger.debug(f"🧹 Cleaned up message from queue {queue}")
            except Exception as e:
                logger.debug(f"Queue {queue} cleanup skipped: {e}")

        yield service

        # Quick cleanup after test (limit to 1 message per queue)
        for queue in queues_to_clean:
            try:
                # Only clean 1 message per queue to avoid delays
                messages = service.receive_messages(queue, max_messages=1, wait_time_seconds=0.1)
                for message in messages:
                    service.delete_message(queue, message["ReceiptHandle"])
                    logger.debug(f"🧹 Cleaned up message from queue {queue}")
            except Exception as e:
                logger.debug(f"Queue {queue} cleanup skipped: {e}")

        service.close()
        logger.info("🔧 RabbitMQ service fixture cleaned up")

    except Exception as e:
        logger.error(f"❌ Failed to create RabbitMQ service: {e}")
        pytest.skip(f"RabbitMQ not available: {e}")


@pytest.fixture
def cleanup_database(ci_app):
    """Clean up database after each test"""
    with ci_app.app_context():
        yield
        try:
            # Clean up any test data but keep schema
            db.session.remove()
            print("🧹 Test data cleaned up")
        except Exception as e:
            print(f"⚠️ Error cleaning up test data: {e}")


@pytest.fixture
def mock_simulation_results():
    """Provides mock results for a simulation."""
    return {
        "equities": {"Hero": 0.65, "Opponent_1": 0.35},
        "win_percentages": {"Hero": 0.60, "Opponent_1": 0.30, "Tie": 0.10},
        "hand_combinations_processed": 1000,
    }


from factory import Faker, Iterator, LazyFunction, SelfAttribute, SubFactory

# Factory classes for creating test data
from factory.alchemy import SQLAlchemyModelFactory


class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "commit"

    email = Faker("email")
    username = Faker("user_name")
    first_name = Faker("first_name")
    last_name = Faker("last_name")
    password = LazyFunction(lambda: "test_password")
    is_admin = False
    subscription_tier = "FREE"


class SpotFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Spot
        sqlalchemy_session_persistence = "commit"

    name = Faker("sentence", nb_words=3)
    description = Faker("paragraph")
    top_board = LazyFunction(lambda: ["Ah", "Ks", "Qd"])
    bottom_board = LazyFunction(lambda: ["2c", "3h", "4s"])
    players = LazyFunction(lambda: [[], []])
    user_id = SelfAttribute("user.id")
    user = SubFactory(UserFactory)


class JobFactory(SQLAlchemyModelFactory):
    class Meta:
        model = Job
        sqlalchemy_session_persistence = "commit"

    job_type = Iterator([JobType.SPOT_SIMULATION, JobType.SOLVER_ANALYSIS])
    input_data = LazyFunction(dict)
    user_id = SelfAttribute("user.id")
    user = SubFactory(UserFactory)
    status = Iterator(["queued", "processing", "completed"])


class SolverSolutionFactory(SQLAlchemyModelFactory):
    class Meta:
        model = SolverSolution
        sqlalchemy_session_persistence = "commit"

    name = Faker("word")
    description = Faker("text", max_nb_chars=100)
    user_id = SelfAttribute("user.id")
    user = SubFactory(UserFactory)
    iterations = 1000
    solve_time = 5.23
    game_state = LazyFunction(
        lambda: {
            "ranges": {"player1": "AA,KK,QQ", "player2": "AK,AQ,AJ"},
            "board": ["As", "2s", "3h"],
            "pot_size": 200,
            "bet_size": 50,
        }
    )
    solution = LazyFunction(
        lambda: {
            "equities": {"player1": 0.65, "player2": 0.35},
            "actions": {"player1": "call", "player2": "fold"},
        }
    )


@pytest.fixture
def user_factory(ci_app, ci_test_database_schema):
    """Factory for creating test users"""
    with ci_app.app_context():
        UserFactory._meta.sqlalchemy_session = db.session
        yield UserFactory


@pytest.fixture
def spot_factory(ci_app, ci_test_database_schema):
    """Factory for creating test spots"""
    with ci_app.app_context():
        SpotFactory._meta.sqlalchemy_session = db.session
        yield SpotFactory


@pytest.fixture
def job_factory(ci_app, ci_test_database_schema):
    """Factory for creating test jobs"""
    with ci_app.app_context():
        JobFactory._meta.sqlalchemy_session = db.session
        yield JobFactory


@pytest.fixture
def solver_solution_factory(ci_app):
    """Factory for creating test solver solutions"""
    with ci_app.app_context():
        SolverSolutionFactory._meta.sqlalchemy_session = db.session
        yield SolverSolutionFactory


@pytest.fixture
def user(ci_app, ci_test_database_schema, user_factory):
    """Create a test user"""
    with ci_app.app_context():
        UserFactory._meta.sqlalchemy_session = db.session
        return user_factory()


@pytest.fixture
def docker_user(ci_app):
    """Alias for user fixture for compatibility"""
    with ci_app.app_context():
        UserFactory._meta.sqlalchemy_session = db.session
        return UserFactory()


@pytest.fixture
def spot(ci_app, ci_test_database_schema, spot_factory, user):
    """Create a test spot"""
    with ci_app.app_context():
        SpotFactory._meta.sqlalchemy_session = db.session
        return spot_factory(user=user)


@pytest.fixture
def auth_headers(ci_app, user_factory):
    """Create authentication headers for a test user"""
    with ci_app.app_context():
        # Create user within this session context
        user = user_factory()
        db.session.add(user)
        db.session.flush()

        token = create_access_token(identity=user.id)
        headers = {"Authorization": f"Bearer {token}"}
        return headers


@pytest.fixture
def docker_auth_headers(ci_app, user_factory):
    """Alias for auth_headers fixture for compatibility"""
    with ci_app.app_context():
        user = user_factory()
        db.session.add(user)
        db.session.flush()

        token = create_access_token(identity=user.id)
        headers = {"Authorization": f"Bearer {token}"}
        return headers


@pytest.fixture
def app(ci_app):
    """Alias for ci_app fixture for compatibility"""
    return ci_app


@pytest.fixture
def client(ci_client):
    """Alias for ci_client fixture for compatibility"""
    return ci_client
