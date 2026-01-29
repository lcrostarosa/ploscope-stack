"""
Integration tests for Redis authentication functionality.
These tests require a real Redis instance to be running.
"""

import os
import time
from unittest.mock import Mock, patch

import pytest
import redis

from src.backend.utils.rate_limiter import RateLimiter, init_rate_limiter


@pytest.mark.integration
class TestRedisAuthenticationIntegration:
    """Integration tests for Redis authentication with real Redis instance."""

    @pytest.fixture(scope="class")
    def redis_with_auth(self):
        """Set up Redis with authentication for testing."""
        # Use the same password as in docker-compose.yml
        password = "dev_redis_password_2024"
        redis_url = f"redis://:{password}@localhost:6379/0"

        try:
            # Test connection
            client = redis.from_url(redis_url)
            client.ping()
            yield client
        except redis.ConnectionError:
            pytest.skip("Redis server not available for integration testing")
        except redis.AuthenticationError:
            pytest.skip("Redis authentication failed - check password configuration")
        finally:
            # Clean up any test keys
            try:
                client = redis.from_url(redis_url)
                # Delete any test keys that might have been created
                keys = client.keys("rate_limit:test_*")
                if keys:
                    client.delete(*keys)
                # Also clean up any keys with test_client in them
                keys = client.keys("rate_limit:*test_client*")
                if keys:
                    client.delete(*keys)
            except Exception:
                pass  # Ignore cleanup errors

    @pytest.fixture(scope="class")
    def redis_without_auth(self):
        """Set up Redis without authentication for testing."""
        redis_url = "redis://localhost:6379/0"

        try:
            # Test connection
            client = redis.from_url(redis_url)
            client.ping()
            yield client
        except redis.ConnectionError:
            pytest.skip("Redis server not available for integration testing")
        except redis.AuthenticationError:
            pytest.skip("Redis requires authentication - this is expected")
        finally:
            # Clean up any test keys
            try:
                client = redis.from_url(redis_url)
                keys = client.keys("rate_limit:test_*")
                if keys:
                    client.delete(*keys)
            except Exception:
                pass  # Ignore cleanup errors

    def test_redis_connection_with_correct_password(self, redis_with_auth):
        """Test Redis connection with correct password."""
        # This should work
        result = redis_with_auth.ping()
        assert result is True

        # Test basic operations
        redis_with_auth.set("test_key", "test_value", ex=10)
        value = redis_with_auth.get("test_key")
        assert value.decode() == "test_value"

        # Clean up
        redis_with_auth.delete("test_key")

    def test_redis_connection_with_incorrect_password(self):
        """Test Redis connection with incorrect password."""
        redis_url = "redis://:wrong_password@localhost:6379/0"

        with pytest.raises(redis.AuthenticationError):
            client = redis.from_url(redis_url)
            client.ping()

    def test_redis_connection_without_password(self):
        """Test Redis connection without password."""
        redis_url = "redis://localhost:6379/0"

        with pytest.raises(redis.AuthenticationError):
            client = redis.from_url(redis_url)
            client.ping()

    def test_rate_limiter_with_authenticated_redis(self, redis_with_auth):
        """Test rate limiter with authenticated Redis."""
        # Create rate limiter with authenticated Redis
        rate_limiter = RateLimiter(redis_with_auth)

        # Mock the get_client_identifier method
        import time

        unique_client_id = f"test_client_integration_{int(time.time())}"
        with patch.object(rate_limiter, "get_client_identifier", return_value=unique_client_id):
            # Test rate limit check
            result, rate_info = rate_limiter.check_rate_limit("test_endpoint", "default")

            # Should succeed
            assert result is True
            assert isinstance(rate_info, dict)
            assert "limit" in rate_info
            assert "remaining" in rate_info
            assert "reset" in rate_info

            # Test multiple requests to see rate limiting in action
            for i in range(5):
                result, rate_info = rate_limiter.check_rate_limit("test_endpoint", "default")
                assert result is True
                assert rate_info["remaining"] >= 80  # Should have plenty of requests left (allowing for some variance)

    def test_rate_limiter_redis_operations_integration(self, redis_with_auth):
        """Test rate limiter Redis operations with real Redis."""
        rate_limiter = RateLimiter(redis_with_auth)

        import time

        unique_client_id = f"test_client_ops_{int(time.time())}"
        with patch.object(rate_limiter, "get_client_identifier", return_value=unique_client_id):
            # Test with a very restrictive limit
            custom_limits = {"test": {"requests": 2, "window": 60}}  # Only 2 requests per minute
            rate_limiter.default_limits.update(custom_limits)

            # First request should succeed
            result1, info1 = rate_limiter.check_rate_limit("test_endpoint", "test")
            assert result1 is True
            assert info1["remaining"] == 1

            # Second request should succeed
            result2, info2 = rate_limiter.check_rate_limit("test_endpoint", "test")
            assert result2 is True
            assert info2["remaining"] == 0

            # Third request should fail
            result3, info3 = rate_limiter.check_rate_limit("test_endpoint", "test")
            assert result3 is False
            assert info3["remaining"] == 0

    def test_redis_key_expiration(self, redis_with_auth):
        """Test that Redis keys expire properly."""
        rate_limiter = RateLimiter(redis_with_auth)

        with patch.object(rate_limiter, "get_client_identifier", return_value="test_client_expiry"):
            # Use a very short window for testing
            custom_limits = {"expiry_test": {"requests": 1, "window": 1}}  # 1 request per second
            rate_limiter.default_limits.update(custom_limits)

            # First request should succeed
            result1, _ = rate_limiter.check_rate_limit("test_endpoint", "expiry_test")
            assert result1 is True

            # Second request should fail (within window)
            result2, _ = rate_limiter.check_rate_limit("test_endpoint", "expiry_test")
            assert result2 is False

            # Wait for window to expire
            time.sleep(1.1)

            # Third request should succeed (after window expired)
            result3, _ = rate_limiter.check_rate_limit("test_endpoint", "expiry_test")
            assert result3 is True

    def test_redis_authentication_error_handling(self):
        """Test that authentication errors are handled gracefully."""
        # Mock Flask app with incorrect Redis URL
        mock_app = Mock()
        mock_app.config = {"REDIS_URL": "redis://:wrong_password@localhost:6379/0"}

        # Initialize rate limiter - should fall back to in-memory
        rate_limiter = init_rate_limiter(mock_app)

        # Should fall back to in-memory storage
        assert rate_limiter.redis_client is None
        assert hasattr(rate_limiter, "memory_store")

    def test_redis_connection_timeout(self):
        """Test Redis connection timeout handling."""
        # Mock Flask app with unreachable Redis URL
        mock_app = Mock()
        mock_app.config = {"REDIS_URL": "redis://:password@unreachable-host:6379/0"}

        # Initialize rate limiter - should fall back to in-memory
        rate_limiter = init_rate_limiter(mock_app)

        # Should fall back to in-memory storage
        assert rate_limiter.redis_client is None
        assert hasattr(rate_limiter, "memory_store")

    def test_redis_environment_configuration(self, redis_with_auth):
        """Test Redis configuration from environment variables."""
        # Set environment variables
        test_env = {
            "REDIS_PASSWORD": "dev_redis_password_2024",
            "REDIS_URL": "redis://:dev_redis_password_2024@localhost:6379/0",
        }

        with patch.dict(os.environ, test_env):
            mock_app = Mock()
            mock_app.config = {"REDIS_URL": os.environ.get("REDIS_URL")}

            # Initialize rate limiter
            rate_limiter = init_rate_limiter(mock_app)

            # Should successfully connect to Redis
            assert rate_limiter.redis_client is not None

            # Test basic operation
            with patch.object(rate_limiter, "get_client_identifier", return_value="test_env_client"):
                result, rate_info = rate_limiter.check_rate_limit("test_endpoint", "default")
                assert result is True
                assert isinstance(rate_info, dict)

    def test_redis_pipeline_operations(self, redis_with_auth):
        """Test Redis pipeline operations for rate limiting."""
        rate_limiter = RateLimiter(redis_with_auth)

        with patch.object(rate_limiter, "get_client_identifier", return_value="test_pipeline_client"):
            # Test multiple rapid requests to verify pipeline operations
            results = []
            for i in range(10):
                result, rate_info = rate_limiter.check_rate_limit("test_endpoint", "default")
                results.append((result, rate_info))

            # All should succeed (within default limits)
            for result, rate_info in results:
                assert result is True
                assert isinstance(rate_info, dict)
                assert "limit" in rate_info
                assert "remaining" in rate_info

    def test_redis_memory_fallback_comparison(self, redis_with_auth):
        """Test that Redis and memory fallback produce consistent results."""
        # Test with Redis
        redis_rate_limiter = RateLimiter(redis_with_auth)

        # Test with memory fallback
        memory_rate_limiter = RateLimiter(None)

        with patch.object(redis_rate_limiter, "get_client_identifier", return_value="test_comparison_client"):
            with patch.object(memory_rate_limiter, "get_client_identifier", return_value="test_comparison_client"):
                # Both should return similar structure
                redis_result, redis_info = redis_rate_limiter.check_rate_limit("test_endpoint", "default")
                memory_result, memory_info = memory_rate_limiter.check_rate_limit("test_endpoint", "default")

                # Both should succeed
                assert redis_result is True
                assert memory_result is True

                # Both should return dictionaries with similar keys
                assert isinstance(redis_info, dict)
                assert isinstance(memory_info, dict)
                assert "limit" in redis_info
                assert "limit" in memory_info
                assert "remaining" in redis_info
                assert "remaining" in memory_info
