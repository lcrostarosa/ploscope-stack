import { useState, useEffect, useCallback } from 'react';

import { BoardCards } from '@/types/BoardType';
import { ActionRecord, GameStreet } from '@/types/GameAction';
import { GameConfig } from '@/types/GameConfig';
import type { GameState, ImportedState } from '@/types/GameStateTypes';
import { Pot } from '@/types/Pot';

// GameConfig interface moved to src/types/GameConfig.ts

/**
 * Enhanced Shared Game Logic Hook
 *
 * This hook provides comprehensive poker game logic that can be shared across
 * Live Mode and future Play Mode.
 *
 * Features:
 * - Enhanced state tracking with all player information
 * - Cross-mode state persistence and restoration
 * - Comprehensive card state management
 * - Betting round management with action history
 * - Pot and stack management
 * - Folded cards tracking
 * - Side pot calculations
 * - Card visibility management
 * - Winner state management
 */
export const useGameLogic = (
  initialConfig: Partial<{
    numPlayers: number;
    smallBlind: number;
    bigBlind: number;
    startingStack: number;
    isDoubleBoard: boolean;
    isBombPot: boolean;
    cardVariant: number;
  }> = {}
) => {
  // Game configuration
  const [config, setConfig] = useState({
    numPlayers: 6,
    smallBlind: 1,
    bigBlind: 2,
    startingStack: 200,
    isDoubleBoard: false,
    isBombPot: false,
    cardVariant: 4,
    ...initialConfig,
  });

  // Enhanced game state with comprehensive tracking
  const [gameState, setGameState] = useState<GameState>({
    // Players with full information
    players: [],
    activePlayers: new Set(),
    foldedPlayers: new Set(),
    allInPlayers: new Set(),

    // Board cards for both single and double board variants
    topFlop: ['', '', ''],
    topTurn: '',
    topRiver: '',
    bottomFlop: ['', '', ''],
    bottomTurn: '',
    bottomRiver: '',

    // Betting state
    potSize: 0,
    currentBet: 0,
    playerBets: {} as Record<number, number>,
    lastRaisePlayer: -1,
    lastRaiseAmount: 0,

    // Game flow
    currentStreet: 'preflop',
    currentActionPlayer: 0,
    bettingRoundComplete: false,
    dealerPosition: 0,

    // Action history for replay and analysis
    actionSequence: [] as ActionRecord[],

    // Folded cards (for equity calculations)
    foldedCards: [],

    // Side pots and main pot
    sidePots: [] as Pot[],
    mainPot: { potNumber: 1, size: 0, players: [] },

    // Card visibility
    cardsHidden: false,
    revealedPlayers: new Set() as Set<number>,

    // Winner state
    winner: null,
    showWinnerNotification: false,

    // Additional state for cross-mode compatibility
    street: 'preflop',
    numRandomOpponents: 0,
    heroStack: 200,
    opponentStacks: [] as number[],

    // Folded states for UI
    foldedStates: {
      opponents: [] as boolean[],
      topBoard: false,
      bottomBoard: false,
    },
  });

  // Initialize players based on config
  const initializePlayers = useCallback(() => {
    const players: Array<{
      id: number;
      position: number;
      stack: number;
      cards: string[];
      isInHand: boolean;
      isAllIn: boolean;
      bet: number;
      invested: number;
    }> = [];
    for (let i = 0; i < config.numPlayers; i++) {
      players.push({
        id: i,
        position: i,
        stack: config.startingStack,
        cards: ['', '', '', ''],
        isInHand: true,
        isAllIn: false,
        bet: 0,
        invested: 0,
      });
    }

    const activePlayers = new Set(
      Array.from({ length: config.numPlayers }, (_, i) => i)
    );
    const opponentStacks = Array(config.numPlayers - 1).fill(
      config.startingStack
    );
    const foldedStates = {
      opponents: Array(config.numPlayers - 1).fill(false),
      topBoard: false,
      bottomBoard: false,
    };

    setGameState(prev => ({
      ...prev,
      players,
      activePlayers,
      opponentStacks,
      foldedStates,
    }));
  }, [config.numPlayers, config.startingStack]);

  // Initialize on mount
  useEffect(() => {
    initializePlayers();
  }, [initializePlayers]);

  // Action validation
  const isValidAction = useCallback(
    (
      playerId: number,
      action: 'fold' | 'check' | 'call' | 'bet' | 'raise' | 'allin',
      amount: number = 0
    ) => {
      const player = gameState.players[playerId];
      if (!player || !gameState.activePlayers.has(playerId)) return false;

      const currentPlayerBet = gameState.playerBets[playerId] || 0;
      const callAmount = gameState.currentBet - currentPlayerBet;

      switch (action) {
        case 'fold':
          return true;
        case 'check':
          return callAmount === 0;
        case 'call':
          return callAmount > 0 && callAmount <= player.stack;
        case 'bet':
          return (
            callAmount === 0 &&
            amount >= config.bigBlind &&
            amount <= player.stack
          );
        case 'raise':
          return amount > gameState.currentBet && amount <= player.stack;
        case 'allin':
          return player.stack > 0;
        default:
          return false;
      }
    },
    [gameState, config.bigBlind]
  );

  // Execute player action
  const executeAction = useCallback(
    (
      playerId: number,
      action: 'fold' | 'check' | 'call' | 'bet' | 'raise' | 'allin',
      amount: number = 0
    ) => {
      if (!isValidAction(playerId, action, amount)) {
        return false;
      }

      const player = gameState.players[playerId];
      const currentPlayerBet = gameState.playerBets[playerId] || 0;
      const callAmount = gameState.currentBet - currentPlayerBet;

      const newPlayerBets = { ...gameState.playerBets };
      let newPotSize = gameState.potSize;
      let newCurrentBet = gameState.currentBet;
      let newLastRaisePlayer = gameState.lastRaisePlayer;
      let newLastRaiseAmount = gameState.lastRaiseAmount;
      const newActivePlayers = new Set(gameState.activePlayers);
      const newFoldedPlayers = new Set(gameState.foldedPlayers);
      const newAllInPlayers = new Set(gameState.allInPlayers);
      const newPlayers = [...gameState.players];
      const newActionSequence = [...gameState.actionSequence];

      switch (action) {
        case 'fold': {
          newFoldedPlayers.add(playerId);
          newActivePlayers.delete(playerId);
          newActionSequence.push({
            playerId,
            action,
            amount: 0,
            street: gameState.currentStreet,
          });
          break;
        }

        case 'check':
          newActionSequence.push({
            playerId,
            action,
            amount: 0,
            street: gameState.currentStreet,
          });
          break;

        case 'call': {
          const callCost = Math.min(callAmount, player.stack);
          newPlayerBets[playerId] = currentPlayerBet + callCost;
          newPotSize += callCost;
          newPlayers[playerId] = {
            ...player,
            stack: player.stack - callCost,
            invested: player.invested + callCost,
          };

          if (player.stack - callCost === 0) {
            newAllInPlayers.add(playerId);
          }

          newActionSequence.push({
            playerId,
            action,
            amount: callCost,
            street: gameState.currentStreet,
          });
          break;
        }

        case 'bet': {
          newPlayerBets[playerId] = currentPlayerBet + amount;
          newPotSize += amount;
          newCurrentBet = currentPlayerBet + amount;
          newLastRaisePlayer = playerId;
          newLastRaiseAmount = amount;
          newPlayers[playerId] = {
            ...player,
            stack: player.stack - amount,
            invested: player.invested + amount,
          };

          if (player.stack - amount === 0) {
            newAllInPlayers.add(playerId);
          }

          newActionSequence.push({
            playerId,
            action,
            amount,
            street: gameState.currentStreet,
          });
          break;
        }

        case 'raise': {
          const raiseAmount = amount - currentPlayerBet;
          newPlayerBets[playerId] = amount;
          newPotSize += raiseAmount;
          newCurrentBet = amount;
          newLastRaisePlayer = playerId;
          newLastRaiseAmount = amount - gameState.currentBet;
          newPlayers[playerId] = {
            ...player,
            stack: player.stack - raiseAmount,
            invested: player.invested + raiseAmount,
          };

          if (player.stack - raiseAmount === 0) {
            newAllInPlayers.add(playerId);
          }

          newActionSequence.push({
            playerId,
            action,
            amount,
            street: gameState.currentStreet,
          });
          break;
        }

        case 'allin': {
          const allInAmount = player.stack;
          newPlayerBets[playerId] = currentPlayerBet + allInAmount;
          newPotSize += allInAmount;
          newCurrentBet = Math.max(
            newCurrentBet,
            currentPlayerBet + allInAmount
          );
          newAllInPlayers.add(playerId);
          newPlayers[playerId] = {
            ...player,
            stack: 0,
            invested: player.invested + allInAmount,
          };

          if (allInAmount > gameState.lastRaiseAmount) {
            newLastRaisePlayer = playerId;
            newLastRaiseAmount = allInAmount;
          }

          newActionSequence.push({
            playerId,
            action,
            amount: allInAmount,
            street: gameState.currentStreet,
          });
          break;
        }
      }

      setGameState(prev => ({
        ...prev,
        players: newPlayers,
        activePlayers: newActivePlayers,
        foldedPlayers: newFoldedPlayers,
        allInPlayers: newAllInPlayers,
        playerBets: newPlayerBets,
        potSize: newPotSize,
        currentBet: newCurrentBet,
        lastRaisePlayer: newLastRaisePlayer,
        lastRaiseAmount: newLastRaiseAmount,
        actionSequence: newActionSequence,
      }));

      return true;
    },
    [gameState, isValidAction]
  );

  // Check if betting round is complete
  const isBettingRoundComplete = useCallback(() => {
    const activePlayers = Array.from(gameState.activePlayers).filter(
      id => !gameState.allInPlayers.has(id)
    );
    if (activePlayers.length <= 1) return true;

    const allBetsEqual = activePlayers.every(
      id => (gameState.playerBets[id] || 0) === gameState.currentBet
    );

    const allPlayersActed = activePlayers.every((id: number) => {
      const lastAction = gameState.actionSequence
        .filter(
          (action: ActionRecord) =>
            action.playerId === id && action.street === gameState.currentStreet
        )
        .pop();
      if (!lastAction) return false;
      if (lastAction.action === 'fold' || lastAction.action === 'allin') {
        return true;
      }
      return (gameState.playerBets[id] || 0) === gameState.currentBet;
    });

    return allBetsEqual && allPlayersActed;
  }, [gameState]);

  // Get next action player
  const getNextActionPlayer = useCallback((): number | null => {
    const activePlayers = Array.from(gameState.activePlayers).filter(
      id => !gameState.allInPlayers.has(id)
    );
    if (activePlayers.length <= 1) return null;

    const currentIndex = activePlayers.indexOf(gameState.currentActionPlayer);
    const nextIndex = (currentIndex + 1) % activePlayers.length;
    return activePlayers[nextIndex];
  }, [gameState]);

  // Advance to next street
  const nextStreet = useCallback(() => {
    const streets: GameStreet[] = ['preflop', 'flop', 'turn', 'river'];
    const currentIndex = streets.indexOf(gameState.currentStreet);
    const nextStreetValue = streets[currentIndex + 1];

    if (nextStreetValue) {
      setGameState(prev => ({
        ...prev,
        currentStreet: nextStreetValue,
        street: nextStreetValue,
        currentBet: 0,
        playerBets: {} as Record<number, number>,
        lastRaisePlayer: -1,
        lastRaiseAmount: 0,
        bettingRoundComplete: false,
      }));
    }
  }, [gameState.currentStreet]);

  // Clear all actions
  const clearActions = useCallback(() => {
    setGameState(prev => ({
      ...prev,
      actionSequence: [] as ActionRecord[],
      currentBet: 0,
      playerBets: {} as Record<number, number>,
      lastRaisePlayer: -1,
      lastRaiseAmount: 0,
      bettingRoundComplete: false,
    }));
  }, []);

  // Remove last action
  const removeLastAction = useCallback(() => {
    setGameState(prev => {
      const newActionSequence = prev.actionSequence.slice(
        0,
        -1
      ) as ActionRecord[];
      return {
        ...prev,
        actionSequence: newActionSequence,
      };
    });
  }, []);

  // Add folded card
  const addFoldedCard = useCallback((card: string) => {
    setGameState(prev => ({
      ...prev,
      foldedCards: [...prev.foldedCards, card],
    }));
  }, []);

  // Remove folded card
  const removeFoldedCard = useCallback((index: number) => {
    setGameState(prev => ({
      ...prev,
      foldedCards: prev.foldedCards.filter(
        (_: string, i: number) => i !== index
      ),
    }));
  }, []);

  // Update player cards
  const updatePlayerCards = useCallback((playerId: number, cards: string[]) => {
    setGameState(prev => {
      const newPlayers = [...prev.players];
      newPlayers[playerId] = { ...newPlayers[playerId], cards };
      return { ...prev, players: newPlayers };
    });
  }, []);

  // Update board cards
  const updateBoardCards = useCallback(
    (
      board: 'topBoard' | 'bottomBoard',
      street: 'flop' | 'turn' | 'river',
      cards: string[] | string
    ) => {
      setGameState(prev => {
        const boardPrefix = board === 'topBoard' ? 'top' : 'bottom';
        const streetKey =
          `${boardPrefix}${street.charAt(0).toUpperCase() + street.slice(1)}` as keyof GameState;

        return {
          ...prev,
          [streetKey]: cards,
        };
      });
    },
    []
  );

  // Get available actions for a player
  const getAvailableActions = useCallback(
    (playerId: number) => {
      const actions: Array<
        'fold' | 'check' | 'call' | 'bet' | 'raise' | 'allin'
      > = [];

      if (isValidAction(playerId, 'fold')) actions.push('fold');
      if (isValidAction(playerId, 'check')) actions.push('check');
      if (isValidAction(playerId, 'call')) actions.push('call');
      if (isValidAction(playerId, 'bet', config.bigBlind)) actions.push('bet');
      if (
        isValidAction(playerId, 'raise', gameState.currentBet + config.bigBlind)
      )
        actions.push('raise');
      if (isValidAction(playerId, 'allin')) actions.push('allin');

      return actions;
    },
    [gameState, isValidAction, config.bigBlind]
  );

  // Toggle card visibility
  const toggleCardVisibility = useCallback((playerId: number) => {
    setGameState(prev => {
      const newRevealedPlayers = new Set(prev.revealedPlayers);
      if (newRevealedPlayers.has(playerId)) {
        newRevealedPlayers.delete(playerId);
      } else {
        newRevealedPlayers.add(playerId);
      }
      return {
        ...prev,
        revealedPlayers: newRevealedPlayers,
      };
    });
  }, []);

  // Toggle global card visibility
  const toggleGlobalCardVisibility = useCallback(() => {
    setGameState(prev => ({
      ...prev,
      cardsHidden: !prev.cardsHidden,
    }));
  }, []);

  // Export game state for persistence
  const exportGameState = useCallback(() => {
    return {
      config,
      gameState: {
        ...gameState,
        activePlayers: Array.from(gameState.activePlayers),
        foldedPlayers: Array.from(gameState.foldedPlayers),
        allInPlayers: Array.from(gameState.allInPlayers),
        revealedPlayers: Array.from(gameState.revealedPlayers),
      },
      timestamp: Date.now(),
    };
  }, [config, gameState]);

  // Import game state

  const importGameState = useCallback((savedState: ImportedState) => {
    if (savedState.config) {
      setConfig(prev => ({ ...prev, ...savedState.config }));
    }
    if (savedState.gameState) {
      setGameState(prev => ({
        ...prev,
        ...savedState.gameState,
        activePlayers: new Set(
          savedState.gameState?.activePlayers || []
        ) as Set<number>,
        foldedPlayers: new Set(
          savedState.gameState?.foldedPlayers || []
        ) as Set<number>,
        allInPlayers: new Set(
          savedState.gameState?.allInPlayers || []
        ) as Set<number>,
        revealedPlayers: new Set(
          savedState.gameState?.revealedPlayers || []
        ) as Set<number>,
      }));
    }
  }, []);

  // Reset game
  const resetGame = useCallback(() => {
    setGameState(prev => ({
      ...prev,
      players: [] as GameState['players'],
      activePlayers: new Set(),
      foldedPlayers: new Set(),
      allInPlayers: new Set(),
      topFlop: ['', '', ''],
      topTurn: '',
      topRiver: '',
      bottomFlop: ['', '', ''],
      bottomTurn: '',
      bottomRiver: '',
      potSize: 0,
      currentBet: 0,
      playerBets: {} as Record<number, number>,
      lastRaisePlayer: -1,
      lastRaiseAmount: 0,
      currentStreet: 'preflop',
      street: 'preflop',
      currentActionPlayer: 0,
      bettingRoundComplete: false,
      actionSequence: [] as ActionRecord[],
      foldedCards: [],
      sidePots: [] as Pot[],
      mainPot: { potNumber: 1, size: 0, players: [] },
      cardsHidden: false,
      revealedPlayers: new Set<number>(),
      winner: null,
      showWinnerNotification: false,
      numRandomOpponents: 0,
      heroStack: 200,
      opponentStacks: [] as number[],
      foldedStates: {
        opponents: [] as boolean[],
        topBoard: false,
        bottomBoard: false,
      },
    }));
  }, []);

  return {
    // State
    config,
    gameState,

    // Actions
    executeAction,
    isValidAction,
    getAvailableActions,

    // Game flow
    nextStreet,
    clearActions,
    removeLastAction,
    resetGame,

    // Card management
    addFoldedCard,
    removeFoldedCard,
    updatePlayerCards,
    updateBoardCards,
    toggleCardVisibility,
    toggleGlobalCardVisibility,

    // State management
    exportGameState,
    importGameState,

    // Utilities
    isBettingRoundComplete,
    getNextActionPlayer,
  };
};
