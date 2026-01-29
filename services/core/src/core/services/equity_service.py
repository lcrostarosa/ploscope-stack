"""Equity calculation service for PLO.

This module provides equity calculation functionality for Pot Limit Omaha.
"""

# import logging
import multiprocessing
from concurrent.futures import ThreadPoolExecutor

from core.equity.calculator import run_estimated_equity_simulation_chunk as safe_run_estimated_equity_simulation_chunk

# Import utilities
from core.services.card_service import DuplicateCardError, get_random_board, str_to_cards, validate_card_input
from core.services.equity_calculator import run_double_board_analysis_chunk as safe_run_double_board_analysis_chunk
from core.utils.evaluator_utils import evaluate_plo_hand
from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


def is_daemon_process() -> bool:
    """Check if current process is a daemon process (like Celery worker)."""
    return multiprocessing.current_process().daemon


def chunk_iterations(total: int, chunks: int) -> list[int]:
    """Divide iterations into evenly sized chunks for multiprocessing."""
    base = total // chunks
    return [base + (1 if i < total % chunks else 0) for i in range(chunks)]


# Note: evaluate_plo_hand function is now imported from utils.evaluator_utils
# This function has been moved to the centralized evaluator utility to avoid
# creating new Evaluator instances for every hand evaluation.


