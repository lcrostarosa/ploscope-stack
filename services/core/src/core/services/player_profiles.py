"""Player Profile Management.

This module provides player profile management for PLO solver simulations.
"""

import json
import random

# import os
from dataclasses import dataclass
from typing import Optional  # List


@dataclass
class PlayerProfile:
    """Defines a player's behavioral characteristics for simulation."""

    name: str
    description: str

    # Hand Selection (0-100, higher = tighter)
    hand_range_tightness: int

    # Aggression Levels (0-100, higher = more aggressive)
    preflop_aggression: int
    flop_aggression: int
    turn_aggression: int
    river_aggression: int

    # Betting Patterns (0-100)
    bluff_frequency: int
    value_bet_frequency: int
    fold_to_pressure: int  # How easily they fold to aggression

    # Specific Actions (0-100)
    threeb_frequency: int  # 3-bet frequency
    fourb_frequency: int  # 4-bet frequency
    cbet_frequency: int  # Continuation bet frequency
    check_call_frequency: int
    donk_bet_frequency: int  # Leading into the preflop aggressor

    # Sizing Tendencies (0-100, higher = larger bets)
    bet_sizing_aggression: int

    # Positional Awareness (0-100, higher = more position conscious)
    positional_awareness: int

    # Other Tendencies
    slow_play_frequency: int  # How often they slow play strong hands
    tilt_resistance: int  # How well they handle bad beats (0-100)

    def to_dict(self) -> dict:
        """Convert profile to dictionary for JSON serialization."""
        return {
            "name": self.name,
            "description": self.description,
            "hand_range_tightness": self.hand_range_tightness,
            "preflop_aggression": self.preflop_aggression,
            "flop_aggression": self.flop_aggression,
            "turn_aggression": self.turn_aggression,
            "river_aggression": self.river_aggression,
            "bluff_frequency": self.bluff_frequency,
            "value_bet_frequency": self.value_bet_frequency,
            "fold_to_pressure": self.fold_to_pressure,
            "threeb_frequency": self.threeb_frequency,
            "fourb_frequency": self.fourb_frequency,
            "cbet_frequency": self.cbet_frequency,
            "check_call_frequency": self.check_call_frequency,
            "donk_bet_frequency": self.donk_bet_frequency,
            "bet_sizing_aggression": self.bet_sizing_aggression,
            "positional_awareness": self.positional_awareness,
            "slow_play_frequency": self.slow_play_frequency,
            "tilt_resistance": self.tilt_resistance,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "PlayerProfile":
        """Create profile from dictionary."""
        return cls(**data)


# Predefined Player Profiles
PREDEFINED_PROFILES = {
    "nit": PlayerProfile(
        name="Nit",
        description="Extremely tight and passive player who only plays premium hands",
        hand_range_tightness=85,
        preflop_aggression=25,
        flop_aggression=30,
        turn_aggression=35,
        river_aggression=40,
        bluff_frequency=5,
        value_bet_frequency=60,
        fold_to_pressure=80,
        threeb_frequency=8,
        fourb_frequency=3,
        cbet_frequency=45,
        check_call_frequency=70,
        donk_bet_frequency=5,
        bet_sizing_aggression=30,
        positional_awareness=40,
        slow_play_frequency=30,
        tilt_resistance=80,
    ),
    "fish": PlayerProfile(
        name="Fish",
        description="Loose passive player who calls too much and rarely bluffs",
        hand_range_tightness=20,
        preflop_aggression=15,
        flop_aggression=20,
        turn_aggression=25,
        river_aggression=30,
        bluff_frequency=5,
        value_bet_frequency=40,
        fold_to_pressure=25,
        threeb_frequency=5,
        fourb_frequency=2,
        cbet_frequency=35,
        check_call_frequency=85,
        donk_bet_frequency=15,
        bet_sizing_aggression=25,
        positional_awareness=15,
        slow_play_frequency=60,
        tilt_resistance=30,
    ),
    "loose_passive": PlayerProfile(
        name="Loose Passive",
        description="Plays many hands but rarely bets or raises without a strong hand",
        hand_range_tightness=30,
        preflop_aggression=20,
        flop_aggression=25,
        turn_aggression=30,
        river_aggression=35,
        bluff_frequency=10,
        value_bet_frequency=50,
        fold_to_pressure=40,
        threeb_frequency=12,
        fourb_frequency=5,
        cbet_frequency=40,
        check_call_frequency=75,
        donk_bet_frequency=10,
        bet_sizing_aggression=35,
        positional_awareness=25,
        slow_play_frequency=45,
        tilt_resistance=50,
    ),
    "tight_passive": PlayerProfile(
        name="Tight Passive",
        description="Plays few hands and rarely bets without a strong hand",
        hand_range_tightness=70,
        preflop_aggression=25,
        flop_aggression=30,
        turn_aggression=35,
        river_aggression=40,
        bluff_frequency=5,
        value_bet_frequency=55,
        fold_to_pressure=65,
        threeb_frequency=10,
        fourb_frequency=4,
        cbet_frequency=50,
        check_call_frequency=60,
        donk_bet_frequency=5,
        bet_sizing_aggression=40,
        positional_awareness=35,
        slow_play_frequency=40,
        tilt_resistance=70,
    ),
    "tight_aggressive": PlayerProfile(
        name="Tight Aggressive",
        description="Plays premium hands aggressively with good positional awareness",
        hand_range_tightness=65,
        preflop_aggression=70,
        flop_aggression=75,
        turn_aggression=70,
        river_aggression=65,
        bluff_frequency=25,
        value_bet_frequency=80,
        fold_to_pressure=45,
        threeb_frequency=25,
        fourb_frequency=15,
        cbet_frequency=75,
        check_call_frequency=35,
        donk_bet_frequency=10,
        bet_sizing_aggression=70,
        positional_awareness=80,
        slow_play_frequency=20,
        tilt_resistance=75,
    ),
    "loose_aggressive": PlayerProfile(
        name="Loose Aggressive",
        description="Plays many hands very aggressively, bluffs frequently",
        hand_range_tightness=25,
        preflop_aggression=80,
        flop_aggression=85,
        turn_aggression=80,
        river_aggression=75,
        bluff_frequency=50,
        value_bet_frequency=85,
        fold_to_pressure=30,
        threeb_frequency=35,
        fourb_frequency=20,
        cbet_frequency=85,
        check_call_frequency=25,
        donk_bet_frequency=25,
        bet_sizing_aggression=80,
        positional_awareness=60,
        slow_play_frequency=10,
        tilt_resistance=40,
    ),
    "maniac": PlayerProfile(
        name="Maniac",
        description="Extremely aggressive player who bets and raises with any hand",
        hand_range_tightness=10,
        preflop_aggression=95,
        flop_aggression=90,
        turn_aggression=85,
        river_aggression=80,
        bluff_frequency=70,
        value_bet_frequency=90,
        fold_to_pressure=15,
        threeb_frequency=50,
        fourb_frequency=35,
        cbet_frequency=95,
        check_call_frequency=15,
        donk_bet_frequency=40,
        bet_sizing_aggression=90,
        positional_awareness=30,
        slow_play_frequency=5,
        tilt_resistance=20,
    ),
}


class PlayerProfileManager:
    """Manages player profiles for simulation."""

    def __init__(self):
        self.custom_profiles: dict[str, PlayerProfile] = {}

    def get_profile(self, profile_name: str) -> Optional[PlayerProfile]:
        """Get a profile by name (predefined or custom)"""
        if profile_name in PREDEFINED_PROFILES:
            return PREDEFINED_PROFILES[profile_name]
        elif profile_name in self.custom_profiles:
            return self.custom_profiles[profile_name]
        return None

    def get_all_profiles(self) -> dict[str, PlayerProfile]:
        """Get all available profiles."""
        all_profiles = PREDEFINED_PROFILES.copy()
        all_profiles.update(self.custom_profiles)
        return all_profiles

    def add_custom_profile(self, profile: PlayerProfile) -> bool:
        """Add a custom profile."""
        # Normalize the name for comparison
        normalized_name = profile.name.lower().replace(" ", "_")

        # Check if the normalized name conflicts with predefined profiles
        if normalized_name in PREDEFINED_PROFILES:
            return False

        # Also check against existing predefined profile names
        predefined_names = {p.name.lower().replace(" ", "_") for p in PREDEFINED_PROFILES.values()}
        if normalized_name in predefined_names:
            return False

        self.custom_profiles[normalized_name] = profile
        return True

    def remove_custom_profile(self, profile_name: str) -> bool:
        """Remove a custom profile."""
        if profile_name in self.custom_profiles:
            del self.custom_profiles[profile_name]
            return True
        return False

    def save_custom_profiles(self, filepath: str):
        """Save custom profiles to file."""
        data = {name: profile.to_dict() for name, profile in self.custom_profiles.items()}
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)

    def load_custom_profiles(self, filepath: str):
        """Load custom profiles from file."""
        try:
            with open(filepath) as f:
                data = json.load(f)
            self.custom_profiles = {name: PlayerProfile.from_dict(profile_data) for name, profile_data in data.items()}
        except FileNotFoundError:
            pass  # No custom profiles file yet


