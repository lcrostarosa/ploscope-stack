import React, {
  useCallback,
  useMemo,
  useState,
  memo,
  useEffect,
  useRef,
} from 'react';

import type { Equities } from '../../types/GameStateTypes';
import { Card } from '../ui';

import BetInput from './BetInput';
import EquitySection from './EquitySection';

type PlayerProps = {
  cards: string[];
  index: number;
  equities: Equities;
  isLoading: boolean;
  isDealer: boolean;
  isActivePlayer: boolean;
  onPlayerAction: any;
  isFolded: boolean;
  isAllIn: boolean;
  // onPlayerAction: (playerIndex: number, action: 'fold'|'call'|'check'|'bet'|'raise') => void; // TODO: Implement player action handling
  onRebuy: () => void;
  defaultStackSize: number;
  hasBetThisRound: boolean;
  chipStack: number;
  invested: number;
  currentBet: number;
  showBetInput: number | null;
  betInputValue: number;
  onBetInputChange: (_value: number) => void;
  onBetInputSubmit: (_playerIndex: number, _action: 'bet' | 'raise') => void;
  onBetInputCancel: () => void;
  calculateMaxBet: (_playerIndex: number) => number;
  calculateMaxRaise: (_playerIndex: number) => number;
  calculateMinRaise: () => number;
  cardsHidden: boolean;
  isRevealed: boolean;
  onToggleReveal: () => void;
  potSize: number;
  isWinner: boolean;
  showWinnerNotification: boolean;
  editMode?: boolean;
  onEditCard?: (playerIndex: number, cardIndex: number) => void;
};

