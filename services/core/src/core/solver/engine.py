"""Enhanced PLO GTO Solver Engine.

This module provides the src solver functionality extracted from the backend, including the GameState class and
EnhancedPLOSolver.
"""

import hashlib
import json
import time
from dataclasses import dataclass
from enum import Enum
from typing import Any, Optional

from sklearn.ensemble import RandomForestRegressor

from core.services.equity_service import simulate_estimated_equity


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
    betting_history: list[Any]  # Can be List[Tuple[int, ActionType, float]] or List[Dict]
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
            return 0, ActionType.CHECK, 0.0

        # Convert action string to ActionType enum
        try:
            action = ActionType(action_str)
        except ValueError:
            action = ActionType.CHECK

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
        # For now, use a simplified infoset based on key game state elements
        board_str = "".join(self.board) if self.board else ""
        street_str = self.street or "preflop"
        pot_str = str(int(self.pot_size))
        bet_str = str(int(self.current_bet))

        return f"{street_str}_{board_str}_{pot_str}_{bet_str}_{self.player_position}"


class Action:
    """Represents a poker action."""

    def __init__(self, action_type: ActionType, amount: float = 0.0):
        self.action_type = action_type
        self.amount = amount

    def __str__(self):
        if self.action_type == ActionType.FOLD:
            return "fold"
        elif self.action_type == ActionType.CHECK:
            return "check"
        elif self.action_type == ActionType.CALL:
            return "call"
        else:
            return f"{self.action_type.value} {self.amount}"


class CFRNode:
    """Node in the CFR decision tree."""

    def __init__(self, infoset: str):
        self.infoset = infoset
        self.regret_sum = {}  # Action -> regret sum
        self.strategy_sum = {}  # Action -> strategy sum
        self.actions = []  # Available actions

    def get_strategy(self, reach_prob: float) -> dict[Action, float]:
        """Get current strategy for this node."""
        strategy = {}
        regret_sum = 0

        # Calculate regret sum
        for action in self.actions:
            regret_sum += max(0, self.regret_sum.get(action, 0))

        # Calculate strategy
        for action in self.actions:
            if regret_sum > 0:
                strategy[action] = max(0, self.regret_sum.get(action, 0)) / regret_sum
            else:
                strategy[action] = 1.0 / len(self.actions)

        return strategy

    def get_average_strategy(self) -> dict[Action, float]:
        """Get average strategy over all iterations."""
        avg_strategy = {}
        strategy_sum = 0

        for action in self.actions:
            strategy_sum += self.strategy_sum.get(action, 0)

        for action in self.actions:
            if strategy_sum > 0:
                avg_strategy[action] = self.strategy_sum.get(action, 0) / strategy_sum
            else:
                avg_strategy[action] = 1.0 / len(self.actions)

        return avg_strategy

    def update_regret(self, action: Action, regret: float):
        """Update regret for an action."""
        if action not in self.regret_sum:
            self.regret_sum[action] = 0
        self.regret_sum[action] += regret

    def update_strategy(self, action: Action, strategy: float):
        """Update strategy sum for an action."""
        if action not in self.strategy_sum:
            self.strategy_sum[action] = 0
        self.strategy_sum[action] += strategy


