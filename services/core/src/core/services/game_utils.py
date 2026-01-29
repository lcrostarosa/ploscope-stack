import logging

from core.services.player_profiles import PlayerProfile
from core.utils.logging_utils import setup_enhanced_logging

# Initialize logger
logger = setup_enhanced_logging()


def normalize_player_data(players: list) -> list[dict]:
    """Normalize player data to consistent dictionary format.

    Handles both old format (list of dicts with 'cards' key) and new format (list of lists).
    """
    if not players:
        return []

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug(f"Normalizing player data with {len(players) if isinstance(players, list) else 0} players")

    normalized_players = []
    for i, player in enumerate(players):
        try:
            if isinstance(player, dict) and "cards" in player:
                # Already in correct format
                normalized_players.append(player)
            elif isinstance(player, list):
                # Convert list of cards to player dict
                player_dict = {"player_number": i + 1, "cards": player}
                normalized_players.append(player_dict)
            else:
                error_msg = f"Invalid player data format at index {i}: " f"{type(player)}, value: {player}"
                logger.error(error_msg)
                raise ValueError(error_msg)
        except Exception as e:
            logger.error(f"Error processing player {i}: {e}")
            raise

    if logger.isEnabledFor(logging.DEBUG):
        logger.debug(f"Normalized {len(normalized_players)} players successfully")
    return normalized_players


def calculate_exploits_vs_profile(profile: PlayerProfile, hero_top_equity: float, hero_bottom_equity: float) -> dict:
    """Calculate suggested exploits against a specific player profile."""

    exploits = []

    # Analyze based on profile characteristics
    if profile.fold_to_pressure > 70:
        exploits.append(
            {
                "type": "bluff_more",
                "description": (
                    f"{profile.name} folds to pressure {profile.fold_to_pressure}% "
                    f"of the time - increase bluffing frequency"
                ),
                "confidence": "high" if profile.fold_to_pressure > 80 else "medium",
            }
        )

    if profile.check_call_frequency > 70:
        exploits.append(
            {
                "type": "value_bet_more",
                "description": (
                    f"{profile.name} calls too much ({profile.check_call_frequency}%) " f"- bet more hands for value"
                ),
                "confidence": "high" if profile.check_call_frequency > 80 else "medium",
            }
        )

    if profile.threeb_frequency < 15:
        exploits.append(
            {
                "type": "steal_blinds",
                "description": (
                    f"{profile.name} rarely 3-bets ({profile.threeb_frequency}%) " f"- steal their blinds more often"
                ),
                "confidence": "medium",
            }
        )

    if profile.positional_awareness < 40:
        exploits.append(
            {
                "type": "position_abuse",
                "description": (
                    f"{profile.name} has poor positional awareness "
                    f"({profile.positional_awareness}%) - play more hands in position"
                ),
                "confidence": "medium",
            }
        )

    if profile.bet_sizing_aggression < 40:
        exploits.append(
            {
                "type": "larger_bets",
                "description": (
                    f"{profile.name} uses small bet sizes "
                    f"({profile.bet_sizing_aggression}%) - use larger bets for value"
                ),
                "confidence": "medium",
            }
        )

    if profile.slow_play_frequency > 50:
        exploits.append(
            {
                "type": "dont_pay_off",
                "description": (
                    f"{profile.name} slow plays strong hands often "
                    f"({profile.slow_play_frequency}%) - be careful when they show aggression"
                ),
                "confidence": "medium",
            }
        )

    if profile.tilt_resistance < 50:
        exploits.append(
            {
                "type": "apply_pressure",
                "description": (
                    f"{profile.name} tilts easily ({100 - profile.tilt_resistance}%) "
                    f"- apply maximum pressure after bad beats"
                ),
                "confidence": "high" if profile.tilt_resistance < 30 else "medium",
            }
        )

    return {
        "profile_summary": {
            "tightness": (
                "very tight"
                if profile.hand_range_tightness > 80
                else (
                    "tight"
                    if profile.hand_range_tightness > 60
                    else "loose"
                    if profile.hand_range_tightness < 40
                    else "standard"
                )
            ),
            "aggression": (
                "very aggressive"
                if profile.preflop_aggression > 80
                else (
                    "aggressive"
                    if profile.preflop_aggression > 60
                    else "passive"
                    if profile.preflop_aggression < 40
                    else "standard"
                )
            ),
            "bluffing": (
                "frequent bluffer"
                if profile.bluff_frequency > 40
                else ("occasional bluffer" if profile.bluff_frequency > 20 else "rarely bluffs")
            ),
        },
        "exploits": exploits,
        "hero_equity_vs_profile": {
            "top_board": hero_top_equity,
            "bottom_board": hero_bottom_equity,
            "average": (hero_top_equity + hero_bottom_equity) / 2,
        },
    }
