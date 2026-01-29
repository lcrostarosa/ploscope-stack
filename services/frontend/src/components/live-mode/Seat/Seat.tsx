import React from 'react';

import type { LiveGameState } from '../../../types/GameStateTypes';
import { Player } from '../../game';
import './Seat.scss';

type SeatProps = {
  i: number;
  cards: string[];
  chipStack: number;
  gameState: LiveGameState;
  editMode?: boolean;
  onPlayerCardClick?: (playerIndex: number, cardIndex: number) => void;
};

const Seat: React.FC<SeatProps> = ({
  i,
  cards,
  chipStack,
  gameState,
  editMode,
  onPlayerCardClick,
}) => {
  const invested = gameState.playerInvested[i];
  // Calculate current bet (excluding ante)
  // If pot > 0, ante was collected (1BB per player), so subtract it
  const anteAmount = gameState.pot > 0 ? 1 : 0;
  const currentBet = Math.max(0, invested - anteAmount);
  const showChips = currentBet > 0 && !gameState.foldedPlayers?.has(i);
  const isRemoved = gameState.removedSeats?.has(i) || false;
  const hasCards = cards && cards.length > 0 && cards.some(c => c);

  // If seat is removed and no cards, show add back button
  if (isRemoved && !hasCards) {
    return (
      <div className={`seat seat-${i} removed-seat`}>
        <div className="add-back-seat-container">
          <button
            className="add-back-seat-btn"
            onClick={() => gameState.addBackSeat(i)}
            title="Add seat back"
          >
            <span className="add-icon">↩️</span>
            <span className="add-text">Add Seat {i + 1}</span>
          </button>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`seat seat-${i} ${
        i === gameState.activePlayer ? 'active-seat' : ''
      }`}
    >
      {editMode && hasCards && !isRemoved && (
        <button
          className="remove-seat-btn"
          onClick={() => gameState.removeSeat(i)}
          title="Remove seat"
        >
          🗑️
        </button>
      )}
      {showChips && (
        <div className="player-chips">
          <span className="chips-icon">🪙</span>
          <span className="chips-amount">{currentBet}</span>
        </div>
      )}
      <Player
        index={i}
        cards={cards}
        equities={gameState.equities}
        isLoading={gameState.isLoading}
        isDealer={i === gameState.dealerPosition}
        isActivePlayer={i === gameState.activePlayer}
        isFolded={gameState.foldedPlayers?.has(i) || false}
        isAllIn={gameState.allInPlayers?.has(i) || false}
        onPlayerAction={gameState.handlePlayerAction}
        onRebuy={() => gameState.rebuyPlayer(i)}
        defaultStackSize={gameState.defaultStackSize}
        hasBetThisRound={gameState.hasBetThisRound}
        chipStack={chipStack}
        invested={gameState.playerInvested[i]}
        currentBet={gameState.currentBet}
        showBetInput={gameState.showBetInput}
        betInputValue={gameState.betInputValue}
        onBetInputChange={gameState.setBetInputValue}
        onBetInputSubmit={gameState.handleBetInputSubmit}
        onBetInputCancel={gameState.handleBetInputCancel}
        calculateMaxBet={gameState.calculateMaxBet}
        calculateMaxRaise={gameState.calculateMaxRaise}
        calculateMinRaise={gameState.calculateMinRaise}
        cardsHidden={gameState.cardsHidden}
        isRevealed={gameState.revealedPlayers?.has(i) || false}
        onToggleReveal={() => gameState.togglePlayerReveal(i)}
        potSize={gameState.pot}
        isWinner={gameState.winner === i}
        showWinnerNotification={gameState.showWinnerNotification}
        editMode={editMode}
        onEditCard={onPlayerCardClick}
      />
    </div>
  );
};

export default Seat;
