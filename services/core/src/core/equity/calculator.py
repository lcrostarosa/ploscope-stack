"""Core equity calculation functions for PLO.

This module contains the src equity calculation logic extracted from the backend services, optimized for use as a
standalone package.
"""

import multiprocessing
import random
from concurrent.futures import ThreadPoolExecutor

from treys import Card  # type: ignore

from core.utils.card_utils import DuplicateCardError, str_to_cards, validate_card_input
from core.utils.evaluator_utils import evaluate_plo_hand

ALL_CARD_INTS = [Card.new(rank + suit) for rank in "23456789TJQKA" for suit in "shdc"]


def is_daemon_process() -> bool:
    """Check if current process is a daemon process (like Celery worker)."""
    return multiprocessing.current_process().daemon


def chunk_iterations(total: int, chunks: int) -> list[int]:
    """Divide iterations into evenly sized chunks for multiprocessing."""
    base = total // chunks
    return [base + (1 if i < total % chunks else 0) for i in range(chunks)]


def get_random_board(used_cards: list[int], needed_cards: int) -> list[int]:
    """Get random board cards excluding used cards."""
    available_cards = [card for card in ALL_CARD_INTS if card not in used_cards]

    if len(available_cards) < needed_cards:
        raise ValueError(f"Not enough cards available. Need {needed_cards}, have {len(available_cards)}")

    return random.sample(available_cards, needed_cards)


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
    if folded_cards:
        used_cards.extend(folded_cards)

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
        return (0, 0, num_iterations, {}, {})

    for _ in range(num_iterations):
        try:
            # Complete the board
            full_board = board + get_random_board(used_cards, missing)

            # Generate random opponent hands
            opponent_hands = []
            current_used_cards = used_cards + full_board

            for _ in range(actual_num_opponents):
                opponent_hand = get_random_board(current_used_cards, 4)
                opponent_hands.append(opponent_hand)
                current_used_cards.extend(opponent_hand)

            # Evaluate all hands
            hero_score = evaluate_plo_hand(single_hand, full_board)
            opponent_scores = [evaluate_plo_hand(hand, full_board) for hand in opponent_hands]

            # Find the best score (lowest in Treys)
            all_scores = [hero_score] + opponent_scores
            best_score = min(all_scores)

            # Count winners
            winners = [i for i, score in enumerate(all_scores) if score == best_score]

            # Update statistics
            if len(winners) == 1 and winners[0] == 0:
                # Hero wins
                wins += 1
                hand_type = categorize_hand_strength(hero_score)
                if hand_type not in hand_breakdown:
                    hand_breakdown[hand_type] = {"wins": 0, "ties": 0, "losses": 0, "total": 0}
                hand_breakdown[hand_type]["wins"] += 1
                hand_breakdown[hand_type]["total"] += 1
            elif 0 in winners:
                # Hero ties
                ties += 1
                hand_type = categorize_hand_strength(hero_score)
                if hand_type not in hand_breakdown:
                    hand_breakdown[hand_type] = {"wins": 0, "ties": 0, "losses": 0, "total": 0}
                hand_breakdown[hand_type]["ties"] += 1
                hand_breakdown[hand_type]["total"] += 1
            else:
                # Hero loses
                losses += 1
                hand_type = categorize_hand_strength(hero_score)
                if hand_type not in hand_breakdown:
                    hand_breakdown[hand_type] = {"wins": 0, "ties": 0, "losses": 0, "total": 0}
                hand_breakdown[hand_type]["losses"] += 1
                hand_breakdown[hand_type]["total"] += 1

            # Update opponent breakdown
            for i, score in enumerate(opponent_scores):
                hand_type = categorize_hand_strength(score)
                if hand_type not in opponent_breakdown:
                    opponent_breakdown[hand_type] = {"wins": 0, "ties": 0, "losses": 0, "total": 0}

                if len(winners) == 1 and winners[0] == i + 1:  # +1 because hero is at index 0
                    opponent_breakdown[hand_type]["wins"] += 1
                elif i + 1 in winners:
                    opponent_breakdown[hand_type]["ties"] += 1
                else:
                    opponent_breakdown[hand_type]["losses"] += 1
                opponent_breakdown[hand_type]["total"] += 1

        except Exception:
            # If there's an error in simulation, count as a loss
            losses += 1

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
    """Run double board analysis chunk for multiprocessing."""
    chop_both = [0] * len(hands)
    scoop_both = [0] * len(hands)
    split_top = [0] * len(hands)
    split_bottom = [0] * len(hands)

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
    """Calculate double board PLO statistics.

    Args:
        hands: List of player hands (each hand is a list of card strings)
        top_board: List of top board cards
        bottom_board: List of bottom board cards
        num_iterations: Number of simulation iterations

    Returns:
        Tuple of (chop_both, scoop_both, split_top, split_bottom) percentages
    """
    # Validate all cards for duplicates first
    try:
        validate_card_input(hands + [top_board, bottom_board])
    except DuplicateCardError as e:
        raise ValueError(f"Duplicate cards detected in double board calculation: {e}")

    # Convert card strings to Treys integers
    hands_int = [str_to_cards(hand) for hand in hands]
    top_board_int = str_to_cards(top_board)
    bottom_board_int = str_to_cards(bottom_board)

    # Optimize CPU usage for Celery workers
    available_cores = multiprocessing.cpu_count()
    cpu_count = max(2, min(int(available_cores * 0.75), 12))
    iterations_per_worker = chunk_iterations(num_iterations, cpu_count)

    # Use ThreadPoolExecutor for all processes to avoid multiprocessing issues in Celery
    with ThreadPoolExecutor(max_workers=cpu_count) as executor:
        results = list(
            executor.map(
                lambda iterations: run_double_board_analysis_chunk(
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

    # Convert to percentages
    chop_both_percent = [(count / num_iterations) for count in chop_both]
    scoop_both_percent = [(count / num_iterations) for count in scoop_both]
    split_top_percent = [(count / num_iterations) for count in split_top]
    split_bottom_percent = [(count / num_iterations) for count in split_bottom]

    return chop_both_percent, scoop_both_percent, split_top_percent, split_bottom_percent


def simulate_estimated_equity(
    hand: list[str],
    board: list[str],
    num_iterations: int = 2000,
    folded_cards: list[str] = None,
    max_hand_combinations: int = 10000,
    num_opponents: int = 7,
) -> tuple[float, float, dict, dict, dict]:
    """Simulate estimated equity against random opponents with duplicate validation.

    Args:
        hand: List of hole cards
        board: List of board cards
        num_iterations: Number of simulation iterations
        folded_cards: List of folded cards (optional)
        max_hand_combinations: Maximum hand combinations to consider
        num_opponents: Number of random opponents to simulate

    Returns:
        Tuple of (equity, tie_percent, hand_breakdown, opponent_breakdown, additional_stats)
    """
    # Validate all cards for duplicates first
    try:
        card_lists = [hand]
        if board:
            card_lists.append(board)
        if folded_cards:
            card_lists.append(folded_cards)
        validate_card_input(card_lists)
    except DuplicateCardError as e:
        raise ValueError(f"Duplicate cards detected in estimated equity calculation: {e}")

    # Convert card strings to Treys integers
    hand_int = str_to_cards(hand)
    board_int = str_to_cards(board) if board else []
    folded_cards_int = str_to_cards(folded_cards) if folded_cards else []

    # Optimize CPU usage for Celery workers
    cpu_count = min(multiprocessing.cpu_count(), 8)
    iterations_per_worker = chunk_iterations(num_iterations, cpu_count)

    # Use ThreadPoolExecutor for all processes to avoid multiprocessing issues in Celery
    with ThreadPoolExecutor(max_workers=cpu_count) as executor:
        results = list(
            executor.map(
                lambda iterations: run_estimated_equity_simulation_chunk(
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
    total_wins = 0
    total_ties = 0
    total_losses = 0
    combined_hand_breakdown = {}
    combined_opponent_breakdown = {}

    for result in results:
        total_wins += result[0]
        total_ties += result[1]
        total_losses += result[2]

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
        return 0.0, 0.0, {}, {}, {}

    win_percentage = (total_wins / total_games) * 100
    tie_percentage = (total_ties / total_games) * 100

    # Calculate equity as win_percentage + tie_percentage / 2
    equity = win_percentage + (tie_percentage / 2)

    return (
        equity,
        tie_percentage,
        combined_hand_breakdown,
        combined_opponent_breakdown,
        {},
    )


def simulate_equity(
    hands: list[list[str]],
    board: list[str],
    num_iterations: int = 2000,
    double_board: bool = False,
) -> tuple[list[float], list[float]]:
    """Simulate equity for multiple hands against each other.

    Args:
        hands: List of player hands (each hand is a list of card strings)
        board: List of board cards
        num_iterations: Number of simulation iterations
        double_board: Whether this is a double board game

    Returns:
        Tuple of (equity_percentages, tie_percentages) for each player
    """
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
        raise ValueError(f"Duplicate cards detected in equity simulation: {e}")

    # Convert hands and board to Treys integers
    parsed_hands = [str_to_cards(hand) for hand in hands]
    parsed_board = str_to_cards(board)
    num_players = len(parsed_hands)

    # Dynamic CPU allocation for better performance
    available_cores = multiprocessing.cpu_count()
    cpu_count = max(2, min(int(available_cores * 0.75), 12))
    iterations_per_worker = chunk_iterations(num_iterations, cpu_count)

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

    return equity, tie_percent
