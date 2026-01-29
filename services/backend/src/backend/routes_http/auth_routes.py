"""
Authentication routes_http for PLOSolver.

This module provides authentication endpoints including registration, login, logout,
and user management.
"""

# import logging
# from datetime import datetime, timedelta
# from functools import wraps

import smtplib
from email.mime.text import MIMEText

from core.utils.logging_utils import get_enhanced_logger
from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import (  # create_refresh_token,; verify_jwt_in_request,
    create_access_token,
    get_jwt,
    get_jwt_identity,
    jwt_required,
)

from src.backend.database import db
from src.backend.models.user import User
from src.backend.models.user_credit import UserCredit
from src.backend.models.user_session import UserSession

# Import utilities
from ..utils.auth_utils import (
    auth_required,
    auth_required_with_options,
    create_user_tokens,
    log_user_action,
    revoke_all_user_tokens,
    revoke_user_token,
    validate_email,
    validate_password,
)

logger = get_enhanced_logger(__name__)

auth_routes = Blueprint("auth", __name__)


def send_waitlist_email(payload: dict):
    try:
        notify_email = current_app.config.get("WAITLIST_NOTIFY_EMAIL")
        if not notify_email:
            return False
        sender = current_app.config.get("MAIL_DEFAULT_SENDER") or notify_email
        body = "New waitlist submission:\n\n" + "\n".join([f"{k}: {v}" for k, v in payload.items()])
        msg = MIMEText(body)
        msg["Subject"] = "PLOScope Waitlist Submission"
        msg["From"] = sender
        msg["To"] = notify_email

        server = current_app.config.get("MAIL_SERVER")
        port = current_app.config.get("MAIL_PORT")
        username = current_app.config.get("MAIL_USERNAME")
        password = current_app.config.get("MAIL_PASSWORD")
        use_tls = current_app.config.get("MAIL_USE_TLS", True)

        with smtplib.SMTP(server, port) as smtp:
            if use_tls:
                smtp.starttls()
            if username and password:
                smtp.login(username, password)
            smtp.sendmail(sender, [notify_email], msg.as_string())
        return True
    except Exception as e:
        logger.error(f"Waitlist email send failed: {e}")
        return False


@auth_routes.route("/waitlist", methods=["POST", "OPTIONS"])
def waitlist():
    if request.method == "OPTIONS":
        return "", 200
    data = request.get_json() or {}
    # Basic validation
    email = (data.get("email") or "").strip().lower()
    if not validate_email(email):
        return jsonify({"error": "Invalid email"}), 400
    # Send notification email
    sent = send_waitlist_email(data)
    return jsonify({"message": "Added to waitlist", "notified": bool(sent)}), 200