def categorize_hand_strength(score: int) -> str:
    """Categorize a Treys hand score into poker hand strength categories. Lower scores are stronger in Treys (1 is best,
    7462 is worst).

     Ranges align with the standard 5-card evaluator used by Treys/Deuces:
       1 -   10 : Straight Flush
      11 -  166 : Four of a Kind
     167 -  322 : Full House
     323 - 1599 : Flush
    1600 - 1609 : Straight
    1610 - 2467 : Three of a Kind
    2468 - 3325 : Two Pair
    3326 - 6185 : One Pair
    6186 - 7462 : High Card
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


def run_estimated_equity_simulation_chunk(
    single_hand: list[int],
    board: list[int],
    num_iterations: int,
    folded_cards: list[int] = None,
    max_hand_combinations: int = 10000,
    num_opponents: int = 7,
) -> tuple[int, int, int, dict, dict]:
    """Calculate estimated equity for a single hand without considering other players' cards.

    This simulates the hand against random opponents. Returns (wins, ties, losses, hand_breakdown, opponent_breakdown)
    """
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

    # If we can't simulate even 1 opponent, log and return default values
    if actual_num_opponents < 1:
        logger.warning(
            f"Cannot simulate any opponents - not enough cards available. "
            f"Total excluded: {total_excluded}, folded cards: {len(folded_cards) if folded_cards else 0}"
        )
        return (
            0,
            0,
            num_iterations,
            {},
            {},
        )  # All losses if no opponents can be simulated

    for _ in range(num_iterations):
        try:
            full_board = board + get_random_board(used_cards, missing, folded_cards)

            # Generate random opponent hands
            opponent_hands = []
            iteration_used_cards = used_cards + full_board

            for _ in range(actual_num_opponents):
                try:
                    opponent_hand = get_random_board(iteration_used_cards, 4, folded_cards)
                    opponent_hands.append(opponent_hand)
                    iteration_used_cards.extend(opponent_hand)
                except ValueError as e:
                    # If we can't generate more opponent hands, break and continue with what we have
                    logger.debug(f"Could not generate full opponent set: {e}")
                    break

            # If we couldn't generate any opponents, skip this iteration
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
            if len(winners) == 1 and 0 in winners:  # Our hand wins alone
                wins += 1
                hand_breakdown[hand_category]["wins"] += 1
            elif 0 in winners:  # Our hand ties
                ties += 1
                hand_breakdown[hand_category]["ties"] += 1
            else:  # Our hand loses
                losses += 1
                hand_breakdown[hand_category]["losses"] += 1

            # Track wins/ties/losses for opponents
            for i, opponent_score in enumerate(scores[1:], 1):
                opponent_category = categorize_hand_strength(opponent_score)

                if len(winners) == 1 and i in winners:  # This opponent wins alone
                    opponent_breakdown[opponent_category]["wins"] += 1
                elif i in winners:  # This opponent ties
                    opponent_breakdown[opponent_category]["ties"] += 1
                else:  # This opponent loses
                    opponent_breakdown[opponent_category]["losses"] += 1

        except ValueError as e:
            logger.error(f"Error in simulation iteration: {e}")
            continue

    return wins, ties, losses, hand_breakdown, opponent_breakdown


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
        full_board = board + get_random_board(all_used_cards, missing)

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
            # Single winner
            winner_idx = winners[0]
            wins[winner_idx] += 1
        else:
            # Multiple winners - tie
            for w in winners:
                ties[w] += 1

    return wins, ties


def run_double_board_analysis_chunk(
    hands: list[list[int]],
    top_board: list[int],
    bottom_board: list[int],
    num_iterations: int,
) -> tuple[list[int], list[int], list[int], list[int]]:
    """
    Calculate double board specific statistics for each player:
    - Chop Both Boards: Player ties on both boards
    - Scoop Both Boards: Player wins both boards outright
    - Split Top: Player gets money from top board (wins or ties)
    - Split Bottom: Player gets money from bottom board (wins or ties)
    """
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
        full_top_board = top_board + get_random_board(all_used_cards, needed_top_cards)
        iteration_used_cards = all_used_cards + full_top_board
        full_bottom_board = bottom_board + get_random_board(iteration_used_cards, needed_bottom_cards)

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


def calculate_double_board_stats(
    hands: list[list[str]],
    top_board: list[str],
    bottom_board: list[str],
    num_iterations: int = 2000,
) -> tuple[list[float], list[float], list[float], list[float]]:
    """Calculate double board statistics using multiprocessing with duplicate validation."""
    logger.debug("Calculating double board statistics...")

    # Validate all cards for duplicates first
    try:
        validate_card_input(hands, [top_board, bottom_board])
    except DuplicateCardError as e:
        logger.error(f"Duplicate cards detected in double board calculation: {e}")
        raise

    # Convert card strings to Treys integers
    hands_int = [str_to_cards(hand) for hand in hands]
    top_board_int = str_to_cards(top_board)
    bottom_board_int = str_to_cards(bottom_board)

    logger.debug(f"Starting double board analysis with {num_iterations} iterations")

    # Optimize CPU usage for Celery workers
    # Dynamic CPU allocation based on system load and available cores
    available_cores = multiprocessing.cpu_count()
    # For production, use 75% of available cores, minimum 2, maximum 12
    cpu_count = max(2, min(int(available_cores * 0.75), 12))
    iterations_per_worker = chunk_iterations(num_iterations, cpu_count)
    logger.debug(
        f"Using {cpu_count} CPU cores for double board analysis, iterations per worker: {iterations_per_worker}"
    )

    # Use ThreadPoolExecutor for all processes to avoid multiprocessing issues in Celery
    # This is more reliable in containerized environments
    with ThreadPoolExecutor(max_workers=cpu_count) as executor:
        results = list(
            executor.map(
                lambda iterations: safe_run_double_board_analysis_chunk(
                    hands_int, top_board_int, bottom_board_int, iterations
                ),
                iterations_per_worker,
            )
        )

    # Aggregate results
    num_hands = len(hands)
    chop_both = [0] * num_hands
    scoop_both = [0] * num_hands
    split_top = [0] * num_hands
    split_bottom = [0] * num_hands

    for result in results:
        for i in range(num_hands):
            chop_both[i] += result[0][i]
            scoop_both[i] += result[1][i]
            split_top[i] += result[2][i]
            split_bottom[i] += result[3][i]

    logger.debug(
        f"Double board analysis completed. Chop both: {chop_both}, "
        f"Scoop both: {scoop_both}, Split top: {split_top}, "
        f"Split bottom: {split_bottom}"
    )
    return chop_both, scoop_both, split_top, split_bottom


def simulate_estimated_equity(
    hand: list[str],
    board: list[str],
    num_iterations: int = 2000,
    folded_cards: list[str] = None,
    max_hand_combinations: int = 10000,
    num_opponents: int = 7,
) -> tuple[float, float, dict, dict, dict]:
    """Simulate estimated equity against random opponents with duplicate validation."""
    logger.debug(
        f"Starting estimated equity simulation with {num_iterations} iterations " f"against {num_opponents} opponents"
    )

    # Validate all cards for duplicates first
    try:
        card_lists = [hand]
        if board:
            card_lists.append(board)
        if folded_cards:
            card_lists.append(folded_cards)
        validate_card_input(card_lists)
    except DuplicateCardError as e:
        logger.error(f"Duplicate cards detected in estimated equity calculation: {e}")
        raise

    # Convert card strings to Treys integers
    hand_int = str_to_cards(hand)
    board_int = str_to_cards(board) if board else []
    folded_cards_int = str_to_cards(folded_cards) if folded_cards else []

    # Optimize CPU usage for Celery workers
    cpu_count = min(multiprocessing.cpu_count(), 8)  # Reduced from 26 to 8
    iterations_per_worker = chunk_iterations(num_iterations, cpu_count)
    logger.debug(
        f"Using {cpu_count} CPU cores for estimated equity simulation, iterations per worker: {iterations_per_worker}"
    )

    # Use ThreadPoolExecutor for all processes to avoid multiprocessing issues in Celery
    with ThreadPoolExecutor(max_workers=cpu_count) as executor:
        results = list(
            executor.map(
                lambda iterations: safe_run_estimated_equity_simulation_chunk(
                    hand_int,
                    board_int,
                    iterations,
                    folded_cards_int,
                    max_hand_combinations,
                    num_opponents,
                ),
                iterations_per_worker,
            )
        )

    # Aggregate results
    total_wins = sum(result[0] for result in results)
    total_ties = sum(result[1] for result in results)
    total_losses = sum(result[2] for result in results)

    # Combine hand breakdowns
    combined_hand_breakdown = {}
    combined_opponent_breakdown = {}

    for result in results:
        hand_breakdown, opponent_breakdown = result[3], result[4]

        # Merge hand breakdowns
        for hand_type, breakdown in hand_breakdown.items():
            if hand_type not in combined_hand_breakdown:
                combined_hand_breakdown[hand_type] = {
                    "wins": 0,
                    "ties": 0,
                    "losses": 0,
                    "total": 0,
                }
            combined_hand_breakdown[hand_type]["wins"] += breakdown.get("wins", 0)
            combined_hand_breakdown[hand_type]["ties"] += breakdown.get("ties", 0)
            combined_hand_breakdown[hand_type]["losses"] += breakdown.get("losses", 0)
            combined_hand_breakdown[hand_type]["total"] += breakdown.get("total", 0)

        # Merge opponent breakdowns
        for hand_type, breakdown in opponent_breakdown.items():
            if hand_type not in combined_opponent_breakdown:
                combined_opponent_breakdown[hand_type] = {
                    "wins": 0,
                    "ties": 0,
                    "losses": 0,
                    "total": 0,
                }
            combined_opponent_breakdown[hand_type]["wins"] += breakdown.get("wins", 0)
            combined_opponent_breakdown[hand_type]["ties"] += breakdown.get("ties", 0)
            combined_opponent_breakdown[hand_type]["losses"] += breakdown.get("losses", 0)
            combined_opponent_breakdown[hand_type]["total"] += breakdown.get("total", 0)

    # Calculate percentages
    total_games = total_wins + total_ties + total_losses
    if total_games == 0:
        logger.warning("No games were simulated, returning default values")
        return 0.0, 0.0, {}, {}, {}

    win_percentage = (total_wins / total_games) * 100
    tie_percentage = (total_ties / total_games) * 100

    # Calculate equity as win_percentage + tie_percentage / 2
    equity = win_percentage + (tie_percentage / 2)

    logger.debug(
        f"Estimated equity simulation completed. Win: {win_percentage:.2f}%, "
        f"Tie: {tie_percentage:.2f}%, Equity: {equity:.2f}%, Total games: {total_games}"
    )

    return (
        equity,
        tie_percentage,
        combined_hand_breakdown,
        combined_opponent_breakdown,
        {},
    )
