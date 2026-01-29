import unittest
from datetime import datetime
from unittest.mock import patch

from core.services.hand_history_parser import (
    Action,
    HandHistoryParser,
    ParsedHandData,
    PlayerInfo,
    calculate_file_hash,
    is_plo_hand,
)


class TestHandHistoryParser(unittest.TestCase):
    def setUp(self):
        """Set up test fixtures."""
        self.parser = HandHistoryParser()

    def test_detect_site_pokerstars(self):
        """Test detecting PokerStars format."""
        content = "PokerStars Hand #12345: Tournament"
        result = self.parser.detect_site(content)
        self.assertEqual(result, "pokerstars")

        content2 = "Hand #67890: Some tournament"
        result2 = self.parser.detect_site(content2)
        self.assertEqual(result2, "pokerstars")

    def test_detect_site_ggpoker(self):
        """Test detecting GGPoker format."""
        content = "GGPoker Hand History"
        result = self.parser.detect_site(content)
        self.assertEqual(result, "ggpoker")

        content2 = "GG Poker tournament"
        result2 = self.parser.detect_site(content2)
        self.assertEqual(result2, "ggpoker")

    def test_detect_site_888poker(self):
        """Test detecting 888poker format."""
        content = "888poker tournament history"
        result = self.parser.detect_site(content)
        self.assertEqual(result, "888poker")

    def test_detect_site_partypoker(self):
        """Test detecting PartyPoker format."""
        content = "PartyPoker hand history"
        result = self.parser.detect_site(content)
        self.assertEqual(result, "partypoker")

    def test_detect_site_unknown(self):
        """Test detecting unknown format."""
        content = "Unknown poker site format"
        result = self.parser.detect_site(content)
        self.assertIsNone(result)

    def test_parse_file_unknown_site(self):
        """Test parsing file with unknown site format."""
        content = "Unknown format hand history"
        hands, errors = self.parser.parse_file(content, "test.txt")

        self.assertEqual(len(hands), 0)
        self.assertEqual(len(errors), 1)
        self.assertIn("Could not detect poker site format", errors[0])

    def test_parse_file_unsupported_site(self):
        """Test parsing file with unsupported site."""
        content = "888poker tournament history"
        hands, errors = self.parser.parse_file(content, "test.txt")

        self.assertEqual(len(hands), 0)
        self.assertEqual(len(errors), 1)
        self.assertIn("Parsing for 888poker not yet implemented", errors[0])

    @patch.object(HandHistoryParser, "_parse_pokerstars")
    def test_parse_file_pokerstars(self, mock_parse):
        """Test parsing PokerStars file."""
        mock_parse.return_value = ([], [])
        content = "PokerStars Hand #12345"

        hands, errors = self.parser.parse_file(content, "test.txt")

        mock_parse.assert_called_once_with(content)

    @patch.object(HandHistoryParser, "_parse_ggpoker")
    def test_parse_file_ggpoker(self, mock_parse):
        """Test parsing GGPoker file."""
        mock_parse.return_value = ([], [])
        content = "GGPoker Hand History"

        hands, errors = self.parser.parse_file(content, "test.txt")

        mock_parse.assert_called_once_with(content)

    def test_parse_pokerstars_empty_content(self):
        """Test parsing empty PokerStars content."""
        content = ""
        hands, errors = self.parser._parse_pokerstars(content)

        self.assertEqual(len(hands), 0)
        self.assertEqual(len(errors), 0)

    def test_parse_pokerstars_invalid_hand(self):
        """Test parsing invalid PokerStars hand history."""
        content = "Invalid hand history content without proper format"
        parser = HandHistoryParser()
        hands, errors = parser.parse_file(content, "test.txt")
        # Parser should handle invalid content gracefully
        self.assertEqual(len(hands), 0)
        # May or may not have errors depending on parsing logic

    def test_parse_pokerstars_hand_no_header(self):
        """Test parsing PokerStars hand without valid header."""
        hand_text = "Invalid header line\nSeat 1: Player1 ($100 in chips)"
        result = self.parser._parse_pokerstars_hand(hand_text)

        self.assertIsNone(result)

    def test_parse_pokerstars_hand_valid(self):
        """Test parsing valid PokerStars hand."""
        hand_text = (
            "PokerStars Hand #123456789: Tournament #987654321, $10+$1 USD "
            "Hold'em Pot Limit Omaha - Level I (10/20) - 2023/01/01 10:00:00 ET\n"
            "Table '987654321 1' 6-max Seat #1 is the button\n"
            "Seat 1: Player1 ($100.00 in chips)\n"
            "Seat 2: Hero ($200.00 in chips)\n"
            "Player1: posts small blind $0.10\n"
            "Hero: posts big blind $0.20\n"
            "*** HOLE CARDS ***\n"
            "Dealt to Hero [Ah Kh Qd Jc]\n"
            "Player1: calls $0.10\n"
            "Hero: checks\n"
            "*** FLOP *** [As Ks Qh]\n"
            "Hero: bets $0.40\n"
            "Player1: folds\n"
            "Uncalled bet ($0.40) returned to Hero\n"
            "Hero collected $0.40 from pot\n"
            "*** SUMMARY ***\n"
            "Total pot $0.40 | Rake $0.00\n"
            "Board [As Ks Qh]\n"
            "Seat 1: Player1 (button) (small blind) folded on the flop\n"
            "Seat 2: Hero (big blind) collected ($0.40)"
        )

        result = self.parser._parse_pokerstars_hand(hand_text)

        self.assertIsNotNone(result)
        self.assertEqual(result.hand_id, "123456789")
        self.assertEqual(len(result.players), 2)
        self.assertEqual(result.players[0].name, "Player1")
        self.assertEqual(result.players[1].name, "Hero")
        self.assertTrue(result.players[1].is_hero)
        self.assertEqual(result.hero_cards, ["Ah", "Kh", "Qd", "Jc"])
        self.assertEqual(result.board_cards, ["As", "Ks", "Qh"])

    def test_parse_pokerstars_hand_with_showdown(self):
        """Test parsing PokerStars hand that goes to showdown."""
        hand_text = (
            "PokerStars Hand #123456789: Tournament #987654321, $10+$1 USD "
            "Hold'em Pot Limit Omaha - Level I (10/20) - 2023/01/01 10:00:00 ET\n"
            "Table '987654321 1' 6-max Seat #1 is the button\n"
            "Seat 1: Player1 ($100.00 in chips)\n"
            "Seat 2: Hero ($200.00 in chips)\n"
            "Player1: posts small blind $0.10\n"
            "Hero: posts big blind $0.20\n"
            "*** HOLE CARDS ***\n"
            "Dealt to Hero [Ah Kh Qd Jc]\n"
            "Player1: calls $0.10\n"
            "Hero: checks\n"
            "*** FLOP *** [As Ks Qh]\n"
            "Hero: bets $0.40\n"
            "Player1: calls $0.40\n"
            "*** TURN *** [As Ks Qh 9h]\n"
            "Hero: bets $1.00\n"
            "Player1: calls $1.00\n"
            "*** RIVER *** [As Ks Qh 9h 2c]\n"
            "Hero: checks\n"
            "Player1: checks\n"
            "*** SHOW DOWN ***\n"
            "Hero: shows [Ah Kh Qd Jc] (two pair, Aces and Kings)\n"
            "Player1: mucks hand\n"
            "Hero collected $3.20 from pot"
        )

        result = self.parser._parse_pokerstars_hand(hand_text)

        self.assertIsNotNone(result)
        self.assertTrue(result.showdown_reached)
        self.assertEqual(result.board_cards, ["As", "Ks", "Qh", "9h", "2c"])

    def test_parse_pokerstars_hand_with_various_actions(self):
        """Test parsing PokerStars hand with various action types."""
        hand_text = (
            "PokerStars Hand #123456789: Tournament #987654321, $10+$1 USD "
            "Hold'em Pot Limit Omaha - Level I (10/20) - 2023/01/01 10:00:00 ET\n"
            "Table '987654321 1' 6-max Seat #1 is the button\n"
            "Seat 1: Player1 ($100.00 in chips)\n"
            "Seat 2: Hero ($200.00 in chips)\n"
            "Seat 3: Player3 ($150.00 in chips)\n"
            "Player1: posts small blind $0.10\n"
            "Hero: posts big blind $0.20\n"
            "*** HOLE CARDS ***\n"
            "Dealt to Hero [Ah Kh Qd Jc]\n"
            "Player3: raises $0.60 to $0.80\n"
            "Player1: folds\n"
            "Hero: calls $0.60\n"
            "*** FLOP *** [As Ks Qh]\n"
            "Hero: checks\n"
            "Player3: bets $1.50\n"
            "Hero: raises $4.50 to $6.00\n"
            "Player3: calls $4.50\n"
            "*** TURN *** [As Ks Qh 9h]\n"
            "Hero: bets $15.00\n"
            "Player3: calls $15.00 and is all-in\n"
            "*** RIVER *** [As Ks Qh 9h 2c]\n"
            "*** SHOW DOWN ***\n"
            "Hero: shows [Ah Kh Qd Jc] (two pair, Aces and Kings)\n"
            "Player3: mucks hand\n"
            "Hero collected $300.10 from pot"
        )

        result = self.parser._parse_pokerstars_hand(hand_text)

        self.assertIsNotNone(result)
        self.assertEqual(len(result.players), 3)
        self.assertGreater(len(result.actions), 0)

    def test_parse_ggpoker_not_implemented(self):
        """Test parsing GGPoker hand history."""
        content = "GGPoker Hand #123456789"
        parser = HandHistoryParser()
        hands, errors = parser.parse_file(content, "test.txt")
        # GGPoker parsing is implemented as fallback to PokerStars, so no errors expected
        self.assertEqual(len(errors), 0)

    def test_calculate_file_hash(self):
        """Test file hash calculation."""
        content = "Test content for hashing"
        hash1 = calculate_file_hash(content)
        hash2 = calculate_file_hash(content)

        self.assertEqual(hash1, hash2)
        self.assertEqual(len(hash1), 64)  # SHA-256 produces 64 character hex string

        # Different content should produce different hash
        hash3 = calculate_file_hash("Different content")
        self.assertNotEqual(hash1, hash3)

    def test_is_plo_hand_positive_cases(self):
        """Test is_plo_hand with various PLO game types."""
        self.assertTrue(is_plo_hand("Pot Limit Omaha"))
        self.assertTrue(is_plo_hand("PLO"))
        self.assertTrue(is_plo_hand("PLO8"))
        self.assertTrue(is_plo_hand("Pot Limit Omaha Hi/Lo"))

    def test_is_plo_hand_negative_cases(self):
        """Test is_plo_hand with non-PLO formats."""
        self.assertFalse(is_plo_hand("Hold'em"))
        self.assertFalse(is_plo_hand("Texas Hold'em"))
        self.assertFalse(is_plo_hand("Stud"))
        self.assertFalse(is_plo_hand("Draw"))
        self.assertFalse(is_plo_hand("Unknown"))
        self.assertFalse(is_plo_hand(""))


