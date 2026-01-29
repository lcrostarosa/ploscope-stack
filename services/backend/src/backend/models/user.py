import uuid
from datetime import datetime
from typing import Optional

from src.backend.database import bcrypt, db
from src.backend.models.enums import SubscriptionTier


class BaseModel:
    """Base model class for dataclass models."""

    def __init__(self):
        self.id = str(uuid.uuid4())
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return bcrypt.generate_password_hash(password).decode("utf-8")


def check_password(password: str, password_hash: str) -> bool:
    """Check if a password matches its hash."""
    return bcrypt.check_password_hash(password_hash, password)


class User(db.Model):
    """User model using SQLAlchemy ORM."""

    __tablename__ = "users"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    username = db.Column(db.String(100), unique=True, nullable=True, index=True)
    password_hash = db.Column(db.String(255), nullable=True)  # Nullable for OAuth users
    first_name = db.Column(db.String(100), nullable=True)
    last_name = db.Column(db.String(100), nullable=True)

    # OAuth fields
    google_id = db.Column(db.String(255), nullable=True, unique=True, index=True)
    facebook_id = db.Column(db.String(255), nullable=True, unique=True, index=True)
    profile_picture = db.Column(db.String(500), nullable=True)

    # Account status
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    email_verified = db.Column(db.Boolean, default=False, nullable=False)
    is_admin = db.Column(db.Boolean, default=False, nullable=False)
    is_beta_user = db.Column(db.Boolean, default=True, nullable=False)

    # Subscription fields
    subscription_tier = db.Column(db.Enum(SubscriptionTier), default=SubscriptionTier.FREE, nullable=False)
    stripe_customer_id = db.Column(db.String(255), nullable=True, unique=True, index=True)
    stripe_subscription_id = db.Column(db.String(255), nullable=True, unique=True, index=True)
    subscription_status = db.Column(db.String(50), default="active", nullable=False)
    subscription_current_period_end = db.Column(db.DateTime, nullable=True)
    subscription_cancel_at_period_end = db.Column(db.Boolean, default=False, nullable=False)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    last_login = db.Column(db.DateTime, nullable=True)

    def __init__(
        self,
        email: str,
        username: Optional[str] = None,
        password: Optional[str] = None,
        password_hash: Optional[str] = None,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        google_id: Optional[str] = None,
        facebook_id: Optional[str] = None,
        profile_picture: Optional[str] = None,
        is_admin: bool = False,
        is_beta_user: bool = True,
        subscription_tier: SubscriptionTier = SubscriptionTier.FREE,
    ):
        self.email = email
        self.username = username

        # Handle password - if password is provided, hash it; otherwise use password_hash
        if password is not None:
            self.password_hash = hash_password(password)
        else:
            self.password_hash = password_hash

        self.first_name = first_name
        self.last_name = last_name
        self.google_id = google_id
        self.facebook_id = facebook_id
        self.profile_picture = profile_picture
        self.is_admin = is_admin
        self.is_beta_user = is_beta_user
        self.subscription_tier = subscription_tier

    def set_password(self, password: str) -> None:
        """Hash and set password using bcrypt."""
        from src.backend.database import bcrypt

        self.password_hash = bcrypt.generate_password_hash(password).decode("utf-8")

    def check_password(self, password: str) -> bool:
        """Check if provided password matches hash."""
        if not self.password_hash:
            return False
        from src.backend.database import bcrypt

        return bcrypt.check_password_hash(self.password_hash, password)

    def update_last_login(self) -> None:
        """Update last login timestamp."""
        self.last_login = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def to_dict(self) -> dict:
        """Convert user to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "email": self.email,
            "username": self.username,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "profile_picture": self.profile_picture,
            "is_active": self.is_active,
            "email_verified": self.email_verified,
            "is_beta_user": self.is_beta_user,
            "subscription_tier": self.subscription_tier.value if self.subscription_tier else None,
            "subscription_status": self.subscription_status,
            "subscription_current_period_end": (
                self.subscription_current_period_end.isoformat() if self.subscription_current_period_end else None
            ),
            "subscription_cancel_at_period_end": self.subscription_cancel_at_period_end,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
        }

    @classmethod
    def create_user(
        cls,
        email: str,
        password: Optional[str] = None,
        username: Optional[str] = None,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        google_id: Optional[str] = None,
        facebook_id: Optional[str] = None,
        profile_picture: Optional[str] = None,
        is_admin: bool = False,
        is_beta_user: bool = True,
        subscription_tier: SubscriptionTier = SubscriptionTier.FREE,
    ) -> "User":
        """Factory method to create a new user with optional password."""
        user = cls(
            email=email,
            username=username,
            password=password,
            first_name=first_name,
            last_name=last_name,
            google_id=google_id,
            facebook_id=facebook_id,
            profile_picture=profile_picture,
            is_admin=is_admin,
            is_beta_user=is_beta_user,
            subscription_tier=subscription_tier,
        )

        return user

    def __repr__(self) -> str:
        return f"<User {self.username or self.email}>"
