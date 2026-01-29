"""Basic tests for plosolver-src package."""

import pytest

from core.equity.calculator import calculate_double_board_stats, simulate_estimated_equity

# Database models removed - core package no longer includes database functionality
from core.services.card_service import str_to_cards, validate_card_input
from core.solver.engine import GameState, get_solver


def test_equity_calculation():
    """Test basic equity calculation functionality."""
    hands = [["Ah", "Kh", "Qh", "Jh"], ["As", "Ks", "Qs", "Js"]]
    top_board = ["2h", "3h", "4h"]
    bottom_board = ["5s", "6s", "7s"]

    chop_both, scoop_both, split_top, split_bottom = calculate_double_board_stats(
        hands=hands,
        top_board=top_board,
        bottom_board=bottom_board,
        num_iterations=100,  # Small number for testing
    )

    assert len(chop_both) == 2
    assert len(scoop_both) == 2
    assert len(split_top) == 2
    assert len(split_bottom) == 2

    # All values should be between 0 and 1
    for values in [chop_both, scoop_both, split_top, split_bottom]:
        for value in values:
            assert 0 <= value <= 1


def test_estimated_equity():
    """Test estimated equity calculation."""
    hand = ["Ah", "Kh", "Qh", "Jh"]
    board = ["2h", "3h", "4h"]

    equity, tie_percent, hand_breakdown, opponent_breakdown, _ = simulate_estimated_equity(
        hand=hand,
        board=board,
        num_iterations=100,
        num_opponents=2,  # Small number for testing
    )

    assert 0 <= equity <= 100
    assert 0 <= tie_percent <= 100


def test_card_utilities():
    """Test card utility functions."""
    cards = ["Ah", "Kh", "Qh", "Jh"]

    # Test str_to_cards
    card_ints = str_to_cards(cards)
    assert len(card_ints) == 4
    assert all(isinstance(card, int) for card in card_ints)

    # Test validation
    validate_card_input([cards])

    # Test duplicate detection
    with pytest.raises(Exception):
        validate_card_input([["Ah", "Ah", "Kh", "Qh"]])


def test_game_state():
    """Test GameState creation and methods."""
    game_state = GameState(
        player_position=0,
        active_players=[0, 1, 2],
        board=["Ah", "Kh", "Qh"],
        pot_size=100.0,
        current_bet=10.0,
        stack_sizes=[1000.0, 1000.0, 1000.0],
        betting_history=[],
        street="flop",
        player_ranges={},
        hero_cards=["2h", "3h", "4h", "5h"],
    )

    assert game_state.player_position == 0
    assert len(game_state.active_players) == 3
    assert len(game_state.board) == 3
    assert game_state.pot_size == 100.0

    # Test hash generation
    state_hash = game_state.to_hash()
    assert isinstance(state_hash, str)
    assert len(state_hash) > 0


def test_solver():
    """Test solver functionality."""
    solver = get_solver()
    assert solver is not None

    game_state = GameState(
        player_position=0,
        active_players=[0, 1],
        board=["Ah", "Kh", "Qh"],
        pot_size=100.0,
        current_bet=10.0,
        stack_sizes=[1000.0, 1000.0],
        betting_history=[],
        street="flop",
        player_ranges={},
        hero_cards=["2h", "3h", "4h", "5h"],
    )

    # Test solving (with minimal iterations for testing)
    solution = solver.solve_spot(game_state, iterations=10)

    assert "strategies" in solution
    assert "equity" in solution
    assert "solve_time" in solution


# Enums test removed - core package no longer includes database functionality


# Database-dependent tests removed - core package no longer includes database functionality


def test_package_imports():
    """Test that all main package imports work."""

    # Just verify imports work
    assert calculate_double_board_stats is not None
    assert simulate_estimated_equity is not None
    assert get_solver is not None
    assert GameState is not None
    assert str_to_cards is not None
    assert validate_card_input is not None
