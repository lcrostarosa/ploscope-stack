// Enhanced utility for serializing and deserializing the common game state format
// Supports cross-mode compatibility between Live Mode and Spot Mode
import { logError } from './logger';

export function serializeGameState({
  heroCards,
  opponentCards,
  foldedCards,
  numRandomOpponents,
  heroStack,
  opponentStacks,
  street,
  potSize,
  currentBet,
  actionSequence,
  players,
  activePlayers,
  foldedPlayers,
  allInPlayers,
  playerBets,
  lastRaisePlayer,
  lastRaiseAmount,
  currentActionPlayer,
  bettingRoundComplete,
  dealerPosition,
  cardsHidden,
  revealedPlayers,
  sidePots,
  mainPot,
  winner,
  showWinnerNotification,
  // Enhanced game logic state
  gameLogicState,
  // Community cards (flat structure)
  topFlop,
  topTurn,
  topRiver,
  bottomFlop,
  bottomTurn,
  bottomRiver,
  // Additional state for cross-mode compatibility
  foldedStates,
  currentStreet,
  // Legacy support for tests
  mode,
  timestamp,
  ...rest
}: Record<string, unknown>) {
  return JSON.stringify({
    heroCards,
    opponentCards,
    foldedCards,
    numRandomOpponents,
    heroStack,
    opponentStacks,
    street,
    potSize,
    currentBet,
    actionSequence,
    players,
    activePlayers,
    foldedPlayers,
    allInPlayers,
    playerBets,
    lastRaisePlayer,
    lastRaiseAmount,
    currentActionPlayer,
    bettingRoundComplete,
    dealerPosition,
    cardsHidden,
    revealedPlayers,
    sidePots,
    mainPot,
    winner,
    showWinnerNotification,
    // Enhanced game logic state
    gameLogicState,
    // Community cards (flat structure)
    topFlop,
    topTurn,
    topRiver,
    bottomFlop,
    bottomTurn,
    bottomRiver,
    // Additional state for cross-mode compatibility
    foldedStates,
    currentStreet,
    // Legacy support for tests
    mode,
    fromSpotMode: true,
    timestamp: timestamp || Date.now(),
    ...rest,
  });
}

export function deserializeGameState(data: string | null) {
  try {
    if (!data) return null;
    const parsed = JSON.parse(data);

    // Convert arrays back to Sets for player collections
    if (parsed.activePlayers && Array.isArray(parsed.activePlayers)) {
      parsed.activePlayers = new Set(parsed.activePlayers);
    }
    if (parsed.foldedPlayers && Array.isArray(parsed.foldedPlayers)) {
      parsed.foldedPlayers = new Set(parsed.foldedPlayers);
    }
    if (parsed.allInPlayers && Array.isArray(parsed.allInPlayers)) {
      parsed.allInPlayers = new Set(parsed.allInPlayers);
    }
    if (parsed.revealedPlayers && Array.isArray(parsed.revealedPlayers)) {
      parsed.revealedPlayers = new Set(parsed.revealedPlayers);
    }

    return parsed;
  } catch (e) {
    logError('Failed to parse game state:', e);
    return null;
  }
}

// Player type used across all game modes
export interface Player {
  id: number;
  position: number;
  stack: number;
  cards: string[];
  isInHand: boolean;
  isAllIn: boolean;
  bet: number;
  invested: number;
}

// Unified game state structure that works for all modes
export interface UnifiedGameState extends Record<string, unknown> {
  // Core card data
  heroCards: string[];
  opponentCards: string[][];

  // Community cards (flat structure)
  topFlop: string[];
  topTurn: string;
  topRiver: string;
  bottomFlop: string[];
  bottomTurn: string;
  bottomRiver: string;

  foldedCards: string[];

  // Game state
  numRandomOpponents: number;
  heroStack: number;
  opponentStacks: number[];
  street: string;
  actionSequence: unknown[];
  potSize: number;
  currentBet: number;
  playerBets: Record<number, number>;
  lastRaisePlayer: number;
  lastRaiseAmount: number;
  currentActionPlayer: number;
  bettingRoundComplete: boolean;
  dealerPosition: number;
  cardsHidden: boolean;
  revealedPlayers: Set<number>;
  sidePots: unknown[];
  mainPot: number;
  winner: unknown;
  showWinnerNotification: boolean;

  // Player management
  players: Player[];
  activePlayers: Set<number>;
  foldedPlayers: Set<number>;
  allInPlayers: Set<number>;

