import uuid
from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, declarative_base, mapped_column, relationship

Base = declarative_base()


class ParsedHand(Base):
    __tablename__ = "parsed_hands"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    hand_history_id: Mapped[str] = mapped_column(String(36), ForeignKey("hand_histories.id"), nullable=False)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)

    # Hand identification
    hand_id: Mapped[str] = mapped_column(String(100), nullable=False)  # Site's hand ID
    table_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    game_type: Mapped[str] = mapped_column(String(50), nullable=False)  # PLO, PLO8, etc.
    stakes: Mapped[str | None] = mapped_column(String(20), nullable=True)  # $0.50/$1.00

    # Timing
    hand_datetime: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    # Game state
    hero_seat: Mapped[int | None] = mapped_column(Integer, nullable=True)
    hero_cards: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # ["As", "Ks", "Qh", "Jd"]
    board_cards: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # ["Ah", "Kd", "Qc", "Js", "Td"]
    players: Mapped[list] = mapped_column(JSON, nullable=False)  # Player info and positions

    # Action and results
    actions: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # All betting actions
    pot_size: Mapped[float | None] = mapped_column(Float, nullable=True)
    hero_result: Mapped[float | None] = mapped_column(Float, nullable=True)  # Profit/loss for hero
    showdown_reached: Mapped[bool] = mapped_column(Boolean, default=False)

    # Analysis results (calculated after parsing)
    hero_equity: Mapped[float | None] = mapped_column(Float, nullable=True)
    expected_value: Mapped[float | None] = mapped_column(Float, nullable=True)
    equity_realization: Mapped[float | None] = mapped_column(Float, nullable=True)  # Actual result vs equity

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    # Relationships
    hand_history = relationship("HandHistory", backref="parsed_hands")
    user = relationship("User", backref="parsed_hands")

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
