# Claude Development Guidelines for PLOSolver

## Project Overview
This is a Pot Limit Omaha (PLO) Double Board Bomb Pot solver application with Python backend and React frontend.

## General Development Principles
- You are a staff engineer expert in Python, Algorithms, Javascript, React, and gRPC
- Write clean, readable, and properly documented code
- Always consider the impacts of requests before writing code
- It's acceptable to say you don't know something
- Always use loggers over print or console.log statements
- Ensure code passes linting with `make lint`
- Write unit tests for any new functionality or bug fixes
- Prefer simple solutions over clever or overly abstract ones
- Keep codebase clean: no commented-out code, debug prints, or unused dependencies
- Avoid files larger than 200-300 lines; refactor when necessary
- Don't introduce new patterns/technologies for bug fixes unless simpler options are exhausted
- Avoid code duplication; refactor when duplication occurs
- Never add stubbing or fake data affecting development/production environments
- Write code with multi-environment awareness (dev, staging, prod)
- Prefer environment variables over hardcoded values
- Don't auto-approve and commit changes without approval
- Validate changes don't break existing features by running `make test`
- Follow 12-factor app principles (https://12factor.net/)

## Port Configuration
- Frontend: port 3001
- Backend: port 5001

## Local Development
- Use `make run-local` to start servers (not npm/npx/python directly)
- Use `make dev` for local testing unless explicitly told otherwise
- Run `make test` to verify all tests pass
- Only verify unit tests when making new changes

## Card Data Format
- **CRITICAL**: Never use ♣ ♦ ♥ ♠ characters in data processing
- These symbols are ONLY for frontend display
- Always use short form: d, s, c, h for suits in all backend logic and data transfer

## Frontend Guidelines
- Ensure no duplicate or redundant hooks
- Follow React best practices: https://react.dev/learn/thinking-in-react
- Register new feature flags in featureFlags.js
- Check existing CSS styles before creating new ones
- Avoid duplicating CSS styles and hardcoding values
- Ensure dark mode compatibility (black background, white text)

## Backend Guidelines
- Don't use SQLite for tests; application runs on PostgreSQL
- Use gRPC for service communication where applicable
- Follow Python best practices and PEP standards

## PLO Game Rules Implementation

### Standard PLO Rules
- 4 hole cards per player
- Pot-limit betting structure (max bet = current pot size after call)
- Must use exactly 2 hole cards + 3 community cards
- Standard betting rounds: Preflop, Flop, Turn, River

### Bomb Pot Format (Double Board)
- Skip preflop betting; all players ante
- Two separate community boards run simultaneously
- Pot-limit betting starts on flop
- Players build separate hands for each board
- Pot split 50/50 between board winners (or scoop if same player wins both)

### Hand Construction
- Each hand must use exactly 2 hole cards + 3 community cards
- Different combinations can be used on each board
- Standard poker hand rankings apply (high-only)

### Position System
| Position | Name | Description |
|----------|------|-------------|
| UTG | Under the Gun | First to act preflop |
| HJ | Hijack | One seat before cutoff |
| CO | Cutoff | One seat right of button |
| BTN | Button | Dealer position, acts last postflop |
| SB | Small Blind | Posts ½ BB, acts first postflop |
| BB | Big Blind | Posts 1 BB, acts second postflop |

### Pot Splitting Logic
- 50/50 split: Different players win each board
- Scoop: Same player wins both boards (100% of pot)
- Quarter pots: When ties occur on one board
- Side pots: Handle all-in situations with different stack sizes

## Testing Requirements
- Write comprehensive unit tests for all game logic
- Test edge cases in pot splitting and hand evaluation
- Verify multi-board scenarios work correctly
- Test all-in and side pot calculations
- Ensure position and betting logic is accurate

## Code Quality Standards
- All code must pass `make lint`
- All tests must pass with `make test`
- Follow existing patterns and conventions in the codebase
- Document complex game logic clearly
- Use descriptive variable names for poker concepts