"""
Core compatibility layer for PLOSolver Backend.

This module provides compatibility between the core package models and the backend's SQLAlchemy models.
It maps core package imports to the appropriate backend models.
"""

from src.backend.database import db

# Import backend models
from src.backend.models import Job, Spot, User
from src.backend.models.enums import JobStatus, JobType, SubscriptionTier


# Create compatibility aliases
# Map core.models imports to backend models
class UserCredit:
    """Compatibility class for UserCredit - placeholder for now."""

    pass


class UserSession:
    """Compatibility class for UserSession - placeholder for now."""

    pass


class ParsedHand:
    """Compatibility class for ParsedHand - placeholder for now."""

    pass


class HandHistory:
    """Compatibility class for HandHistory - placeholder for now."""

    pass


class SolverSolution:
    """Compatibility class for SolverSolution - placeholder for now."""

    pass


# Export all the models that might be imported
__all__ = [
    "User",
    "Job",
    "Spot",
    "UserCredit",
    "UserSession",
    "ParsedHand",
    "HandHistory",
    "SolverSolution",
    "JobStatus",
    "JobType",
    "SubscriptionTier",
    "db",
]