class EnhancedPLOSolver:
    """Enhanced PLO GTO Solver with equity integration and ML capabilities."""

    def __init__(self, config: Optional[dict[str, Any]] = None):
        self.config = config or self._get_default_config()
        self.nodes = {}  # infoset -> CFRNode
        self.equity_cache = {}
        self.ml_model = None
        self._initialize_ml_model()

    def _get_default_config(self) -> dict[str, Any]:
        """Get default solver configuration."""
        return {
            "max_iterations": 10000,
            "exploration_constant": 1.414,
            "enable_equity_integration": True,
            "enable_ml_enhancement": True,
            "equity_weight": 0.3,
            "regret_weight": 0.7,
            "enable_precomputed_spots": False,
            "spot_db_path": None,
        }

    def _initialize_ml_model(self):
        """Initialize machine learning model for equity prediction."""
        if self.config.get("enable_ml_enhancement", True):
            self.ml_model = RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42)

    def _get_node(self, infoset: str) -> CFRNode:
        """Get or create CFR node for an information set."""
        if infoset not in self.nodes:
            self.nodes[infoset] = CFRNode(infoset)
            self.nodes[infoset].actions = [
                Action(ActionType.FOLD),
                Action(ActionType.CALL),
                Action(ActionType.RAISE, 50),
                Action(ActionType.RAISE, 100),
            ]
        return self.nodes[infoset]

    def _calculate_equity(self, game_state: GameState) -> float:
        """Calculate equity for the current game state."""
        if not self.config.get("enable_equity_integration", True):
            return 0.5  # Neutral equity

        # Use cached equity if available
        state_hash = game_state.to_hash()
        if state_hash in self.equity_cache:
            return self.equity_cache[state_hash]

        # Calculate equity using the equity module
        try:
            if game_state.hero_cards and game_state.board:
                equity, _, _, _, _ = simulate_estimated_equity(
                    hand=game_state.hero_cards,
                    board=game_state.board,
                    num_iterations=1000,
                    num_opponents=len(game_state.active_players) - 1,
                )
                equity_percent = equity / 100.0  # Convert to 0-1 range
            else:
                equity_percent = 0.5  # Default neutral equity
        except Exception:
            equity_percent = 0.5  # Fallback to neutral equity

        # Cache the result
        self.equity_cache[state_hash] = equity_percent
        return equity_percent

    def _apply_action(self, game_state: GameState, action: Action) -> GameState:
        """Apply an action to create a new game state."""
        # Create a copy of the game state
        new_state = GameState(
            player_position=game_state.player_position,
            active_players=game_state.active_players.copy(),
            board=game_state.board.copy(),
            pot_size=game_state.pot_size,
            current_bet=game_state.current_bet,
            stack_sizes=game_state.stack_sizes.copy(),
            betting_history=game_state.betting_history.copy(),
            street=game_state.street,
            player_ranges=game_state.player_ranges.copy(),
            board2=game_state.board2.copy() if game_state.board2 else None,
            num_boards=game_state.num_boards,
            num_cards=game_state.num_cards,
            hero_cards=game_state.hero_cards.copy() if game_state.hero_cards else None,
            opponents=game_state.opponents.copy() if game_state.opponents else None,
            board_selection_mode=game_state.board_selection_mode,
        )

        # Apply the action
        if action.action_type == ActionType.FOLD:
            # Remove player from active players
            if new_state.player_position in new_state.active_players:
                new_state.active_players.remove(new_state.player_position)
        elif action.action_type == ActionType.CALL:
            # Add call amount to pot
            new_state.pot_size += new_state.current_bet
        elif action.action_type in [ActionType.BET, ActionType.RAISE]:
            # Add bet/raise amount to pot
            new_state.pot_size += action.amount
            new_state.current_bet = action.amount

        # Add action to betting history
        new_state.betting_history.append(
            {"player": new_state.player_position, "action": action.action_type.value, "amount": action.amount}
        )

        return new_state

    def cfr(self, game_state: GameState, reach_probs: list[float], remaining_iterations: int) -> float:
        """Counterfactual Regret Minimization algorithm."""
        if remaining_iterations <= 0:
            return 0.0

        # Terminal state check
        if len(game_state.active_players) <= 1:
            return self._terminal_value(game_state)

        # Get current player
        current_player = game_state.active_players[game_state.player_position % len(game_state.active_players)]

        # Get information set
        infoset = game_state.to_infoset()
        node = self._get_node(infoset)

        # Get strategy
        strategy = node.get_strategy(reach_probs[current_player])

        # Calculate node utility
        node_utility = 0.0
        action_utilities = {}

        for action in node.actions:
            # Apply action to get new state
            new_state = self._apply_action(game_state, action)

            # Calculate utility for this action
            action_utility = self.cfr(new_state, reach_probs, remaining_iterations - 1)
            action_utilities[action] = action_utility
            node_utility += strategy[action] * action_utility

        # Update regrets
        for action in node.actions:
            regret = action_utilities[action] - node_utility
            node.update_regret(action, regret)

            # Update strategy sum
            node.update_strategy(action, reach_probs[current_player] * strategy[action])

        return node_utility

    def _terminal_value(self, game_state: GameState) -> float:
        """Calculate terminal value for a game state."""
        if len(game_state.active_players) == 1:
            # Only one player left - they win
            return 1.0 if game_state.player_position in game_state.active_players else -1.0

        # Calculate equity-based value
        equity = self._calculate_equity(game_state)
        return 2.0 * equity - 1.0  # Convert to [-1, 1] range

    def solve_spot(self, game_state: GameState, iterations: Optional[int] = None) -> dict[str, Any]:
        """Solve a poker spot using enhanced CFR."""
        if iterations is None:
            iterations = self.config["max_iterations"]

        # Initialize reach probabilities
        reach_probs = [1.0] * len(game_state.active_players)

        # Run CFR iterations
        start_time = time.time()
        for i in range(iterations):
            if i % 1000 == 0:
                pass  # Could add logging here

        self.cfr(game_state, reach_probs, iterations)
        solve_time = time.time() - start_time

        # Extract final strategies
        strategies = {}
        for infoset, node in self.nodes.items():
            strategies[infoset] = node.get_average_strategy()

        # Calculate equity and other metrics
        equity_data = self._calculate_equity(game_state)

        # Build solution
        solution = {
            "strategies": strategies,
            "equity": equity_data,
            "solve_time": solve_time,
            "iterations": iterations,
            "game_state_hash": game_state.to_hash(),
            "config": self.config,
        }

        return solution


# Global solver instance
_solver_instance = None


def get_solver() -> EnhancedPLOSolver:
    """Get the global enhanced solver instance."""
    global _solver_instance
    if _solver_instance is None:
        _solver_instance = EnhancedPLOSolver()
    return _solver_instance


# Alias for backwards compatibility
SolverEngine = EnhancedPLOSolver
