import React from 'react';

import type { LiveGameState } from '../../../types/GameStateTypes';
import { GameBoard } from '../../game';
import './BoardContainer.scss';

type BoardContainerProps = {
  gameState: LiveGameState;
  editMode?: boolean;
  onBoardCardClick?: (
    meta:
      | { boardType: 'topFlop' | 'bottomFlop'; flopIndex: number }
      | { boardType: 'topTurn' | 'bottomTurn' | 'topRiver' | 'bottomRiver' }
  ) => void;
};

const BoardContainer: React.FC<BoardContainerProps> = ({
  gameState,
  editMode,
  onBoardCardClick,
}) => {
  // Check if cards are dealt (any flop cards exist) and not in showdown phase
  const cardsAreDealt =
    gameState.topFlop.length > 0 || gameState.bottomFlop.length > 0;
  const isWaitingForNextHand = gameState.handPhase === 'showdown';

  // Show board and pot info only when cards are dealt and not waiting for next hand
  const shouldShowBoardAndPot = cardsAreDealt && !isWaitingForNextHand;

  // Show deal cards button when no cards are dealt and not waiting for next hand
  const shouldShowDealButton = !cardsAreDealt && !isWaitingForNextHand;

  if (shouldShowDealButton) {
    return (
      <div className="board-container" data-testid="board-container">
        <div className="deal-cards-section">
          <button
            className="deal-cards-button"
            onClick={() => {
              gameState.deal();
              // Scroll to the cards after dealing
              setTimeout(() => {
                const feltElement = document.querySelector('.felt');
                if (feltElement) {
                  feltElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'center',
                  });
                }
              }, 100);
            }}
            data-testid="deal-cards-button"
          >
            Deal Cards
          </button>
        </div>
      </div>
    );
  }

  if (!shouldShowBoardAndPot) {
    return null;
  }

  return (
    <GameBoard
      topFlop={gameState.topFlop}
      bottomFlop={gameState.bottomFlop}
      topTurn={gameState.topTurn ?? undefined}
      bottomTurn={gameState.bottomTurn ?? undefined}
      topRiver={gameState.topRiver ?? undefined}
      bottomRiver={gameState.bottomRiver ?? undefined}
      mainPot={gameState.mainPot}
      pot={gameState.pot}
      sidePots={gameState.sidePots}
      editMode={editMode}
      onBoardCardClick={onBoardCardClick}
    />
  );
};

export default BoardContainer;
