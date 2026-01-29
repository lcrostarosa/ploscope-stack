"""Centralized Evaluator utility to avoid creating new instances for every hand evaluation.

This provides a singleton pattern for the Treys Evaluator to improve performance.
"""

from itertools import combinations

# import logging
from typing import Optional

from treys import Evaluator

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)
# Global evaluator instance
_evaluator: Optional[Evaluator] = None


def get_evaluator() -> Evaluator:
    """Get or create the global evaluator instance.

    This ensures we only create one Evaluator instance per process.
    """
    global _evaluator
    if _evaluator is None:
        _evaluator = Evaluator()
        logger.info("Initialized Evaluator singleton for this process")
    return _evaluator


def reset_evaluator():
    """Reset the global evaluator instance.

    Useful for testing or when you need a fresh instance.
    """
    global _evaluator
    _evaluator = None
    logger.info("Reset Evaluator singleton")


def evaluate_plo_hand(hole_cards, board) -> int:
    """Evaluate a PLO hand using the global evaluator instance.

    This is a convenience function that uses the singleton evaluator.
    """
    evaluator = get_evaluator()
    best_score = float("inf")  # Lower is better in Treys

    # Try all combinations of 2 hole cards with 3 board cards
    for hole_combo in combinations(hole_cards, 2):
        for board_combo in combinations(board, 3):
            hand = list(hole_combo) + list(board_combo)
            try:
                score = evaluator.evaluate(hand, [])
                if score < best_score:
                    best_score = score
            except Exception as e:
                logger.error(f"Error evaluating hand: {hand} - {e}")
                continue

    return best_score


def evaluate_plo_best_hand(hole_cards: list[int], board: list[int]) -> tuple[int, list[int], list[int]]:
    """Evaluate a PLO hand and return the best score along with the exact 2 hole cards and 3 board cards used to make
    that hand.

    Args:
        hole_cards: list of Treys ints for the 4 hole cards
        board: list of Treys ints for the community cards (>= 3)

    Returns:
        (best_score, best_hole_combo, best_board_combo)
    """
    evaluator = get_evaluator()
    best_score = float("inf")
    best_hole_combo: list[int] = []
    best_board_combo: list[int] = []

    for hole_combo in combinations(hole_cards, 2):
        for board_combo in combinations(board, 3):
            hand = list(hole_combo) + list(board_combo)
            try:
                score = evaluator.evaluate(hand, [])
                if score < best_score:
                    best_score = score
                    best_hole_combo = list(hole_combo)
                    best_board_combo = list(board_combo)
            except Exception as e:
                logger.error(f"Error evaluating hand: {hand} - {e}")
                continue

    return best_score, best_hole_combo, best_board_combo
