/* @ts-nocheck */

import { useState, useEffect, useCallback, useRef } from 'react';

import { useNavigate, useLocation } from 'react-router-dom';

import { useGameState } from '../../hooks/useGameState';
import { usePerformanceMonitoring } from '../../hooks/usePerformanceMonitoring';
import { persistGameState } from '../../utils/gameStateUtils';
import { logError, logInfo, logDebug } from '../../utils/logger';

type ModeInfo = {
  isLiveMode: boolean;
  isHomeMode?: boolean;
  isHandHistoryMode?: boolean;
};

export const useAppGameState = (modeInfo: ModeInfo) => {
  const navigate = useNavigate();
  const location = useLocation();

  // State management - setup mode is no longer used
  const showLiveModeSetup = false;
  const [gameConfig, setGameConfig] = useState(() => {
    // Try to restore gameConfig from localStorage on component mount
    try {
      const savedConfig = localStorage.getItem('plosolver-gameConfig');
      if (savedConfig) {
        return JSON.parse(savedConfig);
      }
    } catch (error) {
      logError('Failed to restore gameConfig from localStorage:', error);
    }

    // Default game configuration - no setup required
    return {
      setupMode: 'quick',
      gameType: 'tournament',
      stackSizes: 'equal',
      bigBlindsPerPlayer: 100,
      individualStacks: Array(10).fill(100),
      isBombPot: true,
      isDoubleBoard: true,
      cardVariant: 4,
      burnConfig: 'each-street',
      numPlayers: 8,
    };
  });

  // One-time refs to avoid repeated config application
  const appliedNavConfigRef = useRef(false);
  const appliedLocalConfigRef = useRef(false);

  // Initialize hooks
  const gameState = useGameState();

  // Performance monitoring
  const { trackRender } = usePerformanceMonitoring('AppWrapper', {
    trackRenders: true,
  });

  // Keyboard shortcuts for live mode - memoized with useCallback
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (
        modeInfo.isHomeMode ||
        modeInfo.isHandHistoryMode ||
        gameState.activePlayer === null ||
        gameState.showBetInput !== null
      )
        return;

      const key = event.key.toLowerCase();

      switch (key) {
        case 'c':
          event.preventDefault();
          gameState.handlePlayerAction(gameState.activePlayer, 'check');
          break;
        case 'b':
          event.preventDefault();
          gameState.handlePlayerAction(gameState.activePlayer, 'bet');
          break;
        case 'f':
          event.preventDefault();
          gameState.handlePlayerAction(gameState.activePlayer, 'fold');
          break;
        default:
          break;
      }
    },
    [modeInfo, gameState]
  );


  // Keyboard shortcuts for live mode - useEffect for event listener
  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);

  // Handle game setup
  // Setup functions are no longer needed

  // Function to reset gameConfig to defaults
  const handleResetGameConfig = useCallback(() => {
    const defaultConfig = {
      setupMode: 'quick',
      gameType: 'tournament',
      stackSizes: 'equal',
      bigBlindsPerPlayer: 100,
      individualStacks: Array(10).fill(100),
      isBombPot: true,
      isDoubleBoard: true,
      cardVariant: 4,
      burnConfig: 'each-street',
      numPlayers: 8,
    };

    setGameConfig(defaultConfig);
    try {
      localStorage.setItem(
        'plosolver-gameConfig',
        JSON.stringify(defaultConfig)
      );
    } catch (error) {
      logError('Failed to persist default gameConfig to localStorage:', error);
    }

    // Reset the game state
    gameState.nextHand();
  }, [gameState]);

  // Handle game config from navigation state
  useEffect(() => {
    if (
      !appliedNavConfigRef.current &&
      modeInfo.isLiveMode &&
      location.state?.gameConfig
    ) {
      // Apply game config from navigation state
      const config = location.state.gameConfig;
      setGameConfig(config);

      // Set number of active players first
      if (config.numPlayers) {
        gameState.setNumActivePlayers(config.numPlayers);
      }

      // Set up chip stacks based on configuration
      if (config.stackSizes === 'equal' && config.bigBlindsPerPlayer) {
        gameState.setDefaultStackSize(config.bigBlindsPerPlayer);
        gameState.setAllChipStacks();
      } else if (config.stackSizes === 'different' && config.individualStacks) {
        // Set individual stacks for the number of players
        const stacks = Array(8).fill(100); // Default for unused positions
        for (
          let i = 0;
          i < Math.min(config.numPlayers, config.individualStacks.length);
          i++
        ) {
          stacks[i] = config.individualStacks[i];
        }
        gameState.setChipStacks(stacks);
      }

      // Note: Cards are not auto-dealt - user must click "Deal Cards" to start
      appliedNavConfigRef.current = true;
    }
  }, [modeInfo.isLiveMode, location.state, gameState]);

  // Apply game config when it's restored from localStorage
  useEffect(() => {
    if (
      !appliedLocalConfigRef.current &&
      modeInfo.isLiveMode &&
      gameConfig &&
      !location.state?.gameConfig
    ) {
      // Apply game config from localStorage
      const config = gameConfig;

      // Set number of active players first
      if (config.numPlayers) {
        gameState.setNumActivePlayers(config.numPlayers);
      }

      // Set up chip stacks based on configuration
      if (config.stackSizes === 'equal' && config.bigBlindsPerPlayer) {
        gameState.setDefaultStackSize(config.bigBlindsPerPlayer);
        gameState.setAllChipStacks();
      } else if (config.stackSizes === 'different' && config.individualStacks) {
        // Set individual stacks for the number of players
        const stacks = Array(8).fill(100); // Default for unused positions
        for (
          let i = 0;
          i < Math.min(config.numPlayers, config.individualStacks.length);
          i++
        ) {
          stacks[i] = config.individualStacks[i];
        }
        gameState.setChipStacks(stacks);
      }

      // Note: Cards are not auto-dealt - user must click "Deal Cards" to start
      appliedLocalConfigRef.current = true;
    }
  }, [modeInfo.isLiveMode, gameConfig, location.state, gameState]);

  // Setup mode is no longer used - gameConfig is always initialized with defaults

  // Persist live mode state when it changes
  useEffect(() => {
    if (
      modeInfo.isLiveMode &&
      gameState.players.some(player => player.cards.length > 0)
    ) {
      // Persist LiveMode state as-is - no conversion needed
      persistGameState(gameState, 'live');
    }
  }, [modeInfo.isLiveMode, gameState]);

  // Debug: log button enabled and player card counts instead of rendering in UI
  useEffect(() => {
    const playersWithCards = gameState.players.filter(
      player => player.cards && player.cards.length > 0
    ).length;
    const buttonEnabled = playersWithCards > 0;
    logDebug(
      `Button enabled: ${buttonEnabled ? 'Yes' : 'No'} | Players with cards: ${playersWithCards} | Total players: ${gameState.players.length}`
    );

    // Track render performance
    trackRender();
  }, [gameState.players, trackRender]);

  return {
    showLiveModeSetup,
    gameConfig,
    setGameConfig,
    gameState,
    trackRender,
    handleResetGameConfig,
  };
};
