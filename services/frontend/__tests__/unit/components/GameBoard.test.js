import React from 'react';

import { render, screen } from '@testing-library/react';

import { GameBoard } from '../../../components/game/GameBoard';

// Mock the Card and ActionButtons components
jest.mock('../../../components/ui', () => ({
  Card: ({ card }) => <div data-testid="card">{card}</div>,
  ActionButtons: ({ activePlayer }) => (
    <div data-testid="action-buttons">Player {activePlayer} Actions</div>
  ),
}));

describe('GameBoard', () => {
  const defaultProps = {
    topFlop: ['Ah', 'Kh', 'Qh'],
    bottomFlop: ['Ad', 'Kd', 'Qd'],
    topTurn: 'Jh',
    bottomTurn: 'Jd',
    topRiver: null,
    bottomRiver: null,
    mainPot: 100,
    pot: 150,
    sidePots: [],
    actionButtonProps: {
      activePlayer: 0,
      showBetInput: null,
      currentBet: 10,
      playerInvested: [0, 0, 0],
      foldedPlayers: new Set(),
      allInPlayers: new Set(),
      onPlayerAction: jest.fn(),
    },
  };

  it('renders the board container with correct layout classes', () => {
    render(<GameBoard {...defaultProps} />);

    const boardContainer = screen.getByTestId('board-container');
    expect(boardContainer).toBeInTheDocument();
    expect(boardContainer).toHaveClass('board-container');
  });

  it('renders the board section with correct classes', () => {
    render(<GameBoard {...defaultProps} />);

    const boardSection = screen.getByTestId('board-section');
    expect(boardSection).toBeInTheDocument();
    expect(boardSection).toHaveClass('board');
  });

  it('renders the pot display section with correct classes', () => {
    render(<GameBoard {...defaultProps} />);

    const potDisplay = screen.getByText('Main Pot: 100 BB');
    expect(potDisplay).toBeInTheDocument();
    expect(potDisplay.closest('.pot-display')).toBeInTheDocument();
  });

  it('renders both top and bottom boards', () => {
    render(<GameBoard {...defaultProps} />);

    expect(screen.getByText('Top Board')).toBeInTheDocument();
    expect(screen.getByText('Bottom Board')).toBeInTheDocument();
  });

  it('renders pot information correctly', () => {
    render(<GameBoard {...defaultProps} />);

    expect(screen.getByText(/Main Pot: 100 BB/)).toBeInTheDocument();
    expect(screen.getByText(/Total: 150 BB/)).toBeInTheDocument();
  });

  it('renders side pots when provided', () => {
    const propsWithSidePots = {
      ...defaultProps,
      sidePots: [
        { amount: 50, eligiblePlayers: [0, 1] },
        { amount: 25, eligiblePlayers: [2] },
      ],
    };

    render(<GameBoard {...propsWithSidePots} />);

    expect(screen.getByText(/Side Pot 1: 50 BB/)).toBeInTheDocument();
    expect(screen.getByText(/Side Pot 2: 25 BB/)).toBeInTheDocument();
    expect(screen.getByText(/(P1, P2)/)).toBeInTheDocument();
    expect(screen.getByText(/(P3)/)).toBeInTheDocument();
  });

  it('renders total pot information', () => {
    render(<GameBoard {...defaultProps} />);

    expect(screen.getByText('Total: 150 BB')).toBeInTheDocument();
  });
});
