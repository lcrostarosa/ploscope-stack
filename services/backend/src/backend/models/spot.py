import uuid
from datetime import datetime

from src.backend.database import db


class Spot(db.Model):
    __tablename__ = "spots"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)

    # Spot configuration
    top_board = db.Column(db.JSON, nullable=False)  # List of cards
    bottom_board = db.Column(db.JSON, nullable=False)  # List of cards
    players = db.Column(db.JSON, nullable=False)  # List of player objects with cards
    simulation_runs = db.Column(db.Integer, nullable=False, default=10000)
    max_hand_combinations = db.Column(db.Integer, nullable=False, default=10000)

    # Results
    results = db.Column(db.JSON, nullable=True)  # Store the simulation results

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship("User", backref=db.backref("spots", lazy=True))

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