class TestDataClasses(unittest.TestCase):
    """Test the dataclasses used by the parser."""

    def test_player_info_creation(self):
        """Test PlayerInfo dataclass creation."""
        player = PlayerInfo("TestPlayer", 1, 100.0, True)

        self.assertEqual(player.name, "TestPlayer")
        self.assertEqual(player.seat, 1)
        self.assertEqual(player.stack, 100.0)
        self.assertTrue(player.is_hero)

    def test_player_info_default_hero(self):
        """Test PlayerInfo default is_hero value."""
        player = PlayerInfo("TestPlayer", 1, 100.0)

        self.assertFalse(player.is_hero)

    def test_action_creation(self):
        """Test Action dataclass creation."""
        action = Action("TestPlayer", "bet", 50.0, "flop")

        self.assertEqual(action.player, "TestPlayer")
        self.assertEqual(action.action_type, "bet")
        self.assertEqual(action.amount, 50.0)
        self.assertEqual(action.street, "flop")

    def test_parsed_hand_data_creation(self):
        """Test ParsedHandData dataclass creation."""
        players = [PlayerInfo("Player1", 1, 100.0)]
        actions = [Action("Player1", "bet", 50.0, "flop")]

        hand_data = ParsedHandData(
            hand_id="123456",
            datetime=datetime(2023, 1, 1, 10, 0, 0),
            table_name="Test Table",
            game_type="PLO",
            stakes="$1/$2",
            max_players=6,
            players=players,
            hero_cards=["Ah", "Kh", "Qd", "Jc"],
            board_cards=["As", "Ks", "Qh"],
            actions=actions,
            pot_size=100.0,
            hero_result=50.0,
            showdown_reached=True,
            raw_text="Raw hand text",
        )

        self.assertEqual(hand_data.hand_id, "123456")
        self.assertEqual(hand_data.table_name, "Test Table")
        self.assertEqual(hand_data.game_type, "PLO")
        self.assertEqual(hand_data.stakes, "$1/$2")
        self.assertEqual(hand_data.max_players, 6)
        self.assertEqual(len(hand_data.players), 1)
        self.assertEqual(len(hand_data.actions), 1)
        self.assertEqual(hand_data.pot_size, 100.0)
        self.assertTrue(hand_data.showdown_reached)


if __name__ == "__main__":
    unittest.main()
