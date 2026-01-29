"""Core service implementation for gRPC."""

import datetime
import logging

from ..protos import common_pb2, core_pb2, core_pb2_grpc
from . import shared_logic as shared
from .utils import _to_proto_timestamp

logger = logging.getLogger(__name__)


class CoreServiceServicer(core_pb2_grpc.CoreServiceServicer):
    """gRPC service implementation for core operations."""

    def HealthCheck(self, request, context):
        """Health check endpoint."""
        data = shared.get_root_health()
        ts = (
            _to_proto_timestamp(datetime.datetime.fromisoformat(data["timestamp"]))
            if "timestamp" in data
            else _to_proto_timestamp(datetime.datetime.utcnow())
        )
        return core_pb2.HealthCheckResponse(status="healthy", version="1.0.0", timestamp=ts)

    def GetSystemStatus(self, request, context):
        """Get system status and metrics."""
        try:
            status = shared.get_system_status()
            return core_pb2.SystemStatusResponse(
                status=status.get("status", "healthy"),
                services=status.get("routes_grpc", {}),
                metrics=status.get("metrics", {}),
            )
        except Exception as e:
            logger.error(f"Error getting system status: {str(e)}")
            return core_pb2.SystemStatusResponse(
                status="unhealthy", error=common_pb2.Error(code="INTERNAL_ERROR", message="Internal server error")
            )
