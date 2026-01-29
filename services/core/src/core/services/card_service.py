# import logging
import random

from treys import Card

from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


class DuplicateCardError(ValueError):
    """Raised when duplicate cards are detected."""


class CardValidationError(ValueError):
    """Raised when card validation fails."""


def convert_unicode_suits_to_standard(card: str) -> str:
    """Convert Unicode suit symbols to standard single-letter format."""
    if not card:
        return card

    # Handle edge cases
    card = card.strip()
    if len(card) < 2:
        return card

    # Map Unicode suits to standard notation
    suit_conversion = {
        "♥": "h",  # hearts
        "♦": "d",  # diamonds
        "♠": "s",  # spades
        "♣": "c",  # clubs
    }

    # Handle potential longer card strings (shouldn't happen, but be safe)
    if len(card) == 2:
        rank = card[0]
        suit = card[1]
    else:
        # For longer strings, take first char as rank and last char as suit
        rank = card[0]
        suit = card[-1]

    # Convert Unicode suit to standard notation if needed
    if suit in suit_conversion:
        return rank + suit_conversion[suit]

    # Return as-is if already in standard format
    return card


def validate_no_duplicates(card_strs: list[str]) -> None:
    """Validate that there are no duplicate cards in the list.

    Raises DuplicateCardError if duplicates are found.
    """
    if not card_strs:
        return

    # Convert to standard format for comparison
    standard_cards = [convert_unicode_suits_to_standard(card) for card in card_strs]

    # Check for duplicates
    seen_cards = set()
    duplicates = []

    for i, card in enumerate(standard_cards):
        if not card or not card.strip():
            continue  # Skip empty cards

        card_clean = card.strip().upper()
        if card_clean in seen_cards:
            duplicates.append(card_clean)
        else:
            seen_cards.add(card_clean)

    if duplicates:
        raise DuplicateCardError(f"Duplicate cards detected: {duplicates}")


def validate_all_cards_unique(*card_lists: list[str]) -> None:
    """Validate that no cards appear multiple times across all provided lists.

    Used to check hands, boards, folded cards, etc.
    """
    all_cards = []

    for card_list in card_lists:
        if card_list:
            all_cards.extend(card_list)

    # Filter out empty/None cards
    all_cards = [card for card in all_cards if card and card.strip()]

    if not all_cards:
        return

    validate_no_duplicates(all_cards)


def str_to_cards(card_strs: list[str], validate_duplicates: bool = True) -> list[int]:
    """Convert a list of card strings to Treys card ints.

    Args:
        card_strs: List of card strings (e.g., ['Ah', 'Kd'])
        validate_duplicates: Whether to check for duplicate cards

    Returns:
        List of Treys card integers

    Raises:
        DuplicateCardError: If duplicate cards are found
        CardValidationError: If card format is invalid
    """
    if not card_strs:
        return []

    # Validate for duplicates first if requested
    if validate_duplicates:
        validate_no_duplicates(card_strs)

    # Convert Unicode suits to standard format before processing
    standard_cards = [convert_unicode_suits_to_standard(card) for card in card_strs]

    # Log the conversion for debugging
    if any(card != standard for card, standard in zip(card_strs, standard_cards)):
        logger.info(f"Converted Unicode suits: {card_strs} -> {standard_cards}")

    try:
        # Filter out empty cards and convert
        valid_cards = [card for card in standard_cards if card and card.strip()]
        return [Card.new(card) for card in valid_cards]
    except Exception as e:
        logger.error(
            f"Error converting cards to Treys format: {standard_cards}, original: {card_strs}, error: {str(e)}"
        )
        raise CardValidationError(f"Invalid card format: {e}")


def get_all_cards_treys() -> list[int]:
    """Get all 52 cards as Treys integers."""
    all_card_strings = []
    ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
    suits = ["h", "d", "c", "s"]

    for rank in ranks:
        for suit in suits:
            all_card_strings.append(rank + suit)

    return [Card.new(card_str) for card_str in all_card_strings]


def get_random_board(
    exclude_cards: list[int], board_size: int, additional_exclude: list[int] | None = None
) -> list[int]:
    """Return a random board, excluding already dealt cards and optionally additional cards.

    Args:
        exclude_cards: Cards that are already in use
        board_size: Number of cards needed for the board
        additional_exclude: Additional cards to exclude (like folded cards)

    Returns:
        List of random card integers

    Raises:
        ValueError: If not enough cards available or invalid board_size
    """
    # Get all possible cards
    all_cards = get_all_cards_treys()

    # Filter out already used cards and additional excluded cards
    exclude_set = set(exclude_cards)
    if additional_exclude:
        exclude_set.update(additional_exclude)

    available_cards = [card for card in all_cards if card not in exclude_set]

    # Validate that we have enough cards available
    if board_size < 0:
        logger.error(f"Invalid board_size: {board_size} (cannot be negative)")
        raise ValueError(f"Invalid board_size: {board_size} (cannot be negative)")

    if board_size > len(available_cards):
        logger.error(
            f"Cannot sample {board_size} cards from {len(available_cards)} available cards. "
            f"Excluded {len(exclude_set)} cards from 52 total cards."
        )
        raise ValueError(
            f"Cannot sample {board_size} cards from {len(available_cards)} available cards. "
            f"Excluded {len(exclude_set)} cards from 52 total cards."
        )

    if board_size == 0:
        return []

    return random.sample(available_cards, board_size)


def validate_card_input(
    hands: list[list[str]],
    boards: list[list[str]] = None,
    folded_cards: list[str] = None,
) -> None:
    """Comprehensive validation of all card inputs for duplicates.

    Args:
        hands: List of player hands
        boards: List of board cards (for double board)
        folded_cards: List of folded cards

    Raises:
        DuplicateCardError: If any duplicate cards are found
        CardValidationError: If card format is invalid
    """
    all_card_lists = []

    # Add all hands
    for hand in hands:
        if hand:
            all_card_lists.append(hand)

    # Add all boards
    if boards:
        for board in boards:
            if board:
                all_card_lists.append(board)

    # Add folded cards
    if folded_cards:
        all_card_lists.append(folded_cards)

    # Validate no duplicates across all cards
    validate_all_cards_unique(*all_card_lists)


def count_total_cards_used(
    hands: list[list[str]],
    boards: list[list[str]] = None,
    folded_cards: list[str] = None,
) -> int:
    """Count total number of cards being used."""
    total = 0

    # Count hand cards
    for hand in hands:
        if hand:
            total += len([card for card in hand if card and card.strip()])

    # Count board cards
    if boards:
        for board in boards:
            if board:
                total += len([card for card in board if card and card.strip()])

    # Count folded cards
    if folded_cards:
        total += len([card for card in folded_cards if card and card.strip()])

    return total


def check_card_availability(
    hands: list[list[str]],
    boards: list[list[str]] = None,
    folded_cards: list[str] = None,
    needed_random_cards: int = 0,
) -> bool:
    """Check if there are enough cards available for the simulation.

    Returns:
        True if enough cards available, False otherwise
    """
    used_cards = count_total_cards_used(hands, boards, folded_cards)
    total_needed = used_cards + needed_random_cards

    return total_needed <= 52
