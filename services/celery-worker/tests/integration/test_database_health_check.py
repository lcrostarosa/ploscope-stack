#!/usr/bin/env python3
"""
Test script to demonstrate Database health check functionality.
This script will test the database connection via get_db_session and
show how the application behaves for valid and invalid configurations.
"""

import logging
import os
import sys
from contextlib import suppress

try:
    from sqlalchemy import text as sa_text
    from sqlalchemy.exc import DBAPIError, OperationalError, SQLAlchemyError
except ImportError:  # Fallback types if SQLAlchemy is unavailable at lint time

    class SQLAlchemyError(Exception):
        pass

    class OperationalError(SQLAlchemyError):
        pass

    class DBAPIError(SQLAlchemyError):
        pass

    def sa_text(sql: str):  # type: ignore
        return sql


# Add src to path so we can import our modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))


# Configure logging to see the health check messages
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")


def _try_db_connection(database_url: str) -> None:
    """Attempt to create a DB session and run a simple query."""
    # Import inside function to ensure sys.path is prepared first
    from celery_worker.tasks import get_db_session

    # Temporarily override env for this attempt
    original_db_url = os.environ.get("DATABASE_URL")
    try:
        os.environ["DATABASE_URL"] = database_url
        db_session_factory = get_db_session()
        session = db_session_factory()
        try:
            # Simple validation query; may fail if DB not reachable
            session.execute(sa_text("SELECT 1"))
            logging.info("✅ Database connection and simple query successful")
        finally:
            with suppress(Exception):
                session.close()
            db_session_factory.remove()
    finally:
        # Restore original env var
        if original_db_url is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = original_db_url


def test_database_health_check():
    """Test the Database health check functionality."""
    print("🧪 Testing Database Health Check")
    print("=" * 50)

    # Test 1: Valid/Current DB configuration (may succeed if DB is running)
    print("\n1️⃣ Testing with current DATABASE_URL configuration...")
    try:
        current_db_url = os.environ.get(
            "DATABASE_URL",
            "postgresql://postgres:postgres@localhost:5432/plosolver",
        )
        print(f"   DATABASE_URL: {current_db_url}")
        _try_db_connection(current_db_url)
        print("   ✅ Database health check attempt completed (success if DB reachable)")
    except (SQLAlchemyError, DBAPIError, OperationalError, ValueError) as e:
        print(f"   ❌ Database health check failed: {e}")
        print("   This is expected if the database is not running or misconfigured.")

    # Test 2: Missing DATABASE_URL should raise ValueError
    print("\n2️⃣ Testing with missing DATABASE_URL (expect failure)...")
    try:
        from celery_worker.tasks import get_db_session

        original_db_url = os.environ.get("DATABASE_URL")
        try:
            os.environ["DATABASE_URL"] = "NOT_SET"
            try:
                get_db_session()
                print("   ❌ This should not be reached (expected ValueError)")
            except ValueError as e:
                print(f"   ✅ Correctly failed for missing DATABASE_URL: {e}")
        finally:
            if original_db_url is None:
                os.environ.pop("DATABASE_URL", None)
            else:
                os.environ["DATABASE_URL"] = original_db_url
    except (SQLAlchemyError, DBAPIError, OperationalError, ValueError) as e:
        print(f"   ❌ Unexpected error: {e}")

    # Test 3: Invalid URL format should raise ValueError
    print("\n3️⃣ Testing with invalid DATABASE_URL format (expect failure)...")
    try:
        from celery_worker.tasks import get_db_session

        original_db_url = os.environ.get("DATABASE_URL")
        try:
            os.environ["DATABASE_URL"] = "invalid-url"
            try:
                get_db_session()
                print("   ❌ This should not be reached (expected ValueError)")
            except ValueError as e:
                print(f"   ✅ Correctly failed for invalid format: {e}")
        finally:
            if original_db_url is None:
                os.environ.pop("DATABASE_URL", None)
            else:
                os.environ["DATABASE_URL"] = original_db_url
    except (SQLAlchemyError, DBAPIError, OperationalError, ValueError) as e:
        print(f"   ❌ Unexpected error: {e}")

    # Test 4: Unreachable database URL (valid format but wrong host/port)
    print("\n4️⃣ Testing with unreachable database URL (may fail to connect)...")
    try:
        unreachable_url = "postgresql://postgres:postgres@localhost:9999/plosolver"
        print(f"   DATABASE_URL: {unreachable_url}")
        _try_db_connection(unreachable_url)
        print("   ❌ This likely should not be reached if DB is not running on port 9999")
    except (SQLAlchemyError, DBAPIError, OperationalError) as e:
        print(f"   ✅ Correctly failed to connect to unreachable DB: {e}")

    print("\n" + "=" * 50)
    print("🏁 Database Health Check Test Complete")


if __name__ == "__main__":
    test_database_health_check()
