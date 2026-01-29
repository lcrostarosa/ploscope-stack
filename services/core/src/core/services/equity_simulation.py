"""Equity simulation module for PLO.

This module provides the core simulate_equity function that was extracted to break circular dependencies between
equity_service and equity_calculator.
"""

import multiprocessing
from concurrent.futures import ThreadPoolExecutor

from core.services.card_service import DuplicateCardError, str_to_cards, validate_card_input
from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


def chunk_iterations(total: int, chunks: int) -> list[int]:
    """Divide iterations into evenly sized chunks for multiprocessing."""
    base = total // chunks
    return [base + (1 if i < total % chunks else 0) for i in range(chunks)]


def run_equity_simulation_chunk(
    hands: list[list[int]], board: list[int], num_iterations: int, double_board: bool
) -> tuple[list[int], list[int]]:
    """Run equity simulation chunk for multiprocessing."""
    from core.services.equity_calculator import get_random_board_safe
    from core.utils.evaluator_utils import evaluate_plo_hand

    wins = [0] * len(hands)
    ties = [0] * len(hands)

    needed_board_cards = 10 if double_board else 5
    existing_board_len = len(board)
    missing = max(0, needed_board_cards - existing_board_len)

    all_used_cards = [card for hand in hands for card in hand] + board

    for _ in range(num_iterations):
        if missing > 0:
            # Complete the board
            if double_board:
                # For double board, we need 10 cards total
                # First complete the top board (first 5 cards)
                top_board = board[:5] if len(board) >= 5 else board
                needed_top = max(0, 5 - len(top_board))
                top_board_complete = top_board + get_random_board_safe(all_used_cards, needed_top)

                # Then complete the bottom board (next 5 cards)
                bottom_board = board[5:] if len(board) >= 10 else []
                needed_bottom = max(0, 5 - len(bottom_board))
                bottom_board_complete = bottom_board + get_random_board_safe(
                    all_used_cards + top_board_complete, needed_bottom
                )

                # Combine both boards
                full_board = top_board_complete + bottom_board_complete
            else:
                # Single board
                full_board = board + get_random_board_safe(all_used_cards, missing)
        else:
            full_board = board

        # Evaluate all hands
        scores = [evaluate_plo_hand(hand, full_board) for hand in hands]

        # Find the best score (lowest in treys)
        best_score = min(scores)

        # Count winners and ties
        winners = [i for i, score in enumerate(scores) if score == best_score]

        if len(winners) == 1:
            # Single winner
            wins[winners[0]] += 1
        else:
            # Tie - split the win among winners
            for winner in winners:
                ties[winner] += 1

    return wins, ties


def simulate_equity(
    hands: list[list[str]],
    board: list[str],
    num_iterations: int = 2000,
    double_board: bool = False,
) -> tuple[list[float], list[float]]:
    """Simulate equity between known hands with duplicate validation."""
    logger.debug(
        f"simulate_equity: {len(hands)} hands, {len(board)} board cards, "
        f"{num_iterations} iterations, double_board={double_board}"
    )

    # Validate input types
    if not isinstance(hands, list):
        raise TypeError(f"hands must be a list, got {type(hands)}")
    if not isinstance(board, list):
        raise TypeError(f"board must be a list, got {type(board)}")

    # Validate all cards for duplicates first
    try:
        card_lists = hands.copy()
        if board:
            card_lists.append(board)
        validate_card_input(card_lists)
    except DuplicateCardError as e:
        logger.error(f"Duplicate cards detected in equity simulation: {e}")
        raise

    logger.debug(f"Starting simulation with {num_iterations} iterations, double_board={double_board}")

    logger.debug(f"Converting {len(hands)} hands and board cards")
    parsed_hands = [str_to_cards(hand) for hand in hands]
    parsed_board = str_to_cards(board)
    num_players = len(parsed_hands)

    # Dynamic CPU allocation for better performance
    available_cores = multiprocessing.cpu_count()
    cpu_count = max(2, min(int(available_cores * 0.75), 12))  # Use 75% of cores, max 12
    iterations_per_worker = chunk_iterations(num_iterations, cpu_count)
    logger.debug(f"Using {cpu_count} threads, iterations per worker: {iterations_per_worker}")

    args = [(parsed_hands, parsed_board, chunk, double_board) for chunk in iterations_per_worker]

    results: list = []

    with ThreadPoolExecutor(max_workers=cpu_count) as executor:
        futures = [executor.submit(run_equity_simulation_chunk, *arg) for arg in args]
        for future in futures:
            results.append(future.result())

    total_wins = [0] * num_players
    total_ties = [0] * num_players

    for wins, ties in results:
        for i in range(num_players):
            total_wins[i] += wins[i]
            total_ties[i] += ties[i]

    total_sims = num_iterations
    equity = [round((w + t / len(hands)) / total_sims * 100, 2) for w, t in zip(total_wins, total_ties)]
    tie_percent = [round(t / total_sims * 100, 2) for t in total_ties]

    logger.debug(f"Simulation completed. Equity: {equity}, Tie percentages: {tie_percent}")
    return equity, tie_percent
