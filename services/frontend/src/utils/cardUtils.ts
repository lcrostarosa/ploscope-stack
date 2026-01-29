import {
  CardType,
  CardArrayUtils,
  BoardUtils,
  Card,
  CardValue,
  CardArray,
  CardArray4,
  CardArray3,
  BoardCards,
  Rank,
  SuitShort,
  SuitEmoji,
  CardShort,
  CardEmoji,
  CardValidation,
  CardAnalysis,
} from '../types/CardType';

import { generateDeck } from './constants';

/**
 * Card Utilities for PLO Analysis
 * Provides type-safe card operations using the CardType system
 */

// Basic card validation
export const isValidCard = (card: string): boolean => {
  if (!card || card.length !== 2) return false;

  const rank = card[0].toUpperCase();
  const suit = card[1].toLowerCase();

  const validRanks = new Set([
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A',
  ]);
  const validSuits = new Set(['h', 'd', 's', 'c']);

  return validRanks.has(rank) && validSuits.has(suit);
};

// Card conversion functions
export const convertToShort = (card: string): CardShort | null => {
  if (!isValidCard(card)) return null;

  const rank = card[0].toUpperCase() as Rank;
  const suit = card[1].toLowerCase() as SuitShort;

  return `${rank}${suit}` as CardShort;
};

export const convertToEmoji = (card: string): CardEmoji | null => {
  if (!isValidCard(card)) return null;

  const rank = card[0].toUpperCase() as Rank;
  const suit = card[1].toLowerCase();

  let suitEmoji: SuitEmoji;
  switch (suit) {
    case 'h':
      suitEmoji = '♥';
      break;
    case 'd':
      suitEmoji = '♦';
      break;
    case 's':
      suitEmoji = '♠';
      break;
    case 'c':
      suitEmoji = '♣';
      break;
    default:
      return null;
  }

  return `${rank}${suitEmoji}` as CardEmoji;
};

// Card property getters
export const getRank = (card: Card): Rank => {
  return card[0] as Rank;
};

export const getSuit = (card: Card): SuitShort => {
  return card[1] as SuitShort;
};

export const getSuitEmoji = (card: Card): SuitEmoji => {
  const suit = getSuit(card);
  switch (suit) {
    case 'h':
      return '♥';
    case 'd':
      return '♦';
    case 's':
      return '♠';
    case 'c':
      return '♣';
  }
};

// Card value checks
export const isRandom = (card: CardValue): boolean => {
  return card === 'RANDOM';
};

export const isEmpty = (card: CardValue): boolean => {
  return card === '';
};

export const isFilled = (card: CardValue): boolean => {
  return card !== '' && card !== 'RANDOM';
};

// Card array operations
export const getUsedCards = (cards: CardArray): Set<Card> => {
  return CardArrayUtils.getUsedCards(cards);
};

export const getFilledCards = (cards: CardArray): Card[] => {
  return CardArrayUtils.getFilledCards(cards);
};

export const getRandomCards = (cards: CardArray): number => {
  return CardArrayUtils.getRandomCards(cards);
};

export const getEmptyCards = (cards: CardArray): number => {
  return CardArrayUtils.getEmptyCards(cards);
};

export const isComplete = (cards: CardArray): boolean => {
  return CardArrayUtils.isComplete(cards);
};

export const hasAnyCards = (cards: CardArray): boolean => {
  return CardArrayUtils.hasAnyCards(cards);
};

export const countCards = (cards: CardArray): number => {
  return CardArrayUtils.countCards(cards);
};

// Available cards calculation
export const getAvailableCards = (usedCards: Set<Card>): Card[] => {
  const allCards = generateDeck();
  return allCards.filter(card => !usedCards.has(card as Card)) as Card[];
};

// Random card generation
export const generateRandomCards = (
  count: number,
  usedCards: Set<Card> = new Set()
): Card[] => {
  const availableCards = getAvailableCards(usedCards);
  const shuffled = [...availableCards].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, count);
};

// Alternative random card generation with excludeCards array
export const generateRandomCardsFromExclude = (
  count: number,
  excludeCards: string[] = []
): string[] => {
  const allCards = generateDeck();
  const availableCards = allCards.filter(card => !excludeCards.includes(card));
  const selectedCards = [];

  for (let i = 0; i < count && availableCards.length > 0; i++) {
    const randomIndex = Math.floor(Math.random() * availableCards.length);
    selectedCards.push(availableCards[randomIndex]);
    availableCards.splice(randomIndex, 1);
  }

  return selectedCards;
};

