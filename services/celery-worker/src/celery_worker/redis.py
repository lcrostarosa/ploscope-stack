import sys

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)
from urllib.parse import urlparse

import redis


def check_redis_connection(backend_url: str) -> None:
    """
    Check Redis connection on startup and fail hard if connection fails.

    Args:
        backend_url: The Redis URL to test connection to

    Raises:
        SystemExit: If Redis connection fails
    """
    # Only check Redis connections, skip other backends
    if not backend_url.startswith("redis://"):
        logger.info("Skipping Redis health check - backend is not Redis: %s", backend_url)
        return

    try:
        # Parse Redis URL
        parsed = urlparse(backend_url)
        host = parsed.hostname or "localhost"
        port = parsed.port or 6379
        password = parsed.password
        db = int(parsed.path.lstrip("/")) if parsed.path else 0

        logger.info("Testing Redis connection to %s:%s (db=%s)", host, port, db)

        # Create Redis client
        redis_client = redis.Redis(
            host=host,
            port=port,
            password=password,
            db=db,
            socket_connect_timeout=5,  # 5 second timeout
            socket_timeout=5,
            retry_on_timeout=False,
            decode_responses=True,
        )

        # Test connection with ping
        redis_client.ping()
        logger.info("✅ Redis connection successful")

        # Test basic operations
        test_key = "celery_worker_health_check"
        redis_client.set(test_key, "test_value", ex=10)  # Expire in 10 seconds
        redis_client.get(test_key)
        redis_client.delete(test_key)
        logger.info("✅ Redis read/write operations successful")

    except redis.ConnectionError as e:  # type: ignore[name-defined]
        logger.error("❌ Redis connection failed: %s", str(e))
        logger.error("   Check that Redis is running and accessible at %s:%s", host, port)
        if password:
            logger.error("   Verify Redis password is correct")
        sys.exit(1)
    except redis.AuthenticationError as e:  # type: ignore[name-defined]
        logger.error("❌ Redis authentication failed: %s", str(e))
        logger.error("   Check Redis password configuration")
        sys.exit(1)
    except (ValueError, TypeError) as e:
        logger.error("❌ Redis health check failed with configuration error: %s", str(e))
        sys.exit(1)
