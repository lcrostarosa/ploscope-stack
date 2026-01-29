"""Equity Calculator for PLO.

This module provides equity calculation functionality for Pot Limit Omaha.
"""

import random

# import logging
from typing import Optional  # Optional

from treys import Card

from core.equity.calculator import simulate_estimated_equity as equity_simulate_estimated_equity
from core.services.card_service import str_to_cards as card_str_to_cards
from core.utils.evaluator_utils import evaluate_plo_hand
from core.utils.logging_utils import get_enhanced_logger

from .equity_simulation import simulate_equity as equity_simulate_equity

logger = get_enhanced_logger(__name__)


def chunk_iterations(total: int, chunks: int) -> list[int]:
    """Divide iterations into evenly sized chunks for multiprocessing."""
    base = total // chunks
    return [base + (1 if i < total % chunks else 0) for i in range(chunks)]


def categorize_hand_strength(score: int) -> str:
    """Categorize a Treys hand score into poker hand strength categories.

    Lower scores are stronger in Treys (1 is best, 7462 is worst).
    """
    if score <= 10:
        return "Straight Flush"
    if score <= 166:
        return "Four of a Kind"
    if score <= 322:
        return "Full House"
    if score <= 1599:
        return "Flush"
    if score <= 1609:
        return "Straight"
    if score <= 2467:
        return "Three of a Kind"
    if score <= 3325:
        return "Two Pair"
    if score <= 6185:
        return "One Pair"
    return "High Card"


def get_random_board_safe(
    exclude_cards: list[int], board_size: int, additional_exclude: Optional[list[int]] = None
) -> list[int]:
    """Safe version of get_random_board that doesn't cause circular imports.

    This is used by multiprocessing workers.
    """

    # Create all possible cards
    all_card_strings = []
    ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    suits = ["h", "d", "c", "s"]

    for rank in ranks:
        for suit in suits:
            all_card_strings.append(rank + suit)

    all_cards = [Card.new(card_str) for card_str in all_card_strings]

    # Filter out excluded cards
    exclude_set = set(exclude_cards)
    if additional_exclude:
        exclude_set.update(additional_exclude)

    available_cards = [card for card in all_cards if card not in exclude_set]

    if board_size > len(available_cards):
        raise ValueError(f"Cannot sample {board_size} cards from {len(available_cards)} available cards")

    if board_size == 0:
        return []

    return random.sample(available_cards, board_size)


def run_equity_simulation_chunk(
    hands: list[list[int]], board: list[int], num_iterations: int, double_board: bool
) -> tuple[list[int], list[int]]:
    """Run equity simulation chunk for multiprocessing."""
    wins = [0] * len(hands)
    ties = [0] * len(hands)

    needed_board_cards = 10 if double_board else 5
    existing_board_len = len(board)
    missing = max(0, needed_board_cards - existing_board_len)

    all_used_cards = [card for hand in hands for card in hand] + board

    for _ in range(num_iterations):
        full_board = board + get_random_board_safe(all_used_cards, missing)

        if double_board:
            board1 = full_board[:5]
            board2 = full_board[5:]
            scores = [[evaluate_plo_hand(hand, board1), evaluate_plo_hand(hand, board2)] for hand in hands]
            combined_scores = [sum(score) for score in scores]
        else:
            combined_scores = [evaluate_plo_hand(hand, full_board) for hand in hands]

        best_score = min(combined_scores)
        winners = [i for i, score in enumerate(combined_scores) if score == best_score]

        if len(winners) == 1:
            winner_idx = winners[0]
            wins[winner_idx] += 1
        else:
            for w in winners:
                ties[w] += 1

    return wins, ties


