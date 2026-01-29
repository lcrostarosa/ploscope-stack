import uuid
from datetime import datetime, timedelta
from typing import Any, Optional

from sqlalchemy import JSON, DateTime
from sqlalchemy import Enum as SAEnum
from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, declarative_base, mapped_column

from src.celery_worker.models.enums import JobStatus, JobType

Base = declarative_base()


class Job(Base):
    __tablename__ = "jobs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    job_type: Mapped[JobType] = mapped_column(SAEnum(JobType), nullable=False)
    status: Mapped[JobStatus] = mapped_column(SAEnum(JobStatus), nullable=False, default=JobStatus.QUEUED)
    input_data: Mapped[dict] = mapped_column(JSON, nullable=False)
    result_data: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    queue_message_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    estimated_duration: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    actual_duration: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    progress_percentage: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    progress_message: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=datetime.utcnow)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=datetime.utcnow)

    def __init__(
        self,
        user_id: str,
        job_type: JobType,
        input_data: dict[str, Any],
        user: Optional[Any] = None,
        estimated_duration: Optional[int] = None,
    ):
        if not user_id:
            raise ValueError("user_id is required")
        if not job_type:
            raise ValueError("job_type is required")
        if input_data is None:
            raise ValueError("input_data is required")

        self.user_id = user_id
        self.job_type = job_type
        self.input_data = input_data
        self.status = JobStatus.QUEUED
        self.estimated_duration = estimated_duration
        self.user = user
        # Ensure sane defaults when not persisted (SQLAlchemy defaults apply on flush only)
        if getattr(self, "progress_percentage", None) is None:
            self.progress_percentage = 0

        # Validate that user_id matches user.id if both are provided
        if self.user and getattr(self.user, "id", None) and self.user.id != self.user_id:
            raise ValueError(f"user_id ({self.user_id}) does not match user.id ({self.user.id})")

    def start_processing(self):
        self.status = JobStatus.PROCESSING
        self.started_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def complete_job(self, result_data):
        self.status = JobStatus.COMPLETED
        self.completed_at = datetime.utcnow()
        self.result_data = result_data
        self.progress_percentage = 100
        self.progress_message = "Completed successfully"
        if self.started_at:
            self.actual_duration = int((self.completed_at - self.started_at).total_seconds())
        self.updated_at = datetime.utcnow()

    def fail_job(self, error_message):
        self.status = JobStatus.FAILED
        self.completed_at = datetime.utcnow()
        self.error_message = error_message
        self.progress_message = f"Failed: {error_message}"
        if self.started_at:
            self.actual_duration = int((self.completed_at - self.started_at).total_seconds())
        self.updated_at = datetime.utcnow()

    def update_progress(self, percentage, message=None):
        self.progress_percentage = min(100, max(0, percentage))
        if message:
            self.progress_message = message
        self.updated_at = datetime.utcnow()

    def get_estimated_completion_time(self):
        if self.status == JobStatus.COMPLETED:
            return self.completed_at
        if not self.estimated_duration:
            return None
        if self.status == JobStatus.PROCESSING and self.started_at:
            return self.started_at + timedelta(seconds=self.estimated_duration)
        if self.status == JobStatus.QUEUED:
            return self.created_at + timedelta(seconds=self.estimated_duration + 60)
        return None

    def to_dict(self):
        estimated_completion = self.get_estimated_completion_time()
        return {
            "id": self.id,
            "user_id": self.user_id,
            "job_type": self.job_type.value if self.job_type else None,  # Keep original case
            "status": self.status.value if self.status else None,
            "input_data": self.input_data,
            "result_data": self.result_data,
            "error_message": self.error_message,
            "estimated_duration": self.estimated_duration,
            "actual_duration": self.actual_duration,
            "progress_percentage": self.progress_percentage,
            "progress_message": self.progress_message,
            "estimated_completion_time": estimated_completion.isoformat() if estimated_completion else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def to_summary_dict(self):
        return {k: v for k, v in self.to_dict().items() if k not in ["input_data", "result_data"]}

    def __repr__(self):
        job_type_str = self.job_type.value.lower() if self.job_type else "unknown"
        status_str = self.status.value if self.status else "unknown"
        return f"<Job {self.id} {job_type_str} {status_str}>"

    @classmethod
    def from_dict(cls, data):
        job = cls(
            user_id=data.get("user_id"),
            job_type=JobType(data.get("job_type")),
            input_data=data.get("input_data"),
        )
        job.id = data.get("id")
        job.status = JobStatus(data.get("status"))
        job.result_data = data.get("result_data")
        job.error_message = data.get("error_message")
        job.progress_percentage = data.get("progress_percentage")
        job.progress_message = data.get("progress_message")
        job.created_at = datetime.fromisoformat(data.get("created_at")) if data.get("created_at") else None
        job.started_at = datetime.fromisoformat(data.get("started_at")) if data.get("started_at") else None
        job.completed_at = datetime.fromisoformat(data.get("completed_at")) if data.get("completed_at") else None
        job.updated_at = datetime.fromisoformat(data.get("updated_at")) if data.get("updated_at") else None
        job.estimated_duration = data.get("estimated_duration")
        job.actual_duration = data.get("actual_duration")
        return job
