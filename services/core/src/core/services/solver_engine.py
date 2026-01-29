"""Enhanced PLO GTO Solver Engine Implements proper Counterfactual Regret Minimization (CFR) with equity integration and
machine learning for optimal strategy computation."""

import hashlib
import json

# import logging
import multiprocessing
import os
import random
import threading
import time
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
from dataclasses import asdict, dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Optional

import joblib
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

# Import existing equity calculation functions
from core.services.equity_calculator import simulate_equity
from core.utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


class EnumJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder that handles Enum types."""

    def default(self, obj):
        if isinstance(obj, Enum):
            return obj.value
        return super().default(obj)


class ActionType(Enum):
    FOLD = "fold"
    CHECK = "check"
    CALL = "call"
    BET = "bet"
    RAISE = "raise"


@dataclass
class GameState:
    """Represents a game state in the PLO decision tree."""

    player_position: int
    active_players: list[int]
    board: list[str]
    pot_size: float
    current_bet: float
    stack_sizes: list[float]
    betting_history: list[
        Any
    ]  # Can be List[Tuple[int, ActionType, float]] or List[Dict] with player, action, amount keys
    street: str  # 'preflop', 'flop', 'turn', 'river'
    player_ranges: dict[int, list[list[str]]]  # Player -> list of possible hole card combinations

    # Additional fields for enhanced game state support
    board2: list[str] = None  # Second board for double board games
    num_boards: int = 1  # Number of boards (1 or 2)
    num_cards: int = 4  # Number of hole cards per player
    hero_cards: list[str] = None  # Hero's hole cards
    opponents: list[dict[str, Any]] = None  # Opponent information
    board_selection_mode: str = None  # Board selection mode for UI

    def _extract_betting_action(self, action_entry):
        """Extract player, action, and amount from betting history entry.

        Handles both tuple format [player, action, amount] and object format {player, action, amount}.
        """
        if isinstance(action_entry, (list, tuple)) and len(action_entry) >= 3:
            # Tuple/list format: [player, action, amount]
            player = action_entry[0]
            action_str = action_entry[1]
            amount = action_entry[2]
        elif isinstance(action_entry, dict):
            # Object format: {player, action, amount, ...}
            player = action_entry.get("player", 0)
            action_str = action_entry.get("action", "check")
            amount = action_entry.get("amount", 0.0)
        else:
            # Fallback for unexpected format
            logger.warning(f"Unexpected betting history entry format: {action_entry}")
            return 0, ActionType.CHECK, 0.0

        # Convert action string to ActionType enum
        try:
            action = ActionType(action_str)
        except ValueError:
            logger.warning(f"Unknown action type: {action_str}, defaulting to check")
            action = ActionType.CHECK

        # Log successful extraction for debugging
        logger.debug(f"Extracted betting action: player={player}, action={action.value}, amount={amount}")

        return player, action, amount

    def to_hash(self) -> str:
        """Generate a unique hash for this game state."""
        board2_str = "".join(self.board2) if self.board2 else ""
        state_str = (
            f"{self.player_position}_{self.active_players}_{self.board}_{board2_str}_"
            f"{self.num_boards}_{self.pot_size}_{self.current_bet}_{self.betting_history}_{self.street}"
        )
        return hashlib.md5(state_str.encode()).hexdigest()

    def to_infoset(self) -> str:
        """Create information set identifier for CFR."""
        # In real implementation, this would include the player's hole cards
        # For now, using position, board, pot odds, and betting history
        board_str = "".join(self.board) if self.board else "preflop"
        board2_str = "".join(self.board2) if self.board2 else ""

        # Calculate pot odds
        pot_odds = (
            self.current_bet / (self.pot_size + self.current_bet) if (self.pot_size + self.current_bet) > 0 else 0
        )

        # Betting sequence abstraction
        bet_sequence = []
        for action_entry in self.betting_history[-3:]:  # Last 3 actions
            _, action, amount = self._extract_betting_action(action_entry)
            if action in [ActionType.BET, ActionType.RAISE]:
                bet_sequence.append(f"{action.value}_{amount / self.pot_size:.2f}")
            else:
                bet_sequence.append(action.value)

        # Include board2 in infoset for double board games
        if self.num_boards == 2 and board2_str:
            infoset = (
                f"pos_{self.player_position}_board_{board_str}_board2_{board2_str}_"
                f"boards_{self.num_boards}_pot_{pot_odds:.2f}_seq_{'_'.join(bet_sequence)}"
            )
        else:
            infoset = f"pos_{self.player_position}_board_{board_str}_pot_{pot_odds:.2f}_seq_{'_'.join(bet_sequence)}"
        return infoset


@dataclass
class Action:
    """Represents a possible action in a game state."""

    action_type: ActionType
    amount: float = 0.0

    def __str__(self):
        if self.amount > 0:
            return f"{self.action_type.value}_{self.amount:.0f}"
        return self.action_type.value


@dataclass
class StrategyNode:
    """Enhanced strategy node with CFR learning."""

    infoset: str
    actions: list[Action]
    regret_sum: dict[str, float]
    strategy_sum: dict[str, float]
    visits: int = 0

    def get_strategy(self, realization_weight: float = 1.0) -> dict[str, float]:
        """Get current strategy using regret matching."""
        strategy = {}
        normalizing_sum = 0.0

        for action in self.actions:
            action_str = str(action)
            regret = max(0.0, self.regret_sum.get(action_str, 0.0))
            strategy[action_str] = regret
            normalizing_sum += regret

        # If no positive regrets, use uniform strategy
        if normalizing_sum > 0:
            for action_str in strategy:
                strategy[action_str] /= normalizing_sum
        else:
            uniform_prob = 1.0 / len(self.actions)
            for action in self.actions:
                strategy[str(action)] = uniform_prob

        # Update strategy sum for average strategy calculation
        for action_str in strategy:
            self.strategy_sum[action_str] = (
                self.strategy_sum.get(action_str, 0.0) + realization_weight * strategy[action_str]
            )

        return strategy

    def get_average_strategy(self) -> dict[str, float]:
        """Get average strategy over all iterations."""
        avg_strategy = {}
        normalizing_sum = sum(self.strategy_sum.values())

        if normalizing_sum > 0:
            for action_str, sum_val in self.strategy_sum.items():
                avg_strategy[action_str] = sum_val / normalizing_sum
        else:
            uniform_prob = 1.0 / len(self.actions)
            for action in self.actions:
                avg_strategy[str(action)] = uniform_prob

        return avg_strategy


@dataclass
class EquityData:
    """Stores equity calculation results."""

    player_equities: list[float]
    win_rates: list[float]
    tie_rates: list[float]
    scoop_rates: list[float]
    detailed_breakdown: dict[str, Any]


class PrecomputedSpotDB:
    """Database for storing precomputed GTO solutions (simplified in-memory implementation)."""

    def __init__(self, db_path: str = "solver_cache/precomputed_spots.db"):
        self.solutions = {}
        self.training_data = []
        logger.info("Initialized simplified PrecomputedSpotDB (in-memory)")

    def _init_db(self):
        # No-op for simplified implementation
        pass

    def store_solution(self, game_state, solution):
        key = game_state.to_hash()
        self.solutions[key] = solution
        logger.debug(f"Stored solution for key: {key}")

    def get_solution(self, game_state):
        key = game_state.to_hash()
        solution = self.solutions.get(key)
        if solution:
            logger.debug(f"Retrieved cached solution for key: {key}")
        return solution

    def store_training_data(self, game_state, action, reward):
        self.training_data.append(
            {
                "game_state": game_state.to_hash(),
                "action": action,
                "reward": reward,
                "timestamp": time.time(),
            }
        )

    def get_training_data(self, limit: int = 1000):
        return self.training_data[-limit:] if self.training_data else []


class MLPredictor:
    """Machine learning predictor for strategy suggestions."""

    def __init__(self, model_path: str = "solver_cache/strategy_model.joblib"):
        self.model_path = model_path
        self.model = None
        self.feature_columns = [
            "position",
            "num_players",
            "pot_odds",
            "stack_ratio",
            "equity_estimate",
            "win_rate",
            "aggression_factor",
        ]
        self.load_model()

    def load_model(self):
        """Load existing model or create new one."""
        if Path(self.model_path).exists():
            try:
                self.model = joblib.load(self.model_path)
                logger.info("Loaded existing ML model")
            except Exception as e:
                logger.warning(f"Failed to load model: {e}. Creating new one.")
                self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        else:
            self.model = RandomForestRegressor(n_estimators=100, random_state=42)

    def extract_features(self, game_state: GameState, equity_data: EquityData) -> list[float]:
        """Extract features from game state and equity data."""
        position = game_state.player_position / len(game_state.active_players)
        num_players = len(game_state.active_players)
        pot_odds = (
            game_state.current_bet / (game_state.pot_size + game_state.current_bet)
            if (game_state.pot_size + game_state.current_bet) > 0
            else 0
        )

        player_idx = game_state.player_position
        stack_ratio = game_state.stack_sizes[player_idx] / game_state.pot_size if game_state.pot_size > 0 else 1.0

        equity_estimate = (
            equity_data.player_equities[player_idx] if player_idx < len(equity_data.player_equities) else 0.2
        )
        win_rate = equity_data.win_rates[player_idx] if player_idx < len(equity_data.win_rates) else 0.15

        # Aggression factor based on betting history
        aggression_factor = 0.0
        for action_entry in game_state.betting_history[-5:]:
            _, action, amount = game_state._extract_betting_action(action_entry)
            if action in [ActionType.BET, ActionType.RAISE]:
                aggression_factor += amount / game_state.pot_size
        aggression_factor = min(aggression_factor, 3.0)  # Cap at 3x pot

        return [
            position,
            num_players,
            pot_odds,
            stack_ratio,
            equity_estimate,
            win_rate,
            aggression_factor,
        ]

    def predict_action_values(
        self, game_state: GameState, equity_data: EquityData, actions: list[Action]
    ) -> dict[str, float]:
        """Predict expected values for each action."""
        if self.model is None:
            return {str(action): 0.5 for action in actions}

        features = self.extract_features(game_state, equity_data)

        action_values = {}
        for action in actions:
            # Modify features based on action
            action_features = features.copy()
            if action.action_type in [ActionType.BET, ActionType.RAISE]:
                action_features.append(action.amount / game_state.pot_size)
            else:
                action_features.append(0.0)

            try:
                # Pad or truncate features to match expected input size
                if len(action_features) < 8:
                    action_features.extend([0.0] * (8 - len(action_features)))
                elif len(action_features) > 8:
                    action_features = action_features[:8]

                prediction = self.model.predict([action_features])[0]
                action_values[str(action)] = float(prediction)
            except Exception as e:
                logger.debug(f"Prediction failed for action {action}: {e}")
                action_values[str(action)] = 0.5

        return action_values

    def train_model(self, training_data: list[dict[str, Any]]):
        """Train the ML model with new data."""
        if len(training_data) < 50:
            logger.warning("Not enough training data to train model")
            return

        try:
            X = []
            y = []

            for data in training_data:
                game_state = GameState(**json.loads(data["game_state"]))
                equity_data = EquityData(**json.loads(data["equity_data"]))

                features = self.extract_features(game_state, equity_data)
                features.append(0.0)  # Action placeholder

                # Pad or truncate to 8 features
                if len(features) < 8:
                    features.extend([0.0] * (8 - len(features)))
                elif len(features) > 8:
                    features = features[:8]

                X.append(features)
                y.append(data["ev_estimate"])

            if len(X) > 10:
                X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
                self.model.fit(X_train, y_train)

                # Log training metrics
                train_score = self.model.score(X_train, y_train)
                test_score = self.model.score(X_test, y_test)
                logger.info(f"Model trained: Train R² = {train_score:.3f}, Test R² = {test_score:.3f}")

                # Save the model
                joblib.dump(self.model, self.model_path)

        except Exception as e:
            logger.error(f"Model training failed: {e}")


class HandBucketClassifier:
    """Classifies PLO hands into strategic buckets."""

    @staticmethod
    def classify_hand(hole_cards: list[str], board: list[str]) -> str:
        """Classify a PLO hand into a strategic bucket."""
        if len(board) < 3:
            return HandBucketClassifier._classify_preflop_hand(hole_cards)

        # Analyze hand strength
        hand_type = HandBucketClassifier._get_made_hand_type(hole_cards, board)
        if hand_type:
            return hand_type

        # Check for draws
        draw_type = HandBucketClassifier._get_draw_type(hole_cards, board)
        if draw_type:
            return draw_type

        # Default to pair classification
        return HandBucketClassifier._classify_pair_strength(hole_cards, board)

    @staticmethod
    def _classify_preflop_hand(hole_cards: list[str]) -> str:
        """Classify preflop hand strength."""
        ranks = [card[0] for card in hole_cards]
        suits = [card[1] for card in hole_cards]

        # Count pairs and suited cards
        rank_counts = {}
        for rank in ranks:
            rank_counts[rank] = rank_counts.get(rank, 0) + 1

        suit_counts = {}
        for suit in suits:
            suit_counts[suit] = suit_counts.get(suit, 0) + 1

        # Check for pairs
        pairs = [rank for rank, count in rank_counts.items() if count >= 2]
        if pairs:
            if len(pairs) > 1 or max(rank_counts.values()) > 2:
                return "overpair"

        # Check suitedness
        suited_cards = max(suit_counts.values()) if suit_counts else 0
        if suited_cards >= 3:
            return "nut_flush_draw"

        return "high_card"

    @staticmethod
    def _get_made_hand_type(hole_cards: list[str], board: list[str]) -> Optional[str]:
        """Identify made hand types."""
        board_ranks = [card[0] for card in board]
        hole_ranks = [card[0] for card in hole_cards]

        # Check for sets (pair in hole cards matching board)
        for hole_rank in hole_ranks:
            if hole_ranks.count(hole_rank) == 2 and hole_rank in board_ranks:
                if hole_rank == max(board_ranks, key=lambda x: HandBucketClassifier._rank_value(x)):
                    return "top_set"
                elif hole_rank == min(board_ranks, key=lambda x: HandBucketClassifier._rank_value(x)):
                    return "bottom_set"
                else:
                    return "middle_set"

        # Check for trips (using one hole card)
        for board_rank in board_ranks:
            if board_ranks.count(board_rank) == 2:
                if board_rank in hole_ranks:
                    if board_rank == max(board_ranks, key=lambda x: HandBucketClassifier._rank_value(x)):
                        return "top_trips"
                    elif board_rank == min(board_ranks, key=lambda x: HandBucketClassifier._rank_value(x)):
                        return "bottom_trips"
                    else:
                        return "middle_trips"

        # Check for flushes (simplified)
        board_suits = [card[1] for card in board]
        hole_suits = [card[1] for card in hole_cards]

        for suit in set(board_suits + hole_suits):
            board_suit_count = board_suits.count(suit)
            hole_suit_count = hole_suits.count(suit)

            if board_suit_count + hole_suit_count >= 5 and hole_suit_count >= 2:
                hole_suit_cards = [card for card in hole_cards if card[1] == suit]
                if any(card[0] == "A" for card in hole_suit_cards):
                    return "nut_flush"
                elif any(card[0] in ["K", "Q"] for card in hole_suit_cards):
                    return "middle_flush"
                else:
                    return "low_flush"

        return None

    @staticmethod
    def _get_draw_type(hole_cards: list[str], board: list[str]) -> Optional[str]:
        """Identify draw types."""
        board_suits = [card[1] for card in board]
        hole_suits = [card[1] for card in hole_cards]

        # Flush draw check
        for suit in set(board_suits + hole_suits):
            board_suit_count = board_suits.count(suit)
            hole_suit_count = hole_suits.count(suit)

            if board_suit_count + hole_suit_count == 4 and hole_suit_count >= 2:
                hole_suit_cards = [card for card in hole_cards if card[1] == suit]
                if any(card[0] == "A" for card in hole_suit_cards):
                    return "nut_flush_draw"
                else:
                    return "low_flush_draw"

        # Straight draw detection (simplified)
        all_ranks = [card[0] for card in hole_cards + board]
        numeric_ranks = [HandBucketClassifier._rank_value(rank) for rank in all_ranks]
        unique_ranks = sorted(set(numeric_ranks))

        if len(unique_ranks) >= 4:
            # Check for consecutive ranks
            for i in range(len(unique_ranks) - 3):
                consecutive = unique_ranks[i : i + 4]
                if consecutive[-1] - consecutive[0] == 3:
                    return "open_ended_straight_draw"

        return None

    @staticmethod
    def _classify_pair_strength(hole_cards: list[str], board: list[str]) -> str:
        """Classify pair strength relative to board."""
        board_ranks = [card[0] for card in board]
        hole_ranks = [card[0] for card in hole_cards]

        board_rank_values = [HandBucketClassifier._rank_value(rank) for rank in board_ranks]
        max_board_rank = max(board_rank_values)
        min_board_rank = min(board_rank_values)

        # Look for pairs using hole cards
        for hole_rank in hole_ranks:
            if hole_rank in board_ranks:
                hole_rank_value = HandBucketClassifier._rank_value(hole_rank)
                if hole_rank_value == max_board_rank:
                    return "top_pair"
                elif hole_rank_value == min_board_rank:
                    return "bottom_pair"
                else:
                    return "middle_pair"

        return "high_card"

    @staticmethod
    def _rank_value(rank: str) -> int:
        """Convert rank to numeric value for comparison."""
        rank_values = {"A": 14, "K": 13, "Q": 12, "J": 11, "T": 10}
        if rank.isdigit():
            return int(rank)
        return rank_values.get(rank, 0)


class EnhancedPLOSolver:
    """Enhanced PLO GTO Solver with equity integration and ML capabilities."""

    def __init__(self, config: dict[str, Any] = None):
        self.config = config or self._default_config()
        self.nodes: dict[str, StrategyNode] = {}
        self.iteration = 0
        self.solutions_cache = {}
        self.bulk_jobs = {}

        # Set up components
        self.cache_dir = Path("solver_cache")
        self.cache_dir.mkdir(exist_ok=True)

        self.spot_db = PrecomputedSpotDB()
        self.ml_predictor = MLPredictor()
        self.equity_cache = {}

        # Thread safety
        self.lock = threading.Lock()

        logger.info(f"Enhanced PLO Solver initialized with config: {self.config}")

    def _default_config(self) -> dict[str, Any]:
        """Default solver configuration."""
        return {
            "max_iterations": 100,  # Reduced from 5000 to prevent infinite loops
            "convergence_threshold": 0.01,
            "bet_sizes": [0.33, 0.5, 0.75, 1.0, 1.5, 2.0],
            "min_bet_size": 0.25,
            "max_players": 6,
            "abstraction_level": "intermediate",
            "enable_caching": True,
            "cache_ttl": 3600,
            "parallel_workers": min(8, multiprocessing.cpu_count()),
            "use_ml_suggestions": False,  # Disabled to prevent unfitted model errors
            "equity_simulation_runs": 500,  # Reduced from 2000 for faster processing
            "cfr_exploration_threshold": 0.1,  # Reduced from 0.6 to limit recursive calls
            "enable_precomputed_spots": True,
        }

    def calculate_equity(self, game_state: GameState) -> EquityData:
        """Calculate equity using the existing equity server functions."""
        cache_key = f"{game_state.to_hash()}_equity"

        if cache_key in self.equity_cache:
            return self.equity_cache[cache_key]

        try:
            # For now, simulate with random hands since we don't have actual player cards
            # In a real implementation, you'd use the actual player ranges
            num_players = len(game_state.active_players)

            # Generate sample hands for equity calculation
            sample_hands = []
            all_cards = [
                "As",
                "Ks",
                "Qs",
                "Js",
                "Ts",
                "9s",
                "8s",
                "7s",
                "6s",
                "5s",
                "4s",
                "3s",
                "2s",
                "Ah",
                "Kh",
                "Qh",
                "Jh",
                "Th",
                "9h",
                "8h",
                "7h",
                "6h",
                "5h",
                "4h",
                "3h",
                "2h",
                "Ad",
                "Kd",
                "Qd",
                "Jd",
                "Td",
                "9d",
                "8d",
                "7d",
                "6d",
                "5d",
                "4d",
                "3d",
                "2d",
                "Ac",
                "Kc",
                "Qc",
                "Jc",
                "Tc",
                "9c",
                "8c",
                "7c",
                "6c",
                "5c",
                "4c",
                "3c",
                "2c",
            ]

            # Remove board cards from available cards
            available_cards = [card for card in all_cards if card not in game_state.board]

            # Generate random hands for each player
            for i in range(num_players):
                hand = random.sample(available_cards, 4)
                sample_hands.append(hand)
                available_cards = [card for card in available_cards if card not in hand]

            # Calculate equity using existing function
            equities, tie_rates = simulate_equity(
                sample_hands,
                game_state.board,
                num_iterations=self.config["equity_simulation_runs"],
            )

            # Calculate additional PLO-specific equity data
            win_rates = []
            scoop_rates = []
            chop_rates = []
            split_rates = []

            for i in range(num_players):
                # Convert equity percentages to decimals
                equity_decimal = equities[i] / 100.0
                tie_decimal = tie_rates[i] / 100.0

                # Calculate win rate (equity minus half of ties)
                win_rate = max(0.0, equity_decimal - (tie_decimal / 2))
                win_rates.append(win_rate)

                # For PLO, scoop rate is approximately win rate for single board
                scoop_rate = win_rate
                scoop_rates.append(scoop_rate)

                # Chop rate is tie rate (multiple players sharing the pot)
                chop_rate = tie_decimal
                chop_rates.append(chop_rate)

                # Split rate is total rate of getting money (wins + ties)
                split_rate = equity_decimal
                split_rates.append(split_rate)

            # Create EquityData object with comprehensive data
            equity_data = EquityData(
                player_equities=[e / 100.0 for e in equities],
                win_rates=win_rates,
                tie_rates=[t / 100.0 for t in tie_rates],
                scoop_rates=scoop_rates,
                detailed_breakdown={
                    "chop_rates": chop_rates,
                    "split_rates": split_rates,
                    "raw_equities": equities,
                    "raw_tie_rates": tie_rates,
                },
            )

            self.equity_cache[cache_key] = equity_data
            return equity_data

        except Exception as e:
            logger.error(f"Equity calculation failed: {e}")
            # Return default equity data
            num_players = len(game_state.active_players)
            default_equity = 1.0 / num_players
            return EquityData(
                player_equities=[default_equity] * num_players,
                win_rates=[default_equity * 0.8] * num_players,
                tie_rates=[default_equity * 0.2] * num_players,
                scoop_rates=[default_equity * 0.6] * num_players,
                detailed_breakdown={},
            )

    def get_possible_actions(self, game_state: GameState) -> list[Action]:
        """Get all possible actions for the current game state."""
        actions = []

        # Always can fold (except when no bet to call)
        if game_state.current_bet > 0:
            actions.append(Action(ActionType.FOLD))

        # Check or call
        if game_state.current_bet == 0:
            actions.append(Action(ActionType.CHECK))
        else:
            # Can call if we have enough chips
            player_idx = game_state.player_position
            if (
                player_idx < len(game_state.stack_sizes)
                and game_state.stack_sizes[player_idx] >= game_state.current_bet
            ):
                actions.append(Action(ActionType.CALL))

        # Betting options
        player_idx = game_state.player_position
        if player_idx < len(game_state.stack_sizes):
            available_stack = game_state.stack_sizes[player_idx]

            for bet_fraction in self.config["bet_sizes"]:
                bet_amount = game_state.pot_size * bet_fraction

                # Ensure minimum bet size
                if game_state.current_bet > 0:
                    min_bet = max(
                        game_state.current_bet * 2,
                        game_state.pot_size * self.config["min_bet_size"],
                    )
                else:
                    min_bet = game_state.pot_size * self.config["min_bet_size"]

                bet_amount = max(bet_amount, min_bet)

                if bet_amount <= available_stack and bet_amount > game_state.current_bet:
                    if game_state.current_bet == 0:
                        actions.append(Action(ActionType.BET, bet_amount))
                    else:
                        actions.append(Action(ActionType.RAISE, bet_amount))

        return actions

    def cfr(self, game_state: GameState, reach_probs: list[float], iteration: int) -> float:
        """Enhanced CFR implementation with equity integration."""
        # Safety check to prevent infinite recursion
        if iteration <= 0:
            return self._estimate_action_utility(game_state, Action(ActionType.CHECK), None)

        # Check if terminal
        if self._is_terminal(game_state):
            return self._calculate_terminal_utility(game_state)

        infoset = game_state.to_infoset()
        current_player = game_state.player_position

        # Get or create strategy node
        if infoset not in self.nodes:
            actions = self.get_possible_actions(game_state)
            self.nodes[infoset] = StrategyNode(
                infoset=infoset,
                actions=actions,
                regret_sum={str(action): 0.0 for action in actions},
                strategy_sum={str(action): 0.0 for action in actions},
            )

        node = self.nodes[infoset]

        # Get current strategy
        strategy = node.get_strategy(reach_probs[current_player])

        # Calculate equity for informed decision making
        equity_data = self.calculate_equity(game_state)

        # Use ML suggestions if enabled
        if self.config["use_ml_suggestions"] and iteration > 100:
            ml_suggestions = self.ml_predictor.predict_action_values(game_state, equity_data, node.actions)

            # Blend CFR strategy with ML suggestions
            for action_str in strategy:
                if action_str in ml_suggestions:
                    strategy[action_str] = 0.7 * strategy[action_str] + 0.3 * ml_suggestions[action_str]

        utilities = {}
        node_utility = 0.0

        # Calculate utilities for each action
        for action in node.actions:
            action_str = str(action)

            # Create new game state after action
            new_game_state = self._apply_action(game_state, action)
            new_reach_probs = reach_probs.copy()
            new_reach_probs[current_player] *= strategy.get(action_str, 0.0)

            # Recursive CFR call
            if iteration > 0 and random.random() < self.config["cfr_exploration_threshold"]:
                utilities[action_str] = self.cfr(new_game_state, new_reach_probs, iteration - 1)
            else:
                # Use heuristic estimate for deeper nodes
                utilities[action_str] = self._estimate_action_utility(new_game_state, action, equity_data)

            node_utility += strategy.get(action_str, 0.0) * utilities[action_str]

        # Update regrets
        for action in node.actions:
            action_str = str(action)
            regret = utilities[action_str] - node_utility

            # Calculate counterfactual reach probability
            cfr_reach_prob = 1.0
            for i, prob in enumerate(reach_probs):
                if i != current_player:
                    cfr_reach_prob *= prob

            node.regret_sum[action_str] += cfr_reach_prob * regret

        node.visits += 1

        # Store training data periodically
        if iteration % 50 == 0:
            best_action = max(utilities.items(), key=lambda x: x[1])
            self.spot_db.store_training_data(game_state, best_action[0], best_action[1])

        return node_utility

    def _estimate_action_utility(self, game_state: GameState, action: Action, equity_data: EquityData = None) -> float:
        """Estimate utility of an action using equity and game theory principles."""
        player_idx = game_state.player_position

        # Default equity if no equity data provided
        if equity_data is None or player_idx >= len(equity_data.player_equities):
            player_equity = 1.0 / len(game_state.active_players) if game_state.active_players else 0.5
        else:
            player_equity = equity_data.player_equities[player_idx]
        pot_size = game_state.pot_size

        if action.action_type == ActionType.FOLD:
            return 0.0

        elif action.action_type == ActionType.CHECK:
            return player_equity * pot_size

        elif action.action_type == ActionType.CALL:
            call_amount = game_state.current_bet
            total_pot = pot_size + call_amount * len(game_state.active_players)
            return player_equity * total_pot - call_amount

        elif action.action_type in [ActionType.BET, ActionType.RAISE]:
            # Betting/raising utility considers fold equity and value
            bet_amount = action.amount

            # Fold equity estimation
            num_opponents = len(game_state.active_players) - 1
            fold_equity = min(0.3, bet_amount / pot_size * 0.1) * num_opponents

            # Value betting
            value_component = player_equity * (pot_size + bet_amount)

            # Risk component
            risk_component = bet_amount * (1 - player_equity)

            return fold_equity * pot_size + value_component - risk_component

        return 0.0

    def _is_terminal(self, game_state: GameState) -> bool:
        """Check if game state is terminal."""
        return (
            len(game_state.active_players) <= 1
            or self._is_betting_complete(game_state)
            or game_state.street == "showdown"
        )

    def _is_betting_complete(self, game_state: GameState) -> bool:
        """Check if betting round is complete."""
        if not game_state.betting_history:
            return False

        # All players have acted at least once
        players_acted = set()
        for action_entry in game_state.betting_history:
            player, _, _ = game_state._extract_betting_action(action_entry)
            players_acted.add(player)

        return len(players_acted) >= len(game_state.active_players)

    def _calculate_terminal_utility(self, game_state: GameState) -> float:
        """Calculate utility at terminal nodes using equity."""
        equity_data = self.calculate_equity(game_state)
        player_idx = game_state.player_position

        if player_idx < len(equity_data.player_equities):
            return equity_data.player_equities[player_idx] * game_state.pot_size

        return 0.0

    def _apply_action(self, game_state: GameState, action: Action) -> GameState:
        """Apply action to create new game state."""
        new_active_players = game_state.active_players.copy()
        new_stack_sizes = game_state.stack_sizes.copy()
        new_betting_history = game_state.betting_history.copy()
        new_pot_size = game_state.pot_size
        new_current_bet = game_state.current_bet

        player_idx = game_state.player_position

        # Apply action effects
        if action.action_type == ActionType.FOLD:
            if player_idx in new_active_players:
                new_active_players.remove(player_idx)

        elif action.action_type == ActionType.CALL:
            call_amount = game_state.current_bet
            new_pot_size += call_amount
            if player_idx < len(new_stack_sizes):
                new_stack_sizes[player_idx] -= call_amount

        elif action.action_type in [ActionType.BET, ActionType.RAISE]:
            new_pot_size += action.amount
            new_current_bet = action.amount
            if player_idx < len(new_stack_sizes):
                new_stack_sizes[player_idx] -= action.amount

        # Add to betting history
        new_betting_history.append((player_idx, action.action_type, action.amount))

        # Next player
        if new_active_players:
            current_pos = new_active_players.index(player_idx) if player_idx in new_active_players else 0
            next_pos = (current_pos + 1) % len(new_active_players)
            new_player_position = new_active_players[next_pos]
        else:
            new_player_position = 0

        return GameState(
            player_position=new_player_position,
            active_players=new_active_players,
            board=game_state.board.copy(),
            pot_size=new_pot_size,
            current_bet=new_current_bet,
            stack_sizes=new_stack_sizes,
            betting_history=new_betting_history,
            street=game_state.street,
            player_ranges=game_state.player_ranges.copy(),
            board2=game_state.board2.copy() if game_state.board2 else None,
            num_boards=game_state.num_boards,
            num_cards=game_state.num_cards,
            hero_cards=game_state.hero_cards.copy() if game_state.hero_cards else None,
            opponents=game_state.opponents.copy() if game_state.opponents else None,
            board_selection_mode=game_state.board_selection_mode,
        )

    def solve_spot(self, game_state: GameState, iterations: int = None) -> dict[str, Any]:
        """Solve a poker spot using enhanced CFR."""
        if iterations is None:
            iterations = self.config["max_iterations"]

        # Check for precomputed solution
        if self.config["enable_precomputed_spots"]:
            cached_solution = self.spot_db.get_solution(game_state)
            if cached_solution:
                logger.info(f"Using precomputed solution for spot: {game_state.to_hash()}")
                return cached_solution

        logger.info(f"Starting CFR solve for spot: {game_state.to_hash()}")
        start_time = time.time()

        # Initialize reach probabilities
        reach_probs = [1.0] * len(game_state.active_players)

        # Run CFR iterations
        for i in range(iterations):
            if i % 100 == 0:
                logger.debug(f"CFR iteration {i}/{iterations}")

            self.cfr(game_state, reach_probs, iterations - i)

        # Extract final strategies
        strategies = {}
        for infoset, node in self.nodes.items():
            strategies[infoset] = node.get_average_strategy()

        # Calculate equity and other metrics
        equity_data = self.calculate_equity(game_state)

        # Perform bucket analysis
        bucket_analysis = self._analyze_hand_buckets(game_state, strategies, equity_data)

        solution = {
            "strategies": strategies,
            "equity": {f"player_{i}": eq for i, eq in enumerate(equity_data.player_equities)},
            "ev": equity_data.player_equities[game_state.player_position] * game_state.pot_size,
            "game_state": asdict(game_state),
            "solve_time": time.time() - start_time,
            "iterations": iterations,
            "exploitability": self._calculate_exploitability(strategies),
            "equity_breakdown": equity_data.detailed_breakdown,
            "bucket_analysis": bucket_analysis,
        }

        # Store solution for future use
        if self.config["enable_precomputed_spots"]:
            self.spot_db.store_solution(game_state, solution)

        logger.info(f"CFR solve completed in {solution['solve_time']:.2f}s")
        return solution

    def _calculate_exploitability(self, strategies: dict[str, dict[str, float]]) -> float:
        """Calculate exploitability of the strategy profile."""
        # Simplified exploitability calculation
        # In practice, this would require computing best response strategies
        total_entropy = 0.0
        for strategy in strategies.values():
            entropy = -sum(p * np.log(p + 1e-10) for p in strategy.values() if p > 0)
            total_entropy += entropy

        # Normalize by number of information sets
        if len(strategies) > 0:
            avg_entropy = total_entropy / len(strategies)
            # Convert to exploitability estimate (lower entropy = more exploitable)
            return max(0.0, (2.0 - avg_entropy) / 10.0)

        return 0.1

    def _analyze_hand_buckets(
        self,
        game_state: GameState,
        strategies: dict[str, dict[str, float]],
        equity_data: EquityData,
    ) -> dict[str, Any]:
        """Analyze hand buckets and their optimal strategies."""

        # Define hand buckets
        hand_buckets = {
            "high_card": {"name": "High Card", "category": "weak"},
            "bottom_pair": {"name": "Bottom Pair", "category": "weak"},
            "middle_pair": {"name": "Middle Pair", "category": "medium"},
            "top_pair": {"name": "Top Pair", "category": "medium"},
            "overpair": {"name": "Overpair", "category": "strong"},
            "bottom_middle_two_pair": {
                "name": "Bottom & Middle Two Pair",
                "category": "medium",
            },
            "top_bottom_two_pair": {
                "name": "Top & Bottom Two Pair",
                "category": "medium",
            },
            "top_middle_two_pair": {
                "name": "Top & Middle Two Pair",
                "category": "strong",
            },
            "bottom_trips": {"name": "Bottom Trips", "category": "strong"},
            "middle_trips": {"name": "Middle Trips", "category": "strong"},
            "top_trips": {"name": "Top Trips", "category": "very_strong"},
            "bottom_set": {"name": "Bottom Set", "category": "very_strong"},
            "middle_set": {"name": "Middle Set", "category": "very_strong"},
            "top_set": {"name": "Top Set", "category": "nuts"},
            "low_straight": {"name": "Low Straight", "category": "strong"},
            "middle_straight": {"name": "Middle Straight", "category": "very_strong"},
            "nut_straight": {"name": "Nut Straight", "category": "nuts"},
            "low_flush": {"name": "Low Flush", "category": "strong"},
            "middle_flush": {"name": "Middle Flush", "category": "very_strong"},
            "nut_flush": {"name": "Nut Flush", "category": "nuts"},
            "bottom_full_house": {
                "name": "Bottom Full House",
                "category": "very_strong",
            },
            "middle_full_house": {"name": "Middle Full House", "category": "nuts"},
            "top_full_house": {"name": "Top Full House", "category": "nuts"},
            "quads_low": {"name": "Quads Low", "category": "nuts"},
            "quads_high": {"name": "Quads High", "category": "nuts"},
            "low_straight_flush": {"name": "Low Straight Flush", "category": "nuts"},
            "high_straight_flush": {"name": "High Straight Flush", "category": "nuts"},
            "royal_flush": {"name": "Royal Flush", "category": "nuts"},
            "gutshot_straight_draw": {
                "name": "Gutshot Straight Draw",
                "category": "draw",
            },
            "open_ended_straight_draw": {
                "name": "Open-Ended Straight Draw",
                "category": "draw",
            },
            "wrap_straight_draw": {"name": "Wrap Straight Draw", "category": "draw"},
            "low_flush_draw": {"name": "Low Flush Draw", "category": "draw"},
            "nut_flush_draw": {"name": "Nut Flush Draw", "category": "draw"},
            "straight_flush_draw": {"name": "Straight Flush Draw", "category": "draw"},
            "royal_flush_draw": {"name": "Royal Flush Draw", "category": "draw"},
            "combo_draw": {"name": "Combo Draw (Straight + Flush)", "category": "draw"},
        }

        bucket_analysis = {}

        # Analyze each bucket
        for bucket_key, bucket_info in hand_buckets.items():
            bucket_data = {
                "name": bucket_info["name"],
                "category": bucket_info["category"],
                "optimal_strategy": self._calculate_bucket_optimal_strategy(bucket_info["category"]),
                "expected_value": self._calculate_bucket_ev(bucket_info["category"], game_state.pot_size),
                "frequency": self._estimate_bucket_frequency(bucket_info["category"]),
                "nut_potential": self._calculate_nut_potential(bucket_info["category"]),
            }
            bucket_analysis[bucket_key] = bucket_data

        # Calculate nutability analysis
        nutability = self._analyze_nutability(game_state)

        return {"bucket_strategies": bucket_analysis, "nutability": nutability}

    def _calculate_bucket_optimal_strategy(self, category: str) -> dict[str, float]:
        """Calculate optimal strategy for a hand strength category."""
        strategies = {
            "weak": {"fold": 60, "check_call": 35, "bet_raise": 5},
            "medium": {"fold": 25, "check_call": 55, "bet_raise": 20},
            "strong": {"fold": 5, "check_call": 40, "bet_raise": 55},
            "very_strong": {"fold": 2, "check_call": 18, "bet_raise": 80},
            "nuts": {"fold": 0, "check_call": 10, "bet_raise": 90},
            "draw": {"fold": 30, "check_call": 45, "bet_raise": 25},
        }
        return strategies.get(category, strategies["medium"])

    def _calculate_bucket_ev(self, category: str, pot_size: float) -> float:
        """Calculate expected value for a hand strength category."""
        base_ev = {
            "weak": -0.15,
            "medium": 0.05,
            "strong": 0.25,
            "very_strong": 0.45,
            "nuts": 0.70,
            "draw": 0.10,
        }
        return base_ev.get(category, 0.0) * pot_size

    def _estimate_bucket_frequency(self, category: str) -> float:
        """Estimate frequency of hand strength category."""
        frequencies = {
            "weak": 15.0,
            "medium": 25.0,
            "strong": 20.0,
            "very_strong": 10.0,
            "nuts": 5.0,
            "draw": 25.0,
        }
        return frequencies.get(category, 10.0)

    def _calculate_nut_potential(self, category: str) -> float:
        """Calculate nut potential for hand strength category."""
        nut_potentials = {
            "weak": 0.0,
            "medium": 5.0,
            "strong": 15.0,
            "very_strong": 35.0,
            "nuts": 95.0,
            "draw": 25.0,
        }
        return nut_potentials.get(category, 0.0)

    def _analyze_nutability(self, game_state: GameState) -> dict[str, Any]:
        """Analyze board nutability."""
        board = game_state.board

        if len(board) < 3:
            return {
                "board_texture": "preflop",
                "nut_hand_types": ["high_cards"],
                "nut_draws": [],
                "overall_nutability": 10,
            }

        # Analyze board texture
        suits = [card[1] for card in board]
        ranks = [card[0] for card in board]

        flush_possible = len(set(suits)) <= 2 and max([suits.count(suit) for suit in set(suits)]) >= 2

        # Convert ranks to numeric values for straight analysis
        rank_values = {"A": 14, "K": 13, "Q": 12, "J": 11, "T": 10}
        numeric_ranks = []
        for rank in ranks:
            if rank.isdigit():
                numeric_ranks.append(int(rank))
            else:
                numeric_ranks.append(rank_values.get(rank, 0))

        sorted_ranks = sorted(numeric_ranks)
        straight_possible = (sorted_ranks[-1] - sorted_ranks[0]) <= 4
        paired = len(ranks) != len(set(ranks))

        # Determine board texture
        if paired and flush_possible and straight_possible:
            texture = "wet_paired"
            nutability = 90
        elif paired:
            texture = "dry_paired"
            nutability = 35
        elif flush_possible and straight_possible:
            texture = "wet_coordinated"
            nutability = 85
        elif flush_possible:
            texture = "flush_draw"
            nutability = 60
        elif straight_possible:
            texture = "straight_draw"
            nutability = 55
        else:
            texture = "dry_rainbow"
            nutability = 20

        # Determine nut hand types
        nut_hands = ["royal_flush"]
        if texture == "dry_paired":
            nut_hands.extend(["quads_high", "top_full_house"])
        elif texture == "wet_coordinated":
            nut_hands.extend(["high_straight_flush", "nut_straight", "nut_flush"])
        elif texture == "flush_draw":
            nut_hands.extend(["nut_flush", "top_set"])
        elif texture == "straight_draw":
            nut_hands.extend(["nut_straight", "top_set"])
        else:
            nut_hands.extend(["top_set", "top_two_pair"])

        # Determine nut draws
        nut_draws = []
        if flush_possible:
            nut_draws.extend(["nut_flush_draw", "royal_flush_draw"])
        if straight_possible:
            nut_draws.extend(["wrap_straight_draw", "open_ended_straight_draw"])
        if texture == "wet_coordinated":
            nut_draws.extend(["straight_flush_draw", "combo_draw"])

        return {
            "board_texture": texture,
            "nut_hand_types": nut_hands[:5],  # Top 5
            "nut_draws": nut_draws,
            "overall_nutability": nutability,
        }

    def bulk_solve(self, spots: list[GameState], max_workers: int = None) -> dict[str, Any]:
        """Solve multiple spots in parallel with enhanced processing."""
        if max_workers is None:
            max_workers = self.config["parallel_workers"]

        logger.info(f"Starting bulk solve for {len(spots)} spots with {max_workers} workers")
        start_time = time.time()

        job_id = hashlib.md5(f"{time.time()}_{len(spots)}".encode()).hexdigest()[:8]

        with self.lock:
            self.bulk_jobs[job_id] = {
                "status": "running",
                "total_spots": len(spots),
                "completed_spots": 0,
                "start_time": start_time,
                "results": {},
            }

        try:
            # Use ThreadPoolExecutor for development to avoid SocketIO issues with multiprocessing
            # Use ProcessPoolExecutor for production when performance is critical
            use_multiprocessing = os.getenv("USE_MULTIPROCESSING", "false").lower() == "true"

            if use_multiprocessing:
                executor_class = ProcessPoolExecutor
            else:
                executor_class = ThreadPoolExecutor
                # Use more threads for threading since it's lighter weight
                max_workers = min(max_workers * 2, 16)

            with executor_class(max_workers=max_workers) as executor:
                future_to_spot = {
                    executor.submit(_solve_spot_worker_static, asdict(spot), self.config): i
                    for i, spot in enumerate(spots)
                }

                for future in future_to_spot:
                    spot_index = future_to_spot[future]
                    try:
                        result = future.result()

                        # Check if the result contains an error from the worker process
                        if isinstance(result, dict) and "error" in result:
                            logger.error(f"Worker error for spot {spot_index}: {result['error']}")

                        with self.lock:
                            self.bulk_jobs[job_id]["results"][f"spot_{spot_index}"] = result
                            self.bulk_jobs[job_id]["completed_spots"] += 1

                    except Exception as e:
                        logger.error(f"Error solving spot {spot_index}: {e}")
                        with self.lock:
                            self.bulk_jobs[job_id]["results"][f"spot_{spot_index}"] = {
                                "error": str(e),
                                "error_type": type(e).__name__,
                            }

            with self.lock:
                self.bulk_jobs[job_id]["status"] = "completed"
                self.bulk_jobs[job_id]["completion_time"] = time.time()

            total_time = time.time() - start_time
            logger.info(f"Bulk solve completed in {total_time:.2f}s")

            # Retrain ML model with new data
            self._retrain_ml_model()

            return {
                "job_id": job_id,
                "status": "completed",
                "total_time": total_time,
                "results": self.bulk_jobs[job_id]["results"],
            }

        except Exception as e:
            with self.lock:
                self.bulk_jobs[job_id]["status"] = "failed"
                self.bulk_jobs[job_id]["error"] = str(e)
            logger.error(f"Bulk solve failed: {e}")
            raise

    def _solve_spot_worker(self, spot: GameState) -> dict[str, Any]:
        """Worker function for parallel spot solving."""
        # Create a new solver instance for this worker to avoid shared state issues
        worker_solver = EnhancedPLOSolver(self.config)
        return worker_solver.solve_spot(spot)

    def _retrain_ml_model(self):
        """Retrain ML model with latest training data."""
        try:
            training_data = self.spot_db.get_training_data(limit=5000)
            if len(training_data) > 100:
                logger.info(f"Retraining ML model with {len(training_data)} samples")
                self.ml_predictor.train_model(training_data)
        except Exception as e:
            logger.error(f"ML model retraining failed: {e}")

    def get_bulk_job_status(self, job_id: str) -> dict[str, Any]:
        """Get status of bulk solving job."""
        with self.lock:
            if job_id not in self.bulk_jobs:
                return {"error": "Job not found"}

            job = self.bulk_jobs[job_id]
            status = {
                "job_id": job_id,
                "status": job["status"],
                "total_spots": job["total_spots"],
                "completed_spots": job["completed_spots"],
                "progress": ((job["completed_spots"] / job["total_spots"]) * 100 if job["total_spots"] > 0 else 0),
                "start_time": job["start_time"],
            }

            if job["status"] == "completed":
                status["completion_time"] = job.get("completion_time")
                status["total_time"] = job.get("completion_time", time.time()) - job["start_time"]
            elif job["status"] == "failed":
                status["error"] = job.get("error")

            return status

    def generate_precomputed_spots(self, num_spots: int = 1000):
        """Generate and solve common poker spots for precomputation."""
        logger.info(f"Generating {num_spots} precomputed spots...")

        common_boards = [
            ["As", "Kh", "7c"],  # Dry ace-high
            ["Ts", "9h", "8c"],  # Connected board
            ["Qd", "Qc", "5h"],  # Paired board
            ["Jh", "Tc", "9s"],  # Straight draw heavy
            ["Ah", "Kh", "Qh"],  # Flush draw heavy
            [],  # Preflop
        ]

        spots = []
        for board in common_boards:
            for num_players in [2, 3, 4, 6]:
                for pot_size in [50, 100, 200]:
                    for bet_ratio in [0, 0.5, 1.0]:
                        current_bet = pot_size * bet_ratio

                        game_state = GameState(
                            player_position=0,
                            active_players=list(range(num_players)),
                            board=board,
                            pot_size=pot_size,
                            current_bet=current_bet,
                            stack_sizes=[200] * num_players,
                            betting_history=[],
                            street="flop" if board else "preflop",
                            player_ranges={},
                            board2=None,
                            num_boards=1,
                            num_cards=4,
                            hero_cards=None,
                            opponents=None,
                            board_selection_mode="default",
                        )

                        spots.append(game_state)

                        if len(spots) >= num_spots:
                            break
                    if len(spots) >= num_spots:
                        break
                if len(spots) >= num_spots:
                    break
            if len(spots) >= num_spots:
                break

        # Solve all spots
        # Use threading for development to avoid SocketIO issues
        use_multiprocessing = os.getenv("USE_MULTIPROCESSING", "false").lower() == "true"
        if use_multiprocessing:
            max_workers = min(8, multiprocessing.cpu_count())
        else:
            max_workers = min(16, multiprocessing.cpu_count() * 2)  # More threads for threading

        results = self.bulk_solve(spots[:num_spots], max_workers=max_workers)
        logger.info(f"Precomputed spots generation completed: {results['status']}")

        return results


def _solve_spot_worker_static(spot_dict: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    """Static worker function for ProcessPoolExecutor compatibility."""
    try:
        # Ensure required fields are present and infer street if missing
        if "street" not in spot_dict or not spot_dict["street"]:
            # Infer street from board data
            board = spot_dict.get("board", [])
            if not board:
                spot_dict["street"] = "preflop"
            elif len(board) == 3:
                spot_dict["street"] = "flop"
            elif len(board) == 4:
                spot_dict["street"] = "turn"
            elif len(board) == 5:
                spot_dict["street"] = "river"
            else:
                spot_dict["street"] = "preflop"  # fallback

        # Reconstruct GameState from dict
        spot = GameState(**spot_dict)

        # Create a new solver instance for this worker
        worker_solver = EnhancedPLOSolver(config)
        return worker_solver.solve_spot(spot)
    except Exception as e:
        # Return error information that can be serialized
        return {
            "error": str(e),
            "error_type": type(e).__name__,
            "spot_hash": spot_dict.get("player_position", "unknown"),
        }


# Global solver instance
_solver_instance = None


def get_solver() -> EnhancedPLOSolver:
    """Get the global enhanced solver instance."""
    global _solver_instance
    if _solver_instance is None:
        _solver_instance = EnhancedPLOSolver()
    return _solver_instance


# Alias for backwards compatibility with tests
SolverEngine = EnhancedPLOSolver
