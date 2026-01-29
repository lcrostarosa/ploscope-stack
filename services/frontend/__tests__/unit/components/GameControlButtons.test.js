import React from 'react';

import { render, screen, act } from '@testing-library/react';

import GameControlButtons from '../../../components/live-mode/GameControlButtons/GameControlButtons';

// Mock the logger
jest.mock('../../../utils/logger', () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logDebug: jest.fn(),
}));

describe('GameControlButtons', () => {
  const mockGameState = {
    deal: jest.fn(),
    nextHand: jest.fn(),
    players: [{ cards: ['Ah', 'Kh'] }, { cards: ['Qd', 'Jd'] }],
    cardsHidden: false,
    toggleGlobalCardVisibility: jest.fn(),
  };

  const mockHandleCopyToSpotMode = jest.fn();
  const mockHandleResetGameConfig = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders all buttons correctly', () => {
    render(
      <GameControlButtons
        gameState={mockGameState}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    expect(screen.getByText('Deal Cards')).toBeInTheDocument();
    expect(screen.getByText('Next Hand')).toBeInTheDocument();
    expect(screen.getByText('📊 Study This Spot')).toBeInTheDocument();
    expect(screen.getByText('✏️ Edit Cards')).toBeInTheDocument();
    expect(screen.getByText('Set Chips')).toBeInTheDocument();
    expect(screen.getByText('🔒 Hide All Cards')).toBeInTheDocument();
  });

  it('calls deal function when Deal Cards is clicked', async () => {
    render(
      <GameControlButtons
        gameState={mockGameState}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    await act(async () => {
      screen.getByText('Deal Cards').click();
      // Wait for the async deal function to complete
      await new Promise(resolve => setTimeout(resolve, 350));
    });

    expect(mockGameState.deal).toHaveBeenCalled();
  });

  it('calls nextHand function when Next Hand is clicked', () => {
    render(
      <GameControlButtons
        gameState={mockGameState}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    act(() => {
      screen.getByText('Next Hand').click();
    });
    expect(mockGameState.nextHand).toHaveBeenCalled();
  });

  it('calls onStudySpot when Study This Spot is clicked', () => {
    render(
      <GameControlButtons
        gameState={mockGameState}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    act(() => {
      screen.getByText('📊 Study This Spot').click();
    });
    expect(mockHandleCopyToSpotMode).toHaveBeenCalled();
  });

  it('calls toggleGlobalCardVisibility when visibility button is clicked', () => {
    render(
      <GameControlButtons
        gameState={mockGameState}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    act(() => {
      screen.getByText('🔒 Hide All Cards').click();
    });
    expect(mockGameState.toggleGlobalCardVisibility).toHaveBeenCalled();
  });

  it('disables Study This Spot button when no players have cards', () => {
    const gameStateWithNoCards = {
      ...mockGameState,
      players: [{ cards: [] }, { cards: [] }],
    };

    render(
      <GameControlButtons
        gameState={gameStateWithNoCards}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    const studyButton = screen.getByText('📊 Study This Spot');
    expect(studyButton).toBeDisabled();
  });

  it('shows correct visibility button text based on cardsHidden state', () => {
    const gameStateWithHiddenCards = {
      ...mockGameState,
      cardsHidden: true,
    };

    render(
      <GameControlButtons
        gameState={gameStateWithHiddenCards}
        handleResetGameConfig={mockHandleResetGameConfig}
        onStudySpot={mockHandleCopyToSpotMode}
      />
    );

    expect(screen.getByText('👁️ Show All Cards')).toBeInTheDocument();
  });
});
