from core.services.card_service import str_to_cards
from core.utils.evaluator_utils import evaluate_plo_hand
from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


def _build_pot_layers(player_invested: list[int], folded_players: set[int]) -> list[tuple[int, list[int]]]:
    """Build pot layers (main + side pots) from per-player invested amounts.

    Each layer is a tuple of (amount, eligible_contenders), where amount is the total chips in that layer contributed by
    all players who have invested at least up to that level, and eligible_contenders are the players who have not folded
    and have invested at least up to that level.

    This correctly includes folded players' contributions in the amount while excluding them from eligibility to win
    that layer.
    """
    unique_levels = sorted({amt for amt in player_invested if amt > 0})
    if not unique_levels:
        return []

    layers: list[tuple[int, list[int]]] = []
    previous = 0
    num_players = len(player_invested)

    for level in unique_levels:
        if level <= previous:
            continue

        # All participants who contributed at least up to this level (folded included)
        participants_count = sum(1 for i in range(num_players) if player_invested[i] >= level)
        layer_amount = (level - previous) * participants_count

        # Eligible contenders are those who have not folded and contributed up to this level
        eligible_contenders = [i for i in range(num_players) if player_invested[i] >= level and i not in folded_players]

        if layer_amount > 0 and eligible_contenders:
            layers.append((layer_amount, eligible_contenders))

        previous = level

    return layers


def get_board_winners_for_contenders(
    hands_treys_by_index: dict[int, list[int]],
    board_treys: list[int],
    contenders: list[int],
) -> list[int]:
    """Determine winners on a single board for the given contenders.

    Returns a sorted list of player indices who tie for best hand.
    """
    best_score = None
    winners: list[int] = []
    for idx in contenders:
        score = evaluate_plo_hand(hands_treys_by_index[idx], board_treys)
        if best_score is None or score < best_score:
            best_score = score
            winners = [idx]
        elif score == best_score:
            winners.append(idx)

    return sorted(winners)


def _distribute_amount_evenly(amount: int, winners: list[int], payouts: list[int]) -> None:
    """Evenly distribute an integer amount among winners.

    Any remainder is given one by one starting from the smallest player index for determinism.
    """
    if amount <= 0 or not winners:
        return

    base_share = amount // len(winners)
    remainder = amount % len(winners)

    for w in winners:
        payouts[w] += base_share

    # Distribute odd chips deterministically to lowest indices
    for i in range(remainder):
        payouts[winners[i]] += 1


def resolve_showdown_payouts(
    players: list[dict],
    top_board: list[str],
    bottom_board: list[str],
    player_invested: list[int],
    folded_players: list[int],
) -> tuple[list[int], dict[str, object]]:
    """Resolve a double-board PLO showdown with potential side pots.

    - Chips invested by folded players remain in the pot but they are not eligible
      to win any portion.
    - For each pot layer, half the layer amount is awarded to top-board winners
      and half to bottom-board winners (ties split evenly with odd chips assigned
      deterministically to lower seat indices).

    Returns payouts per player index and a details dict for debugging/UX.
    """
    num_players = len(player_invested)
    payouts: list[int] = [0] * num_players

    # Convert boards and hole cards to treys ints
    try:
        top_treys = str_to_cards(top_board)
        bottom_treys = str_to_cards(bottom_board)
    except Exception as e:
        logger.error(f"Invalid board cards in resolve_showdown: {e}")
        raise

    # Map player index -> treys list of 4 hole cards
    hands_treys_by_index: dict[int, list[int]] = {}
    for p in players:
        try:
            # players are 1-indexed via player_number on frontend
            idx = p.get("player_number", 0) - 1
            if idx < 0 or idx >= num_players:
                continue
            hands_treys_by_index[idx] = str_to_cards(p.get("cards", []), validate_duplicates=False)
        except Exception:
            # Skip invalid hands; those players will simply be ineligible
            continue

    folded_set: set[int] = set(folded_players or [])

    # Build pot layers from investment levels
    layers = _build_pot_layers(player_invested, folded_set)

    details = {
        "layers": [],
        "total_pot": sum(player_invested),
    }

    for amount, contenders in layers:
        # Split layer into top/bottom halves (ensure total conserved)
        top_half = amount // 2
        bottom_half = amount - top_half

        # Compute winners per board among contenders only
        top_winners = get_board_winners_for_contenders(hands_treys_by_index, top_treys, contenders)
        bottom_winners = get_board_winners_for_contenders(hands_treys_by_index, bottom_treys, contenders)

        _distribute_amount_evenly(top_half, top_winners, payouts)
        _distribute_amount_evenly(bottom_half, bottom_winners, payouts)

        details["layers"].append(
            {
                "amount": amount,
                "contenders": contenders,
                "top_half": top_half,
                "bottom_half": bottom_half,
                "top_winners": top_winners,
                "bottom_winners": bottom_winners,
            }
        )

    details["total_distributed"] = sum(payouts)
    return payouts, details
