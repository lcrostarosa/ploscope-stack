// Component prop types

export interface JobStatusPanelProps {
  onJobCompleted?: (job: import('./Job').Job) => void;
  onLoadSpotData?: (spotData: import('./SpotModeData').SpotModeData) => void;
  isActive?: boolean;
}

export type LoginProps = {
  onSwitchToRegister: () => void;
  onClose?: () => void;
};

export type LiveModeProps = {
  gameState: import('./GameStateTypes').LiveGameState;
  onGameStateChange: (
    newState: import('./GameStateTypes').LiveGameState
  ) => void;
  onAction: (action: string, amount?: number) => void;
  onReset: () => void;
  onSave: () => void;
  onLoad: () => void;
};

export interface GameConfig {
  setupMode: string;
  numPlayers: number;
  smallBlind: number;
  bigBlind: number;
  startingStack: number;
  isDoubleBoard: boolean;
  isBombPot: boolean;
  cardVariant: number;
}
