"""Card utility functions for PLO.

This module provides card validation, conversion, and utility functions extracted from the backend card service.
"""

from treys import Card


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

    validate_no_duplicates(all_cards)


def validate_card_input(card_lists: list[list[str]]) -> None:
    """Validate card input for duplicates and format.

    Args:
        card_lists: List of card lists to validate

    Raises:
        DuplicateCardError: If duplicate cards are found
        CardValidationError: If card validation fails
    """
    try:
        validate_all_cards_unique(*card_lists)
    except DuplicateCardError as e:
        raise DuplicateCardError(f"Card validation failed: {e}")


def str_to_cards(card_strs: list[str]) -> list[int]:
    """Convert card strings to Treys integer format.

    Args:
        card_strs: List of card strings in format like ["Ah", "Kh", "Qh", "Jh"]

    Returns:
        List of Treys integer representations

    Raises:
        CardValidationError: If card format is invalid
    """
    if not card_strs:
        return []

    # Convert to standard format first
    standard_cards = [convert_unicode_suits_to_standard(card) for card in card_strs]

    # Filter out empty cards
    standard_cards = [card for card in standard_cards if card and card.strip()]

    try:
        # Convert to Treys integers
        return [Card.new(card) for card in standard_cards]
    except Exception as e:
        raise CardValidationError(f"Failed to convert cards to Treys format: {e}")


def cards_to_str(card_ints: list[int]) -> list[str]:
    """Convert Treys integer cards back to string format.

    Args:
        card_ints: List of Treys integer representations

    Returns:
        List of card strings in format like ["Ah", "Kh", "Qh", "Jh"]
    """
    if not card_ints:
        return []

    return [Card.int_to_str(card_int) for card_int in card_ints]


def is_valid_card(card: str) -> bool:
    """Check if a card string is valid.

    Args:
        card: Card string to validate

    Returns:
        True if valid, False otherwise
    """
    if not card or not card.strip():
        return False

    # Convert to standard format
    standard_card = convert_unicode_suits_to_standard(card.strip())

    if len(standard_card) != 2:
        return False

    rank = standard_card[0].upper()
    suit = standard_card[1].lower()

    # Valid ranks: 2-9, T, J, Q, K, A
    valid_ranks = set("23456789TJQKA")

    # Valid suits: h, d, s, c
    valid_suits = set("hdcs")

    return rank in valid_ranks and suit in valid_suits