  // Folded states
  foldedStates: {
    opponents: boolean[];
    topBoard: boolean;
    bottomBoard: boolean;
  };

  // Additional metadata
  heroPosition?: string;
}

export type GameModeInput = {
  // ============ PLAYER CARDS ============
  // SpotMode style
  heroCards?: string[];
  opponentCards?: string[][];

  // LiveMode style (unified players array)
  players?: Array<{ cards?: string[]; stack?: number }>;
  foldedPlayers?: Set<number> | number[];

  // Legacy style
  heroHoleCards?: string[];
  opponents?: Array<{ holeCards?: string[]; stack?: number }>;

  // Common
  foldedCards?: string[];

  // ============ COMMUNITY CARDS ============
  // Flat structure (used by all modes)
  topFlop?: string[];
  bottomFlop?: string[];
  topTurn?: string;
  bottomTurn?: string;
  topRiver?: string;
  bottomRiver?: string;

  // ============ STACK SIZES ============
  heroStack?: number; // SpotMode
  heroStackSize?: number; // Legacy
  opponentStacks?: number[];
  numRandomOpponents?: number;

  // ============ BETTING STATE ============
  street?: string;
  actionSequence?: unknown[];

  // Pot (different names)
  potSize?: number; // SpotMode
  pot?: number; // LiveMode

  currentBet?: number;

  // Player bets/investment (different names)
  playerBets?: Record<number, number>; // SpotMode
  playerInvested?: Record<number, number>; // LiveMode

  lastRaisePlayer?: number;
  lastRaiseAmount?: number;

  currentActionPlayer?: number; // SpotMode
  activePlayer?: number; // LiveMode

  // Betting round complete (different names)
  bettingRoundComplete?: boolean; // SpotMode
  actionComplete?: boolean; // LiveMode

  // ============ UI STATE ============
  dealerPosition?: number;
  cardsHidden?: boolean;
  revealedPlayers?: Set<number> | number[];

  // ============ POT TRACKING ============
  sidePots?: unknown[];
  mainPot?: number;

  // ============ GAME OUTCOME ============
  winner?: unknown;
  showWinnerNotification?: boolean;

  // ============ FOLDED STATE ============
  foldedStates?: {
    opponents: boolean[];
    topBoard: boolean;
    bottomBoard: boolean;
  };
};

// Helper function to determine street based on board cards
function determineStreet(
  topFlop?: string[],
  topTurn?: string,
  topRiver?: string,
  bottomFlop?: string[],
  bottomTurn?: string,
  bottomRiver?: string
): string {
  if (topRiver || bottomRiver) return 'river';
  if (topTurn || bottomTurn) return 'turn';
  if (
    (topFlop && topFlop.some(card => card)) ||
    (bottomFlop && bottomFlop.some(card => card))
  )
    return 'flop';
  return 'preflop';
}

