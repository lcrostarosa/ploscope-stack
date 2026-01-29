import time
from functools import wraps
from typing import Callable, Dict, Optional

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)

# Import redis at module level for testing
try:
    import redis
except ImportError:
    redis = None


class RateLimitExceeded(Exception):
    """Raised when a rate limit is exceeded."""

    def __init__(self, rate_limit_info: Dict[str, int]):
        super().__init__("Rate limit exceeded")
        self.rate_limit_info = rate_limit_info


class RateLimiter:
    def __init__(self, redis_client=None, default_limits=None):
        self.redis_client = redis_client
        self.default_limits = default_limits or {
            "default": {"requests": 100, "window": 3600},  # 100 requests per hour
            "auth": {"requests": 5, "window": 300},  # 5 auth attempts per 5 minutes
            "upload": {"requests": 10, "window": 3600},  # 10 uploads per hour
            "simulation": {"requests": 50, "window": 3600},  # 50 simulations per hour
        }

        # Fallback to in-memory storage if Redis not available
        self.memory_store = {}
        self.cleanup_interval = 300  # 5 minutes
        self.last_cleanup = time.time()

    def get_client_identifier(
        self, *, user_id: Optional[str] = None, ip: Optional[str] = None, forwarded_for: Optional[str] = None
    ) -> str:
        """Get unique identifier for the client without framework dependencies.

        Priority:
        1) user_id provided and not Anonymous
        2) first IP from forwarded_for
        3) provided ip
        4) fallback to Anonymous
        """
        if user_id and user_id != "Anonymous":
            return f"user:{user_id}"

        candidate_ip = None
        if forwarded_for:
            candidate_ip = forwarded_for.split(",")[0].strip()
        elif ip:
            candidate_ip = ip

        if candidate_ip:
            return f"ip:{candidate_ip}"

        return "user:Anonymous"

    def get_rate_limit_key(self, client_id, endpoint, rate_type="default"):
        """Generate Redis key for rate limiting."""
        timestamp_window = int(time.time() // self.default_limits[rate_type]["window"])
        return f"rate_limit:{rate_type}:{client_id}:{endpoint}:{timestamp_window}"

    def check_rate_limit(self, endpoint: str, rate_type: str = "default", client_id: Optional[str] = None):
        """Check if request is within rate limits."""
        try:
            client_id = client_id or self.get_client_identifier()
            limits = self.default_limits.get(rate_type, self.default_limits["default"])

            if self.redis_client:
                return self._check_redis_rate_limit(client_id, endpoint, rate_type, limits)
            else:
                return self._check_memory_rate_limit(client_id, endpoint, rate_type, limits)

        except (KeyError, AttributeError, RuntimeError, TypeError, ValueError) as e:
            logger.error("Rate limiting error: %s", e)
            # Fail open - allow request if rate limiting fails
            return True, {}

    def _check_redis_rate_limit(self, client_id, endpoint, rate_type, limits):
        """Check rate limit using Redis."""
        key = self.get_rate_limit_key(client_id, endpoint, rate_type)
        window = limits["window"]
        max_requests = limits["requests"]

        try:
            # Use Redis pipeline for atomic operations
            pipe = self.redis_client.pipeline()

            # Increment counter
            pipe.incr(key)
            pipe.expire(key, window)

            results = pipe.execute()
            current_requests = results[0]

            # Calculate remaining requests and reset time
            remaining = max(0, max_requests - current_requests)
            reset_time = int(time.time()) + window

            rate_limit_info = {
                "limit": max_requests,
                "remaining": remaining,
                "reset": reset_time,
                "window": window,
            }

            # Check if limit exceeded
            if current_requests > max_requests:
                logger.warning("Rate limit exceeded for %s on %s", client_id, endpoint)
                return False, rate_limit_info

            return True, rate_limit_info

        except (ConnectionError, OSError, RuntimeError, ValueError, TypeError) as e:
            logger.error("Redis rate limiting error: %s", e)
            return True, {}

    def _check_memory_rate_limit(self, client_id, endpoint, rate_type, limits):
        """Check rate limit using in-memory storage (fallback)"""
        current_time = time.time()
        window = limits["window"]
        max_requests = limits["requests"]

        # Cleanup old entries periodically
        if current_time - self.last_cleanup > self.cleanup_interval:
            self._cleanup_memory_store()
            self.last_cleanup = current_time

        # Create key for this client/endpoint/rate_type combination
        key = f"{rate_type}:{client_id}:{endpoint}"

        if key not in self.memory_store:
            self.memory_store[key] = []

        # Remove old timestamps outside the window
        self.memory_store[key] = [
            timestamp for timestamp in self.memory_store[key] if current_time - timestamp < window
        ]

        # Add current timestamp
        self.memory_store[key].append(current_time)

        current_requests = len(self.memory_store[key])
        remaining = max(0, max_requests - current_requests)
        reset_time = int(current_time + window)

        rate_limit_info = {
            "limit": max_requests,
            "remaining": remaining,
            "reset": reset_time,
            "window": window,
        }

        if current_requests > max_requests:
            logger.warning("Rate limit exceeded for %s on %s", client_id, endpoint)
            return False, rate_limit_info

        return True, rate_limit_info

    def _cleanup_memory_store(self):
        """Clean up old entries from memory store."""
        current_time = time.time()
        max_age = max(limit["window"] for limit in self.default_limits.values())

        keys_to_remove = []
        for key, timestamps in self.memory_store.items():
            # Remove timestamps older than the maximum window
            self.memory_store[key] = [timestamp for timestamp in timestamps if current_time - timestamp < max_age]
            # Remove empty entries
            if not self.memory_store[key]:
                keys_to_remove.append(key)

        for key in keys_to_remove:
            del self.memory_store[key]

    def get_rate_limit_headers(self, rate_limit_info):
        """Generate HTTP headers for rate limiting info."""
        if not rate_limit_info:
            return {}

        return {
            "X-RateLimit-Limit": str(rate_limit_info.get("limit", "")),
            "X-RateLimit-Remaining": str(rate_limit_info.get("remaining", "")),
            "X-RateLimit-Reset": str(rate_limit_info.get("reset", "")),
            "X-RateLimit-Window": str(rate_limit_info.get("window", "")),
        }


def init_rate_limiter(config: Optional[Dict] = None, *, redis_url: Optional[str] = None) -> RateLimiter:
    """Initialize rate limiter using plain configuration.

    Args:
        config: Dict of custom limits under key RATE_LIMITS, optional.
        redis_url: Redis connection URL, optional.
    """
    # Try to connect to Redis
    redis_client = None

    if redis_url and redis:
        try:
            redis_client = redis.from_url(redis_url)
            # Test connection
            redis_client.ping()
            logger.info("Rate limiter initialized with Redis backend")
        except (ConnectionError, OSError, RuntimeError, ValueError) as e:
            logger.warning("Failed to connect to Redis, using in-memory fallback: %s", e)
            redis_client = None

    # Custom rate limits from config
    custom_limits = (config or {}).get("RATE_LIMITS", {})
    default_limits = {
        "default": {"requests": 100, "window": 3600},
        "auth": {"requests": 5, "window": 300},
        "upload": {"requests": 10, "window": 3600},
        "simulation": {"requests": 50, "window": 3600},
        **custom_limits,
    }

    return RateLimiter(redis_client, default_limits)


def rate_limit(
    rate_type: str = "default",
    endpoint: Optional[str] = None,
    *,
    rate_limiter_instance: Optional[RateLimiter] = None,
    client_id_provider: Optional[Callable[[], str]] = None,
    on_limit_exceeded: Optional[Callable[[Dict[str, int]], object]] = None,
):
    """Decorator to apply rate limiting in a framework-agnostic way.

    - client_id_provider: callable returning a stable client identifier.
    - on_limit_exceeded: optional callback receiving rate_info; if not provided, raises RateLimitExceeded.
    """

    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            rl = rate_limiter_instance
            if not rl:
                logger.warning("Rate limiter not initialized, allowing call")
                return f(*args, **kwargs)

            endpoint_name = endpoint or f.__name__
            client_id = client_id_provider() if client_id_provider else None

            allowed, rate_info = rl.check_rate_limit(endpoint_name, rate_type, client_id)

            if not allowed:
                if on_limit_exceeded:
                    return on_limit_exceeded(rate_info)
                raise RateLimitExceeded(rate_info)

            return f(*args, **kwargs)

        return wrapper

    return decorator


# Convenience decorators for common rate limits
def auth_rate_limit(f):
    """Rate limit for authentication endpoints."""
    return rate_limit("auth")(f)


def upload_rate_limit(f):
    """Rate limit for file upload endpoints."""
    return rate_limit("upload")(f)


def simulation_rate_limit(f):
    """Rate limit for simulation endpoints."""
    return rate_limit("simulation")(f)
