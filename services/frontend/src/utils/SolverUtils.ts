import { generateRandomCardsFromExclude } from './cardUtils';
import { generateDeck, convertCardsForBackend } from './constants';
import { validateBetSize, calculateMaxBet } from './gameutils';

// PLO Positions
export const POSITIONS = {
  UTG: 'UTG (Under the Gun)',
  UTG1: 'UTG+1',
  MP1: 'MP1 (Middle Position 1)',
  MP2: 'MP2 (Middle Position 2)',
  LJ: 'LJ (Lojack)',
  HJ: 'HJ (Hijack)',
  CO: 'CO (Cutoff)',
  BTN: 'BTN (Button)',
  SB: 'SB (Small Blind)',
  BB: 'BB (Big Blind)',
};

// Updated position ordering to reflect correct betting order
export const POSITION_ORDER = [
  'SB',
  'BB',
  'UTG',
  'UTG1',
  'MP1',
  'MP2',
  'LJ',
  'HJ',
  'CO',
  'BTN',
];

// Board Textures
export const BOARD_TEXTURES = {
  dry: {
    name: 'Dry',
    description: 'Low connectivity, few draws (e.g., A♠7♣2♦)',
    examples: [
      ['A♠', '7♣', '2♦'],
      ['K♦', '8♠', '3♥'],
      ['Q♣', '6♠', '2♥'],
      ['J♦', '5♣', '2♠'],
      ['T♠', '4♦', '2♣'],
    ],
  },
  paired: {
    name: 'Paired',
    description: 'Contains a pair (e.g., 8♠8♣3♦)',
    examples: [
      ['A♠', 'A♣', '5♦'],
      ['K♦', 'K♠', '7♥'],
      ['Q♣', 'Q♠', '4♥'],
      ['8♠', '8♣', '3♦'],
      ['7♦', '7♣', '2♠'],
    ],
  },
  rainbow: {
    name: 'Rainbow',
    description: 'Three different suits (e.g., A♠K♦5♣)',
    examples: [
      ['A♠', 'K♦', '5♣'],
      ['Q♥', 'J♠', '7♦'],
      ['T♣', '9♠', '4♥'],
      ['9♦', '6♣', '3♠'],
      ['8♥', '5♦', '2♣'],
    ],
  },
  monotone: {
    name: 'Monotone',
    description: 'All same suit (e.g., A♠K♠5♠)',
    examples: [
      ['A♠', 'K♠', '5♠'],
      ['Q♦', 'J♦', '7♦'],
      ['T♣', '9♣', '4♣'],
      ['9♥', '6♥', '3♥'],
      ['8♠', '5♠', '2♠'],
    ],
  },
  twotone: {
    name: 'Two-tone',
    description: 'Two suits represented (e.g., A♠K♠5♦)',
    examples: [
      ['A♠', 'K♠', '5♦'],
      ['Q♦', 'J♦', '7♣'],
      ['T♣', '9♣', '4♠'],
      ['9♥', '6♥', '3♦'],
      ['8♠', '5♠', '2♣'],
    ],
  },
  straight_heavy: {
    name: 'Straight Possibilities',
    description: 'Connected cards with straight draws (e.g., 9♠8♦7♣)',
    examples: [
      ['9♠', '8♦', '7♣'],
      ['T♥', '9♠', '8♦'],
      ['8♣', '7♠', '6♥'],
      ['7♦', '6♣', '5♠'],
      ['6♥', '5♦', '4♣'],
    ],
  },
  coordinated: {
    name: 'Coordinated',
    description: 'Mix of straight and flush possibilities (e.g., J♠T♠9♦)',
    examples: [
      ['J♠', 'T♠', '9♦'],
      ['Q♦', 'J♦', 'T♣'],
      ['T♣', '9♣', '8♠'],
      ['9♥', '8♥', '7♦'],
      ['8♠', '7♠', '6♣'],
    ],
  },
  wet: {
    name: 'Wet',
    description: 'High connectivity with multiple draws (e.g., T♠9♥8♠)',
    examples: [
      ['T♠', '9♥', '8♠'],
      ['J♦', 'T♦', '9♣'],
      ['9♣', '8♣', '7♠'],
      ['8♥', '7♥', '6♦'],
      ['7♠', '6♠', '5♣'],
    ],
  },
};

