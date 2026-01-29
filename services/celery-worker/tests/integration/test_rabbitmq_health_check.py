#!/usr/bin/env python3
"""
Test script to demonstrate RabbitMQ health check functionality.
This script will test the RabbitMQ connection via the Celery inspect stats
and show how the application behaves for valid and invalid configurations.
"""

import logging
import os
import sys

# Add project root to path so we can import health_check and celery app
sys.path.insert(0, os.path.dirname(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))


# Configure logging to see the health check messages
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")


def _print_broker_env():
    keys = [
        "CELERY_BROKER_URL",
        "RABBITMQ_DEFAULT_USER",
        "RABBITMQ_DEFAULT_PASS",
        "RABBITMQ_USERNAME",
        "RABBITMQ_PASSWORD",
        "RABBITMQ_HOST",
        "RABBITMQ_PORT",
        "RABBITMQ_DEFAULT_VHOST",
        "RABBITMQ_VHOST",
    ]
    for k in keys:
        v = os.environ.get(k, "<not set>")
        print(f"   {k} = {v}")


def test_rabbitmq_health_check():
    """Test the RabbitMQ health check functionality."""
    print("🧪 Testing RabbitMQ Health Check")
    print("=" * 50)

    from health_check import check_rabbitmq_connection

    # Test 1: With current environment
    print("\n1️⃣ Testing with current RabbitMQ configuration...")
    _print_broker_env()
    try:
        ok = check_rabbitmq_connection()
        if ok:
            print("   ✅ RabbitMQ health check passed!")
        else:
            print("   ❌ RabbitMQ health check returned false")
    except SystemExit as e:
        print(f"   ❌ RabbitMQ health check exited: {e}")
    except (ConnectionError, OSError, ValueError) as e:
        print(f"   ❌ Broker health check error: {e}")

    # Test 2: Invalid broker URL (simulate failure)
    print("\n2️⃣ Testing with invalid CELERY_BROKER_URL (expect failure)...")
    try:
        from src.celery_worker.celery_app import make_celery

        original_broker = os.environ.get("CELERY_BROKER_URL")
        try:
            os.environ["CELERY_BROKER_URL"] = "amqp://invalid:invalid@localhost:5673/invalid_vhost"
            # Recreate celery app with bad broker to test behavior
            _ = make_celery()
            ok = check_rabbitmq_connection()
            if ok:
                print("   ❌ This should likely not be reached with an invalid broker URL")
            else:
                print("   ✅ Correctly failed the health check with invalid broker settings")
        finally:
            if original_broker is None:
                os.environ.pop("CELERY_BROKER_URL", None)
            else:
                os.environ["CELERY_BROKER_URL"] = original_broker
    except (ConnectionError, OSError, ValueError) as e:
        print(f"   ✅ Caught expected failure when using invalid broker: {e}")

    print("\n" + "=" * 50)
    print("🏁 RabbitMQ Health Check Test Complete")


if __name__ == "__main__":
    test_rabbitmq_health_check()
