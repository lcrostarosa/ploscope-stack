import { renderHook, act, waitFor } from '@testing-library/react';

import { useGameState } from '../../../hooks/useGameState';

describe('useGameState - collectAntes', () => {
  it('should deduct 1BB from each active player and add total to the pot', async () => {
    const { result } = renderHook(() => useGameState());

    // Reset to a clean state
    act(() => {
      result.current.nextHand();
    });

    act(() => {
      result.current.setNumActivePlayers(8);
    });
    await waitFor(() => {
      expect(result.current.numActivePlayers).toBe(8);
    });

    act(() => {
      result.current.setChipStacks(Array(8).fill(100));
    });
    await waitFor(() => {
      expect(result.current.chipStacks).toEqual(Array(8).fill(100));
    });

    act(() => {
      result.current.setPlayers(
        Array(8)
          .fill(null)
          .map(() => ({
            cards: ['Ah', 'Kh', 'Qh', 'Jh'],
            isInHand: true,
          }))
      );
    });
    await waitFor(() => {
      expect(
        result.current.players.every(p => p.cards.length === 4 && p.isInHand)
      ).toBe(true);
    });

    // Wait for the chipStacks to update after collectAntes is called by useEffect
    await waitFor(
      () => {
        expect(result.current.chipStacks).toEqual(Array(8).fill(99));
        expect(result.current.playerInvested).toEqual(Array(8).fill(1));
        expect(result.current.pot).toBe(8);
        expect(result.current.mainPot).toBe(8);
      },
      { timeout: 2000 }
    );
  });
});

describe('useGameState - winner notification', () => {
  it('should award pot to winner when only one player remains', async () => {
    const { result } = renderHook(() => useGameState());

    // Reset to a clean state
    act(() => {
      result.current.nextHand();
    });

    // Set up initial state with 2 players
    act(() => {
      result.current.setNumActivePlayers(2);
      // Only give chips to the first 2 players
      result.current.setChipStacks([100, 100, 0, 0, 0, 0, 0, 0]);
      // Set up players - only first 2 are in hand
      result.current.setPlayers([
        { cards: ['AS', 'AD', 'AH', 'AC'], isInHand: true },
        { cards: ['KS', 'KD', 'KH', 'KC'], isInHand: true },
        { cards: [], isInHand: false },
        { cards: [], isInHand: false },
        { cards: [], isInHand: false },
        { cards: [], isInHand: false },
        { cards: [], isInHand: false },
        { cards: [], isInHand: false },
      ]);
    });

    await waitFor(() => {
      expect(result.current.pot).toBe(2); // 1 BB ante from each active player (2 players)
    });

    // First player folds
    act(() => {
      result.current.handlePlayerAction(0, 'fold');
    });

    await waitFor(() => {
      expect(result.current.winner).toBe(1); // Player 2 should be the winner
      expect(result.current.showWinnerNotification).toBe(true);
      expect(result.current.chipStacks[1]).toBe(101); // 99 (after ante) + 2 BB pot
      expect(result.current.pot).toBe(0); // Pot should be cleared
    });

    // Wait for notification to clear
    await waitFor(
      () => {
        expect(result.current.showWinnerNotification).toBe(false);
        expect(result.current.winner).toBe(null);
      },
      { timeout: 4000 }
    );
  });
});
