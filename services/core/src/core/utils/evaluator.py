"""PLO hand evaluation utilities.

This module provides the src PLO hand evaluation functionality extracted from the backend evaluator utilities.
"""

import itertools

from treys import Evaluator  # type: ignore


def evaluate_plo_hand(hole_cards: list[int], board: list[int]) -> int:
    """Evaluate a PLO hand using Treys.

    Args:
        hole_cards: List of Treys integer representations of hole cards
        board: List of Treys integer representations of board cards

    Returns:
        Treys hand score (lower is better)

    Raises:
        ValueError: If invalid number of cards provided
    """
    if len(hole_cards) != 4:
        raise ValueError(f"PLO requires exactly 4 hole cards, got {len(hole_cards)}")
    if len(board) != 5:
        raise ValueError(f"Full board requires exactly 5 cards, got {len(board)}")

    evaluator = Evaluator()
    min_score = float("inf")
    for hole_combo in itertools.combinations(hole_cards, 2):
        for board_combo in itertools.combinations(board, 3):
            score = evaluator.evaluate(list(board_combo), list(hole_combo))
            if score < min_score:
                min_score = score
    return min_score


def get_hand_rank(score: int) -> str:
    """Get the hand rank name from a Treys score.

    Args:
        score: Treys hand score

    Returns:
        Hand rank name (e.g., "Straight Flush", "Four of a Kind", etc.)
    """
    evaluator = Evaluator()
    return evaluator.class_to_string(evaluator.get_rank_class(score))


def get_hand_class(score: int) -> int:
    """Get the hand class from a Treys score.

    Args:
        score: Treys hand score

    Returns:
        Hand class (1-9, where 1 is best)
    """
    evaluator = Evaluator()
    return evaluator.get_rank_class(score)
