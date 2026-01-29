"""Test integration of core DTOs in backend environment."""

from datetime import datetime

import pytest

# Skip this test module if core module is not available
try:
    from core.dto.hand_dto import HandHistoryDTO
    from core.dto.job_dto import JobCreateRequest, JobDTO, JobStatus, JobType
    from core.dto.solver_dto import SolverSolutionDTO
    from core.dto.spot_dto import SpotDTO
    from core.dto.user_dto import SubscriptionTier, UserDTO
except ImportError:
    pytest.skip("core module not available", allow_module_level=True)


class TestCoreDTOIntegration:
    """Test that core DTOs work correctly in backend environment."""

    def test_job_dto_import_and_creation(self):
        """Test that JobDTO can be imported and created."""
        now = datetime.now()
        job = JobDTO(
            id="test-job-123",
            job_type=JobType.SPOT_SIMULATION,
            status=JobStatus.QUEUED,
            input_data={"players": 2, "board": ["Ah", "Kh", "Qh"]},
            created_at=now,
            updated_at=now,
            user_id="user-123",
        )

        assert job.id == "test-job-123"
        assert job.job_type == JobType.SPOT_SIMULATION
        assert job.status == JobStatus.QUEUED
        assert job.user_id == "user-123"

    def test_job_create_request(self):
        """Test JobCreateRequest creation."""
        request = JobCreateRequest(
            job_type=JobType.SOLVER_ANALYSIS,
            input_data={"game_state": {"board": ["Ah", "Kh", "Qh"]}},
            user_id="user-456",
            priority=5,
            estimated_duration=60.0,
        )

        assert request.job_type == JobType.SOLVER_ANALYSIS
        assert request.user_id == "user-456"
        assert request.priority == 5
        assert request.estimated_duration == 60.0

    def test_user_dto_import_and_creation(self):
        """Test that UserDTO can be imported and created."""
        now = datetime.now()
        user = UserDTO(
            id="user-789",
            email="test@example.com",
            display_name="Test User",
            created_at=now,
            updated_at=now,
            subscription_tier=SubscriptionTier.PREMIUM,
        )

        assert user.id == "user-789"
        assert user.email == "test@example.com"
        assert user.display_name == "Test User"
        assert user.subscription_tier == SubscriptionTier.PREMIUM

    def test_hand_dto_import_and_creation(self):
        """Test that HandHistoryDTO can be imported and created."""
        now = datetime.now()
        hand = HandHistoryDTO(
            id="hand-123",
            user_id="user-456",
            raw_content="PokerStars Hand #123456789",
            created_at=now,
            updated_at=now,
            site="PokerStars",
            game_type="PLO",
        )

        assert hand.id == "hand-123"
        assert hand.user_id == "user-456"
        assert hand.site == "PokerStars"
        assert hand.game_type == "PLO"

    def test_spot_dto_import_and_creation(self):
        """Test that SpotDTO can be imported and created."""
        now = datetime.now()
        spot = SpotDTO(
            id="spot-123",
            user_id="user-456",
            name="Test Spot",
            game_state={"board": ["Ah", "Kh", "Qh"], "pot": 100},
            created_at=now,
            updated_at=now,
        )

        assert spot.id == "spot-123"
        assert spot.name == "Test Spot"
        assert spot.game_state["pot"] == 100

    def test_solver_dto_import_and_creation(self):
        """Test that SolverSolutionDTO can be imported and created."""
        now = datetime.now()
        solution = SolverSolutionDTO(
            id="solution-123",
            user_id="user-456",
            name="Test Solution",
            game_state={"board": ["Ah", "Kh", "Qh"]},
            solution={"strategy": {"fold": 0.3, "call": 0.7}},
            solve_time=45.5,
            created_at=now,
            updated_at=now,
        )

        assert solution.id == "solution-123"
        assert solution.name == "Test Solution"
        assert solution.solve_time == 45.5
        assert solution.solution["strategy"]["fold"] == 0.3

    def test_dto_serialization(self):
        """Test that DTOs can be serialized to/from dictionaries."""
        now = datetime.now()

        # Test JobDTO serialization
        job = JobDTO(
            id="job-123",
            job_type=JobType.SPOT_SIMULATION,
            status=JobStatus.COMPLETED,
            input_data={"test": "data"},
            created_at=now,
            updated_at=now,
        )

        job_dict = job.to_dict()
        assert job_dict["id"] == "job-123"
        assert job_dict["job_type"] == "spot_simulation"
        assert job_dict["status"] == "completed"

        # Test deserialization
        job_from_dict = JobDTO.from_dict(job_dict)
        assert job_from_dict.id == job.id
        assert job_from_dict.job_type == job.job_type
        assert job_from_dict.status == job.status

    def test_no_database_dependencies(self):
        """Test that DTOs can be used without any database initialization."""
        # This test verifies that we can create and use DTOs without
        # any database setup, which was the main goal of the refactoring

        now = datetime.now()

        # Create multiple DTOs without any database concerns
        job = JobDTO(
            id="job-123",
            job_type=JobType.SPOT_SIMULATION,
            status=JobStatus.QUEUED,
            input_data={"players": 2},
            created_at=now,
            updated_at=now,
        )

        user = UserDTO(
            id="user-123", email="test@example.com", display_name="Test User", created_at=now, updated_at=now
        )

        # Verify they work independently
        assert job.id != user.id
        assert job.job_type == JobType.SPOT_SIMULATION
        assert user.email == "test@example.com"

        # Test that we can serialize them
        job_dict = job.to_dict()
        user_dict = user.to_dict()

        assert "job_type" in job_dict
        assert "email" in user_dict
