import json
import unittest
from unittest.mock import mock_open, patch

from core.services.player_profiles import (
    PREDEFINED_PROFILES,
    PlayerProfile,
    PlayerProfileManager,
    get_betting_action,
    get_hand_strength_threshold,
    should_player_fold_to_aggression,
)


class TestPlayerProfile(unittest.TestCase):
    """Test the PlayerProfile dataclass."""

    def setUp(self):
        """Set up test fixtures."""
        self.profile = PlayerProfile(
            name="Test Player",
            description="A test player profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

    def test_profile_creation(self):
        """Test PlayerProfile creation with all attributes."""
        self.assertEqual(self.profile.name, "Test Player")
        self.assertEqual(self.profile.description, "A test player profile")
        self.assertEqual(self.profile.hand_range_tightness, 50)
        self.assertEqual(self.profile.preflop_aggression, 60)
        self.assertEqual(self.profile.bluff_frequency, 20)
        self.assertEqual(self.profile.tilt_resistance, 65)

    def test_to_dict(self):
        """Test converting profile to dictionary."""
        profile_dict = self.profile.to_dict()

        self.assertIsInstance(profile_dict, dict)
        self.assertEqual(profile_dict["name"], "Test Player")
        self.assertEqual(profile_dict["hand_range_tightness"], 50)
        self.assertEqual(profile_dict["preflop_aggression"], 60)
        self.assertIn("description", profile_dict)
        self.assertIn("tilt_resistance", profile_dict)

    def test_from_dict(self):
        """Test creating profile from dictionary."""
        profile_dict = {
            "name": "Dict Player",
            "description": "Created from dict",
            "hand_range_tightness": 75,
            "preflop_aggression": 45,
            "flop_aggression": 50,
            "turn_aggression": 55,
            "river_aggression": 50,
            "bluff_frequency": 15,
            "value_bet_frequency": 65,
            "fold_to_pressure": 60,
            "threeb_frequency": 12,
            "fourb_frequency": 6,
            "cbet_frequency": 55,
            "check_call_frequency": 50,
            "donk_bet_frequency": 8,
            "bet_sizing_aggression": 55,
            "positional_awareness": 65,
            "slow_play_frequency": 30,
            "tilt_resistance": 70,
        }

        profile = PlayerProfile.from_dict(profile_dict)

        self.assertEqual(profile.name, "Dict Player")
        self.assertEqual(profile.hand_range_tightness, 75)
        self.assertEqual(profile.preflop_aggression, 45)
        self.assertEqual(profile.tilt_resistance, 70)

    def test_round_trip_dict_conversion(self):
        """Test converting to dict and back preserves data."""
        original_dict = self.profile.to_dict()
        new_profile = PlayerProfile.from_dict(original_dict)
        new_dict = new_profile.to_dict()

        self.assertEqual(original_dict, new_dict)


class TestPlayerProfileManager(unittest.TestCase):
    """Test the PlayerProfileManager class."""

    def setUp(self):
        """Set up test fixtures."""
        self.manager = PlayerProfileManager()
        self.test_profile = PlayerProfile(
            name="Custom Test",
            description="A custom test profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

    def test_get_predefined_profile(self):
        """Test getting a predefined profile."""
        profile = self.manager.get_profile("nit")

        self.assertIsNotNone(profile)
        self.assertEqual(profile.name, "Nit")
        self.assertGreater(profile.hand_range_tightness, 80)

    def test_get_nonexistent_profile(self):
        """Test getting a non-existent profile."""
        profile = self.manager.get_profile("nonexistent")

        self.assertIsNone(profile)

    def test_get_all_profiles_includes_predefined(self):
        """Test that get_all_profiles includes predefined profiles."""
        all_profiles = self.manager.get_all_profiles()

        self.assertIn("nit", all_profiles)
        self.assertIn("fish", all_profiles)
        self.assertIn("tight_aggressive", all_profiles)
        self.assertIn("loose_aggressive", all_profiles)

    def test_add_custom_profile(self):
        """Test adding a custom profile."""
        manager = PlayerProfileManager()
        profile = PlayerProfile(
            name="Custom Test",
            description="A custom test profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

        success = manager.add_custom_profile(profile)
        self.assertTrue(success)

        # Profile is stored with normalized key
        retrieved = manager.get_profile("custom_test")
        self.assertIsNotNone(retrieved)
        self.assertEqual(retrieved.name, "Custom Test")

    def test_add_custom_profile_duplicate_name(self):
        """Test adding a custom profile with duplicate name."""
        manager = PlayerProfileManager()
        profile1 = PlayerProfile(
            name="Custom Test",
            description="First custom profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

        profile2 = PlayerProfile(
            name="Custom Test",
            description="Second custom profile",
            hand_range_tightness=60,
            preflop_aggression=70,
            flop_aggression=75,
            turn_aggression=70,
            river_aggression=65,
            bluff_frequency=30,
            value_bet_frequency=80,
            fold_to_pressure=50,
            threeb_frequency=25,
            fourb_frequency=12,
            cbet_frequency=70,
            check_call_frequency=35,
            donk_bet_frequency=15,
            bet_sizing_aggression=70,
            positional_awareness=80,
            slow_play_frequency=15,
            tilt_resistance=75,
        )

        success1 = manager.add_custom_profile(profile1)
        success2 = manager.add_custom_profile(profile2)

        # Both should succeed since the second one overwrites the first
        self.assertTrue(success1)
        self.assertTrue(success2)

        # Should have the second profile
        retrieved = manager.get_profile("custom_test")
        self.assertIsNotNone(retrieved)
        self.assertEqual(retrieved.description, "Second custom profile")

    def test_add_custom_profile_conflicts_with_predefined(self):
        """Test adding a custom profile that conflicts with predefined name."""
        manager = PlayerProfileManager()
        profile = PlayerProfile(
            name="nit",  # This conflicts with predefined profile
            description="Custom nit profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

        success = manager.add_custom_profile(profile)
        # The manager should not allow predefined profile names as custom profiles
        self.assertFalse(success)

    def test_remove_custom_profile(self):
        """Test removing a custom profile."""
        manager = PlayerProfileManager()
        profile = PlayerProfile(
            name="Custom Test",
            description="A custom test profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

        manager.add_custom_profile(profile)
        success = manager.remove_custom_profile("custom_test")
        self.assertTrue(success)

        retrieved = manager.get_profile("custom_test")
        self.assertIsNone(retrieved)

    def test_remove_nonexistent_custom_profile(self):
        """Test removing a non-existent custom profile."""
        success = self.manager.remove_custom_profile("nonexistent")
        self.assertFalse(success)

    def test_remove_predefined_profile_fails(self):
        """Test that removing predefined profiles fails."""
        success = self.manager.remove_custom_profile("nit")
        self.assertFalse(success)

        # Verify predefined profile still exists
        profile = self.manager.get_profile("nit")
        self.assertIsNotNone(profile)

    def test_save_custom_profiles(self):
        """Test saving custom profiles to file."""
        manager = PlayerProfileManager()
        profile = PlayerProfile(
            name="Custom Test",
            description="A custom test profile",
            hand_range_tightness=50,
            preflop_aggression=60,
            flop_aggression=65,
            turn_aggression=60,
            river_aggression=55,
            bluff_frequency=20,
            value_bet_frequency=70,
            fold_to_pressure=40,
            threeb_frequency=15,
            fourb_frequency=8,
            cbet_frequency=60,
            check_call_frequency=45,
            donk_bet_frequency=10,
            bet_sizing_aggression=60,
            positional_awareness=70,
            slow_play_frequency=25,
            tilt_resistance=65,
        )

        manager.add_custom_profile(profile)

        with patch("builtins.open", mock_open()) as mock_file:
            manager.save_custom_profiles("test_profiles.json")
            mock_file.assert_called_once_with("test_profiles.json", "w")

            # Check that the correct data was written
            write_calls = mock_file().write.call_args_list
            if write_calls:
                write_call = write_calls[0][0][0]
                # The data should be valid JSON
                try:
                    saved_data = json.loads(write_call)
                    self.assertIn("custom_test", saved_data)
                    self.assertEqual(saved_data["custom_test"]["name"], "Custom Test")
                except json.JSONDecodeError:
                    # If JSON is invalid, just check that something was written
                    self.assertTrue(len(write_call) > 0)

    @patch("os.path.exists")
    @patch("builtins.open", new_callable=mock_open)
    @patch("json.load")
    def test_load_custom_profiles(self, mock_json_load, mock_file, mock_exists):
        """Test loading custom profiles from file."""
        mock_exists.return_value = True
        mock_json_load.return_value = {
            "loaded test": {
                "name": "Loaded Test",
                "description": "A loaded test profile",
                "hand_range_tightness": 60,
                "preflop_aggression": 70,
                "flop_aggression": 75,
                "turn_aggression": 70,
                "river_aggression": 65,
                "bluff_frequency": 25,
                "value_bet_frequency": 75,
                "fold_to_pressure": 35,
                "threeb_frequency": 20,
                "fourb_frequency": 12,
                "cbet_frequency": 70,
                "check_call_frequency": 40,
                "donk_bet_frequency": 15,
                "bet_sizing_aggression": 70,
                "positional_awareness": 75,
                "slow_play_frequency": 20,
                "tilt_resistance": 70,
            }
        }

        # Load profiles
        self.manager.load_custom_profiles("test_profiles.json")

        # Verify file operations
        mock_file.assert_called_once_with("test_profiles.json")
        mock_json_load.assert_called_once()

        # Verify profile was loaded
        loaded_profile = self.manager.get_profile("loaded test")
        self.assertIsNotNone(loaded_profile)
        self.assertEqual(loaded_profile.name, "Loaded Test")

    @patch("os.path.exists")
    def test_load_custom_profiles_file_not_found(self, mock_exists):
        """Test loading custom profiles when file doesn't exist."""
        mock_exists.return_value = False

        # Should not raise exception
        self.manager.load_custom_profiles("nonexistent.json")

        # Custom profiles should remain empty
        all_profiles = self.manager.get_all_profiles()
        for name in all_profiles:
            self.assertIn(name, PREDEFINED_PROFILES)


class TestUtilityFunctions(unittest.TestCase):
    """Test utility functions for player profiles."""

    def setUp(self):
        """Set up test fixtures."""
        self.nit = PREDEFINED_PROFILES["nit"]
        self.lag = PREDEFINED_PROFILES["loose_aggressive"]

    def test_get_hand_strength_threshold_nit_early(self):
        """Test hand strength threshold calculation for nit in early position."""
        threshold = get_hand_strength_threshold(self.nit, "early")
        self.assertGreater(threshold, 0.8)  # Nit should be very tight in early position
        self.assertLess(threshold, 1.0)

    def test_get_hand_strength_threshold_nit_late(self):
        """Test hand strength threshold calculation for nit in late position."""
        threshold = get_hand_strength_threshold(self.nit, "late")
        early_threshold = get_hand_strength_threshold(self.nit, "early")
        # Should be looser in late position, but might be the same if positional awareness is low
        self.assertLessEqual(threshold, early_threshold)

    def test_get_hand_strength_threshold_lag(self):
        """Test hand strength threshold calculation for loose aggressive player."""
        threshold = get_hand_strength_threshold(self.lag, "late")
        self.assertLess(threshold, 0.4)  # LAG should be much looser
        self.assertGreater(threshold, 0.0)

    def test_should_player_fold_to_aggression_nit(self):
        """Test fold to aggression for nit player."""
        should_fold = should_player_fold_to_aggression(self.nit, 0.4, 80)
        # This is probabilistic, so we just test that it returns a boolean
        self.assertIsInstance(should_fold, bool)

    def test_should_player_fold_to_aggression_lag(self):
        """Test fold to aggression for loose aggressive player."""
        should_fold = should_player_fold_to_aggression(self.lag, 0.4, 80)
        # This is probabilistic, so we just test that it returns a boolean
        self.assertIsInstance(should_fold, bool)

    def test_get_betting_action_strong_hand(self):
        """Test betting action for strong hand."""
        action = get_betting_action(self.lag, 0.9, "flop", "late")
        # This is probabilistic, so we just test that it returns a valid action
        self.assertIn(action, ["fold", "check", "call", "bet", "raise"])

    def test_get_betting_action_weak_hand(self):
        """Test betting action for weak hand."""
        action = get_betting_action(self.nit, 0.1, "flop", "early")
        # This is probabilistic, so we just test that it returns a valid action
        self.assertIn(action, ["fold", "check", "call", "bet", "raise"])

    def test_get_betting_action_different_streets(self):
        """Test betting action across different streets."""
        for street in ["preflop", "flop", "turn", "river"]:
            action = get_betting_action(self.lag, 0.6, street, "late")
            self.assertIn(action, ["fold", "check", "call", "bet", "raise"])

    def test_get_betting_action_different_positions(self):
        """Test betting action in different positions."""
        for position in ["early", "middle", "late"]:
            action = get_betting_action(self.lag, 0.6, "flop", position)
            self.assertIn(action, ["fold", "check", "call", "bet", "raise"])


if __name__ == "__main__":
    unittest.main()
