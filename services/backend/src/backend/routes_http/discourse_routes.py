import base64
import hashlib
import hmac
import os
import urllib.parse

import requests
from flask import Blueprint, jsonify, redirect, request, url_for
from flask_jwt_extended import get_jwt_identity

from src.backend.models.user import User

from ..utils.auth_utils import auth_required, get_enhanced_logger, log_user_action

# Create blueprint for Discourse routes_http
discourse_routes = Blueprint("discourse", __name__)
logger = get_enhanced_logger(__name__)

# Discourse configuration
DISCOURSE_URL = os.getenv("DISCOURSE_URL", "https://forum.plosolver.com")
DISCOURSE_SSO_SECRET = os.getenv("DISCOURSE_SSO_SECRET")
DISCOURSE_SSO_URL = f"{DISCOURSE_URL}/session/sso_provider"


def generate_discourse_sso_url(user, return_url=None):
    """Generate Discourse SSO URL for authenticated user"""
    if not DISCOURSE_SSO_SECRET:
        raise ValueError("Discourse SSO secret not configured")

    # Build SSO payload
    sso_payload = {
        "nonce": None,  # Will be set from Discourse redirect
        "external_id": str(user.id),
        "email": user.email,
        "username": user.username or f"user_{user.id}",
        "name": (
            f"{user.first_name} {user.last_name}".strip()
            if user.first_name and user.last_name
            else user.username or user.email
        ),
        "require_activation": "false",
        "return_sso_url": return_url or f"{DISCOURSE_URL}/",
    }

    # Add optional fields if available
    if user.first_name:
        sso_payload["first_name"] = user.first_name
    if user.last_name:
        sso_payload["last_name"] = user.last_name

    # For direct SSO without Discourse initiation, we need to handle this differently
    # We'll generate a login URL that initiates the SSO flow
    login_url = f"{DISCOURSE_URL}/session/sso?return_path=/"

    return login_url


def verify_discourse_sso_signature(sso_payload, signature):
    """Verify Discourse SSO signature"""
    if not DISCOURSE_SSO_SECRET:
        return False

    expected_signature = hmac.new(
        DISCOURSE_SSO_SECRET.encode("utf-8"),
        sso_payload.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    return hmac.compare_digest(signature, expected_signature)


def create_discourse_sso_response(user, nonce, return_sso_url):
    """Create Discourse SSO response payload"""
    # Build the SSO response payload
    sso_params = {
        "nonce": nonce,
        "external_id": str(user.id),
        "email": user.email,
        "username": user.username or f"user_{user.id}",
        "name": (
            f"{user.first_name} {user.last_name}".strip()
            if user.first_name and user.last_name
            else user.username or user.email
        ),
        "require_activation": "false",
    }

    # Add optional fields
    if user.first_name:
        sso_params["first_name"] = user.first_name
    if user.last_name:
        sso_params["last_name"] = user.last_name

    # Create query string
    query_string = urllib.parse.urlencode(sso_params)

    # Base64 encode the payload
    sso_payload = base64.b64encode(query_string.encode("utf-8")).decode("utf-8")

    # Generate signature
    signature = hmac.new(
        DISCOURSE_SSO_SECRET.encode("utf-8"),
        sso_payload.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    return sso_payload, signature


@discourse_routes.route("/health", methods=["GET", "OPTIONS"])
def forum_health():
    """Check if the forum is available"""
    if request.method == "OPTIONS":
        return "", 200

    try:
        # Check if forum is accessible
        response = requests.get(f"{DISCOURSE_URL}/srv/status", timeout=5)

        if response.status_code == 200:
            return (
                jsonify({"available": True, "status": "healthy", "forum_url": DISCOURSE_URL}),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "available": False,
                        "status": "unhealthy",
                        "error": f"Forum returned {response.status_code}",
                    }
                ),
                200,
            )

    except requests.exceptions.RequestException:
        logger.warning("Forum health check failed")
        return (
            jsonify(
                {
                    "available": False,
                    "status": "unavailable",
                    "error": "Connection failed",
                }
            ),
            200,
        )


