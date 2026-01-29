"""Hand history model for storing poker hand history files and processing status."""

import uuid
from datetime import datetime

from src.backend.database import db


class HandHistory(db.Model):
    __tablename__ = "hand_histories"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    filename = db.Column(db.String(255), nullable=False)
    file_hash = db.Column(db.String(64), nullable=False)  # SHA256 hash to prevent duplicates
    poker_site = db.Column(db.String(50), nullable=True)  # PokerStars, GGPoker, etc.

    # Processing status
    status = db.Column(db.String(20), default="uploading")  # uploading, processing, completed, failed
    total_hands = db.Column(db.Integer, nullable=True)
    processed_hands = db.Column(db.Integer, default=0)
    error_message = db.Column(db.Text, nullable=True)

    # Session summary
    session_start = db.Column(db.DateTime, nullable=True)
    session_end = db.Column(db.DateTime, nullable=True)
    total_profit = db.Column(db.Float, nullable=True)
    bb_per_100 = db.Column(db.Float, nullable=True)  # Big blinds per 100 hands

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship("User", backref=db.backref("hand_histories", lazy=True))

    def __init__(self, user_id, filename, file_hash, poker_site=None):
        self.user_id = user_id
        self.filename = filename
        self.file_hash = file_hash
        self.poker_site = poker_site

    def to_dict(self):
        """Convert hand history to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "filename": self.filename,
            "poker_site": self.poker_site,
            "status": self.status,
            "total_hands": self.total_hands,
            "processed_hands": self.processed_hands,
            "error_message": self.error_message,
            "session_start": (self.session_start.isoformat() if self.session_start else None),
            "session_end": self.session_end.isoformat() if self.session_end else None,
            "total_profit": self.total_profit,
            "bb_per_100": self.bb_per_100,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<HandHistory {self.filename}>"
