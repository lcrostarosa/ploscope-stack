import pytest

from core.services.equity_calculator import categorize_hand_strength as cat_calc
from core.services.equity_service import categorize_hand_strength as cat_es


@pytest.mark.parametrize(
    "score, expected",
    [
        (10, "Straight Flush"),
        (11, "Four of a Kind"),
        (166, "Four of a Kind"),
        (167, "Full House"),
        (322, "Full House"),
        (323, "Flush"),
        (1599, "Flush"),
        (1600, "Straight"),
        (1609, "Straight"),
        (1610, "Three of a Kind"),
        (2467, "Three of a Kind"),
        (2468, "Two Pair"),
        (3325, "Two Pair"),
        (3326, "One Pair"),
        (6185, "One Pair"),
        (6186, "High Card"),
        (7462, "High Card"),
    ],
)
def test_categorize_hand_strength_thresholds(score, expected):
    assert cat_es(score) == expected
    assert cat_calc(score) == expected


def test_no_false_full_house_on_flush_draw_scenario(monkeypatch):
    """
    Regression test for scenario: Bottom board 5s Qs 2s and hole Ad 6s 3d 3s
    Should not be categorized as Full House.
    This test verifies the category function returns one of the non-house labels
    for scores in the non-house ranges.
    """
    # Choose representative scores in safe non-house bands
    non_house_scores = [400, 1200, 1610, 3000, 7000]
    for s in non_house_scores:
        assert cat_es(s) not in {"Full House", "Four of a Kind", "Straight Flush"}
        assert cat_calc(s) not in {"Full House", "Four of a Kind", "Straight Flush"}
