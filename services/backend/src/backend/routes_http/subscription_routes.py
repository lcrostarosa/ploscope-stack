import os
from datetime import datetime

import stripe
from core.utils.logging_utils import get_enhanced_logger
from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from src.backend.database import db
from src.backend.models.user import User

logger = get_enhanced_logger(__name__)

# Initialize Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "sk_test_...")

subscription_bp = Blueprint("subscription", __name__)

# Stripe price IDs - you'll need to create these in your Stripe dashboard
STRIPE_PRICES = {
    "PRO": {
        "monthly": os.getenv("STRIPE_PRICE_PRO_MONTHLY", "price_pro_monthly"),
        "yearly": os.getenv("STRIPE_PRICE_PRO_YEARLY", "price_pro_yearly"),
    },
    "ELITE": {
        "monthly": os.getenv("STRIPE_PRICE_ELITE_MONTHLY", "price_elite_monthly"),
        "yearly": os.getenv("STRIPE_PRICE_ELITE_YEARLY", "price_elite_yearly"),
    },
}


@subscription_bp.route("/create-checkout-session", methods=["POST"])
@jwt_required()
def create_checkout_session():
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user:
            return jsonify({"error": "User not found"}), 404

        data = request.get_json()
        plan = data.get("plan")  # 'pro' or 'elite'
        billing_cycle = data.get("billing_cycle")  # 'monthly' or 'yearly'

        if not all([plan, billing_cycle]):
            return jsonify({"error": "Missing required parameters"}), 400

        if plan not in STRIPE_PRICES or billing_cycle not in STRIPE_PRICES[plan]:
            return jsonify({"error": "Invalid plan or billing cycle"}), 400

        price_id = STRIPE_PRICES[plan][billing_cycle]

        # Create or get Stripe customer
        if not user.stripe_customer_id:
            customer = stripe.Customer.create(
                email=user.email,
                name=(f"{user.first_name} {user.last_name}" if user.first_name and user.last_name else user.username),
                metadata={"user_id": user.id},
            )
            user.stripe_customer_id = customer.id
            db.session.commit()

        # Get the base URL for success/cancel URLs
        base_url = request.host_url.rstrip("/")

        # Create Stripe Checkout Session
        checkout_session = stripe.checkout.Session.create(
            customer=user.stripe_customer_id,
            payment_method_types=["card"],
            line_items=[
                {
                    "price": price_id,
                    "quantity": 1,
                }
            ],
            mode="subscription",
            success_url=f"{base_url}/checkout/success?session_id={{CHECKOUT_SESSION_ID}}",
            cancel_url=f"{base_url}/pricing",
            metadata={"user_id": user.id, "plan": plan, "billing_cycle": billing_cycle},
            subscription_data={
                "metadata": {
                    "user_id": user.id,
                    "plan": plan,
                    "billing_cycle": billing_cycle,
                }
            },
            allow_promotion_codes=True,  # Allow coupon codes
            billing_address_collection="required",
            customer_update={"address": "auto", "name": "auto"},
        )

        return jsonify({"checkout_url": checkout_session.url, "session_id": checkout_session.id})

    except stripe.error.StripeError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Checkout session creation error: {str(e)}")
        return jsonify({"error": "An error occurred creating checkout session"}), 500


@subscription_bp.route("/checkout-success", methods=["GET"])
@jwt_required()
def checkout_success():
    """Handle successful checkout - verify session and update user"""
    try:
        session_id = request.args.get("session_id")
        if not session_id:
            return jsonify({"error": "No session ID provided"}), 400

        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user:
            return jsonify({"error": "User not found"}), 404

        # Retrieve the checkout session
        session = stripe.checkout.Session.retrieve(session_id)

        if session.payment_status == "paid":
            # Get the subscription
            subscription = stripe.Subscription.retrieve(session.subscription)

            # Update user subscription info
            user.stripe_subscription_id = subscription.id
            user.subscription_tier = session.metadata.get("plan")
            user.subscription_status = subscription.status
            user.subscription_current_period_end = datetime.fromtimestamp(subscription.current_period_end)
            user.subscription_cancel_at_period_end = subscription.cancel_at_period_end

            db.session.commit()

            return jsonify(
                {
                    "success": True,
                    "subscription_id": subscription.id,
                    "plan": user.subscription_tier,
                    "status": user.subscription_status,
                }
            )
        else:
            return jsonify({"error": "Payment not completed"}), 400

    except Exception as e:
        logger.error(f"Checkout success error: {str(e)}")
        return jsonify({"error": "Failed to verify checkout"}), 500


@subscription_bp.route("/cancel-subscription", methods=["POST"])
@jwt_required()
def cancel_subscription():
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user or not user.stripe_subscription_id:
            return jsonify({"error": "No active subscription found"}), 404

        # Cancel subscription at period end
        stripe.Subscription.modify(user.stripe_subscription_id, cancel_at_period_end=True)

        # Update user record
        user.subscription_cancel_at_period_end = True
        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Subscription will be canceled at the end of the billing period",
            }
        )

    except Exception as e:
        logger.error(f"Subscription cancellation error: {str(e)}")
        return jsonify({"error": "Failed to cancel subscription"}), 500


