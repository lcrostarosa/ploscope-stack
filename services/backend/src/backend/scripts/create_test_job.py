#!/usr/bin/env python3
"""
Script to create a test job and mark it as completed for testing the job status panel.
"""

import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timedelta

from core.models.enums import JobStatus, JobType
from core.models.job import Job
from core.models.user import User

from backend.main import create_flask_app
from src.backend.database import db

from ..utils.auth_utils import create_user_tokens


def create_test_job():
    """Create a test job and mark it as completed."""
    app = create_flask_app()

    with app.app_context():
        # Get or create test user
        test_user = User.query.filter_by(email="test@example.com").first()

        if not test_user:
            # Create test user
            test_user = User(
                email="test@example.com",
                username="testuser",
                first_name="Test",
                last_name="User",
            )
            db.session.add(test_user)
            db.session.commit()
            print(f"Created test user: {test_user.email}")
        else:
            print(f"Using existing test user: {test_user.email}")

        # Create a test spot simulation job
        test_job = Job(
            user_id=test_user.id,
            job_type=JobType.SPOT_SIMULATION,
            input_data={
                "board": ["Ah", "Ks", "Qd"],
                "players": [
                    {"name": "Hero", "cards": ["As", "Kh"], "stack": 1000},
                    {"name": "Villain", "cards": ["Ad", "Kc"], "stack": 1000},
                ],
                "pot_size": 200,
                "bet_size": 50,
            },
            status=JobStatus.COMPLETED,
            estimated_duration=60,
        )

        # Set additional fields after creation
        test_job.actual_duration = 45
        test_job.progress_percentage = 100
        test_job.progress_message = "Simulation completed successfully"
        test_job.completed_at = datetime.utcnow() - timedelta(minutes=5)
        test_job.result_data = {
            "equities": {"Hero": 0.65, "Villain": 0.35},
            "win_percentages": {"Hero": 0.60, "Villain": 0.30, "Tie": 0.10},
            "hand_combinations_processed": 1000,
        }

        db.session.add(test_job)
        db.session.commit()

        print(f"Created test job: {test_job.id}")
        print(f"Job type: {test_job.job_type.value}")
        print(f"Status: {test_job.status.value}")
        print(f"Completed at: {test_job.completed_at}")

        # Generate authentication token
        access_token, refresh_token = create_user_tokens(test_user.id)

        print(f"\nTest user ID: {test_user.id}")
        print(f"Access token: {access_token}")
        print("To test the jobs endpoint, use:")
        print("curl -X GET http://localhost:5001/api/jobs/recent \\")
        print(f"  -H 'Authorization: Bearer {access_token}' \\")
        print("  -H 'Content-Type: application/json'")

        return test_user.id, access_token, test_job.id


if __name__ == "__main__":
    user_id, token, job_id = create_test_job()
    print(f"Test job created: {job_id}")