// PLO Starting Hand Categories
export const HERO_HAND_CATEGORIES = {
  premium_pairs: {
    name: 'Premium Pairs',
    description: 'AA, KK, QQ with good side cards',
    examples: ['A♠A♥K♠Q♦', 'K♠K♥Q♠J♦', 'Q♠Q♥J♠T♦'],
  },
  high_pairs: {
    name: 'High Pairs',
    description: 'JJ, TT, 99 with good side cards',
    examples: ['J♠J♥T♠9♦', 'T♠T♥9♠8♦', '9♠9♥8♠7♦'],
  },
  medium_pairs: {
    name: 'Medium Pairs',
    description: '88, 77, 66 with decent side cards',
    examples: ['8♠8♥7♠6♦', '7♠7♥6♠5♦', '6♠6♥5♠4♦'],
  },
  small_pairs: {
    name: 'Small Pairs',
    description: '55, 44, 33, 22 with connectors',
    examples: ['5♠5♥4♠3♦', '4♠4♥3♠2♦', '3♠3♥2♠A♦'],
  },
  double_suited_aces: {
    name: 'Double Suited Aces',
    description: 'Ace high with two suits',
    examples: ['A♠K♠Q♥J♥', 'A♠Q♠K♥T♥', 'A♠J♠T♥9♥'],
  },
  single_suited_aces: {
    name: 'Single Suited Aces',
    description: 'Ace high with one suit',
    examples: ['A♠K♠Q♦J♣', 'A♠Q♠J♦T♣', 'A♠J♠9♦8♣'],
  },
  broadway_connectors: {
    name: 'Broadway Connectors',
    description: 'High cards with straight potential',
    examples: ['K♠Q♠J♦T♣', 'Q♠J♠T♦9♣', 'J♠T♠9♦8♣'],
  },
  suited_connectors: {
    name: 'Suited Connectors',
    description: 'Connected cards of the same suit',
    examples: ['T♠9♠8♦7♣', '9♠8♠7♦6♣', '8♠7♠6♦5♣'],
  },
  rundown_hands: {
    name: 'Rundown Hands',
    description: 'Four connected cards',
    examples: ['9♠8♠7♦6♣', '8♠7♠6♦5♣', '7♠6♠5♦4♣'],
  },
  ace_high_hands: {
    name: 'Ace High Hands',
    description: 'Ace with three other high cards',
    examples: ['A♠K♠Q♦J♣', 'A♠K♠J♦T♣', 'A♠Q♠J♦T♣'],
  },
};

// Position management utilities
export const getActivePositions = (playerCount: number): string[] => {
  // For PLO, always include Button, SB, BB as the last 3 positions
  if (playerCount <= 3) {
    return ['BTN', 'SB', 'BB'].slice(0, playerCount);
  }

  // For more players, include early positions + Button, SB, BB
  const earlyPositions = POSITION_ORDER.slice(0, playerCount - 3);
  return [...earlyPositions, 'BTN', 'SB', 'BB'];
};

// Card generation and validation utilities
export const generateRandomCards = generateRandomCardsFromExclude;

export const getUsedCards = (
  heroHoleCards: string[],
  boardCards: { flop: string[]; turn: string; river: string },
  boardCards2: { flop: string[]; turn: string; river: string },
  opponents: Array<{ useProfile?: boolean; holeCards: string[] }>,
  numBoards: number
): Set<string> => {
  const used = new Set<string>();

  // Hero cards
  heroHoleCards.forEach(card => {
    if (card) used.add(card);
  });

  // Board cards (first board)
  boardCards.flop.forEach(card => {
    if (card) used.add(card);
  });
  if (boardCards.turn) used.add(boardCards.turn);
  if (boardCards.river) used.add(boardCards.river);

  // Second board cards if double board
  if (numBoards === 2) {
    boardCards2.flop.forEach(card => {
      if (card) used.add(card);
    });
    if (boardCards2.turn) used.add(boardCards2.turn);
    if (boardCards2.river) used.add(boardCards2.river);
  }

  // Opponent cards (if specific cards are set)
  opponents.forEach(opp => {
    if (!opp.useProfile) {
      opp.holeCards.forEach(card => {
        if (card) used.add(card);
      });
    }
  });

  return used;
};