// Board operations
export const getBoardUsedCards = (board: BoardCards): Set<Card> => {
  return BoardUtils.getUsedCards(board);
};

export const getBoardFilledCards = (board: BoardCards): Card[] => {
  return BoardUtils.getFilledCards(board);
};

export const isBoardComplete = (board: BoardCards): boolean => {
  return BoardUtils.isComplete(board);
};

export const hasBoardCards = (board: BoardCards): boolean => {
  return BoardUtils.hasAnyCards(board);
};

export const countBoardCards = (board: BoardCards): number => {
  return BoardUtils.countCards(board);
};

// Card validation
export const validateCards = (
  cards: CardArray,
  rules: {
    requireComplete?: boolean;
    maxCards?: number;
    allowRandom?: boolean;
  } = {}
): CardValidation => {
  const errors: string[] = [];
  const warnings: string[] = [];

  const { requireComplete = false, maxCards, allowRandom = true } = rules;

  // Check for invalid cards
  const invalidCards = cards.filter(
    card => card !== '' && card !== 'RANDOM' && !isValidCard(card)
  );

  if (invalidCards.length > 0) {
    errors.push(`Invalid cards found: ${invalidCards.join(', ')}`);
  }

  // Check for random cards if not allowed
  if (!allowRandom && cards.some(isRandom)) {
    errors.push('Random cards are not allowed');
  }

  // Check completeness requirement
  if (requireComplete && !isComplete(cards)) {
    errors.push('All cards must be filled');
  }

  // Check max cards limit
  if (maxCards !== undefined && countCards(cards) > maxCards) {
    errors.push(`Maximum ${maxCards} cards allowed`);
  }

  // Check for duplicates
  const filledCards = getFilledCards(cards);
  const uniqueCards = new Set(filledCards);
  if (filledCards.length !== uniqueCards.size) {
    errors.push('Duplicate cards found');
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings,
  };
};

// Card analysis
export const analyzeCards = (state: {
  heroCards: CardArray4;
  opponentCards: CardArray4[];
  communityCards: {
    topBoard: BoardCards;
    bottomBoard: BoardCards;
  };
  foldedCards: CardArray;
}): CardAnalysis => {
  const { heroCards, opponentCards, communityCards, foldedCards } = state;

  // Count all used cards
  let totalCardsUsed = 0;

  // Hero cards
  totalCardsUsed += countCards(heroCards);

  // Opponent cards
  opponentCards.forEach(cards => {
    totalCardsUsed += countCards(cards);
  });

  // Community cards
  totalCardsUsed += countBoardCards(communityCards.topBoard);
  totalCardsUsed += countBoardCards(communityCards.bottomBoard);

  // Folded cards
  totalCardsUsed += countCards(foldedCards);

  const remainingCards = 52 - totalCardsUsed;

  // Player analysis
  const playerCount = 1 + opponentCards.length; // hero + opponents
  const knownPlayers =
    1 + opponentCards.filter(cards => isComplete(cards)).length;
  const randomPlayers = opponentCards.filter(
    cards => !hasAnyCards(cards)
  ).length;

  // Validation
  const validation = validateCards(
    [...heroCards, ...opponentCards.flat(), ...foldedCards],
    {
      requireComplete: false,
      allowRandom: true,
    }
  );

  return {
    totalCardsUsed,
    remainingCards,
    playerCount,
    knownPlayers,
    randomPlayers,
    isComplete: validation.isValid && isComplete(heroCards),
    validation,
  };
};

// Card picker utilities
export const getCardPickerAvailableCards = (
  usedCards: Set<Card>,
  currentCard?: CardValue
): Card[] => {
  const availableCards = getAvailableCards(usedCards);

  // If there's a current card, include it in available cards
  if (currentCard && isFilled(currentCard)) {
    availableCards.push(currentCard as Card);
  }

  return availableCards;
};

// Card state management
export const createEmptyCardState = () => ({
  heroCards: CardArrayUtils.createEmpty4(),
  opponentCards: [],
  communityCards: {
    topBoard: BoardUtils.createEmpty(),
    bottomBoard: BoardUtils.createEmpty(),
  },
  foldedCards: [],
  foldedStates: {
    topBoard: false,
    bottomBoard: false,
    opponents: [],
  },
});

// Export utility classes for advanced usage
export { CardType, CardArrayUtils, BoardUtils };

// Export all types for convenience
export type {
  Card,
  CardValue,
  CardArray,
  CardArray4,
  CardArray3,
  BoardCards,
  Rank,
  SuitShort,
  SuitEmoji,
  CardShort,
  CardEmoji,
  CardValidation,
  CardAnalysis,
};
