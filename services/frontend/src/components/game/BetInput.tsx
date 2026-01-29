import React, { useCallback, memo, useState, useRef, useEffect } from 'react';
import './BetInput.scss';

type BetInputProps = {
  index: number;
  isAllIn: boolean;
  hasBetThisRound: boolean;
  calculateMaxRaise: (playerIndex: number) => number;
  calculateMaxBet: (playerIndex: number) => number;
  calculateMinRaise: () => number;
  betInputValue: number;
  onBetInputChange: (value: number) => void;
  onBetInputSubmit: (playerIndex: number, action: 'bet' | 'raise') => void;
  onBetInputCancel: () => void;
  formatEV: (ev: number | null) => string;
  formatPotOdds: (odds: string | null) => string;
  raiseEV: number | null;
  raisePotOdds: string | null;
};

const BetInput: React.FC<BetInputProps> = memo(
  ({
    index,
    isAllIn,
    hasBetThisRound,
    calculateMaxRaise,
    calculateMaxBet,
    calculateMinRaise,
    betInputValue,
    onBetInputChange,
    onBetInputSubmit,
    onBetInputCancel,
    formatEV,
    formatPotOdds,
    raiseEV,
    raisePotOdds,
  }) => {
    // Local state for slider value to prevent flickering during drag
    const [localValue, setLocalValue] = useState(betInputValue);
    
    // Track if user is currently dragging
    const isDraggingRef = useRef(false);

    // Sync local value with prop value only when not dragging
    useEffect(() => {
      if (!isDraggingRef.current) {
        setLocalValue(betInputValue);
      }
    }, [betInputValue]);

    // Memoize bet calculation logic
    const betCalculations = useCallback(() => {
      const maxBet = hasBetThisRound
        ? calculateMaxRaise(index)
        : calculateMaxBet(index);
      const minBet = hasBetThisRound ? calculateMinRaise() : 1;
      const validMaxBet = Math.max(2, maxBet);
      const validMinBet = Math.max(1, minBet);

      return { validMaxBet, validMinBet };
    }, [
      hasBetThisRound,
      calculateMaxRaise,
      calculateMaxBet,
      calculateMinRaise,
      index,
    ]);

    // Handle slider change - only update local state during drag
    const handleSliderChange = useCallback((value: number) => {
      setLocalValue(value);
      // Don't update parent during drag - only on release
    }, []);

    // Handle drag start
    const handleDragStart = useCallback(() => {
      isDraggingRef.current = true;
    }, []);

    // Handle drag end
    const handleDragEnd = useCallback((value: number) => {
      isDraggingRef.current = false;
      onBetInputChange(value);
    }, [onBetInputChange]);

    if (isAllIn) return null;

    const { validMaxBet, validMinBet } = betCalculations();

    return (
      <div className="bet-input">
        <div className="bet-slider-container">
          <label className="bet-slider-label">
            {hasBetThisRound ? 'Raise' : 'Bet'}: {localValue} BB
          </label>
          <input
            type="range"
            className="bet-slider"
            value={localValue}
            onMouseDown={handleDragStart}
            onTouchStart={handleDragStart}
            onChange={e => {
              const value = parseInt(e.target.value) || 1;
              handleSliderChange(value);
            }}
            onMouseUp={e => {
              // Update parent only on mouse release
              const value = parseInt((e.target as HTMLInputElement).value) || 1;
              handleDragEnd(value);
            }}
            onTouchEnd={e => {
              // Same for touch devices
              const value = parseInt((e.target as HTMLInputElement).value) || 1;
              handleDragEnd(value);
            }}
            min={validMinBet}
            max={validMaxBet}
            step="1"
            disabled={false}
            style={{
              '--slider-progress': `${((localValue - validMinBet) / (validMaxBet - validMinBet)) * 100}%`
            } as React.CSSProperties}
          />
          <div className="slider-range">
            <span>{validMinBet} BB</span>
            <span>{validMaxBet} BB</span>
          </div>
        </div>
        <div className="bet-input-buttons">
          <button
            onClick={() =>
              onBetInputSubmit(index, hasBetThisRound ? 'raise' : 'bet')
            }
          >
            Confirm
          </button>
          <button onClick={onBetInputCancel}>Cancel</button>
        </div>
        <div className="bet-limits">
          {hasBetThisRound ? (
            <small>
              Min: {validMinBet} BB, Max: {validMaxBet} BB
            </small>
          ) : (
            <small>Max: {validMaxBet} BB</small>
          )}
        </div>
        <div className="ev-calculation">
          <div className="ev-label">Expected Value:</div>
          <div className="ev-value">{formatEV(raiseEV)}</div>
          <div className="pot-odds-label">Pot Odds:</div>
          <div className="pot-odds-value">{formatPotOdds(raisePotOdds)}</div>
        </div>
      </div>
    );
  }
);

BetInput.displayName = 'BetInput';

export default BetInput;
