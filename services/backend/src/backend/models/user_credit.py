import uuid
from datetime import datetime

from sqlalchemy import text

from src.backend.database import db


class UserCredit(db.Model):
    __tablename__ = "user_credits"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)

    # Credit tracking
    daily_credits_used = db.Column(db.Integer, default=0)
    monthly_credits_used = db.Column(db.Integer, default=0)

    # Reset tracking
    daily_reset_date = db.Column(db.Date, default=lambda: datetime.utcnow().date())
    monthly_reset_date = db.Column(db.Date, default=lambda: datetime.utcnow().replace(day=1).date())

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship("User", backref=db.backref("credit_info", uselist=False, lazy=True))

    def __init__(self, user_id):
        self.user_id = user_id

    def get_credit_limits(self, subscription_tier):
        """Get credit limits based on subscription tier."""
        limits = {
            "FREE": {"daily": 1000, "monthly": 1000},
            "PRO": {"daily": 1000, "monthly": 1000},
            "ELITE": {"daily": 1000, "monthly": 1000},
        }
        return limits.get(subscription_tier, limits["FREE"])

    def can_use_credit(self, subscription_tier, job_type="spot"):
        """Check if user can use a credit."""
        limits = self.get_credit_limits(subscription_tier)

        # Check if reset is needed
        today = datetime.utcnow().date()
        current_month = datetime.utcnow().replace(day=1).date()

        if self.daily_reset_date != today:
            self.daily_credits_used = 0
            self.daily_reset_date = today

        if self.monthly_reset_date != current_month:
            self.monthly_credits_used = 0
            self.monthly_reset_date = current_month

        # Check limits
        daily_available = self.daily_credits_used < limits["daily"]
        monthly_available = self.monthly_credits_used < limits["monthly"]

        return daily_available and monthly_available

    def use_credit(self):
        """Use a credit (increment counters) - atomic operation to prevent race conditions"""
        # Use SQL atomic update to prevent race conditions
        result = db.session.execute(
            text(
                """
                UPDATE user_credits
                SET daily_credits_used = daily_credits_used + 1,
                    monthly_credits_used = monthly_credits_used + 1
                WHERE user_id = :user_id
                RETURNING daily_credits_used, monthly_credits_used
            """
            ),
            {"user_id": self.user_id},
        )

        updated_credits = result.fetchone()
        if updated_credits:
            self.daily_credits_used = updated_credits[0]
            self.monthly_credits_used = updated_credits[1]

        db.session.commit()

    def get_remaining_credits(self, subscription_tier):
        """Get remaining credits for today and this month."""
        limits = self.get_credit_limits(subscription_tier)

        # Check if reset is needed
        today = datetime.utcnow().date()
        current_month = datetime.utcnow().replace(day=1).date()

        if self.daily_reset_date != today:
            daily_remaining = limits["daily"]
        else:
            daily_remaining = max(0, limits["daily"] - self.daily_credits_used)

        if self.monthly_reset_date != current_month:
            monthly_remaining = limits["monthly"]
        else:
            monthly_remaining = max(0, limits["monthly"] - self.monthly_credits_used)

        return {
            "daily_remaining": daily_remaining,
            "monthly_remaining": monthly_remaining,
            "daily_limit": limits["daily"],
            "monthly_limit": limits["monthly"],
        }

    def to_dict(self, subscription_tier):
        """Convert to dictionary for JSON serialization."""
        remaining = self.get_remaining_credits(subscription_tier)
        return {
            "id": self.id,
            "daily_credits_used": self.daily_credits_used,
            "monthly_credits_used": self.monthly_credits_used,
            "daily_reset_date": (self.daily_reset_date.isoformat() if self.daily_reset_date else None),
            "monthly_reset_date": (self.monthly_reset_date.isoformat() if self.monthly_reset_date else None),
            **remaining,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<UserCredit {self.user_id}>"
