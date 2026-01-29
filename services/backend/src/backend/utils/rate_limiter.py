import time
from functools import wraps

from core.utils.logging_utils import get_enhanced_logger
from flask import g, jsonify, request

logger = get_enhanced_logger(__name__)

# Import redis at module level for testing
try:
    import redis
except ImportError:
    redis = None


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

    def get_client_identifier(self):
        """Get unique identifier for the client."""
        # Use authenticated user ID if available
        if hasattr(g, "user_id") and g.user_id != "Anonymous":
            return f"user:{g.user_id}"

        # Fall back to IP address for anonymous users
        ip = request.environ.get("HTTP_X_FORWARDED_FOR", request.remote_addr)
        if "," in ip:  # Handle multiple IPs from proxy chains
            ip = ip.split(",")[0].strip()

        return f"ip:{ip}"

    def get_rate_limit_key(self, client_id, endpoint, rate_type="default"):
        """Generate Redis key for rate limiting."""
        timestamp_window = int(time.time() // self.default_limits[rate_type]["window"])
        return f"rate_limit:{rate_type}:{client_id}:{endpoint}:{timestamp_window}"

    def check_rate_limit(self, endpoint, rate_type="default"):
        """Check if request is within rate limits."""
        try:
            client_id = self.get_client_identifier()
            limits = self.default_limits.get(rate_type, self.default_limits["default"])

            if self.redis_client:
                return self._check_redis_rate_limit(client_id, endpoint, rate_type, limits)
            else:
                return self._check_memory_rate_limit(client_id, endpoint, rate_type, limits)

        except Exception as e:
            logger.error(f"Rate limiting error: {e}")
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
                logger.warning(f"Rate limit exceeded for {client_id} on {endpoint}")
                return False, rate_limit_info

            return True, rate_limit_info

        except Exception as e:
            logger.error(f"Redis rate limiting error: {e}")
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
            logger.warning(f"Rate limit exceeded for {client_id} on {endpoint}")
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


# Global rate limiter instance
rate_limiter = None


def init_rate_limiter(app):
    """Initialize rate limiter with Flask app."""
    global rate_limiter

    # Try to connect to Redis
    redis_client = None
    redis_url = app.config.get("REDIS_URL")

    if redis_url and redis:
        try:
            redis_client = redis.from_url(redis_url)
            # Test connection
            redis_client.ping()
            logger.info("Rate limiter initialized with Redis backend")
        except Exception as e:
            logger.warning(f"Failed to connect to Redis, using in-memory fallback: {e}")
            redis_client = None

    # Custom rate limits from config
    custom_limits = app.config.get("RATE_LIMITS", {})
    default_limits = {
        "default": {"requests": 100, "window": 3600},
        "auth": {"requests": 5, "window": 300},
        "upload": {"requests": 10, "window": 3600},
        "simulation": {"requests": 50, "window": 3600},
        **custom_limits,
    }

    rate_limiter = RateLimiter(redis_client, default_limits)
    return rate_limiter


def rate_limit(rate_type="default", endpoint=None):
    """Decorator to apply rate limiting to Flask routes."""

    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            # Skip rate limiting for OPTIONS requests
            if request.method == "OPTIONS":
                return f(*args, **kwargs)

            if not rate_limiter:
                logger.warning("Rate limiter not initialized, allowing request")
                return f(*args, **kwargs)

            # Use endpoint name if not specified
            endpoint_name = endpoint or request.endpoint or f.__name__

            # Check rate limit
            allowed, rate_info = rate_limiter.check_rate_limit(endpoint_name, rate_type)

            if not allowed:
                response = jsonify(
                    {
                        "error": "Rate limit exceeded",
                        "message": f'Too many requests. Try again in {rate_info.get("window", 0)} seconds.',
                        "rate_limit": rate_info,
                    }
                )
                response.status_code = 429

                # Add rate limit headers
                headers = rate_limiter.get_rate_limit_headers(rate_info)
                for key, value in headers.items():
                    response.headers[key] = value

                return response

            # Execute the wrapped function
            response = f(*args, **kwargs)

            # Add rate limit headers to successful responses
            if hasattr(response, "headers"):
                headers = rate_limiter.get_rate_limit_headers(rate_info)
                for key, value in headers.items():
                    response.headers[key] = value

            return response

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
