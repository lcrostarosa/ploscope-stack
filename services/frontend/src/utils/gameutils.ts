/**
 * Game Utilities for PLO Analysis
 * Provides game-related utility functions for betting, validation, and game mechanics
 */

// Bet size validation
export const validateBetSize = (
  betSize: number,
  currentBet: number,
  maxBet: number,
  heroStackSize: number
) => {
  if (betSize < 0) {
    return { isValid: false, error: 'Bet size cannot be negative' };
  }

  let adjustedSize = betSize;
  let isAllIn = false;

  // Adjust to minimum bet if needed
  if (betSize < currentBet && currentBet > 0) {
    adjustedSize = currentBet;
  }

  // Check if this would be an all-in
  if (betSize >= heroStackSize) {
    adjustedSize = heroStackSize;
    isAllIn = true;
  } else if (betSize > maxBet) {
    // Adjust to maximum bet if needed
    adjustedSize = maxBet;
  }

  return {
    isValid: true,
    adjustedSize,
    isAllIn,
  };
};

// Calculate max bet based on pot limit rules
export const calculateMaxBet = (
  potSize: number,
  heroStackSize: number,
  opponents: Array<{ stack?: number; stackSize?: number }>
) => {
  if (!opponents || !Array.isArray(opponents) || opponents.length === 0) {
    return heroStackSize;
  }

  const allStacks = [
    heroStackSize,
    ...opponents.map(opp => opp.stackSize || opp.stack || 0),
  ];
  const smallestStack = Math.min(...allStacks);
  const potLimitBet = potSize;
  return Math.min(potLimitBet, smallestStack, heroStackSize);
};
