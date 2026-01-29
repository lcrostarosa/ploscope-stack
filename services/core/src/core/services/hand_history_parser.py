import hashlib
import re
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from core.utils.logging_utils import get_enhanced_logger

# import logging


logger = get_enhanced_logger(__name__)


@dataclass
class PlayerInfo:
    """Information about a player in the hand."""

    name: str
    seat: int
    stack: float
    is_hero: bool = False


@dataclass
class Action:
    """Represents a single action in a hand."""

    player: str
    action_type: str  # fold, check, call, bet, raise, all-in
    amount: float
    street: str  # preflop, flop, turn, river


@dataclass
class ParsedHandData:
    """Complete parsed hand information."""

    hand_id: str
    datetime: datetime
    table_name: str
    game_type: str
    stakes: str
    max_players: int
    players: list[PlayerInfo]
    hero_cards: Optional[list[str]]
    board_cards: Optional[list[str]]
    actions: list[Action]
    pot_size: float
    hero_result: Optional[float]
    showdown_reached: bool
    raw_text: str


class HandHistoryParser:
    """Base class for hand history parsers."""

    def __init__(self):
        self.supported_sites = ["pokerstars", "ggpoker", "888poker", "partypoker"]

    def detect_site(self, content: str) -> Optional[str]:
        """Detect which poker site the hand history is from."""
        content_lower = content.lower()

        if "pokerstars" in content_lower or "hand #" in content_lower:
            return "pokerstars"
        elif "ggpoker" in content_lower or "gg poker" in content_lower:
            return "ggpoker"
        elif "888poker" in content_lower:
            return "888poker"
        elif "partypoker" in content_lower:
            return "partypoker"

        return None

    def parse_file(self, content: str, filename: str) -> tuple[list[ParsedHandData], list[str]]:
        """Parse a hand history file and return parsed hands and errors."""
        site = self.detect_site(content)
        if not site:
            return [], ["Could not detect poker site format"]

        if site == "pokerstars":
            return self._parse_pokerstars(content)
        elif site == "ggpoker":
            return self._parse_ggpoker(content)
        else:
            return [], [f"Parsing for {site} not yet implemented"]

    def _parse_pokerstars(self, content: str) -> tuple[list[ParsedHandData], list[str]]:
        """Parse PokerStars hand history format."""
        hands = []
        errors = []

        # Split into individual hands
        hand_texts = re.split(r"\n\n\n+", content.strip())

        for hand_text in hand_texts:
            if not hand_text.strip():
                continue

            try:
                parsed_hand = self._parse_pokerstars_hand(hand_text)
                if parsed_hand:
                    hands.append(parsed_hand)
            except Exception as e:
                errors.append(f"Error parsing hand: {str(e)}")
                logger.error(f"Error parsing PokerStars hand: {e}")

        return hands, errors

    def _parse_pokerstars_hand(self, hand_text: str) -> Optional[ParsedHandData]:
        """Parse a single PokerStars hand."""
        lines = hand_text.strip().split("\n")
        if not lines:
            return None

        # Parse header line
        header = lines[0]
        hand_match = re.search(r"Hand #(\d+):", header)
        if not hand_match:
            return None

        hand_id = hand_match.group(1)

        # Extract datetime
        datetime_match = re.search(r"(\d{4}/\d{2}/\d{2} \d{1,2}:\d{2}:\d{2})", header)
        if datetime_match:
            hand_datetime = datetime.strptime(datetime_match.group(1), "%Y/%m/%d %H:%M:%S")
        else:
            hand_datetime = datetime.now()

        # Extract table info
        table_match = re.search(r"Table '([^']+)'", header)
        table_name = table_match.group(1) if table_match else "Unknown"

        # Extract game type and stakes
        game_match = re.search(r"Pot Limit Omaha", header)
        game_type = "PLO" if game_match else "Unknown"

        stakes_match = re.search(r"\(\$?([0-9.]+)/\$?([0-9.]+)\)", header)
        stakes = f"${stakes_match.group(1)}/${stakes_match.group(2)}" if stakes_match else "Unknown"

        # Extract max players
        max_players_match = re.search(r"(\d+)-max", header)
        max_players = int(max_players_match.group(1)) if max_players_match else 9

        # Parse players
        players = []
        hero_cards = None
        board_cards = None
        actions = []
        pot_size = 0.0
        hero_result = None
        showdown_reached = False

        current_street = "preflop"

        for line in lines[1:]:
            line = line.strip()
            if not line:
                continue

            # Parse seat information
            seat_match = re.match(r"Seat (\d+): ([^(]+) \(\$?([0-9.]+) in chips\)", line)
            if seat_match:
                seat_num = int(seat_match.group(1))
                player_name = seat_match.group(2).strip()
                stack = float(seat_match.group(3))
                players.append(PlayerInfo(player_name, seat_num, stack))
                continue

            # Parse hole cards
            dealt_match = re.match(r"Dealt to ([^[]+) \[([^\]]+)\]", line)
            if dealt_match:
                hero_name = dealt_match.group(1).strip()
                cards_str = dealt_match.group(2)
                hero_cards = [card.strip() for card in cards_str.split()]

                # Mark hero player
                for player in players:
                    if player.name == hero_name:
                        player.is_hero = True
                continue

            # Parse board cards
            if line.startswith("*** FLOP ***"):
                current_street = "flop"
                board_match = re.search(r"\[([^\]]+)\]", line)
                if board_match:
                    board_cards = [card.strip() for card in board_match.group(1).split()]
                continue
            elif line.startswith("*** TURN ***"):
                current_street = "turn"
                board_match = re.search(r"\[([^\]]+)\]", line)
                if board_match:
                    all_cards = [card.strip() for card in board_match.group(1).split()]
                    board_cards = all_cards  # Full board including turn
                continue
            elif line.startswith("*** RIVER ***"):
                current_street = "river"
                board_match = re.search(r"\[([^\]]+)\]", line)
                if board_match:
                    all_cards = [card.strip() for card in board_match.group(1).split()]
                    board_cards = all_cards  # Full board including river
                continue
            elif line.startswith("*** SHOW DOWN ***"):
                current_street = "showdown"
                showdown_reached = True
                continue

            # Parse actions
            action_patterns = [
                (r"([^:]+): folds", "fold", 0),
                (r"([^:]+): checks", "check", 0),
                (r"([^:]+): calls \$?([0-9.]+)", "call", 2),
                (r"([^:]+): bets \$?([0-9.]+)", "bet", 2),
                (r"([^:]+): raises \$?[0-9.]+ to \$?([0-9.]+)", "raise", 2),
                (r"([^:]+): calls \$?([0-9.]+) and is all-in", "all-in", 2),
                (r"([^:]+): bets \$?([0-9.]+) and is all-in", "all-in", 2),
                (
                    r"([^:]+): raises \$?[0-9.]+ to \$?([0-9.]+) and is all-in",
                    "all-in",
                    2,
                ),
            ]

            for pattern, action_type, amount_group in action_patterns:
                match = re.match(pattern, line)
                if match:
                    player_name = match.group(1).strip()
                    amount = float(match.group(amount_group)) if amount_group else 0.0
                    actions.append(Action(player_name, action_type, amount, current_street))
                    break

            # Parse pot size
            pot_match = re.search(r"Total pot \$?([0-9.]+)", line)
            if pot_match:
                pot_size = float(pot_match.group(1))

            # Parse hero result
            if hero_cards:  # Only if we have hero cards
                for player in players:
                    if player.is_hero:
                        hero_name = player.name
                        # Look for collected/won lines
                        collected_match = re.search(f"{re.escape(hero_name)} collected \\$?([0-9.]+)", line)
                        if collected_match:
                            collected = float(collected_match.group(1))
                            # Calculate net result (collected - invested)
                            invested = sum(action.amount for action in actions if action.player == hero_name)
                            hero_result = collected - invested

        # If no explicit result found, calculate from actions
        if hero_result is None and hero_cards:
            for player in players:
                if player.is_hero:
                    hero_name = player.name
                    invested = sum(action.amount for action in actions if action.player == hero_name)
                    hero_result = -invested  # Default to loss of invested amount

        return ParsedHandData(
            hand_id=hand_id,
            datetime=hand_datetime,
            table_name=table_name,
            game_type=game_type,
            stakes=stakes,
            max_players=max_players,
            players=players,
            hero_cards=hero_cards,
            board_cards=board_cards,
            actions=actions,
            pot_size=pot_size,
            hero_result=hero_result,
            showdown_reached=showdown_reached,
            raw_text=hand_text,
        )

    def _parse_ggpoker(self, content: str) -> tuple[list[ParsedHandData], list[str]]:
        """Parse GGPoker hand history format - placeholder for now"""
        # GGPoker format is similar to PokerStars but has some differences
        # For now, we'll try to use the PokerStars parser as a fallback
        return self._parse_pokerstars(content)


def calculate_file_hash(content: str) -> str:
    """Calculate SHA256 hash of file content."""
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def is_plo_hand(game_type: str) -> bool:
    """Check if the hand is a PLO variant."""
    plo_variants = ["PLO", "Pot Limit Omaha", "PLO8", "Pot Limit Omaha Hi/Lo"]
    return any(variant.lower() in game_type.lower() for variant in plo_variants)
