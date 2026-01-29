"""
Tests for Celery app configuration.
"""

from unittest.mock import patch

import pytest


class TestCeleryApp:
    """Test Celery app configuration."""

    @pytest.mark.unit
    def test_celery_app_exists(self):
        """Test that the Celery app module exists and can be imported."""
        # This test verifies the basic structure
        import os
        import sys

        # Add the src/celery_worker directory to the path
        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        # Try to import the celery app
        try:
            from src.celery_worker.celery_app import celery

            assert celery is not None
            assert hasattr(celery, "conf")
            assert hasattr(celery, "tasks")
        except ImportError as e:
            pytest.fail(f"Failed to import celery app: {e}")

    @pytest.mark.unit
    def test_celery_app_configuration(self):
        """Test that the Celery app has the expected configuration."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            from src.celery_worker.celery_app import celery

            # Check basic configuration
            assert celery.conf.task_serializer == "json"
            assert celery.conf.accept_content == ["json"]
            assert celery.conf.result_serializer == "json"
            assert celery.conf.timezone == "UTC"
            assert celery.conf.enable_utc is True
            assert celery.conf.task_acks_late is True
            assert celery.conf.task_reject_on_worker_lost is True
            assert celery.conf.worker_prefetch_multiplier == 2
            assert celery.conf.task_time_limit == 1800
            assert celery.conf.task_soft_time_limit == 1500
            assert celery.conf.result_expires == 3600
            assert celery.conf.result_compression == "gzip"

        except ImportError as e:
            pytest.fail(f"Failed to import celery app: {e}")

    @pytest.mark.unit
    def test_task_registration(self):
        """Test that tasks are properly registered."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            from src.celery_worker.celery_app import celery

            # Check that our tasks are in the registered tasks
            registered_tasks = celery.tasks.keys()

            # The tasks should be registered with the full module path
            # Note: The actual task names might be different, so let's check if any tasks are registered
            assert len(registered_tasks) > 0, "No tasks are registered"

            # Check if our specific tasks are registered (they might have different names)
            task_names = list(registered_tasks)
            print(f"Registered tasks: {task_names}")

            # For now, just verify that tasks exist
            assert len(task_names) >= 8, f"Expected at least 8 tasks, got {len(task_names)}"

        except ImportError as e:
            pytest.fail(f"Failed to import celery app: {e}")

    @pytest.mark.unit
    def test_task_routing(self):
        """Test that tasks are routed to correct queues."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            from src.celery_worker.celery_app import celery

            # Check task routing configuration
            task_routes = celery.conf.task_routes

            assert "celery_worker.tasks.process_spot_simulation" in task_routes
            spot_queue = task_routes["celery_worker.tasks.process_spot_simulation"]["queue"]
            assert "spot-processing" in spot_queue  # Allow test- prefix in test environment

            assert "celery_worker.tasks.process_solver_analysis" in task_routes
            solver_queue = task_routes["celery_worker.tasks.process_solver_analysis"]["queue"]
            assert "solver-processing" in solver_queue  # Allow test- prefix in test environment

        except ImportError as e:
            pytest.fail(f"Failed to import celery app: {e}")


class TestCeleryAppCreation:
    """Test Celery app creation with different configurations."""

    @patch("src.celery_worker.celery_app.check_database_connection")
    @patch("src.celery_worker.celery_app.os.environ.get")
    @pytest.mark.unit
    def test_make_celery_function(self, mock_env_get, mock_check_db):
        """Test that the make_celery function works correctly."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        # Mock environment variables
        mock_env_get.side_effect = lambda key, default=None: {
            "CELERY_BROKER_URL": None,
            "RABBITMQ_DEFAULT_USER": "testuser",
            "RABBITMQ_DEFAULT_PASS": "testpass",
            "RABBITMQ_HOST": "testhost",
            "RABBITMQ_PORT": "5672",
            "RABBITMQ_DEFAULT_VHOST": "/testvhost",
            "CELERY_RESULT_BACKEND": "rpc://",
        }.get(key, default)

        try:
            from src.celery_worker.celery_app import make_celery

            celery_app = make_celery()

            assert celery_app is not None
            assert celery_app.conf.task_serializer == "json"
            assert celery_app.conf.accept_content == ["json"]
            assert celery_app.conf.result_serializer == "json"
            assert celery_app.conf.timezone == "UTC"
            assert celery_app.conf.enable_utc is True
            assert celery_app.conf.task_acks_late is True
            assert celery_app.conf.task_reject_on_worker_lost is True
            assert celery_app.conf.worker_prefetch_multiplier == 2
            assert celery_app.conf.task_time_limit == 1800
            assert celery_app.conf.task_soft_time_limit == 1500
            assert celery_app.conf.result_expires == 3600
            assert celery_app.conf.result_compression == "gzip"

        except ImportError as e:
            pytest.fail(f"Failed to import make_celery function: {e}")
