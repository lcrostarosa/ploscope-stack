import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional


@dataclass
class SolverSolution:
    user_id: str
    name: str
    game_state: dict[str, Any]
    solution: dict[str, Any]
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    description: Optional[str] = None
    iterations: int = 1000
    solve_time: Optional[float] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    user: Optional[Any] = None  # For compatibility

    def __post_init__(self):
        if self.user:
            self.user_id = self.user.id

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "game_state": self.game_state,
            "solution": self.solution,
            "iterations": self.iterations,
            "solve_time": self.solve_time,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<SolverSolution {self.name}>"

    @classmethod
    def from_dict(cls, data):
        solution = cls(
            name=data.get("name"),
            game_state=data.get("game_state"),
            solution=data.get("solution"),
            user_id=data.get("user_id"),
            iterations=data.get("iterations"),
            solve_time=data.get("solve_time"),
            description=data.get("description"),
        )
        solution.id = data.get("id")
        solution.created_at = datetime.fromisoformat(data.get("created_at")) if data.get("created_at") else None
        solution.updated_at = datetime.fromisoformat(data.get("updated_at")) if data.get("updated_at") else None
        return solution
