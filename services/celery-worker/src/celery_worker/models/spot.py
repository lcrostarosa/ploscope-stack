import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, declarative_base, mapped_column, relationship

Base = declarative_base()


class Spot(Base):
    __tablename__ = "spots"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Spot configuration
    top_board: Mapped[dict] = mapped_column(JSON, nullable=False)  # List of cards
    bottom_board: Mapped[dict] = mapped_column(JSON, nullable=False)  # List of cards
    players: Mapped[list] = mapped_column(JSON, nullable=False)  # List of player objects with cards
    simulation_runs: Mapped[int] = mapped_column(Integer, nullable=False, default=10000)
    max_hand_combinations: Mapped[int] = mapped_column(Integer, nullable=False, default=10000)

    # Results
    results: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # Store the simulation results

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    # Relationships (optional, keep names consistent if needed elsewhere)
    # Note: relationship to User is left as string; define User model separately if required.
    user = relationship("User", backref="spots")

    def __init__(
        self,
        name,
        top_board,
        bottom_board,
        players,
        user_id=None,
        user=None,
        simulation_runs=10000,
        max_hand_combinations=10000,
        description=None,
    ):
        if user:
            self.user_id = user.id
        elif user_id:
            self.user_id = user_id
        else:
            raise ValueError("A Spot must have a user or user_id.")

        self.name = name
        self.top_board = top_board
        self.bottom_board = bottom_board
        self.players = players
        self.simulation_runs = simulation_runs
        self.max_hand_combinations = max_hand_combinations
        self.description = description

    def to_dict(self):
        """Convert spot to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "top_board": self.top_board,
            "bottom_board": self.bottom_board,
            "players": self.players,
            "simulation_runs": self.simulation_runs,
            "max_hand_combinations": self.max_hand_combinations,
            "results": self.results,
            "user_id": self.user_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Spot {self.name}>"