export const getUsedCardsExcluding = (
  position: any,
  heroHoleCards: string[],
  boardCards: { flop: string[]; turn: string; river: string },
  boardCards2: { flop: string[]; turn: string; river: string },
  opponents: Array<{ useProfile?: boolean; holeCards: string[] }>,
  numBoards: number
): Set<string> => {
  const used = new Set<string>();

  // Hero cards
  heroHoleCards.forEach((card, index) => {
    if (card && !(position.type === 'hero' && position.index === index)) {
      used.add(card);
    }
  });

  // Board cards (first board)
  boardCards.flop.forEach((card, index) => {
    if (
      card &&
      !(
        position.type === 'board' &&
        position.boardNumber === 1 &&
        position.boardType === 'flop' &&
        position.index === index
      )
    ) {
      used.add(card);
    }
  });
  if (
    boardCards.turn &&
    !(
      position.type === 'board' &&
      position.boardNumber === 1 &&
      position.boardType === 'turn'
    )
  ) {
    used.add(boardCards.turn);
  }
  if (
    boardCards.river &&
    !(
      position.type === 'board' &&
      position.boardNumber === 1 &&
      position.boardType === 'river'
    )
  ) {
    used.add(boardCards.river);
  }

  // Second board cards if double board
  if (numBoards === 2) {
    boardCards2.flop.forEach((card, index) => {
      if (
        card &&
        !(
          position.type === 'board' &&
          position.boardNumber === 2 &&
          position.boardType === 'flop' &&
          position.index === index
        )
      ) {
        used.add(card);
      }
    });
    if (
      boardCards2.turn &&
      !(
        position.type === 'board' &&
        position.boardNumber === 2 &&
        position.boardType === 'turn'
      )
    ) {
      used.add(boardCards2.turn);
    }
    if (
      boardCards2.river &&
      !(
        position.type === 'board' &&
        position.boardNumber === 2 &&
        position.boardType === 'river'
      )
    ) {
      used.add(boardCards2.river);
    }
  }

  // Opponent cards (if specific cards are set)
  opponents.forEach((opp, oppIndex) => {
    if (!opp.useProfile) {
      opp.holeCards.forEach((card, cardIndex) => {
        if (
          card &&
          !(
            position.type === 'opponent' &&
            position.oppIndex === oppIndex &&
            position.cardIndex === cardIndex
          )
        ) {
          used.add(card);
        }
      });
    }
  });

  return used;
};

export const isCardDuplicate = (
  card: string,
  position: any,
  heroHoleCards: string[],
  boardCards: { flop: string[]; turn: string; river: string },
  boardCards2: { flop: string[]; turn: string; river: string },
  opponents: Array<{ useProfile?: boolean; holeCards: string[] }>,
  numBoards: number
) => {
  if (!card || card === 'RANDOM') return false;
  const usedCardsExcluding = getUsedCardsExcluding(
    position,
    heroHoleCards,
    boardCards,
    boardCards2,
    opponents,
    numBoards
  );
  return usedCardsExcluding.has(card);
};

// Action validation utilities
export const isValidAction = (
  action: string,
  amount = 0,
  currentActionPlayer: number,
  playersInHand: Set<number>,
  currentBet: number,
  playerBets: Record<number, number>,
  bigBlind: number,
  maxBet: number
) => {
  // Basic validation - ensure player is in hand
  if (!playersInHand.has(currentActionPlayer)) {
    return false;
  }

  switch (action) {
    case 'fold':
      return true;
    case 'check':
      return currentBet === (playerBets[currentActionPlayer] || 0);
    case 'call':
      return currentBet > (playerBets[currentActionPlayer] || 0);
    case 'bet': {
      const minBet = bigBlind;
      return (
        (currentBet === 0 || currentBet === bigBlind) &&
        amount >= minBet &&
        amount <= maxBet
      );
    }
    case 'raise':
      return currentBet > 0 && amount > currentBet && amount <= maxBet;
    case 'all-in':
      return true;
    default:
      return false;
  }
};

export const getNextActivePlayer = (
  startFrom: number,
  playersInHand: Set<number>,
  numPlayers: number
) => {
  const totalPlayers = getActivePositions(numPlayers).length;
  for (let i = 1; i < totalPlayers; i++) {
    const nextPlayer = (startFrom + i) % totalPlayers;
    if (playersInHand.has(nextPlayer)) {
      return nextPlayer;
    }
  }
  return startFrom;
};

