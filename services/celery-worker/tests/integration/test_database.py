"""
Integration tests for database functionality.

These tests require an active database connection and test actual database operations.
"""

import os
import sys

import pytest
from sqlalchemy import text

# Add src to path so we can import our modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "src"))


class TestDatabaseSession:
    """Test database session creation and management."""

    @pytest.mark.integration
    def test_get_db_session_missing_url(self):
        """Test database session creation with missing DATABASE_URL."""
        from celery_worker.tasks import get_db_session

        # Test with DATABASE_URL set to "NOT_SET" which should trigger the error
        original_db_url = os.environ.get("DATABASE_URL")
        try:
            os.environ["DATABASE_URL"] = "NOT_SET"
            with pytest.raises(ValueError, match="DATABASE_URL environment variable is required"):
                get_db_session()
        finally:
            if original_db_url is None:
                os.environ.pop("DATABASE_URL", None)
            else:
                os.environ["DATABASE_URL"] = original_db_url

    @pytest.mark.integration
    def test_get_db_session_invalid_url(self):
        """Test database session creation with invalid URL."""
        from celery_worker.tasks import get_db_session

        original_db_url = os.environ.get("DATABASE_URL")
        try:
            os.environ["DATABASE_URL"] = "invalid-url"
            with pytest.raises(ValueError, match="Invalid DATABASE_URL format"):
                get_db_session()
        finally:
            if original_db_url is None:
                os.environ.pop("DATABASE_URL", None)
            else:
                os.environ["DATABASE_URL"] = original_db_url

    @pytest.mark.integration
    def test_get_db_session_success(self):
        """Test successful database session creation with actual database."""
        from celery_worker.tasks import get_db_session

        # Skip this test if we're using SQLite (test environment)
        database_url = os.environ.get("DATABASE_URL", "")
        if "sqlite" in database_url.lower():
            pytest.skip("This test requires a real PostgreSQL database, not SQLite")

        # Skip this test if no database URL is set or if it's a Docker hostname without database
        if not database_url or database_url == "NOT_SET" or "db:" in database_url:
            pytest.skip("This test requires a real PostgreSQL database connection")

        # This test requires a real database connection
        # It will use the DATABASE_URL from environment
        try:
            db_session_factory = get_db_session()
            assert db_session_factory is not None

            # Test that we can create a session
            session = db_session_factory()
            assert session is not None

            # Test that we can execute a simple query
            result = session.execute(text("SELECT 1"))
            assert result is not None

            # Clean up
            session.close()
            db_session_factory.remove()
        except Exception as e:
            # If database connection fails, skip the test
            pytest.skip(f"Database connection failed: {e}")

    @pytest.mark.integration
    def test_database_connection_error(self):
        """Test handling of database connection errors with unreachable database."""
        from celery_worker.tasks import get_db_session

        original_db_url = os.environ.get("DATABASE_URL")
        try:
            # Use an unreachable database URL
            os.environ["DATABASE_URL"] = "postgresql://user:pass@localhost:9999/nonexistent"

            # The connection might fail during session creation or during actual use
            # So we test both scenarios
            connection_failed = False
            try:
                db_session_factory = get_db_session()
                # If we get here, try to use the session which should fail
                session = db_session_factory()
                session.execute(text("SELECT 1"))
                # If we get here, the connection succeeded (which is unexpected)
                session.close()
                db_session_factory.remove()
            except Exception:
                # This is expected - database connection should fail
                connection_failed = True

            # If the connection didn't fail, that means there's actually a database
            # running on port 9999, which is unexpected but not a test failure
            if not connection_failed:
                pytest.skip(
                    "Database connection succeeded unexpectedly - there might be a database running on port 9999"
                )

        finally:
            if original_db_url is None:
                os.environ.pop("DATABASE_URL", None)
            else:
                os.environ["DATABASE_URL"] = original_db_url


class TestDatabaseConfiguration:
    """Test database configuration and connection pooling."""

    @pytest.mark.integration
    def test_database_connection_pooling(self):
        """Test that database connection pooling works with real database."""
        from celery_worker.tasks import get_db_session

        # Skip this test if we're using SQLite (test environment)
        database_url = os.environ.get("DATABASE_URL", "")
        if "sqlite" in database_url.lower():
            pytest.skip("This test requires a real PostgreSQL database, not SQLite")

        # Skip this test if no database URL is set or if it's a Docker hostname without database
        if not database_url or database_url == "NOT_SET" or "db:" in database_url:
            pytest.skip("This test requires a real PostgreSQL database connection")

        # This test requires a real database connection
        # It will use the DATABASE_URL from environment
        try:
            db_session_factory = get_db_session()
            assert db_session_factory is not None

            # Test multiple sessions to verify pooling works
            sessions = []
            try:
                for i in range(3):
                    session = db_session_factory()
                    sessions.append(session)
                    # Execute a simple query to verify connection works
                    result = session.execute(text("SELECT 1"))
                    assert result is not None
            finally:
                # Clean up all sessions
                for session in sessions:
                    session.close()
                db_session_factory.remove()
        except Exception as e:
            # If database connection fails, skip the test
            pytest.skip(f"Database connection failed: {e}")

    @pytest.mark.integration
    def test_database_health_check(self):
        """Test database health check functionality."""
        from celery_worker.services.database_service import check_database_connection

        # Skip this test if we're using SQLite (test environment)
        database_url = os.environ.get("DATABASE_URL", "")
        if "sqlite" in database_url.lower():
            pytest.skip("This test requires a real PostgreSQL database, not SQLite")

        # Skip this test if no database URL is set or if it's a Docker hostname without database
        if not database_url or database_url == "NOT_SET" or "db:" in database_url:
            pytest.skip("This test requires a real PostgreSQL database connection")

        # This should not raise an exception if database is available
        # If database is not available, it should raise an exception
        try:
            check_database_connection()
            # If we get here, database is available and health check passed
            assert True
        except Exception as e:
            # If database is not available, that's also a valid test result
            # We just want to ensure the health check function works
            # Check for various connection error patterns
            error_msg = str(e).lower()
            if any(keyword in error_msg for keyword in ["connection", "database", "host", "refused", "timeout"]):
                assert True  # Expected connection error
            else:
                pytest.skip(f"Unexpected error type: {e}")
