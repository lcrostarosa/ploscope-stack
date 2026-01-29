"""Utilities module for core PLO functionality.

This module contains utility functions for authentication, card evaluation, logging, rate limiting, and other common
operations.
"""


from .card_utils import (
    CardValidationError,
    DuplicateCardError,
    cards_to_str,
    convert_unicode_suits_to_standard,
    is_valid_card,
    str_to_cards,
    validate_all_cards_unique,
    validate_card_input,
    validate_no_duplicates,
)
from .evaluator import get_hand_class, get_hand_rank

# Card evaluation utilities
from .evaluator_utils import evaluate_plo_best_hand, evaluate_plo_hand, get_evaluator, reset_evaluator
from .json_logging import JSONFormatter, get_json_logger, log_with_context, setup_json_logging

# Logging utilities
from .logging_utils import (
    cleanup_logging_handlers,
    generate_request_id,
    get_client_ip,
    get_enhanced_logger,
    get_request_info,
    log_api_call,
    log_detailed_request,
    log_error_with_context,
    request_tracking_middleware,
    setup_enhanced_logging,
    setup_request_context,
    update_user_context,
)

__all__ = [
    # Card evaluation utilities
    "get_evaluator",
    "reset_evaluator",
    "evaluate_plo_hand",
    "evaluate_plo_best_hand",
    "get_hand_rank",
    "get_hand_class",
    "convert_unicode_suits_to_standard",
    "validate_no_duplicates",
    "validate_all_cards_unique",
    "validate_card_input",
    "str_to_cards",
    "cards_to_str",
    "is_valid_card",
    "DuplicateCardError",
    "CardValidationError",
    # Logging utilities
    "setup_enhanced_logging",
    "cleanup_logging_handlers",
    "generate_request_id",
    "get_client_ip",
    "get_request_info",
    "setup_request_context",
    "update_user_context",
    "get_enhanced_logger",
    "log_api_call",
    "log_detailed_request",
    "log_error_with_context",
    "request_tracking_middleware",
]
