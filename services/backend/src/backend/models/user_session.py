import uuid
from datetime import datetime

from src.backend.database import db


class UserSession(db.Model):
    __tablename__ = "user_sessions"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    token_jti = db.Column(db.String(255), unique=True, nullable=False)  # JWT ID
    ip_address = db.Column(db.String(45), nullable=True)
    user_agent = db.Column(db.String(500), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)
    is_active = db.Column(db.Boolean, default=True)

    user = db.relationship("User", backref=db.backref("sessions", lazy=True))

    def __init__(self, user_id, token_jti, expires_at, ip_address=None, user_agent=None):
        self.user_id = user_id
        self.token_jti = token_jti
        self.expires_at = expires_at
        self.ip_address = ip_address
        self.user_agent = user_agent

    def deactivate(self):
        """Deactivate this session."""
        self.is_active = False
        db.session.commit()

    def is_expired(self):
        """Check if session is expired."""
        return datetime.utcnow() > self.expires_at

    def __repr__(self):
        return f"<UserSession {self.user_id}>"