def get_hand_strength_threshold(profile: PlayerProfile, position: str = "late") -> float:
    """Calculate the minimum hand strength threshold for a profile to play Returns a value between 0.0 and 1.0."""
    base_threshold = profile.hand_range_tightness / 100.0

    # Adjust for positional awareness
    position_multiplier = 1.0
    if profile.positional_awareness > 50:
        if position in ["early", "middle"]:
            position_multiplier = 1.1  # Tighter in early position
        elif position == "late":
            position_multiplier = 0.9  # Looser in late position

    return min(0.95, base_threshold * position_multiplier)


def should_player_fold_to_aggression(profile: PlayerProfile, hand_strength: float, aggression_level: int) -> bool:
    """Determine if a player should fold based on their profile and the situation."""
    fold_threshold = profile.fold_to_pressure / 100.0

    # Adjust based on hand strength
    if hand_strength > 0.8:  # Very strong hand
        fold_threshold *= 0.3
    elif hand_strength > 0.6:  # Good hand
        fold_threshold *= 0.6
    elif hand_strength < 0.3:  # Weak hand
        fold_threshold *= 1.3

    # Adjust based on opponent aggression
    aggression_factor = (aggression_level / 100.0) * 1.2

    return random.random() < (fold_threshold * aggression_factor)


def get_betting_action(profile: PlayerProfile, hand_strength: float, street: str, position: str) -> str:
    """
    Determine what action a player should take based on their profile
    Returns: 'fold', 'check', 'call', 'bet', 'raise'
    """
    # Get aggression level for the street
    aggression_map = {
        "preflop": profile.preflop_aggression,
        "flop": profile.flop_aggression,
        "turn": profile.turn_aggression,
        "river": profile.river_aggression,
    }

    aggression = aggression_map.get(street, 50) / 100.0

    # Weak hands
    if hand_strength < 0.3:
        if random.random() < profile.bluff_frequency / 100.0:
            return "bet" if random.random() < aggression else "call"
        else:
            return "fold" if random.random() < 0.7 else "check"

    # Medium hands
    elif hand_strength < 0.7:
        if random.random() < aggression:
            return "bet" if random.random() < 0.6 else "raise"
        else:
            return "call" if random.random() < 0.7 else "check"

    # Strong hands
    else:
        if random.random() < profile.slow_play_frequency / 100.0:
            return "check" if random.random() < 0.6 else "call"
        else:
            return "bet" if random.random() < aggression else "raise"
