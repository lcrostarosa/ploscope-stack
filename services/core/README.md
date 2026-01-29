# Core

Core PLO (Pot Limit Omaha) solver and equity calculation library for the PLOSolver platform.

## Features

- **Equity Calculation**: Fast and accurate equity calculation for PLO hands
- **Double Board Analysis**: Support for double board PLO games
- **GTO Solver**: Counterfactual Regret Minimization (CFR) based solver
- **Card Utilities**: Comprehensive card validation and conversion utilities
- **Performance Optimized**: Multi-threaded calculations with optimized algorithms

## Installation

### From GitHub Packages (Recommended)

```bash
pip install src --extra-index-url https://__token__:${GITHUB_TOKEN}@npm.pkg.github.com/your-org/
```

### From Source

```bash
git clone https://github.com/your-org/PLOSolver.git
cd PLOSolver/src
poetry install --with-test
```

## Development Setup

### Quick Setup

For a complete development environment setup with pre-commit hooks:

```bash
# Run the setup script (recommended)
make setup-dev

# Or manually:
make deps
make pre-commit-install
```

### Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality. The hooks run automatically on every commit and include:

- **Code Formatting**: Black for consistent code formatting
- **Import Sorting**: isort for organized imports
- **Linting**: flake8 for code style checks
- **Type Checking**: mypy for static type analysis
- **Security**: bandit for security vulnerability scanning
- **Testing**: pytest for running tests
- **Package Building**: poetry build for package validation

#### Installing Pre-commit Hooks

```bash
make pre-commit-install
```

#### Running Pre-commit Hooks Manually

```bash
make pre-commit-run
```

#### Updating Pre-commit Hooks

```bash
make pre-commit-update
```

## Quick Start

### Equity Calculation

```python
from equity import calculate_double_board_stats, simulate_estimated_equity

# Calculate double board statistics
hands = [["Ah", "Kh", "Qh", "Jh"], ["As", "Ks", "Qs", "Js"]]
top_board = ["2h", "3h", "4h"]
bottom_board = ["5s", "6s", "7s"]

chop_both, scoop_both, split_top, split_bottom = calculate_double_board_stats(
    hands=hands,
    top_board=top_board,
    bottom_board=bottom_board,
    num_iterations=10000
)

# Calculate estimated equity
equity, tie_percent, hand_breakdown, opponent_breakdown, _ = simulate_estimated_equity(
    hand=["Ah", "Kh", "Qh", "Jh"],
    board=["2h", "3h", "4h"],
    num_iterations=10000,
    num_opponents=3
)
```

### Solver Analysis

```python
from solver import get_solver, GameState

# Create game state
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
    hero_cards=["2h", "3h", "4h", "5h"]
)

# Get solver and solve
solver = get_solver()
solution = solver.solve_spot(game_state)
```

## API Reference

### Equity Module

#### `calculate_double_board_stats(hands, top_board, bottom_board, num_iterations=2000)`

Calculate double board PLO statistics.

**Parameters:**
- `hands`: List of player hands (each hand is a list of card strings)
- `top_board`: List of top board cards
- `bottom_board`: List of bottom board cards
- `num_iterations`: Number of simulation iterations

**Returns:**
- `chop_both`: List of chop both board percentages for each player
- `scoop_both`: List of scoop both board percentages for each player
- `split_top`: List of split top board percentages for each player
- `split_bottom`: List of split bottom board percentages for each player

#### `simulate_estimated_equity(hand, board, num_iterations=2000, folded_cards=None, max_hand_combinations=10000, num_opponents=7)`

Calculate estimated equity for a single hand against random opponents.

**Parameters:**
- `hand`: List of hole cards
- `board`: List of board cards
- `num_iterations`: Number of simulation iterations
- `folded_cards`: List of folded cards (optional)
- `max_hand_combinations`: Maximum hand combinations to consider
- `num_opponents`: Number of random opponents to simulate

**Returns:**
- `equity`: Estimated equity percentage
- `tie_percent`: Tie percentage
- `hand_breakdown`: Detailed hand strength breakdown
- `opponent_breakdown`: Opponent hand strength breakdown
- `additional_stats`: Additional statistics

### Solver Module

#### `GameState`

Data class representing a PLO game state.

**Fields:**
- `player_position`: Hero's position
- `active_players`: List of active player positions
- `board`: List of board cards
- `pot_size`: Current pot size
- `current_bet`: Current bet amount
- `stack_sizes`: List of player stack sizes
- `betting_history`: List of betting actions
- `street`: Current street (preflop, flop, turn, river)
- `player_ranges`: Player range definitions
- `board2`: Second board for double board games (optional)
- `num_boards`: Number of boards (1 or 2)
- `num_cards`: Number of hole cards per player
- `hero_cards`: Hero's hole cards
- `opponents`: Opponent information
- `board_selection_mode`: Board selection mode

#### `get_solver()`

Get the global solver instance.

**Returns:**
- `EnhancedPLOSolver`: Configured solver instance

#### `EnhancedPLOSolver.solve_spot(game_state, iterations=None)`

Solve a poker spot using CFR.

**Parameters:**
- `game_state`: GameState object
- `iterations`: Number of CFR iterations (optional)

**Returns:**
- `dict`: Solution containing strategies and analysis

### Utils Module

#### `str_to_cards(card_strs)`

Convert card strings to Treys integer format.

#### `validate_card_input(card_lists)`

Validate card input for duplicates and format.

#### `convert_unicode_suits_to_standard(card)`

Convert Unicode suit symbols to standard format.

## Development

### Setup Development Environment

```bash
git clone https://github.com/your-org/PLOSolver.git
cd PLOSolver/src
poetry install
```

### Running Tests

```bash
poetry run pytest
```

### Code Formatting

```bash
poetry run black .
poetry run flake8 .
poetry run mypy .
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run the test suite
6. Submit a pull request

## Support

For support and questions, please open an issue on GitHub.