@subscription_bp.route("/reactivate-subscription", methods=["POST"])
@jwt_required()
def reactivate_subscription():
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user or not user.stripe_subscription_id:
            return jsonify({"error": "No subscription found"}), 404

        # Reactivate subscription
        subscription = stripe.Subscription.modify(user.stripe_subscription_id, cancel_at_period_end=False)

        # Update user record
        user.subscription_cancel_at_period_end = False
        user.subscription_status = subscription.status
        db.session.commit()

        return jsonify({"success": True, "message": "Subscription reactivated successfully"})

    except Exception as e:
        logger.error(f"Subscription reactivation error: {str(e)}")
        return jsonify({"error": "Failed to reactivate subscription"}), 500


@subscription_bp.route("/subscription-status", methods=["GET"])
@jwt_required()
def get_subscription_status():
    try:
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)

        if not user:
            return jsonify({"error": "User not found"}), 404

        if not user.stripe_subscription_id:
            return jsonify(
                {
                    "tier": user.subscription_tier,
                    "status": "FREE",
                    "current_period_end": None,
                    "cancel_at_period_end": False,
                }
            )

        # Get latest subscription info from Stripe
        subscription = stripe.Subscription.retrieve(user.stripe_subscription_id)

        # Update user record with latest info
        user.subscription_status = subscription.status
        user.subscription_current_period_end = datetime.fromtimestamp(subscription.current_period_end)
        user.subscription_cancel_at_period_end = subscription.cancel_at_period_end
        db.session.commit()

        return jsonify(
            {
                "tier": user.subscription_tier,
                "status": subscription.status,
                "current_period_end": subscription.current_period_end,
                "cancel_at_period_end": subscription.cancel_at_period_end,
            }
        )

    except Exception as e:
        logger.error(f"Subscription status error: {str(e)}")
        return jsonify({"error": "Failed to get subscription status"}), 500


@subscription_bp.route("/webhook", methods=["POST"])
def stripe_webhook():
    """Handle Stripe webhooks for subscription updates"""
    payload = request.get_data()
    sig_header = request.headers.get("Stripe-Signature")

    endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, endpoint_secret)
    except ValueError:
        return jsonify({"error": "Invalid payload"}), 400
    except stripe.error.SignatureVerificationError:
        return jsonify({"error": "Invalid signature"}), 400

    # Handle the event
    if event["type"] == "customer.subscription.created":
        subscription = event["data"]["object"]
        handle_subscription_created(subscription)
    elif event["type"] == "customer.subscription.updated":
        subscription = event["data"]["object"]
        handle_subscription_updated(subscription)
    elif event["type"] == "customer.subscription.deleted":
        subscription = event["data"]["object"]
        handle_subscription_deleted(subscription)
    elif event["type"] == "invoice.payment_failed":
        invoice = event["data"]["object"]
        handle_payment_failed(invoice)
    elif event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        handle_checkout_completed(session)

    return jsonify({"status": "success"})


def handle_checkout_completed(session):
    """Handle completed checkout from Stripe webhooks"""
    try:
        if session["mode"] == "subscription":
            user_id = session["metadata"].get("user_id")
            if user_id:
                user = User.query.get(user_id)
                if user:
                    subscription = stripe.Subscription.retrieve(session["subscription"])
                    user.stripe_subscription_id = subscription.id
                    user.subscription_tier = session["metadata"].get("plan", "PRO")
                    user.subscription_status = subscription.status
                    user.subscription_current_period_end = datetime.fromtimestamp(subscription.current_period_end)
                    user.subscription_cancel_at_period_end = subscription.cancel_at_period_end
                    db.session.commit()
    except Exception as e:
        logger.error(f"Error handling checkout completion: {str(e)}")


def handle_subscription_created(subscription):
    """Handle new subscriptions from Stripe webhooks"""
    try:
        user_id = subscription["metadata"].get("user_id")
        if user_id:
            user = User.query.get(user_id)
            if user:
                user.stripe_subscription_id = subscription["id"]
                user.subscription_status = subscription["status"]
                user.subscription_current_period_end = datetime.fromtimestamp(subscription["current_period_end"])
                user.subscription_cancel_at_period_end = subscription["cancel_at_period_end"]
                db.session.commit()
    except Exception as e:
        logger.error(f"Error handling subscription creation: {str(e)}")


def handle_subscription_updated(subscription):
    """Handle subscription updates from Stripe webhooks"""
    try:
        customer_id = subscription["customer"]
        user = User.query.filter_by(stripe_customer_id=customer_id).first()
        if user:
            user.subscription_status = subscription["status"]
            user.subscription_current_period_end = datetime.fromtimestamp(subscription["current_period_end"])
            user.subscription_cancel_at_period_end = subscription["cancel_at_period_end"]
            db.session.commit()
    except Exception as e:
        logger.error(f"Error handling subscription update: {str(e)}")


def handle_subscription_deleted(subscription):
    """Handle subscription deletions from Stripe webhooks"""
    try:
        customer_id = subscription["customer"]
        user = User.query.filter_by(stripe_customer_id=customer_id).first()
        if user:
            user.subscription_tier = "FREE"
            user.subscription_status = "canceled"
            user.stripe_subscription_id = None
            user.subscription_current_period_end = None
            user.subscription_cancel_at_period_end = False
            db.session.commit()
    except Exception as e:
        logger.error(f"Error handling subscription deletion: {str(e)}")


def handle_payment_failed(invoice):
    """Handle failed payments from Stripe webhooks"""
    try:
        customer_id = invoice["customer"]
        user = User.query.filter_by(stripe_customer_id=customer_id).first()
        if user:
            user.subscription_status = "past_due"
            db.session.commit()
            # You might want to send an email notification here
    except Exception as e:
        logger.error(f"Error handling payment failure: {str(e)}")