export const isBettingRoundComplete = (
  newPlayerBets: Record<number, number>,
  newPlayersInHand: Set<number>,
  newLastRaisePlayer: number,
  getPlayerStack: (playerIndex: number) => number
) => {
  const activePlayers = Array.from(newPlayersInHand);

  // If only one player remains, the hand is over
  if (activePlayers.length <= 1) {
    return true;
  }

  // All active players must have equal bets or be all-in
  const maxBet = Math.max(...activePlayers.map(p => newPlayerBets[p]));
  const allEqualOrAllIn = activePlayers.every(p => {
    const playerStack = getPlayerStack(p);
    return newPlayerBets[p] === maxBet || newPlayerBets[p] === playerStack;
  });

  // If there was a raise, action must return to the raiser
  if (newLastRaisePlayer !== -1) {
    const actionReturnedToRaiser = !newPlayersInHand.has(newLastRaisePlayer);
    return allEqualOrAllIn && actionReturnedToRaiser;
  }

  return allEqualOrAllIn;
};

// Board texture generation
export const generateTextureBoard = (
  textureKey: string,
  street: 'flop' | 'turn' | 'river' = 'flop',
  usedCards: Set<string> = new Set()
) => {
  const texture = (BOARD_TEXTURES as Record<string, { examples: string[][] }>)[
    textureKey
  ];
  if (!texture) return null;

  // Get a random example from the texture
  const examples = texture.examples;
  const randomExample = examples[Math.floor(Math.random() * examples.length)];

  // Start with the flop
  const newBoardCards = {
    flop: [...randomExample],
    turn: '',
    river: '',
  };

  // Generate turn and river if needed
  if (street === 'turn' || street === 'river') {
    const availableCards = generateDeck().filter(
      card => !usedCards.has(card) && !randomExample.includes(card)
    );

    if (availableCards.length > 0) {
      const turnCard =
        availableCards[Math.floor(Math.random() * availableCards.length)];
      newBoardCards.turn = turnCard;
      usedCards.add(turnCard);
    }

    if (street === 'river') {
      const remainingCards = generateDeck().filter(
        card => !usedCards.has(card)
      );
      if (remainingCards.length > 0) {
        const riverCard =
          remainingCards[Math.floor(Math.random() * remainingCards.length)];
        newBoardCards.river = riverCard;
      }
    }
  }

  return newBoardCards;
};

// Hero hand generation from categories
export const generateHeroHandFromCategory = (
  categoryKey: string,
  usedCards: Set<string> = new Set()
) => {
  const category = (
    HERO_HAND_CATEGORIES as Record<string, { examples: string[] }>
  )[categoryKey];
  if (!category) return ['', '', '', ''];

  // Get a random example from the category
  const examples = category.examples;
  const randomExample = examples[Math.floor(Math.random() * examples.length)];

  // Convert the example string to individual cards
  const cards = randomExample.split('');
  const heroCards = [];

  // Parse the example format (e.g., 'A♠K♠Q♦J♣')
  for (let i = 0; i < cards.length; i += 2) {
    if (i + 1 < cards.length) {
      heroCards.push(cards[i] + cards[i + 1]);
    }
  }

  // Check if any hero cards conflict with used cards
  const hasConflict = heroCards.some(card => usedCards.has(card));

  if (hasConflict) {
    // Try another example
    const alternativeExample =
      examples[(examples.indexOf(randomExample) + 1) % examples.length];
    const altCards = [];
    const altCardChars = alternativeExample.split('');

    for (let i = 0; i < altCardChars.length; i += 2) {
      if (i + 1 < altCardChars.length) {
        altCards.push(altCardChars[i] + altCardChars[i + 1]);
      }
    }

    const altHasConflict = altCards.some(card => usedCards.has(card));
    if (!altHasConflict) {
      return [...altCards, '', '', '', ''].slice(0, 4);
    } else {
      return ['', '', '', '']; // Return empty array instead of null
    }
  }

  return [...heroCards, '', '', '', ''].slice(0, 4);
};

// Re-export game utilities for backward compatibility
export { validateBetSize, calculateMaxBet } from './gameutils';
