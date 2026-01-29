"""Job service implementation for gRPC."""

import logging

from ..protos import common_pb2, job_pb2, job_pb2_grpc
from . import shared_logic as shared

logger = logging.getLogger(__name__)


class JobServiceServicer(job_pb2_grpc.JobServiceServicer):
    """gRPC service implementation for job operations."""

    def CreateJob(self, request, context):
        """Create a new job."""
        try:
            job_dict = shared.create_job(
                request.user_id, request.job_type, dict(request.parameters), int(request.priority)
            )
            job = job_pb2.Job(
                id=job_dict.get("id", ""),
                user_id=job_dict.get("user_id", ""),
                job_type=job_dict.get("job_type", ""),
                status=job_dict.get("status", ""),
                parameters=job_dict.get("parameters", {}),
                priority=int(job_dict.get("priority", 0)),
                progress=float(job_dict.get("progress", 0.0)),
            )
            return job_pb2.CreateJobResponse(job=job)
        except Exception as e:
            logger.error(f"Error creating job: {str(e)}")
            return job_pb2.CreateJobResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )

    def GetJob(self, request, context):
        """Get job details."""
        try:
            job_status = shared.get_job_status(request.job_id, request.user_id)
            job = job_pb2.Job(
                id=job_status.get("id", ""),
                user_id=job_status.get("user_id", ""),
                job_type=job_status.get("job_type", ""),
                status=job_status.get("status", ""),
                parameters=job_status.get("parameters", {}),
                result=job_status.get("result", {}),
                priority=int(job_status.get("priority", 0)),
                progress=float(job_status.get("progress", 0.0)),
                error_message=job_status.get("error_message", ""),
            )
            return job_pb2.GetJobResponse(job=job)
        except Exception as e:
            logger.error(f"Error getting job: {str(e)}")
            return job_pb2.GetJobResponse(
                error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )
