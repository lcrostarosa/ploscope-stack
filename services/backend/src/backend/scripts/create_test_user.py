#!/usr/bin/env python3
"""
Script to create a test user and generate authentication token for testing.
"""

import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.models.user import User
from core.utils.logging_utils import get_enhanced_logger

from src.backend.database import db
from src.backend.main import create_flask_app

from ..utils.auth_utils import create_user_tokens

logger = get_enhanced_logger(__name__)


def create_test_user():
    """Create a test user and return authentication token."""
    app = create_flask_app()

    with app.app_context():
        # Check if test user already exists
        test_user = User.query.filter_by(email="test@example.com").first()

        if not test_user:
            # Create test user
            test_user = User(
                email="test@example.com",
                username="testuser",
                first_name="Test",
                last_name="User",
                is_active=True,
            )
            db.session.add(test_user)
            db.session.commit()
            logger.info(f"Created test user: {test_user.email}")
        else:
            logger.info(f"Test user already exists: {test_user.email}")

        # Generate authentication token
        access_token, refresh_token = create_user_tokens(test_user.id)

        logger.info(f"\nTest user ID: {test_user.id}")
        logger.info(f"Access token: {access_token}")
        logger.info("\nTo test the jobs endpoint, use:")
        logger.info("curl -X GET http://localhost:5001/api/jobs/recent \\")
        logger.info(f"  -H 'Authorization: Bearer {access_token}' \\")
        logger.info("  -H 'Content-Type: application/json'")

        return test_user.id, access_token


if __name__ == "__main__":
    user_id, token = create_test_user()
    logger.info(f"Test user created: {user_id}")
