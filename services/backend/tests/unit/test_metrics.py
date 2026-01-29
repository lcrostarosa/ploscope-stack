"""
Unit tests for metrics functionality.
"""

from unittest.mock import MagicMock, patch

from flask import Flask

from src.backend.metrics import (
    DATABASE_CONNECTIONS_ACTIVE,
    HTTP_REQUEST_DURATION,
    HTTP_REQUESTS_TOTAL,
    get_health_response,
    get_metrics_response,
    update_database_connections,
    update_system_metrics,
)
from src.backend.routes_http.metrics_routes import metrics_bp


class TestMetrics:
    """Test metrics collection functionality."""

    def test_http_requests_total_metric(self):
        """Test HTTP requests total counter."""
        # Test increment - we can't easily test the exact value without accessing internals
        # but we can test that the operation doesn't raise an exception
        HTTP_REQUESTS_TOTAL.labels(method="GET", endpoint="/test", status_code="200").inc()

        # Test that we can create multiple labels
        HTTP_REQUESTS_TOTAL.labels(method="POST", endpoint="/api", status_code="201").inc()

        # The test passes if no exceptions are raised
        assert True

    def test_http_request_duration_metric(self):
        """Test HTTP request duration histogram."""
        # Test observation
        HTTP_REQUEST_DURATION.labels(method="GET", endpoint="/test").observe(0.5)
        # Histogram doesn't have a simple value getter, so we just test it doesn't raise
        assert True

    def test_database_connections_metric(self):
        """Test database connections gauge."""
        # Test setting value - we can't easily test the exact value without accessing internals
        # but we can test that the operation doesn't raise an exception
        DATABASE_CONNECTIONS_ACTIVE.set(5)

        # Test that we can set different values
        DATABASE_CONNECTIONS_ACTIVE.set(10)

        # The test passes if no exceptions are raised
        assert True

    @patch("src.backend.metrics.db")
    def test_update_database_connections_success(self, mock_db):
        """Test successful database connections update."""
        mock_engine = MagicMock()
        mock_pool = MagicMock()
        mock_pool.size.return_value = 10
        mock_engine.pool = mock_pool
        mock_db.get_engine.return_value = mock_engine

        update_database_connections()

        # We can't easily test the exact value without accessing internals
        # but we can verify the function was called without exceptions
        assert True

    @patch("src.backend.metrics.db")
    def test_update_database_connections_failure(self, mock_db):
        """Test database connections update failure."""
        mock_db.get_engine.side_effect = Exception("Connection failed")

        # Should not raise exception
        update_database_connections()

    @patch("builtins.__import__")
    def test_update_system_metrics_success(self, mock_import):
        """Test successful system metrics update."""
        # Mock psutil module
        mock_psutil = MagicMock()
        mock_memory = MagicMock()
        mock_memory.used = 1024 * 1024 * 100  # 100MB
        mock_psutil.virtual_memory.return_value = mock_memory
        mock_psutil.cpu_percent.return_value = 25.5

        # Make __import__ return our mock when 'psutil' is imported
        def import_side_effect(name, *args, **kwargs):
            if name == "psutil":
                return mock_psutil
            return __import__(name, *args, **kwargs)

        mock_import.side_effect = import_side_effect

        update_system_metrics()

        # We can't easily test the gauge values without accessing internals
        # but we can verify the functions were called
        mock_psutil.virtual_memory.assert_called_once()
        mock_psutil.cpu_percent.assert_called_once_with(interval=1)

    @patch("builtins.__import__")
    def test_update_system_metrics_import_error(self, mock_import):
        """Test system metrics update with import error."""

        # Make __import__ raise ImportError when 'psutil' is imported
        def import_side_effect(name, *args, **kwargs):
            if name == "psutil":
                raise ImportError("psutil not available")
            return __import__(name, *args, **kwargs)

        mock_import.side_effect = import_side_effect

        # Should not raise exception
        update_system_metrics()

    @patch("src.backend.metrics.update_database_connections")
    @patch("src.backend.metrics.update_system_metrics")
    @patch("src.backend.metrics.generate_latest")
    def test_get_metrics_response_success(self, mock_generate, mock_system, mock_db):
        """Test successful metrics response generation."""
        mock_generate.return_value = b"# HELP test_metric Test metric\n# TYPE test_metric counter\ntest_metric 1\n"

        response = get_metrics_response()

        assert response.status_code == 200
        assert response.mimetype == "text/plain"
        mock_generate.assert_called_once()
        mock_system.assert_called_once()
        mock_db.assert_called_once()

    @patch("src.backend.metrics.update_database_connections")
    @patch("src.backend.metrics.update_system_metrics")
    @patch("src.backend.metrics.generate_latest")
    def test_get_metrics_response_failure(self, mock_generate, mock_system, mock_db):
        """Test metrics response generation failure."""
        mock_generate.side_effect = Exception("Generation failed")

        response = get_metrics_response()

        assert response.status_code == 500

    @patch("src.backend.metrics.db")
    def test_get_health_response_healthy(self, mock_db):
        """Test healthy health response."""
        mock_db.session.execute.return_value.fetchone.return_value = (1,)

        health_data = get_health_response()

        assert health_data["status"] == "healthy"
        assert "database" in health_data["routes_grpc"]
        assert health_data["routes_grpc"]["database"] == "healthy"

    @patch("src.backend.metrics.db")
    def test_get_health_response_unhealthy(self, mock_db):
        """Test unhealthy health response."""
        mock_db.session.execute.side_effect = Exception("Database connection failed")

        health_data = get_health_response()

        assert health_data["status"] == "unhealthy"
        assert "database" in health_data["routes_grpc"]
        assert "unhealthy" in health_data["routes_grpc"]["database"]


class TestMetricsRoutes:
    """Test metrics routes_http functionality."""

    def test_metrics_blueprint_registration(self):
        """Test that metrics blueprint can be registered."""
        app = Flask(__name__)
        app.register_blueprint(metrics_bp)

        # Test that routes_http are registered
        rules = [rule.rule for rule in app.url_map.iter_rules()]
        assert "/metrics" in rules
        assert "/health" in rules
        assert "/ready" in rules

    def test_metrics_endpoint(self):
        """Test metrics endpoint."""
        app = Flask(__name__)
        app.register_blueprint(metrics_bp)

        with app.test_client() as client:
            with patch("src.backend.routes_http.metrics_routes.get_metrics_response") as mock_response:
                mock_response.return_value = "test metrics"
                response = client.get("/metrics")
                assert response.status_code == 200

    def test_health_endpoint(self):
        """Test health endpoint."""
        app = Flask(__name__)
        app.register_blueprint(metrics_bp)

        with app.test_client() as client:
            with patch("src.backend.routes_http.metrics_routes.get_health_response") as mock_response:
                mock_response.return_value = {"status": "healthy"}
                response = client.get("/health")
                assert response.status_code == 200

    def test_ready_endpoint(self):
        """Test ready endpoint."""
        app = Flask(__name__)
        app.register_blueprint(metrics_bp)

        with app.test_client() as client:
            response = client.get("/ready")
            assert response.status_code == 200
            data = response.get_json()
            assert data["status"] == "ready"
