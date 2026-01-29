from enum import Enum


class JobType(Enum):
    SPOT_SIMULATION = "SPOT_SIMULATION"
    SOLVER_ANALYSIS = "SOLVER_ANALYSIS"


class JobStatus(Enum):
    QUEUED = "QUEUED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class SubscriptionTier(Enum):
    FREE = "FREE"
    PRO = "PRO"
    ELITE = "ELITE"