// Unified function to create game state from any mode
export function createUnifiedGameState(input: GameModeInput): UnifiedGameState {
  // Extract player data from whatever format is provided
  let heroCards: string[];
  let opponentCards: string[][];
  let heroStack: number;
  let opponentStacks: number[];
  let foldedCards: string[];

  if (input.players) {
    // LiveMode format: unified players array
    const players = input.players;
    heroCards = players[0]?.cards || ['', '', '', ''];
    opponentCards = players.slice(1).map(p => p.cards || ['', '', '', '']);
    heroStack = players[0]?.stack || 200;
    opponentStacks = players.slice(1).map(p => p.stack || 200);
    foldedCards = Array.from(
      (input.foldedPlayers as Set<number> | number[]) || []
    )
      .flatMap((playerId: number) => players[playerId]?.cards || [])
      .filter((card: string) => card && card !== '');
  } else if (input.opponents) {
    // Legacy format: heroHoleCards + opponents array
    heroCards = input.heroHoleCards || ['', '', '', ''];
    opponentCards = input.opponents.map(
      opp => opp.holeCards || ['', '', '', '']
    );
    heroStack = input.heroStackSize || input.heroStack || 200;
    opponentStacks = input.opponents.map(opp => opp.stack || 200);
    foldedCards = input.foldedCards || [];
  } else {
    // SpotMode format: heroCards + opponentCards arrays
    heroCards = input.heroCards || ['', '', '', ''];
    opponentCards = input.opponentCards || [];
    heroStack = input.heroStack || 200;
    opponentStacks = input.opponentStacks || [];
    foldedCards = input.foldedCards || [];
  }

  // Normalize field name variations (use whichever is provided)
  const potSize = input.potSize ?? input.pot ?? 0;
  const playerBets = input.playerBets ?? input.playerInvested ?? {};
  const currentActionPlayer =
    input.currentActionPlayer ?? input.activePlayer ?? 0;
  const bettingRoundComplete =
    input.bettingRoundComplete ?? input.actionComplete ?? false;
  const street =
    input.street ||
    determineStreet(
      input.topFlop,
      input.topTurn,
      input.topRiver,
      input.bottomFlop,
      input.bottomTurn,
      input.bottomRiver
    );

  // Build folded states
  const foldedStates = input.foldedStates || {
    opponents: opponentCards.map((_, index) => {
      if (input.foldedPlayers) {
        const foldedSet = input.foldedPlayers as Set<number> | number[];
        return Array.isArray(foldedSet)
          ? foldedSet.includes(index + 1)
          : foldedSet.has(index + 1);
      }
      return false;
    }),
    topBoard: false,
    bottomBoard: false,
  };

  // Create players array with enhanced information
  const players: Player[] = [];
  const activePlayers = new Set<number>();
  const stateFoldedPlayers = new Set<number>();
  const allInPlayers = new Set<number>();

  // Add hero
  players.push({
    id: 0,
    position: 0,
    stack: heroStack,
    cards: heroCards,
    isInHand: true,
    isAllIn: false,
    bet: 0,
    invested: 0,
  });
  activePlayers.add(0);

  // Add opponents
  opponentCards.forEach((cards: string[], index: number) => {
    const playerId = index + 1;
    const isFolded = foldedStates.opponents[index] || false;

    players.push({
      id: playerId,
      position: playerId,
      stack: opponentStacks[index] || 200,
      cards: cards,
      isInHand: !isFolded,
      isAllIn: false,
      bet: 0,
      invested: 0,
    });

    if (isFolded) {
      stateFoldedPlayers.add(playerId);
    } else {
      activePlayers.add(playerId);
    }
  });

  return {
    heroCards,
    opponentCards,
    topFlop: input.topFlop || ['', '', ''],
    topTurn: input.topTurn || '',
    topRiver: input.topRiver || '',
    bottomFlop: input.bottomFlop || ['', '', ''],
    bottomTurn: input.bottomTurn || '',
    bottomRiver: input.bottomRiver || '',
    foldedCards,
    numRandomOpponents: input.numRandomOpponents || 0,
    heroStack,
    opponentStacks,
    street,
    actionSequence: input.actionSequence || [],
    potSize,
    currentBet: input.currentBet || 0,
    playerBets,
    lastRaisePlayer: input.lastRaisePlayer ?? -1,
    lastRaiseAmount: input.lastRaiseAmount || 0,
    currentActionPlayer,
    bettingRoundComplete,
    dealerPosition: input.dealerPosition || 0,
    cardsHidden: input.cardsHidden || false,
    revealedPlayers:
      input.revealedPlayers instanceof Set
        ? input.revealedPlayers
        : new Set(input.revealedPlayers || []),
    sidePots: input.sidePots || [],
    mainPot: input.mainPot || 0,
    winner: input.winner || null,
    showWinnerNotification: input.showWinnerNotification || false,
    players,
    activePlayers,
    foldedPlayers: stateFoldedPlayers,
    allInPlayers,
    foldedStates,
    heroPosition: 'BTN',
  };
}

// Function to persist game state to session storage
export function persistGameState(
  state: Record<string, unknown>,
  mode: string = 'spotMode'
) {
  try {
    const serializedState = serializeGameState({
      ...state,
      mode,
      timestamp: Date.now(),
    });
    sessionStorage.setItem('persistedGameState', serializedState);
    return true;
  } catch (error) {
    logError('Failed to persist game state:', error);
    return false;
  }
}

// Function to restore game state from session storage
export function restoreGameState() {
  try {
    const serializedState = sessionStorage.getItem('persistedGameState');
    if (!serializedState) return null;

    return deserializeGameState(serializedState);
  } catch (error) {
    logError('Failed to restore game state:', error);
    return null;
  }
}

// Function to clear persisted game state
export function clearPersistedGameState() {
  try {
    sessionStorage.removeItem('persistedGameState');
    return true;
  } catch (error) {
    logError('Failed to clear persisted game state:', error);
    return false;
  }
}
