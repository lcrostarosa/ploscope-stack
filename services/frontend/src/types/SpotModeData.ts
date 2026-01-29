export type SpotModeData = {
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
  spotResults?: unknown;
};





