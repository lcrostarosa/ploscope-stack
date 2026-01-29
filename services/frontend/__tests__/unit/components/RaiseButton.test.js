import React from 'react';

import { render, screen } from '@testing-library/react';

import { Player } from '../../../components/game/Player';

// Mock the Card component
jest.mock('../../../components/ui', () => ({
  Card: ({ card }) => <div data-testid="card">{card}</div>,
}));

describe('Player Component - Inline Raise Button (deprecated in favor of centralized ActionButtons)', () => {
  const defaultProps = {
    cards: ['Ah', 'Kh', 'Qh', 'Jh'],
    index: 0,
    equities: null,
    isLoading: false,
    isDealer: false,
    isActivePlayer: true,
    isFolded: false,
    isAllIn: false,
    onPlayerAction: jest.fn(),
    onRebuy: jest.fn(),
    defaultStackSize: 100,
    hasBetThisRound: false,
    chipStack: 100,
    invested: 0,
    currentBet: 0,
    showBetInput: null,
    betInputValue: 1,
    onBetInputChange: jest.fn(),
    onBetInputSubmit: jest.fn(),
    onBetInputCancel: jest.fn(),
    calculateMaxBet: jest.fn(() => 50),
    calculateMaxRaise: jest.fn(() => 50),
    calculateMinRaise: jest.fn(() => 2),
    cardsHidden: false,
    isRevealed: false,
    onToggleReveal: jest.fn(),
    potSize: 0,
    isWinner: false,
    showWinnerNotification: false,
  };

  it('does not render inline Raise button (actions centralized)', () => {
    render(<Player {...defaultProps} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
  });

  it('does not call onPlayerAction for inline raise (no inline button)', () => {
    const mockOnPlayerAction = jest.fn();
    render(<Player {...defaultProps} onPlayerAction={mockOnPlayerAction} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
    expect(mockOnPlayerAction).not.toHaveBeenCalled();
  });

  it('still no inline raise when player is not active', () => {
    render(<Player {...defaultProps} isActivePlayer={false} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
  });

  it('still no inline raise when player is all-in', () => {
    render(<Player {...defaultProps} isAllIn={true} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
  });

  it('still no inline raise when player is folded', () => {
    render(<Player {...defaultProps} isFolded={true} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
  });

  it('still no inline raise when bet input is shown', () => {
    render(<Player {...defaultProps} showBetInput={0} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
  });

  it('does not open bet input via inline raise (handled centrally)', () => {
    const mockOnPlayerAction = jest.fn();
    render(<Player {...defaultProps} onPlayerAction={mockOnPlayerAction} />);
    expect(screen.queryByText('Raise')).not.toBeInTheDocument();
    expect(mockOnPlayerAction).not.toHaveBeenCalled();
  });
});
