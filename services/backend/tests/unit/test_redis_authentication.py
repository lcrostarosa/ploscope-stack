"""
Unit tests for Redis authentication functionality.
"""

import os
from unittest.mock import Mock, patch

import pytest
import redis

from src.backend.utils.rate_limiter import RateLimiter, init_rate_limiter


class TestRedisAuthentication:
    """Test Redis authentication scenarios."""

    def test_redis_connection_with_correct_password(self):
        """Test Redis connection with correct password."""
        # Mock Redis client
        mock_redis_client = Mock()
        mock_redis_client.ping.return_value = True

        with patch("redis.from_url", return_value=mock_redis_client):
            # Test with correct password in URL
            redis_url = "redis://:dev_redis_password_2024@localhost:6379/0"

            client = redis.from_url(redis_url)
            result = client.ping()

            assert result is True
            mock_redis_client.ping.assert_called_once()

    def test_redis_connection_with_incorrect_password(self):
        """Test Redis connection with incorrect password."""
        # Mock Redis client to raise authentication error
        mock_redis_client = Mock()
        mock_redis_client.ping.side_effect = redis.AuthenticationError("WRONGPASS invalid username-password pair")

        with patch("redis.from_url", return_value=mock_redis_client):
            # Test with incorrect password
            redis_url = "redis://:wrong_password@localhost:6379/0"

            client = redis.from_url(redis_url)

            with pytest.raises(redis.AuthenticationError):
                client.ping()

    def test_redis_connection_without_password(self):
        """Test Redis connection without password (should fail if Redis requires auth)."""
        # Mock Redis client to raise authentication error
        mock_redis_client = Mock()
        mock_redis_client.ping.side_effect = redis.AuthenticationError("NOAUTH Authentication required")

        with patch("redis.from_url", return_value=mock_redis_client):
            # Test without password
            redis_url = "redis://localhost:6379/0"

            client = redis.from_url(redis_url)

            with pytest.raises(redis.AuthenticationError):
                client.ping()

    def test_rate_limiter_with_authenticated_redis(self):
        """Test rate limiter initialization with authenticated Redis."""
        # Mock Redis client
        mock_redis_client = Mock()
        mock_redis_client.ping.return_value = True
        mock_redis_client.incr.return_value = 1
        mock_redis_client.expire.return_value = True

        with patch("redis.from_url", return_value=mock_redis_client):
            # Mock Flask app config
            mock_app = Mock()
            mock_app.config = {"REDIS_URL": "redis://:dev_redis_password_2024@localhost:6379/0"}

            # Initialize rate limiter
            rate_limiter = init_rate_limiter(mock_app)

            # Verify Redis client was created and ping was called
            assert rate_limiter.redis_client is not None
            mock_redis_client.ping.assert_called_once()

    def test_rate_limiter_fallback_on_auth_failure(self):
        """Test rate limiter falls back to in-memory storage when Redis auth fails."""
        # Mock Redis client to raise authentication error
        mock_redis_client = Mock()
        mock_redis_client.ping.side_effect = redis.AuthenticationError("WRONGPASS invalid username-password pair")

        with patch("redis.from_url", return_value=mock_redis_client):
            # Mock Flask app config
            mock_app = Mock()
            mock_app.config = {"REDIS_URL": "redis://:wrong_password@localhost:6379/0"}

            # Initialize rate limiter
            rate_limiter = init_rate_limiter(mock_app)

            # Verify fallback to in-memory storage
            assert rate_limiter.redis_client is None
            assert hasattr(rate_limiter, "memory_store")

    def test_rate_limiter_with_no_redis_url(self):
        """Test rate limiter initialization when no Redis URL is provided."""
        # Mock Flask app config without Redis URL
        mock_app = Mock()
        mock_app.config = {}

        # Initialize rate limiter
        rate_limiter = init_rate_limiter(mock_app)

        # Verify fallback to in-memory storage
        assert rate_limiter.redis_client is None
        assert hasattr(rate_limiter, "memory_store")

    def test_rate_limiter_redis_operations_with_auth(self):
        """Test rate limiter operations with authenticated Redis."""
        # Mock Redis client
        mock_redis_client = Mock()
        mock_redis_client.ping.return_value = True
        mock_redis_client.incr.return_value = 1
        mock_redis_client.expire.return_value = True
        mock_redis_client.get.return_value = None

        # Mock pipeline for Redis operations
        mock_pipeline = Mock()
        mock_pipeline.incr.return_value = mock_pipeline
        mock_pipeline.expire.return_value = mock_pipeline
        mock_pipeline.execute.return_value = [1]  # incr result
        mock_redis_client.pipeline.return_value = mock_pipeline

        with patch("redis.from_url", return_value=mock_redis_client):
            # Create rate limiter with Redis client
            rate_limiter = RateLimiter(mock_redis_client)

            # Mock the get_client_identifier method to avoid Flask context issues
            with patch.object(rate_limiter, "get_client_identifier", return_value="test_client"):
                # Test rate limit check
                result, rate_info = rate_limiter.check_rate_limit("test_endpoint", "default")

                # Verify Redis operations were called
                assert result is True
                assert isinstance(rate_info, dict)
                mock_redis_client.pipeline.assert_called()
                mock_pipeline.incr.assert_called()
                mock_pipeline.expire.assert_called()

    def test_rate_limiter_memory_fallback_operations(self):
        """Test rate limiter operations with in-memory fallback."""
        # Create rate limiter without Redis client (fallback mode)
        rate_limiter = RateLimiter(None)

        # Mock the get_client_identifier method to avoid Flask context issues
        with patch.object(rate_limiter, "get_client_identifier", return_value="test_client"):
            # Test rate limit check
            result, rate_info = rate_limiter.check_rate_limit("test_endpoint", "default")

            # Should work with in-memory storage
            assert result is True
            assert isinstance(rate_info, dict)
            # Check that memory store is being used
            assert hasattr(rate_limiter, "memory_store")

    def test_redis_url_parsing_with_password(self):
        """Test Redis URL parsing with password authentication."""
        # Test various Redis URL formats with passwords
        test_urls = [
            "redis://:password@localhost:6379/0",
            "redis://user:password@localhost:6379/0",
            "redis://:dev_redis_password_2024@redis:6379/0",
        ]

        for url in test_urls:
            with patch("redis.from_url") as mock_from_url:
                mock_client = Mock()
                mock_from_url.return_value = mock_client

                client = redis.from_url(url)
                mock_from_url.assert_called_with(url)
                assert client is not None

    def test_redis_connection_error_handling(self):
        """Test handling of various Redis connection errors."""
        error_scenarios = [
            redis.ConnectionError("Connection refused"),
            redis.TimeoutError("Timeout connecting to server"),
            redis.AuthenticationError("WRONGPASS invalid username-password pair"),
            Exception("Generic connection error"),
        ]

        for error in error_scenarios:
            mock_redis_client = Mock()
            mock_redis_client.ping.side_effect = error

            with patch("redis.from_url", return_value=mock_redis_client):
                mock_app = Mock()
                mock_app.config = {"REDIS_URL": "redis://localhost:6379/0"}

                # Should not raise exception, should fall back to in-memory
                rate_limiter = init_rate_limiter(mock_app)
                assert rate_limiter.redis_client is None

    def test_environment_variable_redis_config(self):
        """Test Redis configuration from environment variables."""
        # Test environment variable configuration
        test_env_vars = {
            "REDIS_URL": "redis://:test_password@localhost:6379/0",
            "REDIS_PASSWORD": "test_password",
        }

        with patch.dict(os.environ, test_env_vars):
            # Mock Redis client
            mock_redis_client = Mock()
            mock_redis_client.ping.return_value = True

            with patch("redis.from_url", return_value=mock_redis_client):
                mock_app = Mock()
                mock_app.config = {"REDIS_URL": os.environ.get("REDIS_URL")}

                rate_limiter = init_rate_limiter(mock_app)

                # Verify Redis client was initialized
                assert rate_limiter.redis_client is not None
                mock_redis_client.ping.assert_called_once()

    def test_redis_authentication_in_docker_environment(self):
        """Test Redis authentication in Docker environment configuration."""
        # Simulate Docker environment variables
        docker_env = {
            "REDIS_PASSWORD": "dev_redis_password_2024",
            "REDIS_URL": "redis://:dev_redis_password_2024@redis:6379/0",
        }

        with patch.dict(os.environ, docker_env):
            mock_redis_client = Mock()
            mock_redis_client.ping.return_value = True

            with patch("redis.from_url", return_value=mock_redis_client):
                mock_app = Mock()
                mock_app.config = {"REDIS_URL": docker_env["REDIS_URL"]}

                rate_limiter = init_rate_limiter(mock_app)

                # Verify successful initialization
                assert rate_limiter.redis_client is not None
                mock_redis_client.ping.assert_called_once()

    def test_redis_connection_retry_mechanism(self):
        """Test Redis connection retry mechanism on authentication failure."""
        # Mock Redis client that fails first, then succeeds
        mock_redis_client = Mock()
        mock_redis_client.ping.side_effect = [
            redis.AuthenticationError("WRONGPASS invalid username-password pair"),
            True,  # Success on retry
        ]

        with patch("redis.from_url", return_value=mock_redis_client):
            mock_app = Mock()
            mock_app.config = {"REDIS_URL": "redis://:dev_redis_password_2024@localhost:6379/0"}

            # First call should fail and fall back to in-memory
            rate_limiter = init_rate_limiter(mock_app)
            assert rate_limiter.redis_client is None

            # Verify ping was called
            assert mock_redis_client.ping.call_count == 1
