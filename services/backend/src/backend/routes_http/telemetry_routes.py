from flask import Blueprint, jsonify, request

from src.backend.services.telemetry_service import build_safe_telemetry_log

from ..utils.rate_limiter import get_enhanced_logger, rate_limit

logger = get_enhanced_logger(__name__)

telemetry_routes = Blueprint("telemetry", __name__)


@telemetry_routes.route("/", methods=["POST", "OPTIONS"])
@rate_limit("default")
def telemetry_ingest():
    """First-party, anonymous telemetry ingest.

    Accepts JSON payloads from the frontend when users opt into Usage Analytics.
    Does not require authentication; stores only coarse metadata and an event body
    without PII. The event is logged and can optionally be pushed to a data sink
    in the future. Returns 204 on success.
    """
    if request.method == "OPTIONS":
        return "", 200

    try:
        data = request.get_json(silent=True) or {}
        log_entry = build_safe_telemetry_log(data, request)
        logger.info(log_entry)
        return "", 204
    except Exception:  # noqa: BLE001 - broad except intentional to protect ingest endpoint
        logger.exception("Telemetry ingest failed")
        return jsonify({"error": "telemetry_error"}), 400