@auth_routes.route("/register", methods=["POST", "OPTIONS"])
def register():
    """Register a new user with email and password"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        email = data.get("email", "").strip().lower()
        password = data.get("password", "")
        username = data.get("username", "").strip()
        first_name = data.get("first_name", "").strip()
        last_name = data.get("last_name", "").strip()
        accept_terms = data.get("accept_terms", False)

        # Validate required fields
        if not email:
            return jsonify({"error": "Email is required"}), 400

        if not password:
            return jsonify({"error": "Password is required"}), 400

        if not accept_terms:
            return (
                jsonify({"error": "You must accept the Terms of Service and Privacy Policy to continue"}),
                400,
            )

        # Validate email format
        if not validate_email(email):
            return jsonify({"error": "Invalid email format"}), 400

        # Validate password strength
        is_valid, message = validate_password(password)
        if not is_valid:
            return jsonify({"error": message}), 400

        # Check if user already exists
        existing_user = User.query.filter_by(email=email).first()
        if existing_user:
            return jsonify({"error": "User with this email already exists"}), 409

        # Check username availability if provided
        if username:
            existing_username = User.query.filter_by(username=username).first()
            if existing_username:
                return jsonify({"error": "Username is already taken"}), 409

        # Enforce signup limit
        try:
            total_users = User.query.count()
        except Exception:
            total_users = 0
        signup_limit = getattr(current_app.config, "SIGNUP_LIMIT", 10)
        if total_users >= signup_limit:
            return (
                jsonify(
                    {
                        "error": "signup_limit_reached",
                        "message": "Signups are currently limited. Please join the waitlist.",
                    }
                ),
                429,
            )

        # Create new user
        user = User(
            email=email,
            username=username if username else None,
            password=password,
            first_name=first_name if first_name else None,
            last_name=last_name if last_name else None,
        )

        db.session.add(user)
        db.session.commit()

        # Create tokens
        access_token, refresh_token = create_user_tokens(user.id)

        # Update last login
        user.update_last_login()

        log_user_action("USER_REGISTERED", user.id, {"username": username})

        return (
            jsonify(
                {
                    "message": "User registered successfully",
                    "user": user.to_dict(),
                    "access_token": access_token,
                    "refresh_token": refresh_token,
                }
            ),
            201,
        )

    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Registration failed"}), 500


@auth_routes.route("/login", methods=["POST", "OPTIONS"])
def login():
    """Login with email/username and password"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        email_or_username = data.get("email", "").strip()
        password = data.get("password", "")

        if not email_or_username or not password:
            return jsonify({"error": "Email/username and password are required"}), 400

        # Find user by email or username
        user = None
        if "@" in email_or_username:
            # Looks like an email
            user = User.query.filter_by(email=email_or_username.lower(), is_active=True).first()
        else:
            # Looks like a username
            user = User.query.filter_by(username=email_or_username, is_active=True).first()

        # If not found, try the other field as fallback
        if not user:
            if "@" in email_or_username:
                user = User.query.filter_by(username=email_or_username, is_active=True).first()
            else:
                user = User.query.filter_by(email=email_or_username.lower(), is_active=True).first()

        if not user:
            return jsonify({"error": "Invalid credentials"}), 401

        # Check password
        if not user.check_password(password):
            return jsonify({"error": "Invalid credentials"}), 401

        # Create tokens
        access_token, refresh_token = create_user_tokens(user.id)

        # Update last login
        user.update_last_login()

        log_user_action("USER_LOGIN", user.id)

        return (
            jsonify(
                {
                    "message": "Login successful",
                    "user": user.to_dict(),
                    "access_token": access_token,
                    "refresh_token": refresh_token,
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return jsonify({"error": "Login failed"}), 500


@auth_routes.route("/logout", methods=["POST", "OPTIONS"])
@auth_required
def logout():
    """Logout current user session"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        claims = get_jwt()
        jti = claims["jti"]

        # Revoke current token
        revoke_user_token(jti)

        log_user_action("USER_LOGOUT", request.current_user.id)

        return jsonify({"message": "Logout successful"}), 200

    except Exception as e:
        logger.error(f"Logout error: {str(e)}")
        return jsonify({"error": "Logout failed"}), 500


@auth_routes.route("/logout-all", methods=["POST", "OPTIONS"])
@auth_required
def logout_all():
    """Logout from all devices"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user_id = get_jwt_identity()

        # Revoke all tokens for user
        revoked_count = revoke_all_user_tokens(user_id)

        log_user_action(
            "USER_LOGOUT_ALL",
            request.current_user.id,
            {"sessions_revoked": revoked_count},
        )

        return (
            jsonify({"message": f"Logged out from all devices ({revoked_count} sessions)"}),
            200,
        )

    except Exception as e:
        logger.error(f"Logout all error: {str(e)}")
        return jsonify({"error": "Logout failed"}), 500


@auth_routes.route("/refresh", methods=["POST", "OPTIONS"])
@jwt_required(refresh=True)
def refresh():
    """Refresh access token using refresh token"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user:
            return jsonify({"error": "User not found"}), 404

        # Create new access token
        access_token = create_access_token(identity=current_user_id, additional_claims={"user_id": current_user_id})

        return (
            jsonify(
                {
                    "access_token": access_token,
                    "message": "Token refreshed successfully",
                }
            ),
            200,
        )

    except Exception as e:
        logger.error(f"Token refresh error: {str(e)}")
        return jsonify({"error": "Token refresh failed"}), 500


@auth_routes.route("/me", methods=["GET", "OPTIONS"])
@auth_required_with_options
def get_current_user():
    """Get current user information"""
    try:
        return jsonify(request.current_user.to_dict()), 200

    except Exception as e:
        logger.error(f"Get current user error: {str(e)}")
        return jsonify({"error": "Failed to get user information"}), 500


@auth_routes.route("/update-profile", methods=["PUT", "OPTIONS"])
@auth_required
def update_profile():
    """Update user profile"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        user = request.current_user

        # Update allowed fields
        if "username" in data:
            username = data["username"].strip()
            if username != user.username:
                # Check if username is available
                existing = User.query.filter_by(username=username).first()
                if existing and existing.id != user.id:
                    return jsonify({"error": "Username is already taken"}), 409
                user.username = username

        if "first_name" in data:
            user.first_name = data["first_name"].strip()

        if "last_name" in data:
            user.last_name = data["last_name"].strip()

        db.session.commit()

        log_user_action("PROFILE_UPDATED", user.id)

        return (
            jsonify({"message": "Profile updated successfully", "user": user.to_dict()}),
            200,
        )

    except Exception as e:
        logger.error(f"Profile update error: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Profile update failed"}), 500


@auth_routes.route("/change-password", methods=["PUT", "OPTIONS"])
@auth_required
def change_password():
    """Change user password"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400

        current_password = data.get("current_password", "")
        new_password = data.get("new_password", "")

        if not current_password or not new_password:
            return jsonify({"error": "Current and new passwords are required"}), 400

        user = request.current_user

        # Verify current password
        if not user.check_password(current_password):
            return jsonify({"error": "Current password is incorrect"}), 401

        # Validate new password
        is_valid, message = validate_password(new_password)
        if not is_valid:
            return jsonify({"error": message}), 400

        # Update password
        user.set_password(new_password)
        db.session.commit()

        # Revoke all existing sessions except current one
        claims = get_jwt()
        current_jti = claims["jti"]
        sessions = UserSession.query.filter_by(user_id=user.id, is_active=True).all()
        revoked_count = 0

        for session in sessions:
            if session.token_jti != current_jti:
                session.deactivate()
                revoked_count += 1

        log_user_action("PASSWORD_CHANGED", user.id, {"sessions_revoked": revoked_count})

        return (
            jsonify({"message": f"Password changed successfully. {revoked_count} other sessions were logged out."}),
            200,
        )

    except Exception as e:
        logger.error(f"Password change error: {str(e)}")
        db.session.rollback()
        return jsonify({"error": "Password change failed"}), 500


@auth_routes.route("/credits", methods=["GET", "OPTIONS"])
@auth_required
def get_user_credits():
    """Get current user's credit information"""
    # Handle preflight requests
    if request.method == "OPTIONS":
        return "", 200

    try:
        user = request.current_user

        # Get or create credit info
        if not user.credit_info:
            credit_info = UserCredit(user_id=user.id)
            db.session.add(credit_info)
            db.session.commit()
        else:
            credit_info = user.credit_info

        return (
            jsonify({"credits_info": credit_info.get_remaining_credits(user.subscription_tier)}),
            200,
        )

    except Exception as e:
        logger.error(f"Get credits error: {str(e)}")
        return jsonify({"error": "Failed to get credit information"}), 500
