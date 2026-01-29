"""Test DTO integration with backend services."""

from datetime import datetime

import pytest

# Skip this test module if core module is not available
try:
    from core.dto.job_dto import JobCreateRequest, JobDTO, JobStatus, JobType, JobUpdateRequest
    from core.services.job_service_interface import JobServiceInterface
except ImportError:
    pytest.skip("core module not available", allow_module_level=True)


class MockJobRepository(JobServiceInterface):
    """Mock implementation of JobServiceInterface for testing."""

    def __init__(self):
        self.jobs = {}
        self.next_id = 1

    def create_job(self, request: JobCreateRequest) -> JobDTO:
        """Create a new job."""
        job_id = f"job-{self.next_id}"
        self.next_id += 1

        now = datetime.now()
        job = JobDTO(
            id=job_id,
            job_type=request.job_type,
            status=JobStatus.QUEUED,
            input_data=request.input_data,
            created_at=now,
            updated_at=now,
            user_id=request.user_id,
            priority=request.priority,
            estimated_duration=request.estimated_duration,
        )

        self.jobs[job_id] = job
        return job

    def get_job(self, job_id: str) -> JobDTO | None:
        """Get a job by ID."""
        return self.jobs.get(job_id)

    def update_job(self, job_id: str, request: JobUpdateRequest) -> JobDTO | None:
        """Update an existing job."""
        if job_id not in self.jobs:
            return None

        job = self.jobs[job_id]

        # Update fields if provided
        if request.status is not None:
            job.status = request.status
        if request.output_data is not None:
            job.output_data = request.output_data
        if request.error_message is not None:
            job.error_message = request.error_message
        if request.actual_duration is not None:
            job.actual_duration = request.actual_duration
        if request.progress is not None:
            job.progress = request.progress

        job.updated_at = datetime.now()
        return job

    def delete_job(self, job_id: str) -> bool:
        """Delete a job."""
        if job_id in self.jobs:
            del self.jobs[job_id]
            return True
        return False

    def list_jobs(self, user_id: str | None = None, limit: int = 100, offset: int = 0) -> list[JobDTO]:
        """List jobs, optionally filtered by user."""
        jobs = list(self.jobs.values())

        if user_id is not None:
            jobs = [job for job in jobs if job.user_id == user_id]

        return jobs[offset : offset + limit]

    def get_jobs_by_status(self, status: str, limit: int = 100) -> list[JobDTO]:
        """Get jobs by status."""
        jobs = [job for job in self.jobs.values() if job.status.value == status]
        return jobs[:limit]


