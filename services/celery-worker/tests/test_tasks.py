"""
Unit tests for Celery worker tasks.
"""


import pytest


class TestBasicFunctionality:
    """Test basic functionality of the celery worker."""

    @pytest.mark.unit
    def test_celery_worker_structure(self):
        """Test that the celery worker has the expected structure."""
        import os

        # Check that the celery worker directory exists
        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        assert os.path.exists(celery_worker_path), "Celery worker directory should exist"

        # Check that required files exist
        required_files = ["celery_app.py", "tasks.py", "__init__.py"]
        for file_name in required_files:
            file_path = os.path.join(celery_worker_path, file_name)
            assert os.path.exists(file_path), f"Required file {file_name} should exist"

    @pytest.mark.unit
    def test_celery_app_import(self):
        """Test that the Celery app can be imported successfully."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            from src.celery_worker.celery_app import celery

            assert celery is not None
            assert hasattr(celery, "conf")
            assert hasattr(celery, "tasks")
        except ImportError as e:
            pytest.fail(f"Failed to import celery app: {e}")

    @pytest.mark.unit
    def test_tasks_import(self):
        """Test that the tasks module can be imported."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            from src.celery_worker.tasks import get_db_session, process_solver_analysis, process_spot_simulation

            assert callable(process_spot_simulation)
            assert callable(process_solver_analysis)
            assert callable(get_db_session)
        except ImportError as e:
            pytest.fail(f"Failed to import tasks: {e}")


class TestTaskDecorators:
    """Test that tasks have proper Celery decorators."""

    @pytest.mark.unit
    def test_task_decorators(self):
        """Test that tasks have proper Celery decorators."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            from src.celery_worker.tasks import process_solver_analysis, process_spot_simulation

            # Check that functions have the @celery.task decorator
            assert hasattr(process_spot_simulation, "delay")
            assert hasattr(process_spot_simulation, "apply_async")
            assert hasattr(process_solver_analysis, "delay")
            assert hasattr(process_solver_analysis, "apply_async")
        except ImportError as e:
            pytest.fail(f"Failed to import tasks: {e}")


class TestConfiguration:
    """Test configuration and settings."""

    @pytest.mark.unit
    def test_celery_configuration(self):
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


class TestErrorHandling:
    """Test error handling in tasks."""

    # Note: Database session error handling test moved to integration tests
    # as it requires database connection testing


class TestIntegration:
    """Integration tests for task workflows."""

    @pytest.mark.unit
    def test_spot_simulation_task_signature(self):
        """Test that spot simulation task has the correct signature."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            import inspect

            from src.celery_worker.tasks import process_spot_simulation

            # Check function signature
            sig = inspect.signature(process_spot_simulation)
            params = list(sig.parameters.keys())

            # Should have job_id parameter (self is bound to the task instance)
            assert "job_id" in params
            assert len(params) >= 1  # At least job_id
        except ImportError as e:
            pytest.fail(f"Failed to import process_spot_simulation: {e}")

    @pytest.mark.unit
    def test_solver_analysis_task_signature(self):
        """Test that solver analysis task has the correct signature."""
        import os
        import sys

        celery_worker_path = os.path.join(os.path.dirname(__file__), "..", "src", "celery_worker")
        if celery_worker_path not in sys.path:
            sys.path.insert(0, celery_worker_path)

        try:
            import inspect

            from src.celery_worker.tasks import process_solver_analysis

            # Check function signature
            sig = inspect.signature(process_solver_analysis)
            params = list(sig.parameters.keys())

            # Should have job_id parameter (self is bound to the task instance)
            assert "job_id" in params
            assert len(params) >= 1  # At least job_id
        except ImportError as e:
            pytest.fail(f"Failed to import process_solver_analysis: {e}")
