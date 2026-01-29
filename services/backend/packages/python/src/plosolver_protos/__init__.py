"""
PLOSolver Protocol Buffer definitions for Python.

This package provides Python bindings for the PLOSolver gRPC services.
"""

from .generated import (  # Common messages; Auth service; Solver service; Job service; Subscription service; Hand history service; Core service
    auth_pb2,
    auth_pb2_grpc,
    common_pb2,
    common_pb2_grpc,
    core_pb2,
    core_pb2_grpc,
    hand_history_pb2,
    hand_history_pb2_grpc,
    job_pb2,
    job_pb2_grpc,
    solver_pb2,
    solver_pb2_grpc,
    subscription_pb2,
    subscription_pb2_grpc,
)
from .generated.auth_pb2 import AuthResponse, GetProfileRequest, GetProfileResponse, LoginRequest, RegisterRequest

# Export service classes
from .generated.auth_pb2_grpc import AuthServiceServicer, AuthServiceStub

# Export commonly used classes for convenience
from .generated.common_pb2 import Error, PaginationRequest, PaginationResponse, User
from .generated.core_pb2_grpc import CoreServiceServicer, CoreServiceStub
from .generated.hand_history_pb2_grpc import HandHistoryServiceServicer, HandHistoryServiceStub
from .generated.job_pb2 import CreateJobRequest, Job, JobResponse, JobStatus
from .generated.job_pb2_grpc import JobServiceServicer, JobServiceStub
from .generated.solver_pb2 import AnalyzeSpotRequest, AnalyzeSpotResponse, GameState, SolverConfig
from .generated.solver_pb2_grpc import SolverServiceServicer, SolverServiceStub
from .generated.subscription_pb2_grpc import SubscriptionServiceServicer, SubscriptionServiceStub

__version__ = "1.0.0"
__all__ = [
    # Common messages
    "User",
    "Error",
    "PaginationRequest",
    "PaginationResponse",
    # Auth messages
    "RegisterRequest",
    "LoginRequest",
    "AuthResponse",
    "GetProfileRequest",
    "GetProfileResponse",
    # Solver messages
    "AnalyzeSpotRequest",
    "AnalyzeSpotResponse",
    "SolverConfig",
    "GameState",
    # Job messages
    "Job",
    "CreateJobRequest",
    "JobResponse",
    "JobStatus",
    # Service stubs
    "AuthServiceStub",
    "SolverServiceStub",
    "JobServiceStub",
    "SubscriptionServiceStub",
    "HandHistoryServiceStub",
    "CoreServiceStub",
    # Service servicers
    "AuthServiceServicer",
    "SolverServiceServicer",
    "JobServiceServicer",
    "SubscriptionServiceServicer",
    "HandHistoryServiceServicer",
    "CoreServiceServicer",
    # Raw protobuf modules
    "common_pb2",
    "common_pb2_grpc",
    "auth_pb2",
    "auth_pb2_grpc",
    "solver_pb2",
    "solver_pb2_grpc",
    "job_pb2",
    "job_pb2_grpc",
    "subscription_pb2",
    "subscription_pb2_grpc",
    "hand_history_pb2",
    "hand_history_pb2_grpc",
    "core_pb2",
    "core_pb2_grpc",
]