@discourse_routes.route("/sso", methods=["GET", "OPTIONS"])
@auth_required
def get_sso_url():
    """Get Discourse SSO URL for the authenticated user"""
    if request.method == "OPTIONS":
        return "", 200

    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"error": "User not found"}), 404

        if not DISCOURSE_SSO_SECRET:
            return jsonify({"error": "Forum integration not configured"}), 500

        # Generate SSO URL
        sso_url = generate_discourse_sso_url(user)

        log_user_action("DISCOURSE_SSO_REQUESTED", user.id)

        return jsonify({"sso_url": sso_url, "discourse_url": DISCOURSE_URL}), 200

    except Exception:
        logger.error("Discourse SSO URL generation error")
        return jsonify({"error": "Failed to generate forum access URL"}), 500


@discourse_routes.route("/sso_provider", methods=["GET", "POST"])
def sso_provider():
    """Handle Discourse SSO provider requests"""
    try:
        # Get SSO payload and signature from Discourse
        sso_payload = request.args.get("sso")
        signature = request.args.get("sig")

        if not sso_payload or not signature:
            return jsonify({"error": "Missing SSO parameters"}), 400

        # Verify signature
        if not verify_discourse_sso_signature(sso_payload, signature):
            return jsonify({"error": "Invalid SSO signature"}), 401

        # Decode payload
        try:
            decoded_payload = base64.b64decode(sso_payload).decode("utf-8")
            sso_params = urllib.parse.parse_qs(decoded_payload)
        except Exception:
            return jsonify({"error": "Invalid SSO payload"}), 400

        nonce = sso_params.get("nonce", [None])[0]
        return_sso_url = sso_params.get("return_sso_url", [DISCOURSE_URL])[0]

        if not nonce:
            return jsonify({"error": "Missing nonce"}), 400

        # For this endpoint, we need the user to be authenticated
        # We'll redirect them to login with a return URL
        auth_return_url = url_for(
            "discourse.sso_callback",
            nonce=nonce,
            return_sso_url=return_sso_url,
            _external=True,
        )

        # Redirect to frontend login with return URL
        frontend_login_url = f"{request.scheme}://{request.host}?sso_return={urllib.parse.quote(auth_return_url)}"

        return redirect(frontend_login_url)

    except Exception as e:
        logger.error(f"Discourse SSO provider error: {str(e)}")
        return jsonify({"error": "SSO provider error"}), 500


@discourse_routes.route("/sso_callback", methods=["GET"])
@auth_required
def sso_callback():
    """Handle SSO callback after user authentication"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"error": "User not found"}), 404

        nonce = request.args.get("nonce")
        return_sso_url = request.args.get("return_sso_url", DISCOURSE_URL)

        if not nonce:
            return jsonify({"error": "Missing nonce"}), 400

        # Create SSO response
        sso_payload, signature = create_discourse_sso_response(user, nonce, return_sso_url)

        # Redirect back to Discourse with SSO response
        discourse_callback_url = f"{return_sso_url}?sso={urllib.parse.quote(sso_payload)}&sig={signature}"

        log_user_action("DISCOURSE_SSO_COMPLETED", user.id)

        return redirect(discourse_callback_url)

    except Exception as e:
        logger.error(f"Discourse SSO callback error: {str(e)}")
        return jsonify({"error": "SSO callback error"}), 500


@discourse_routes.route("/webhook", methods=["POST"])
def discourse_webhook():
    """Handle Discourse webhooks for user synchronization"""
    try:
        # Verify webhook signature if configured
        webhook_secret = os.getenv("DISCOURSE_WEBHOOK_SECRET")
        if webhook_secret:
            signature = request.headers.get("X-Discourse-Event-Signature")
            if not signature:
                return jsonify({"error": "Missing webhook signature"}), 401

            # Verify signature (simplified - implement proper verification)
            # This would need proper HMAC verification in production

        event_type = request.headers.get("X-Discourse-Event-Type")

        if event_type in ["user_created", "user_updated"]:
            # Handle user events if needed
            logger.info(f"Received Discourse webhook: {event_type}")

        return jsonify({"status": "ok"}), 200

    except Exception as e:
        logger.error(f"Discourse webhook error: {str(e)}")
        return jsonify({"error": "Webhook processing error"}), 500
