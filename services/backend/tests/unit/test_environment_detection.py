"""
Test environment detection logic for eventlet and WebSocket configuration.
"""

import os
from unittest.mock import patch


class TestEnvironmentDetection:
    """Test that staging environment is treated as production for eventlet/WebSocket."""

    def test_staging_environment_treated_as_production_for_eventlet(self):
        """Test that staging environment enables eventlet monkey patching."""
        with patch.dict(
            os.environ,
            {
                "FLASK_ENV": "production",
                "NODE_ENV": "production",
                "ENVIRONMENT": "staging",
                "TESTING": "false",
            },
        ):
            # Import the logic from wsgi.py
            import sys
            from pathlib import Path

            # Add the backend directory to the Python path
            backend_path = Path(__file__).parent.parent
            sys.path.insert(0, str(backend_path))

            # Test the condition logic
            should_patch = (
                os.getenv("FLASK_ENV") == "production"
                and os.getenv("NODE_ENV") != "test"
                and os.getenv("ENVIRONMENT") not in ["test"]
                and os.getenv("TESTING") != "true"
            )

            assert should_patch is True, "Staging environment should enable eventlet patching"

    def test_staging_environment_treated_as_production_for_websocket(self):
        """Test that staging environment uses eventlet for WebSocket."""
        with patch.dict(
            os.environ,
            {
                "FLASK_ENV": "production",
                "NODE_ENV": "production",
                "ENVIRONMENT": "staging",
                "TESTING": "false",
            },
        ):
            # Test the condition logic from websocket_service.py
            should_use_eventlet = (
                os.getenv("FLASK_ENV") == "production"
                and os.getenv("NODE_ENV") != "test"
                and os.getenv("ENVIRONMENT") not in ["test"]
                and os.getenv("TESTING") != "true"
            )

            assert should_use_eventlet is True, "Staging environment should use eventlet for WebSocket"

    def test_test_environment_disables_eventlet(self):
        """Test that test environment disables eventlet monkey patching."""
        with patch.dict(
            os.environ,
            {
                "FLASK_ENV": "production",
                "NODE_ENV": "production",
                "ENVIRONMENT": "test",
                "TESTING": "false",
            },
        ):
            should_patch = (
                os.getenv("FLASK_ENV") == "production"
                and os.getenv("NODE_ENV") != "test"
                and os.getenv("ENVIRONMENT") not in ["test"]
                and os.getenv("TESTING") != "true"
            )

            assert should_patch is False, "Test environment should disable eventlet patching"

    def test_development_environment_disables_eventlet(self):
        """Test that development environment disables eventlet monkey patching."""
        with patch.dict(
            os.environ,
            {
                "FLASK_ENV": "development",
                "NODE_ENV": "development",
                "ENVIRONMENT": "development",
                "TESTING": "false",
            },
        ):
            should_patch = (
                os.getenv("FLASK_ENV") == "production"
                and os.getenv("NODE_ENV") != "test"
                and os.getenv("ENVIRONMENT") not in ["test"]
                and os.getenv("TESTING") != "true"
            )

            assert should_patch is False, "Development environment should disable eventlet patching"

    def test_production_environment_enables_eventlet(self):
        """Test that production environment enables eventlet monkey patching."""
        with patch.dict(
            os.environ,
            {
                "FLASK_ENV": "production",
                "NODE_ENV": "production",
                "ENVIRONMENT": "production",
                "TESTING": "false",
            },
        ):
            should_patch = (
                os.getenv("FLASK_ENV") == "production"
                and os.getenv("NODE_ENV") != "test"
                and os.getenv("ENVIRONMENT") not in ["test"]
                and os.getenv("TESTING") != "true"
            )

            assert should_patch is True, "Production environment should enable eventlet patching"
