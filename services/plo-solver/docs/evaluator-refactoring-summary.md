# Evaluator Refactoring Summary

## Problem
A new `Evaluator()` instance was being created for every hand evaluation, which was inefficient and caused performance issues. This happened in multiple files:

- `src/backend/services/equity_service.py` - Line 26: `local_evaluator = Evaluator()`
- `src/backend/services/equity_calculator.py` - Line 23: `evaluator = Evaluator()`
- `src/backend/core/app.py` - Line 135: `app.evaluator = Evaluator()`
- `src/simulation/plo_simulation.py` - Line 25: `self.evaluator = Evaluator()`

## Solution
Implemented a centralized singleton pattern for the Evaluator to ensure only one instance is created per process.

### Changes Made

#### 1. Created Centralized Evaluator Utility
**File**: `src/backend/utils/evaluator_utils.py`

```python
"""
Centralized Evaluator utility to avoid creating new instances for every hand evaluation.
This provides a singleton pattern for the Treys Evaluator to improve performance.
"""

import logging
from typing import Optional
from treys import Evaluator

logger = logging.getLogger(__name__)

# Global evaluator instance
_evaluator: Optional[Evaluator] = None

def get_evaluator() -> Evaluator:
    """
    Get or create the global evaluator instance.
    This ensures we only create one Evaluator instance per process.
    """
    global _evaluator
    if _evaluator is None:
        _evaluator = Evaluator()
        logger.debug("Created new global Evaluator instance")
    return _evaluator

def reset_evaluator():
    """
    Reset the global evaluator instance.
    Useful for testing or when you need a fresh instance.
    """
    global _evaluator
    _evaluator = None
    logger.debug("Reset global Evaluator instance")

def evaluate_plo_hand(hole_cards, board) -> int:
    """
    Evaluate a PLO hand using the global evaluator instance.
    This is a convenience function that uses the singleton evaluator.
    """
    from itertools import combinations
    
    evaluator = get_evaluator()
    best_score = float('inf')  # Lower is better in Treys
    
    # Try all combinations of 2 hole cards with 3 board cards
    for hole_combo in combinations(hole_cards, 2):
        for board_combo in combinations(board, 3):
            hand = list(hole_combo) + list(board_combo)
            try:
                score = evaluator.evaluate(hand, [])
                if score < best_score:
                    best_score = score
            except Exception as e:
                logger.error(f"Error evaluating hand: {hand} - {e}")
                continue
    
    return best_score
```

#### 2. Refactored equity_service.py
**Changes**:
- Removed local `evaluate_plo_hand` function
- Added import: `from utils.evaluator_utils import get_evaluator, evaluate_plo_hand`
- Removed `from treys import Evaluator` import
- All `evaluate_plo_hand` calls now use the centralized version

#### 3. Refactored equity_calculator.py
**Changes**:
- Removed local `evaluate_plo_hand` function
- Added import: `from utils.evaluator_utils import evaluate_plo_hand`
- All `evaluate_plo_hand` calls now use the centralized version

#### 4. Updated app.py
**Changes**:
- Changed from `app.evaluator = Evaluator()` to `app.evaluator = get_evaluator()`
- Added import: `from utils.evaluator_utils import get_evaluator`

#### 5. Updated plo_simulation.py
**Changes**:
- Changed from `self.evaluator = Evaluator()` to `self.evaluator = get_evaluator()`
- Added import: `from utils.evaluator_utils import get_evaluator`
- Removed `from treys import Evaluator` import

## Benefits

### Performance Improvements
- **Single Evaluator instance per process**: Eliminates the overhead of creating new Evaluator instances
- **Reduced memory usage**: Only one Evaluator object exists instead of multiple instances
- **Faster hand evaluations**: No initialization overhead for each evaluation

### Code Quality Improvements
- **Centralized logic**: All evaluator-related code is in one place
- **Consistent behavior**: All parts of the application use the same evaluator instance
- **Easier maintenance**: Changes to evaluator logic only need to be made in one place
- **Better testability**: Can easily reset the evaluator for testing

### Expected Performance Gains
Based on the documentation in `docs/equity-performance-optimization.md`, this refactoring should provide:
- **40-60% reduction in hand evaluation time**
- **Reduced memory allocation overhead**
- **Better scalability for high-frequency evaluations**

## Testing
The refactoring has been tested and verified to work correctly:
- ✅ Evaluator singleton pattern works correctly
- ✅ Hand evaluation produces consistent results
- ✅ All imports work correctly
- ✅ No breaking changes to existing functionality

## Usage
The refactored code maintains the same API, so no changes are needed in calling code. The `evaluate_plo_hand` function works exactly the same way, but now uses the singleton evaluator internally.

## Future Considerations
- Consider adding caching for frequently evaluated hand combinations
- Monitor performance improvements in production
- Consider adding metrics to track evaluator usage patterns 