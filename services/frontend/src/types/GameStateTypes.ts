// Game state related types

export type ModeInfo = {
  isLiveMode: boolean;
  isSpotMode: boolean;
};

export interface GameState {
  players: Array<{ stack: number; invested: number; cards: string[] }>;
  activePlayers: Set<number>;
  foldedPlayers: Set<number>;
  allInPlayers: Set<number>;
  topFlop: string[];
  topTurn: string;
  topRiver: string;
  bottomFlop: string[];
  bottomTurn: string;
  bottomRiver: string;
  potSize: number;
  currentBet: number;
  playerBets: Record<number, number>;
  lastRaisePlayer: number;
  lastRaiseAmount: number;
  currentStreet: 'preflop' | 'flop' | 'turn' | 'river';
  currentActionPlayer: number;
  bettingRoundComplete: boolean;
  dealerPosition: number;
  actionSequence: Array<{
    playerId: number;
    action: 'fold' | 'check' | 'call' | 'bet' | 'raise' | 'allin';
    amount: number;
    street: 'preflop' | 'flop' | 'turn' | 'river';
  }>;
  foldedCards: string[];
  sidePots: Array<{
    potNumber: number;
    size: number;
    players: number[];
  }>;
  mainPot: {
    potNumber: number;
    size: number;
    players: number[];
  };
  cardsHidden: boolean;
  revealedPlayers: Set<number>;
  winner: { playerId: number } | null;
  showWinnerNotification: boolean;
  street: 'preflop' | 'flop' | 'turn' | 'river';
  numRandomOpponents: number;
  heroStack: number;
  opponentStacks: number[];
  foldedStates: {
    opponents: boolean[];
    topBoard: boolean;
    bottomBoard: boolean;
  };
}

export type ImportedState = {
  config?: Partial<{
    numPlayers: number;
    smallBlind: number;
    bigBlind: number;
    startingStack: number;
    isDoubleBoard: boolean;
    isBombPot: boolean;
    cardVariant: number;
  }>;
  gameState?:
    | (Partial<
        Omit<
          GameState,
          'activePlayers' | 'foldedPlayers' | 'allInPlayers' | 'revealedPlayers'
        >
      > & {
        activePlayers?: number[];
        foldedPlayers?: number[];
        allInPlayers?: number[];
        revealedPlayers?: number[];
      })
    | undefined;
  spotData?: {
    heroCards: string[];
    opponentCards: string[][];
    communityCards: {
      topFlop: string[];
      bottomFlop: string[];
      topTurn: string;
      bottomTurn: string;
      topRiver: string;
      bottomRiver: string;
    };
    foldedCards: string[];
    foldedStates: {
      opponents: boolean[];
      topBoard: boolean;
      bottomBoard: boolean;
    };
    simulationRuns: number;
    maxHandCombinations: number;
  };
};

// Additional types that were previously in solver.ts
export type PlayerEquity = {
  top_estimated: string; // percentage string with one decimal
  top_actual: string; // percentage string with one decimal
  bottom_estimated: string; // percentage string with one decimal
  bottom_actual: string; // percentage string with one decimal
  chop_both_boards: string; // percentage string with one decimal
  scoop_both_boards: string; // percentage string with one decimal
  split_top: string; // percentage string with one decimal
  split_bottom: string; // percentage string with one decimal
  // Optional: backend may provide hand categories per board
  top_hand_category?: string;
  bottom_hand_category?: string;
};

export type Equities = Array<PlayerEquity | null>;

export type SidePot = { amount: number; eligiblePlayers: number[] };

export type PlayerState = { cards: string[]; isInHand: boolean };

export type LiveGameState = {
  // State
  players: PlayerState[];
  numActivePlayers: number;
  topFlop: string[];
  bottomFlop: string[];
  topTurn: string | null;
  bottomTurn: string | null;
  topRiver: string | null;
  bottomRiver: string | null;
  isLoading: boolean;
  equities: Equities;
  dealerPosition: number;
  activePlayer: number | null;
  foldedPlayers: Set<number>;
  handPhase: 'preflop' | 'flop' | 'turn' | 'river' | 'showdown';
  actionComplete: boolean;
  actionSequence: Array<{
    playerId: number;
    action: string;
    amount: number;
    street: string;
  }>;
  lastPlayerToAct: number | null;
  hasBetThisRound: boolean;
  playersActed: Set<number>;
  chipStacks: number[];
  defaultStackSize: number;
  pot: number;
  currentBet: number;
  lastRaiseAmount: number;
  showBetInput: number | null;
  betInputValue: number;
  playerInvested: number[];
  sidePots: SidePot[];
  allInPlayers: Set<number>;
  mainPot: number;
  chipReductionPercentage: number;
  setChipReductionPercentage: (value: number) => void;
  cardsHidden: boolean;
  revealedPlayers: Set<number>;
  error: string | null;
  removedSeats: Set<number>;

  // Actions (only those consumed by components)
  setAllChipStacks: () => void;
  setChipStacks: (stacks: number[]) => void;
  setNumActivePlayers: (count: number) => void;
  collectAntes: () => void;
  calculateMaxBet: (playerIndex: number) => number;
  calculateMaxRaise: (playerIndex: number) => number;
  calculateMinRaise: () => number;
  deal: () => void;
  nextHand: () => void;
  handleBetInputSubmit: (playerIndex: number, action: 'bet' | 'raise') => void;
  handleBetInputCancel: () => void;
  rebuyPlayer: (playerIndex: number) => void;
  reduceAllChips: () => void;
  toggleGlobalCardVisibility: () => void;
  togglePlayerReveal: (playerIndex: number) => void;
  handlePlayerAction: (
    playerIndex: number,
    action: 'fold' | 'call' | 'check' | 'bet' | 'raise',
    betAmount?: number
  ) => void;
  setBetInputValue: (newValue: number) => void;
  setDefaultStackSize: (value: number) => void;
  resetAuthState: () => void;
  distributePot: () => void;
  awardPotToWinner: (winnerIndex: number) => void;
  winner: number | null;
  showWinnerNotification: boolean;
  removeSeat: (seatIndex: number) => void;
  addBackSeat: (seatIndex: number) => void;
  dealTurn: () => void;
  dealRiver: () => void;
};
