import React, { useEffect, useRef, useState } from 'react';

import './GameControlButtons.scss';
import type { LiveGameState } from '../../../types/GameStateTypes';

type GameControlButtonsProps = {
  gameState: LiveGameState;
  handleResetGameConfig: () => void;
  onEditCards?: () => void;
  isEditingCards?: boolean;
  onStudySpot?: () => void;
};

const GameControlButtons: React.FC<GameControlButtonsProps> = ({
  gameState,
  handleResetGameConfig,
  onEditCards,
  isEditingCards,
  onStudySpot,
}) => {
  const [isDealing, setIsDealing] = useState(false);
  const [canStudy, setCanStudy] = useState(false);
  const [showChipControls, setShowChipControls] = useState(false);
  const [chipControlMode, setChipControlMode] = useState<'set' | 'reduce'>(
    'set'
  );
  const [amountType, setAmountType] = useState<'percent' | 'bb'>('percent');
  const popoverRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const onClickAway = (e: MouseEvent) => {
      if (
        popoverRef.current &&
        !popoverRef.current.contains(e.target as Node)
      ) {
        setShowChipControls(false);
      }
    };
    document.addEventListener('click', onClickAway);
    return () => document.removeEventListener('click', onClickAway);
  }, []);

  const handleDeal = async () => {
    setIsDealing(true);
    // Add a small delay to show the loading state
    await new Promise(resolve => setTimeout(resolve, 300));
    gameState.deal();
    setIsDealing(false);

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
  };

  // Update study availability and bind keyboard shortcut
  useEffect(() => {
    const hasAnyCards = gameState.players.some(
      (player: any) => player.cards && player.cards.length > 0
    );
    setCanStudy(hasAnyCards);
  }, [gameState.players]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key?.toLowerCase() === 's' && canStudy && onStudySpot) {
        e.preventDefault();
        onStudySpot();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [canStudy, onStudySpot]);

  return (
    <div className="button-group">
      <button
        className={`deal-button ${isDealing ? 'dealing' : ''}`}
        onClick={handleDeal}
        disabled={isDealing}
      >
        {isDealing ? '🃏 Dealing...' : 'Deal Cards'}
      </button>
      <button className="deal-button" onClick={gameState.nextHand}>
        Next Hand
      </button>
      <button
        className={`deal-button edit-cards-btn ${isEditingCards ? 'active' : ''}`}
        onClick={onEditCards}
        disabled={!canStudy}
        title={
          canStudy
            ? isEditingCards
              ? 'Editing mode active: click any card to change'
              : 'Enable editing: click any card to change'
            : 'Deal cards first to enable card editing'
        }
      >
        {isEditingCards ? '✅ Done Editing' : '✏️ Edit Cards'}
      </button>
      <div className="study-spot-wrapper">
        <button
          className="deal-button study-spot-btn"
          onClick={onStudySpot}
          disabled={!canStudy}
          title={
            canStudy
              ? 'Analyze current spot (S)'
              : 'Deal cards first to enable spot analysis'
          }
          data-testid="study-this-spot-button"
        >
          📊 Study This Spot
        </button>
        {/* Floating CTA removed; action panel is fixed bottom-right */}
      </div>
      {/* Single chip control button with mode and amount type selection */}
      <div className="chip-controls-inline">
        <div className="chip-popover" ref={popoverRef}>
          <button
            className="deal-button"
            onClick={e => {
              e.stopPropagation();
              setShowChipControls(v => !v);
            }}
          >
            {chipControlMode === 'set' ? 'Set Chips' : 'Reduce Chips'}
          </button>
          {showChipControls && (
            <div className="chip-popover-content">
              {/* Mode Selection */}
              <div className="mode-selection">
                <label>Action:</label>
                <div className="mode-buttons">
                  <button
                    className={`mode-btn ${chipControlMode === 'set' ? 'active' : ''}`}
                    onClick={() => setChipControlMode('set')}
                  >
                    Set All
                  </button>
                  <button
                    className={`mode-btn ${chipControlMode === 'reduce' ? 'active' : ''}`}
                    onClick={() => setChipControlMode('reduce')}
                  >
                    Reduce
                  </button>
                </div>
              </div>

              {/* Amount Type Selection */}
              <div className="amount-type-selection">
                <label>Amount Type:</label>
                <div className="type-buttons">
                  <button
                    className={`type-btn ${amountType === 'percent' ? 'active' : ''}`}
                    onClick={() => setAmountType('percent')}
                  >
                    %
                  </button>
                  <button
                    className={`type-btn ${amountType === 'bb' ? 'active' : ''}`}
                    onClick={() => setAmountType('bb')}
                  >
                    BB
                  </button>
                </div>
              </div>

              {/* Input Field */}
              <div className="input-section">
                <label htmlFor="chipAmount">
                  {chipControlMode === 'set'
                    ? `Stack Size (${amountType === 'percent' ? '%' : 'BB'})`
                    : `Reduction (${amountType === 'percent' ? '%' : 'BB'})`}
                </label>
                <input
                  id="chipAmount"
                  type="number"
                  value={
                    chipControlMode === 'set'
                      ? gameState.defaultStackSize
                      : gameState.chipReductionPercentage
                  }
                  onChange={e => {
                    const value = parseInt(e.target.value) || 0;
                    if (chipControlMode === 'set') {
                      gameState.setDefaultStackSize(value);
                    } else {
                      gameState.setChipReductionPercentage(value);
                    }
                  }}
                  min={1}
                  max={amountType === 'percent' ? 99 : 10000}
                />
              </div>

              {/* Apply Button */}
              <button
                className="deal-button"
                onClick={e => {
                  e.stopPropagation();
                  if (chipControlMode === 'set') {
                    gameState.setAllChipStacks();
                  } else {
                    gameState.reduceAllChips();
                  }
                  setShowChipControls(false);
                }}
              >
                Apply
              </button>
            </div>
          )}
        </div>
      </div>
      <button
        className={`visibility-button ${
          gameState.cardsHidden ? 'cards-hidden' : 'cards-visible'
        }`}
        onClick={gameState.toggleGlobalCardVisibility}
      >
        {gameState.cardsHidden ? '👁️ Show All Cards' : '🔒 Hide All Cards'}
      </button>
    </div>
  );
};

export default GameControlButtons;