class TestDTOServiceIntegration:
    """Test DTO integration with backend services."""

    def test_job_service_with_dto(self):
        """Test that a job service can work with DTOs."""
        # Create mock repository
        repository = MockJobRepository()

        # Create a job request
        request = JobCreateRequest(
            job_type=JobType.SPOT_SIMULATION,
            input_data={"players": 2, "board": ["Ah", "Kh", "Qh"], "pot_size": 100},
            user_id="user-123",
            priority=1,
            estimated_duration=30.0,
        )

        # Create job through repository
        job = repository.create_job(request)

        assert job.id is not None
        assert job.job_type == JobType.SPOT_SIMULATION
        assert job.status == JobStatus.QUEUED
        assert job.user_id == "user-123"
        assert job.priority == 1
        assert job.estimated_duration == 30.0

        # Update job status
        update_request = JobUpdateRequest(status=JobStatus.RUNNING, progress=50)

        updated_job = repository.update_job(job.id, update_request)

        assert updated_job is not None
        assert updated_job.status == JobStatus.RUNNING
        assert updated_job.progress == 50

        # Complete the job
        complete_request = JobUpdateRequest(
            status=JobStatus.COMPLETED,
            output_data={"equity": 0.65, "strategy": {"fold": 0.3, "call": 0.7}},
            actual_duration=25.5,
        )

        completed_job = repository.update_job(job.id, complete_request)

        assert completed_job.status == JobStatus.COMPLETED
        assert completed_job.output_data["equity"] == 0.65
        assert completed_job.actual_duration == 25.5

    def test_user_job_filtering(self):
        """Test filtering jobs by user."""
        repository = MockJobRepository()

        # Create jobs for different users
        user1_request = JobCreateRequest(
            job_type=JobType.SPOT_SIMULATION, input_data={"test": "data1"}, user_id="user-1"
        )

        user2_request = JobCreateRequest(
            job_type=JobType.SOLVER_ANALYSIS, input_data={"test": "data2"}, user_id="user-2"
        )

        repository.create_job(user1_request)
        repository.create_job(user2_request)

        # Test filtering
        user1_jobs = repository.list_jobs(user_id="user-1")
        user2_jobs = repository.list_jobs(user_id="user-2")
        all_jobs = repository.list_jobs()

        assert len(user1_jobs) == 1
        assert len(user2_jobs) == 1
        assert len(all_jobs) == 2

        assert user1_jobs[0].user_id == "user-1"
        assert user2_jobs[0].user_id == "user-2"

    def test_job_status_filtering(self):
        """Test filtering jobs by status."""
        repository = MockJobRepository()

        # Create jobs with different statuses
        request = JobCreateRequest(job_type=JobType.SPOT_SIMULATION, input_data={"test": "data"})

        job1 = repository.create_job(request)
        repository.create_job(request)

        # Update one to running
        repository.update_job(job1.id, JobUpdateRequest(status=JobStatus.RUNNING))

        # Test status filtering
        queued_jobs = repository.get_jobs_by_status(JobStatus.QUEUED.value)
        running_jobs = repository.get_jobs_by_status(JobStatus.RUNNING.value)

        assert len(queued_jobs) == 1
        assert len(running_jobs) == 1

        assert queued_jobs[0].status == JobStatus.QUEUED
        assert running_jobs[0].status == JobStatus.RUNNING

    def test_dto_serialization_in_service(self):
        """Test that DTOs can be serialized for API responses."""
        repository = MockJobRepository()

        request = JobCreateRequest(
            job_type=JobType.SPOT_SIMULATION, input_data={"players": 2, "board": ["Ah", "Kh", "Qh"]}, user_id="user-123"
        )

        job = repository.create_job(request)

        # Simulate API response serialization
        job_dict = job.to_dict()

        # Verify all expected fields are present
        expected_fields = ["id", "job_type", "status", "input_data", "created_at", "updated_at", "user_id", "priority"]

        for field in expected_fields:
            assert field in job_dict

        # Verify values
        assert job_dict["job_type"] == "spot_simulation"
        assert job_dict["status"] == "queued"
        assert job_dict["user_id"] == "user-123"
        assert job_dict["input_data"]["players"] == 2

    def test_no_database_required(self):
        """Test that the entire service works without any database setup."""
        # This is the key test - we can run a complete job service
        # without any database initialization, Flask app setup, or
        # SQLAlchemy configuration

        repository = MockJobRepository()

        # Create and manage jobs
        request = JobCreateRequest(
            job_type=JobType.SOLVER_ANALYSIS,
            input_data={"game_state": {"board": ["Ah", "Kh", "Qh"]}},
            user_id="user-456",
        )

        job = repository.create_job(request)

        # Update through lifecycle
        repository.update_job(job.id, JobUpdateRequest(status=JobStatus.RUNNING))
        repository.update_job(job.id, JobUpdateRequest(progress=75))
        repository.update_job(
            job.id,
            JobUpdateRequest(
                status=JobStatus.COMPLETED, output_data={"solution": "optimal_strategy"}, actual_duration=45.2
            ),
        )

        # Verify final state
        final_job = repository.get_job(job.id)
        assert final_job.status == JobStatus.COMPLETED
        assert final_job.progress == 75
        assert final_job.output_data["solution"] == "optimal_strategy"
        assert final_job.actual_duration == 45.2
