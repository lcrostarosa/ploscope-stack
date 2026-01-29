#!/usr/bin/env python3
"""
Test script to demonstrate Redis health check functionality.
This script will test the Redis connection and show how the application
fails fast when Redis is unavailable.
"""

import logging
import os
import sys

# Add src to path so we can import our modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

# Configure logging to see the health check messages
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")


def test_redis_health_check():
    """Test the Redis health check functionality."""
    print("🧪 Testing Redis Health Check")
    print("=" * 50)

    # Test 1: Valid Redis connection (if Redis is running)
    print("\n1️⃣ Testing with current Redis configuration...")
    try:
        from celery_worker.celery_app import check_redis_connection

        # Get the current Redis URL from environment
        redis_url = os.environ.get("CELERY_RESULT_BACKEND", "redis://localhost:6379/0")
        print(f"   Redis URL: {redis_url}")

        check_redis_connection(redis_url)
        print("   ✅ Redis health check passed!")

    except SystemExit as e:
        print(f"   ❌ Redis health check failed with exit code: {e.code}")
        print("   This is expected if Redis is not running or misconfigured.")
    except Exception as e:
        print(f"   ❌ Unexpected error: {e}")

    # Test 2: Invalid Redis connection (simulate Redis down)
    print("\n2️⃣ Testing with invalid Redis URL...")
    try:
        from celery_worker.celery_app import check_redis_connection

        # Use an invalid Redis URL
        invalid_redis_url = "redis://localhost:9999/0"  # Non-existent port
        print(f"   Invalid Redis URL: {invalid_redis_url}")

        check_redis_connection(invalid_redis_url)
        print("   ❌ This should not be reached!")

    except SystemExit as e:
        print(f"   ✅ Redis health check correctly failed with exit code: {e.code}")
        print("   This demonstrates the fail-fast behavior.")
    except Exception as e:
        print(f"   ❌ Unexpected error: {e}")

    # Test 3: Non-Redis backend (should be skipped)
    print("\n3️⃣ Testing with non-Redis backend...")
    try:
        from celery_worker.celery_app import check_redis_connection

        # Use a non-Redis backend
        non_redis_url = "rpc://"
        print(f"   Non-Redis URL: {non_redis_url}")

        check_redis_connection(non_redis_url)
        print("   ✅ Non-Redis backend correctly skipped!")

    except SystemExit as e:
        print(f"   ❌ Unexpected failure: {e}")
    except Exception as e:
        print(f"   ❌ Unexpected error: {e}")

    print("\n" + "=" * 50)
    print("🏁 Redis Health Check Test Complete")
    print("\nTo test with your actual Redis setup:")
    print("1. Make sure Redis is running: redis-server")
    print("2. Start your Celery worker: celery -A celery_worker.celery_app worker --loglevel=info")
    print("3. The worker will now fail fast if Redis is not accessible!")


if __name__ == "__main__":
    test_redis_health_check()