def run_estimated_equity_simulation_chunk(
    single_hand: list[int],
    board: list[int],
    num_iterations: int,
    folded_cards: Optional[list[int]] = None,
    max_hand_combinations: int = 10000,
    num_opponents: int = 7,
) -> tuple[int, int, int, dict, dict]:
    """Run estimated equity simulation chunk for multiprocessing."""
    wins = 0
    ties = 0
    losses = 0
    hand_breakdown = {}
    opponent_breakdown = {}

    needed_board_cards = 5
    existing_board_len = len(board)
    missing = max(0, needed_board_cards - existing_board_len)

    # Only exclude the single hand's cards and the board
    used_cards = single_hand + board

    # Calculate how many opponents we can simulate given card constraints
    total_excluded = len(used_cards) + missing  # hero hand + board
    if folded_cards:
        total_excluded += len(folded_cards)

    # Each opponent needs 4 cards, and we have 52 total cards
    max_possible_opponents = (52 - total_excluded) // 4
    # Use the requested number of opponents, but limit by what's possible
    actual_num_opponents = min(num_opponents, max_possible_opponents)

    # If we can't simulate even 1 opponent, return default values
    if actual_num_opponents < 1:
        logger.warning(
            f"Cannot simulate any opponents - not enough cards available. "
            f"Total excluded: {total_excluded}, folded cards: {len(folded_cards) if folded_cards else 0}"
        )
        return 0, 0, num_iterations, {}, {}

    for _ in range(num_iterations):
        try:
            full_board = board + get_random_board_safe(used_cards, missing, folded_cards)

            # Generate random opponent hands
            opponent_hands = []
            iteration_used_cards = used_cards + full_board

            for _ in range(actual_num_opponents):
                try:
                    opponent_hand = get_random_board_safe(iteration_used_cards, 4, folded_cards)
                    opponent_hands.append(opponent_hand)
                    iteration_used_cards.extend(opponent_hand)
                except ValueError as e:
                    logger.debug(f"Could not generate full opponent set: {e}")
                    break

            if not opponent_hands:
                continue

            # Evaluate all hands
            all_hands = [single_hand] + opponent_hands
            scores = [evaluate_plo_hand(hand, full_board) for hand in all_hands]

            # Categorize our hand
            our_score = scores[0]
            hand_category = categorize_hand_strength(our_score)

            # Initialize breakdown for this hand category if not exists
            if hand_category not in hand_breakdown:
                hand_breakdown[hand_category] = {
                    "wins": 0,
                    "ties": 0,
                    "losses": 0,
                    "total": 0,
                }

            hand_breakdown[hand_category]["total"] += 1

            # Track opponent hand breakdowns
            for i, opponent_score in enumerate(scores[1:], 1):
                opponent_category = categorize_hand_strength(opponent_score)
                if opponent_category not in opponent_breakdown:
                    opponent_breakdown[opponent_category] = {
                        "wins": 0,
                        "ties": 0,
                        "losses": 0,
                        "total": 0,
                    }

                opponent_breakdown[opponent_category]["total"] += 1

            best_score = min(scores)
            winners = [i for i, score in enumerate(scores) if score == best_score]

            # Track wins/ties/losses for hero
            if len(winners) == 1 and 0 in winners:
                wins += 1
                hand_breakdown[hand_category]["wins"] += 1
            elif 0 in winners:
                ties += 1
                hand_breakdown[hand_category]["ties"] += 1
            else:
                losses += 1
                hand_breakdown[hand_category]["losses"] += 1

            # Track wins/ties/losses for opponents
            for i, opponent_score in enumerate(scores[1:], 1):
                opponent_category = categorize_hand_strength(opponent_score)

                if len(winners) == 1 and i in winners:
                    opponent_breakdown[opponent_category]["wins"] += 1
                elif i in winners:
                    opponent_breakdown[opponent_category]["ties"] += 1
                else:
                    opponent_breakdown[opponent_category]["losses"] += 1

        except ValueError as e:
            logger.error(f"Error in simulation iteration: {e}")
            continue

    return wins, ties, losses, hand_breakdown, opponent_breakdown


def run_double_board_analysis_chunk(
    hands: list[list[int]],
    top_board: list[int],
    bottom_board: list[int],
    num_iterations: int,
) -> tuple[list[int], list[int], list[int], list[int]]:
    """Calculate double board specific statistics for each player."""
    chop_both = [0] * len(hands)
    scoop_both = [0] * len(hands)
    split_top = [0] * len(hands)
    split_bottom = [0] * len(hands)

    # Calculate needed cards for each board
    needed_top_cards = max(0, 5 - len(top_board))
    needed_bottom_cards = max(0, 5 - len(bottom_board))

    all_used_cards = [card for hand in hands for card in hand] + top_board + bottom_board

    for _ in range(num_iterations):
        # Complete both boards
        full_top_board = top_board + get_random_board_safe(all_used_cards, needed_top_cards)
        iteration_used_cards = all_used_cards + full_top_board
        full_bottom_board = bottom_board + get_random_board_safe(iteration_used_cards, needed_bottom_cards)

        # Evaluate hands for each board
        top_scores = [evaluate_plo_hand(hand, full_top_board) for hand in hands]
        bottom_scores = [evaluate_plo_hand(hand, full_bottom_board) for hand in hands]

        # Find winners for each board
        best_top_score = min(top_scores)
        best_bottom_score = min(bottom_scores)

        top_winners = [i for i, score in enumerate(top_scores) if score == best_top_score]
        bottom_winners = [i for i, score in enumerate(bottom_scores) if score == best_bottom_score]

        # Calculate statistics for each player
        for i in range(len(hands)):
            # Split stats: player gets money from the board (wins or ties)
            if i in top_winners:
                split_top[i] += 1
            if i in bottom_winners:
                split_bottom[i] += 1

            # Chop both: player ties on both boards (multiple winners on both)
            if i in top_winners and i in bottom_winners and len(top_winners) > 1 and len(bottom_winners) > 1:
                chop_both[i] += 1

            # Scoop both: player wins both boards outright (sole winner on both)
            if i in top_winners and len(top_winners) == 1 and i in bottom_winners and len(bottom_winners) == 1:
                scoop_both[i] += 1

    return chop_both, scoop_both, split_top, split_bottom


# The following functions are wrappers for the main functions in equity_service.py
# They are here to avoid circular imports during multiprocessing


def simulate_equity(
    hands: list[list[str]],
    board: list[str],
    num_iterations: int = 2000,
    double_board: bool = False,
) -> tuple[list[float], list[float]]:
    """Wrapper for simulate_equity - delegates to equity_service."""

    return equity_simulate_equity(hands, board, num_iterations, double_board)


def simulate_estimated_equity(
    hand: list[str],
    board: list[str],
    num_iterations: int = 2000,
    folded_cards: list[str] = None,
    max_hand_combinations: int = 10000,
    num_opponents: int = 7,
) -> tuple[float, float, dict, dict, dict]:
    """Wrapper for simulate_estimated_equity - delegates to equity_service."""

    return equity_simulate_estimated_equity(
        hand, board, num_iterations, folded_cards, max_hand_combinations, num_opponents
    )


def str_to_cards(card_strs: list[str]) -> list[int]:
    """Wrapper for str_to_cards - delegates to card_service."""
    return card_str_to_cards(card_strs)


# Card is already imported above
# try:
#     from treys import Card
# except ImportError:
#     Card = None
