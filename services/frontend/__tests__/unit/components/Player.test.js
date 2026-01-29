import React from 'react';

import { render, screen } from '@testing-library/react';

import { Player } from '../../../components/game/Player';

// Mock the Card component
jest.mock('../../../components/ui', () => ({
  Card: ({ card }) => <div data-testid="card">{card}</div>,
}));

describe('Player Component - Hand Display During Calculations', () => {
  const defaultProps = {
    cards: ['As', 'Ks', 'Qs', 'Js'],
    index: 0,
    topBoard: [],
    bottomBoard: [],
    equities: null,
    isLoading: false,
    isDealer: false,
    isActivePlayer: false,
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
    calculateMaxBet: jest.fn(() => 100),
    calculateMaxRaise: jest.fn(() => 200),
    calculateMinRaise: jest.fn(() => 2),
    cardsHidden: false,
    isRevealed: false,
    onToggleReveal: jest.fn(),
    potSize: 10,
  };

  it('should display cards when cardsHidden is false', () => {
    render(<Player {...defaultProps} />);

    expect(screen.getAllByTestId('card')).toHaveLength(4);
    expect(screen.queryByText('🂠')).not.toBeInTheDocument();
  });

  it('should hide cards when cardsHidden is true', () => {
    render(<Player {...defaultProps} cardsHidden={true} />);

    expect(screen.queryByTestId('card')).not.toBeInTheDocument();
    expect(screen.getAllByText('🂠')).toHaveLength(4);
  });

  it('should show reveal button when cardsHidden is true but not during calculations', () => {
    render(<Player {...defaultProps} cardsHidden={true} isLoading={false} />);

    expect(screen.getByTitle('Reveal cards')).toBeInTheDocument();
    expect(screen.getByText('🔒')).toBeInTheDocument();
  });

  it('should not show reveal button during calculations', () => {
    render(<Player {...defaultProps} cardsHidden={true} isLoading={true} />);

    expect(screen.queryByTitle('Reveal cards')).not.toBeInTheDocument();
    expect(screen.queryByText('🔒')).not.toBeInTheDocument();
  });

  it('should apply calculating class to player card during calculations', () => {
    const { container } = render(<Player {...defaultProps} isLoading={true} />);

    const playerCard = container.querySelector('.player-card');
    expect(playerCard).toHaveClass('calculating');
  });

  it('should not apply calculating-cards class to cards during calculations', () => {
    const { container } = render(<Player {...defaultProps} isLoading={true} />);

    const cards = container.querySelector('.cards');
    expect(cards).not.toHaveClass('calculating-cards');
  });

  it('should display revealed cards when isRevealed is true even if cardsHidden is true', () => {
    render(<Player {...defaultProps} cardsHidden={true} isRevealed={true} />);

    expect(screen.getAllByTestId('card')).toHaveLength(4);
    expect(screen.queryByText('🂠')).not.toBeInTheDocument();
  });
});
