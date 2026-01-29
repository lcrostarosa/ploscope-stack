import uuid
from datetime import datetime

from src.backend.database import db


class ParsedHand(db.Model):
    __tablename__ = "parsed_hands"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    hand_history_id = db.Column(db.String(36), db.ForeignKey("hand_histories.id"), nullable=False)
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)

    # Hand identification
    hand_id = db.Column(db.String(100), nullable=False)  # Site's hand ID
    table_name = db.Column(db.String(100), nullable=True)
    game_type = db.Column(db.String(50), nullable=False)  # PLO, PLO8, etc.
    stakes = db.Column(db.String(20), nullable=True)  # $0.50/$1.00

    # Timing
    hand_datetime = db.Column(db.DateTime, nullable=False)

    # Game state
    hero_seat = db.Column(db.Integer, nullable=True)
    hero_cards = db.Column(db.JSON, nullable=True)  # ["As", "Ks", "Qh", "Jd"]
    board_cards = db.Column(db.JSON, nullable=True)  # ["Ah", "Kd", "Qc", "Js", "Td"]
    players = db.Column(db.JSON, nullable=False)  # Player info and positions

    # Action and results
    actions = db.Column(db.JSON, nullable=True)  # All betting actions
    pot_size = db.Column(db.Float, nullable=True)
    hero_result = db.Column(db.Float, nullable=True)  # Profit/loss for hero
    showdown_reached = db.Column(db.Boolean, default=False)

    # Analysis results (calculated after parsing)
    hero_equity = db.Column(db.Float, nullable=True)
    expected_value = db.Column(db.Float, nullable=True)
    equity_realization = db.Column(db.Float, nullable=True)  # Actual result vs equity

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    hand_history = db.relationship("HandHistory", backref=db.backref("parsed_hands", lazy=True))
    user = db.relationship("User", backref=db.backref("parsed_hands", lazy=True))

    def __init__(self, hand_history_id, user_id, hand_id, hand_datetime, game_type, players):
        self.hand_history_id = hand_history_id
        self.user_id = user_id
        self.hand_id = hand_id
        self.hand_datetime = hand_datetime
        self.game_type = game_type
        self.players = players

    def to_dict(self):
        """Convert parsed hand to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "hand_id": self.hand_id,
            "table_name": self.table_name,
            "game_type": self.game_type,
            "stakes": self.stakes,
            "max_players": self.max_players,
            "hand_datetime": (self.hand_datetime.isoformat() if self.hand_datetime else None),
            "hero_seat": self.hero_seat,
            "hero_cards": self.hero_cards,
            "board_cards": self.board_cards,
            "players": self.players,
            "actions": self.actions,
            "pot_size": self.pot_size,
            "hero_result": self.hero_result,
            "showdown_reached": self.showdown_reached,
            "hero_equity": self.hero_equity,
            "expected_value": self.expected_value,
            "equity_realization": self.equity_realization,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<ParsedHand {self.hand_id}>"