const Player: React.FC<PlayerProps> = memo(
  ({
    cards,
    index,
    equities,
    isLoading,
    isDealer,
    isActivePlayer,
    isFolded,
    isAllIn,
    onRebuy,
    onPlayerAction,
    defaultStackSize,
    hasBetThisRound,
    chipStack,
    invested,
    currentBet,
    showBetInput,
    betInputValue,
    onBetInputChange,
    onBetInputSubmit,
    onBetInputCancel,
    calculateMaxBet,
    calculateMaxRaise,
    calculateMinRaise,
    cardsHidden,
    isRevealed,
    onToggleReveal,
    potSize,
    isWinner,
    showWinnerNotification,
    editMode,
    onEditCard,
  }) => {
    // Memoize EV calculations
    const calculateEV = useCallback(
      (action: 'fold' | 'call' | 'raise', amount: number = 0) => {
        if (!equities?.[index]) return null;

        const totalEquity = parseFloat(equities[index].top_actual) / 100;

        switch (action) {
          case 'fold': {
            // The money already invested is a sunk cost, especially in bomb pot scenarios
            return 0;
          }
          case 'call': {
            const callAmount = currentBet - invested;
            return totalEquity * (potSize + callAmount) - callAmount;
          }
          case 'raise': {
            const raiseAmount = amount - invested;
            return totalEquity * (potSize + raiseAmount) - raiseAmount;
          }
          default:
            return null;
        }
      },
      [equities, index, currentBet, invested, potSize]
    );

    // Memoize EV formatting
    const formatEV = useCallback((ev: number | null) => {
      if (ev === null) return 'N/A';
      return `${ev.toFixed(2)} BB`;
    }, []);

    // Memoize pot odds calculation
    const calculatePotOdds = useCallback(
      (amount: number) => {
        if (!amount || amount <= 0) return null;
        const odds = amount / (potSize + amount);
        return (odds * 100).toFixed(1);
      },
      [potSize]
    );

    // Memoize pot odds formatting
    const formatPotOdds = useCallback((odds: string | null) => {
      if (odds === null) return 'N/A';
      return `${odds}%`;
    }, []);

    // Extract current hand categories (if backend supplied via equities)
    const topCategory = (equities?.[index] as any)?.top_hand_category as
      | string
      | undefined;
    const bottomCategory = (equities?.[index] as any)?.bottom_hand_category as
      | string
      | undefined;

    // Memoize computed values
    const computedValues = useMemo(() => {
      const needsToCall = currentBet > invested;
      const callAmount = currentBet - invested;

      // Show cards if:
      // 1. Cards are globally visible (!cardsHidden)
      // 2. This player's cards are individually revealed (isRevealed)
      const shouldShowCards = !cardsHidden || isRevealed;

      const foldEV = calculateEV('fold');
      const callEV = calculateEV('call');
      const raiseEV = calculateEV('raise', betInputValue);
      const callPotOdds = calculatePotOdds(callAmount);
      const raisePotOdds = calculatePotOdds(betInputValue - invested);

      return {
        needsToCall,
        callAmount,
        shouldShowCards,
        foldEV,
        callEV,
        raiseEV,
        callPotOdds,
        raisePotOdds,
      };
    }, [
      currentBet,
      invested,
      cardsHidden,
      isRevealed,
      calculateEV,
      betInputValue,
      calculatePotOdds,
    ]);

    // Collapsible stats
    const [showStats, setShowStats] = useState(false);
    const statsRef = useRef<HTMLDivElement>(null);

    // Handle escape key and click away
    useEffect(() => {
      if (!showStats) return;

      const handleEscape = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          setShowStats(false);
        }
      };

      const handleClickAway = (e: MouseEvent) => {
        if (statsRef.current && !statsRef.current.contains(e.target as Node)) {
          setShowStats(false);
        }
      };

      document.addEventListener('keydown', handleEscape);
      document.addEventListener('mousedown', handleClickAway);

      return () => {
        document.removeEventListener('keydown', handleEscape);
        document.removeEventListener('mousedown', handleClickAway);
      };
    }, [showStats]);

    return (
      <div
        className={`player-card ${isActivePlayer ? 'active-player' : ''} ${isFolded ? 'folded-player' : ''} ${isAllIn ? 'all-in-player' : ''} ${isLoading ? 'calculating' : ''} ${showStats ? 'stats-visible' : ''}`}
      >
        {/* Active indicator moved to seat container highlight */}
        {isWinner && showWinnerNotification && (
          <div className="winner-notification">
            <div className="winner-bubble">🏆 WINNER! 🏆</div>
          </div>
        )}
        <div className="player-header">
          {isDealer && <div className="dealer-button">D</div>}
          {cardsHidden && !isLoading && (
            <button
              className="reveal-button"
              onClick={onToggleReveal}
              title={isRevealed ? 'Hide cards' : 'Reveal cards'}
            >
              {isRevealed ? '👁️' : '🔒'}
            </button>
          )}
          <button
            className="stats-toggle-icon"
            onClick={() => setShowStats(s => !s)}
            title={showStats ? 'Hide Stats' : 'Show Stats'}
          >
            📊
          </button>
        </div>

        {computedValues.shouldShowCards ? (
          <div className="cards">
            {cards.map((card, i) => (
              <Card
                key={i}
                card={card}
                isClickable={!!editMode}
                onClick={editMode ? () => onEditCard?.(index, i) : undefined}
              />
            ))}
          </div>
        ) : (
          <div className="cards-hidden">
            <div className="hidden-card">🂠</div>
            <div className="hidden-card">🂠</div>
            <div className="hidden-card">🂠</div>
            <div className="hidden-card">🂠</div>
          </div>
        )}

        <div className="player-info">
          <div className="player-number">Player {index + 1}</div>
          <div className="chip-stack">{chipStack} BB</div>
        </div>
        {showStats && (
          <div
            className={`stats-overlay ${[3, 4, 5].includes(index) ? 'stats-overlay-bottom' : ''}`}
            ref={statsRef}
          >
            <div className="stats-content">
              <button
                className="stats-close-btn"
                onClick={() => setShowStats(false)}
                aria-label="Close stats"
              >
                ✕
              </button>
              <div className="hand-strength" data-testid="hand-strength">
                <div>Top: {topCategory ?? 'TBD'}</div>
                <div>Bottom: {bottomCategory ?? 'TBD'}</div>
              </div>
              {invested > 0 && (
                <div className="invested">Invested: {invested} BB</div>
              )}
              <EquitySection
                equities={equities}
                index={index}
                isLoading={isLoading}
                isFolded={isFolded}
              />
            </div>
          </div>
        )}

        {showBetInput === index && (
          <BetInput
            index={index}
            isAllIn={isAllIn}
            hasBetThisRound={hasBetThisRound}
            calculateMaxRaise={calculateMaxRaise}
            calculateMaxBet={calculateMaxBet}
            calculateMinRaise={calculateMinRaise}
            betInputValue={betInputValue}
            onBetInputChange={onBetInputChange}
            onBetInputSubmit={onBetInputSubmit}
            onBetInputCancel={onBetInputCancel}
            formatEV={formatEV}
            formatPotOdds={formatPotOdds}
            raiseEV={computedValues.raiseEV}
            raisePotOdds={computedValues.raisePotOdds}
          />
        )}

        {/* Per-player inline action buttons removed; actions are handled via the right-side panel */}

        {isFolded && <div className="folded-indicator">FOLDED</div>}
        {isAllIn && !isFolded && <div className="all-in-indicator">ALL-IN</div>}

        {chipStack === 0 && (
          <div className="rebuy-section">
            <div className="busted-indicator">BUSTED</div>
            <button className="rebuy-btn" onClick={() => onRebuy()}>
              Rebuy ({defaultStackSize} BB)
            </button>
          </div>
        )}
      </div>
    );
  }
);

Player.displayName = 'Player';

export { Player };
export default Player;
