import React from 'react';
import './ActionButtons.scss';

export type PlayerAction = 'fold' | 'call' | 'check' | 'bet' | 'raise';

export interface ActionButtonsProps {
  activePlayer: number | null;
  showBetInput: number | null;
  currentBet: number;
  playerInvested: number[];
  foldedPlayers: Set<number>;
  allInPlayers: Set<number>;
  onPlayerAction: (playerIndex: number, action: PlayerAction) => void;
}

export const ActionButtons: React.FC<ActionButtonsProps> = ({
  activePlayer,
  showBetInput,
  currentBet,
  playerInvested,
  foldedPlayers,
  allInPlayers,
  onPlayerAction,
}) => {
  if (activePlayer === null || showBetInput !== null) return null;

  const playerIndex = activePlayer;
  const needsToCall = currentBet > playerInvested[playerIndex];
  const callAmount = currentBet - playerInvested[playerIndex];
  const shouldShowActionButtons =
    !foldedPlayers.has(playerIndex) && !allInPlayers.has(playerIndex);

  if (!shouldShowActionButtons) return null;

  return (
    <div className="centralized-action-buttons" data-testid="action-buttons">
      <div className="action-buttons-header">
        <strong>Player {activePlayer + 1} Action</strong>
        <div className="keyboard-hints-tooltip">
          <span className="help-icon">?</span>
          <div className="tooltip-content">
            <div>C = Check</div>
            <div>B = Bet</div>
            <div>F = Fold</div>
          </div>
        </div>
      </div>
      <div className="action-buttons">
        {needsToCall ? (
          <>
            <button
              className="action-btn call-btn"
              onClick={() => onPlayerAction(activePlayer, 'call')}
            >
              Call {callAmount}
            </button>
            <button
              className="action-btn raise-btn"
              onClick={() => onPlayerAction(activePlayer, 'raise')}
            >
              Raise
            </button>
          </>
        ) : (
          <>
            <button
              className="action-btn check-btn"
              onClick={() => onPlayerAction(activePlayer, 'check')}
            >
              Check
            </button>
            <button
              className="action-btn bet-btn"
              onClick={() => onPlayerAction(activePlayer, 'bet')}
            >
              Bet
            </button>
          </>
        )}
        <button
          className="action-btn fold-btn"
          onClick={() => onPlayerAction(activePlayer, 'fold')}
        >
          Fold
        </button>
      </div>
    </div>
  );
};
