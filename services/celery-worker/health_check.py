#!/usr/bin/env python3
"""
Celery Health Check Script
This script checks if the Celery worker is healthy by using Celery's control API.
"""

import os
import sys
import time

# Add the celery-worker directory to Python path
sys.path.insert(0, "/app/celery-worker")

try:
    from celery_worker.celery_app import celery
except ImportError:
    # Fallback for different import paths
    try:
        from src.celery_worker.celery_app import celery
    except ImportError:
        print("ERROR: Could not import celery app")
        sys.exit(1)


def check_celery_health():
    """Check if Celery worker is healthy."""
    try:
        # Try to ping the worker
        result = celery.control.ping(timeout=2.0)

        if result:
            print(f"✅ Celery worker is healthy. Found {len(result)} worker(s)")
            # result is a list of worker names that responded
            for worker in result:
                print(f"   Worker: {worker}")
            return True
        else:
            print("❌ No Celery workers responded to ping")
            return False

    except Exception as e:
        print(f"❌ Celery health check failed: {e}")
        return False


def check_rabbitmq_connection():
    """Check if RabbitMQ connection is working."""
    try:
        # Try to get broker info
        info = celery.control.inspect().stats()
        if info:
            print("✅ RabbitMQ connection is working")
            return True
        else:
            print("❌ RabbitMQ connection failed - no stats available")
            return False
    except Exception as e:
        print(f"❌ RabbitMQ connection check failed: {e}")
        return False


def main():
    """Main health check function."""
    print("🔧 Celery Health Check")
    print("=" * 30)

    # Check environment
    print(f"Environment: {os.getenv('ENVIRONMENT', 'unknown')}")
    print(f"Broker URL: {os.getenv('CELERY_BROKER_URL', 'not set')}")

    # Wait a bit for Celery to start up
    time.sleep(1)

    # Check RabbitMQ connection first
    rabbitmq_ok = check_rabbitmq_connection()

    # Check Celery worker health
    celery_ok = check_celery_health()

    if rabbitmq_ok and celery_ok:
        print("✅ All health checks passed")
        sys.exit(0)
    else:
        print("❌ Health checks failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
