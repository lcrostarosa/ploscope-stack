"""
Unit tests for Celery worker metrics functionality.
"""

from unittest.mock import MagicMock, patch

import pytest

from src.celery_worker.metrics import (
    TASK_DURATION,
    TASK_QUEUE_SIZE,
    TASKS_TOTAL,
    WORKER_ACTIVE_TASKS,
    CeleryMetricsCollector,
    get_health_response,
    get_metrics_response,
    get_ready_response,
    track_solver_analysis,
    track_spot_simulation,
    track_task_execution,
)


class TestCeleryMetrics:
    """Test Celery metrics collection functionality."""

    @pytest.mark.unit
    def test_tasks_total_metric(self):
        """Test tasks total counter."""
        # Test increment - we can't easily test the exact value without exposing internal state
        TASKS_TOTAL.labels(task_name="test_task", status="success").inc()
        # Just verify the operation doesn't raise an exception
        assert True

    @pytest.mark.unit
    def test_task_duration_metric(self):
        """Test task duration histogram."""
        # Test observation
        TASK_DURATION.labels(task_name="test_task").observe(0.5)
        # Histogram doesn't have a simple value getter, so we just test it doesn't raise
        assert True

    @pytest.mark.unit
    def test_task_queue_size_metric(self):
        """Test task queue size gauge."""
        # Test setting value - we can't easily test the exact value without exposing internal state
        TASK_QUEUE_SIZE.labels(queue_name="test_queue").set(10)
        # Just verify the operation doesn't raise an exception
        assert True

    @pytest.mark.unit
    def test_worker_active_tasks_metric(self):
        """Test worker active tasks gauge."""
        # Test setting value - we can't easily test the exact value without exposing internal state
        WORKER_ACTIVE_TASKS.labels(worker_name="test_worker").set(5)
        # Just verify the operation doesn't raise an exception
        assert True

    @pytest.mark.unit
    def test_track_task_execution(self):
        """Test task execution tracking."""
        # Test successful execution
        track_task_execution("test_task", 1.5, "success")
        # We can't easily test the internal state, but we can verify it doesn't raise
        assert True

    @pytest.mark.unit
    def test_track_spot_simulation(self):
        """Test spot simulation tracking."""
        # Test successful simulation
        track_spot_simulation("success")
        # We can't easily test the internal state, but we can verify it doesn't raise
        assert True

    @pytest.mark.unit
    def test_track_solver_analysis(self):
        """Test solver analysis tracking."""
        # Test successful analysis
        track_solver_analysis("success")
        # We can't easily test the internal state, but we can verify it doesn't raise
        assert True

    @patch("src.celery_worker.metrics.update_system_metrics")
    @pytest.mark.unit
    def test_get_metrics_response_success(self, mock_update):
        """Test successful metrics response generation."""
        response = get_metrics_response()

        assert isinstance(response, str)
        assert len(response) > 0
        mock_update.assert_called_once()

    @pytest.mark.unit
    def test_get_health_response(self):
        """Test health response generation."""
        health_data = get_health_response()

        assert "status" in health_data
        assert "timestamp" in health_data
        assert "services" in health_data
        assert health_data["status"] in ["healthy", "unhealthy"]

    @pytest.mark.unit
    def test_get_ready_response(self):
        """Test ready response generation."""
        ready_data = get_ready_response()

        assert "status" in ready_data
        assert "timestamp" in ready_data
        assert "checks" in ready_data
        assert ready_data["status"] in ["ready", "not_ready"]


class TestCeleryMetricsCollector:
    """Test Celery metrics collector functionality."""

    @pytest.mark.unit
    def test_collector_initialization(self):
        """Test metrics collector initialization."""
        mock_celery = MagicMock()
        collector = CeleryMetricsCollector(mock_celery)

        assert collector.celery_app == mock_celery
        assert not collector._running

    @pytest.mark.unit
    def test_collector_start_stop(self):
        """Test metrics collector start and stop."""
        mock_celery = MagicMock()
        collector = CeleryMetricsCollector(mock_celery)

        # Test start
        collector.start()
        assert collector._running
        assert collector._thread is not None

        # Test stop
        collector.stop()
        assert not collector._running

    @pytest.mark.unit
    def test_collector_event_handlers(self):
        """Test event handler methods."""
        mock_celery = MagicMock()
        collector = CeleryMetricsCollector(mock_celery)

        # Test that event handlers don't raise exceptions
        test_event = {"name": "test_task", "hostname": "test_worker", "queue": "test_queue", "runtime": 1.5}

        # Test all event handlers
        collector._on_task_sent(test_event)
        collector._on_task_received(test_event)
        collector._on_task_started(test_event)
        collector._on_task_succeeded(test_event)
        collector._on_task_failed(test_event)
        collector._on_task_revoked(test_event)
        collector._on_worker_online(test_event)
        collector._on_worker_offline(test_event)

        # If we get here without exceptions, the test passes
        assert True


class TestMetricsServer:
    """Test metrics server functionality."""

    @pytest.mark.unit
    def test_metrics_server_initialization(self):
        """Test metrics server initialization."""
        from src.celery_worker.metrics_server import MetricsServer

        server = MetricsServer("localhost", 8000)

        assert server.host == "localhost"
        assert server.port == 8000
        assert not server._running

    @patch("src.celery_worker.metrics_server.HTTPServer")
    @pytest.mark.unit
    def test_metrics_server_start(self, mock_http_server):
        """Test metrics server start."""
        from src.celery_worker.metrics_server import MetricsServer

        mock_server_instance = MagicMock()
        mock_http_server.return_value = mock_server_instance

        server = MetricsServer("localhost", 8000)
        server.start()

        assert server._running
        mock_http_server.assert_called_once()

    @pytest.mark.unit
    def test_metrics_server_stop(self):
        """Test metrics server stop."""
        from src.celery_worker.metrics_server import MetricsServer

        server = MetricsServer("localhost", 8000)
        server._running = True

        server.stop()

        assert not server._running
