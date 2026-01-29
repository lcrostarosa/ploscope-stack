import React, { useEffect, useState } from 'react';

import './LiveMode.scss';
import { useLocation } from 'react-router-dom';

import { Player, GameBoard } from '@/components/game';
import type { EditedGameState } from '@/components/game/CardEditorModal';
import { CardPickerModal } from '@/components/game/CardPickerModal';
import { SpotAnalysisConfirmationModal } from '@/components/game/SpotAnalysisConfirmationModal';
import { SpotResultsModal } from '@/components/game/SpotResultsModal';
import EmptyStateBanner from '@/components/live-mode/EmptyStateBanner/EmptyStateBanner';
import Felt from '@/components/live-mode/Felt/Felt';
import GameControlButtons from '@/components/live-mode/GameControlButtons/GameControlButtons';
import Hero from '@/components/live-mode/Hero/Hero';
import Seat from '@/components/live-mode/Seat/Seat';
import { ActionButtons } from '@/components/ui/ActionButtons';
import type { LiveGameState } from '@/types/GameStateTypes';
import { api } from '@/utils/auth';
import { convertCardsForBackend } from '@/utils/constants';
import { logError, logInfo } from '@/utils/logger';

type LiveModeProps = {
  gameState: LiveGameState;
  handleResetGameConfig: () => void;
};

const LiveMode: React.FC<LiveModeProps> = ({
  gameState,
  handleResetGameConfig,
}) => {
  const location = useLocation();
  const [isEditingCards, setIsEditingCards] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [spotResults, setSpotResults] = useState<any>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [analysisError, setAnalysisError] = useState<string | null>(null);
  const [currentJobId, setCurrentJobId] = useState<string | number | null>(
    null
  );
  const [fromRecentJob, setFromRecentJob] = useState(false);
  const [simulationSettings] = useState({
    simulation_runs: 10000,
    max_hand_combinations: 10000,
  });
  type CardPickerState = {
    type: 'player' | 'board';
    playerIndex?: number;
    cardIndex?: number;
    boardType?:
      | 'topFlop'
      | 'bottomFlop'
      | 'topTurn'
      | 'bottomTurn'
      | 'topRiver'
      | 'bottomRiver';
    flopIndex?: number;
  } | null;

  const [cardPicker, setCardPicker] = useState<CardPickerState>(null);

  const handleEditCards = () => {
    setIsEditingCards(v => !v);
    setCardPicker(null);
  };

  const handleSaveEditedCards = (editedState: EditedGameState) => {
    // Update game state with edited cards
    editedState.players.forEach((player, index) => {
      if (index < gameState.players.length) {
        gameState.players[index].cards = player.cards;
      }
    });

    // Update board cards
    gameState.topFlop = editedState.topFlop;
    gameState.bottomFlop = editedState.bottomFlop;
    gameState.topTurn = editedState.topTurn || null;
    gameState.bottomTurn = editedState.bottomTurn || null;
    gameState.topRiver = editedState.topRiver || null;
    gameState.bottomRiver = editedState.bottomRiver || null;

    logInfo('Cards updated successfully', editedState);
  };

  // Inline edit: available cards computation
  const ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A',
  ];
  const suits = ['h', 'd', 'c', 's'];
  const allCards = suits.flatMap(suit => ranks.map(rank => `${rank}${suit}`));

  const getUsedCards = (): Set<string> => {
    const used = new Set<string>();
    gameState.players.forEach(p => {
      (p.cards || []).forEach(c => {
        if (c) used.add(c);
      });
    });
    gameState.topFlop.forEach(c => c && used.add(c));
    gameState.bottomFlop.forEach(c => c && used.add(c));
    if (gameState.topTurn) used.add(gameState.topTurn);
    if (gameState.bottomTurn) used.add(gameState.bottomTurn);
    if (gameState.topRiver) used.add(gameState.topRiver);
    if (gameState.bottomRiver) used.add(gameState.bottomRiver);
    return used;
  };

  const availableCards = (() => {
    // Allow re-selecting current card under edit by not excluding it
    if (!cardPicker) return allCards.filter(c => !getUsedCards().has(c));
    const used = getUsedCards();
    if (cardPicker.type === 'player') {
      const current =
        typeof cardPicker.playerIndex === 'number' &&
        typeof cardPicker.cardIndex === 'number'
          ? gameState.players[cardPicker.playerIndex]?.cards?.[
              cardPicker.cardIndex
            ]
          : undefined;
      if (current) used.delete(current);
    } else if (cardPicker.type === 'board' && cardPicker.boardType) {
      const current = (() => {
        if (cardPicker.boardType === 'topFlop')
          return gameState.topFlop[cardPicker.flopIndex!];
        if (cardPicker.boardType === 'bottomFlop')
          return gameState.bottomFlop[cardPicker.flopIndex!];
        if (cardPicker.boardType === 'topTurn')
          return gameState.topTurn || undefined;
        if (cardPicker.boardType === 'bottomTurn')
          return gameState.bottomTurn || undefined;
        if (cardPicker.boardType === 'topRiver')
          return gameState.topRiver || undefined;
        if (cardPicker.boardType === 'bottomRiver')
          return gameState.bottomRiver || undefined;
        return undefined;
      })();
      if (current) used.delete(current);
    }
    return allCards.filter(c => !used.has(c));
  })();

  // If navigated here with job results, open the results modal automatically
  useEffect(() => {
    const navState = (location.state || {}) as any;
    const resultsFromNav = navState?.jobResults;
    const isFromRecentJob = navState?.fromRecentJob;
    if (resultsFromNav && (!spotResults || spotResults !== resultsFromNav)) {
      setSpotResults(resultsFromNav);
      setIsAnalyzing(false);
      setAnalysisError(null);
      setShowResults(true);
      setFromRecentJob(!!isFromRecentJob);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.state]);

  // Inline edit: click handlers
  const handlePlayerCardClick = (playerIndex: number, cardIndex: number) => {
    if (!isEditingCards) return;
    setCardPicker({ type: 'player', playerIndex, cardIndex });
  };

  const handleBoardCardClick = (
    meta:
      | { boardType: 'topFlop' | 'bottomFlop'; flopIndex: number }
      | { boardType: 'topTurn' | 'bottomTurn' | 'topRiver' | 'bottomRiver' }
  ) => {
    if (!isEditingCards) return;
    setCardPicker({ type: 'board', ...(meta as any) });
  };

  const handleSelectCard = (card: string) => {
    if (!cardPicker) return;
    if (cardPicker.type === 'player') {
      const { playerIndex, cardIndex } = cardPicker;
      if (
        typeof playerIndex === 'number' &&
        typeof cardIndex === 'number' &&
        gameState.players[playerIndex]
      ) {
        gameState.players[playerIndex].cards[cardIndex] = card;
      }
    } else if (cardPicker.type === 'board') {
      const { boardType } = cardPicker;
      if (boardType === 'topFlop' && typeof cardPicker.flopIndex === 'number') {
        gameState.topFlop[cardPicker.flopIndex] = card;
      } else if (
        boardType === 'bottomFlop' &&
        typeof cardPicker.flopIndex === 'number'
      ) {
        gameState.bottomFlop[cardPicker.flopIndex] = card;
      } else if (boardType === 'topTurn') {
        gameState.topTurn = card || null;
      } else if (boardType === 'bottomTurn') {
        gameState.bottomTurn = card || null;
      } else if (boardType === 'topRiver') {
        gameState.topRiver = card || null;
      } else if (boardType === 'bottomRiver') {
        gameState.bottomRiver = card || null;
      }
    }
    setCardPicker(null);
  };

  const cancelJob = async (jobId: string | number) => {
    try {
      await api.post(`/jobs/${jobId}/cancel`);
      logInfo(`Job ${jobId} cancelled successfully`);
      setCurrentJobId(null);
      setIsAnalyzing(false);
      setAnalysisError('Job was cancelled');
    } catch (error) {
      logError('Failed to cancel job:', error);
      setAnalysisError('Failed to cancel job');
    }
  };

  const pollJobStatus = async (jobId: string | number): Promise<any> => {
    const maxAttempts = 120; // 10 minutes max (5 second intervals)
    let attempts = 0;

    while (attempts < maxAttempts) {
      try {
        // Use the correct API endpoint to get full job details
        const response = await api.get(`/jobs/${jobId}/details`);
        const job = response.data.job;

        logInfo(`Job ${jobId} status: ${job.status}`, {
          progress: job.progress,
          hasResultData: !!job.result_data,
        });

        if (job.status === 'completed' || job.status === 'COMPLETED') {
          logInfo('Job completed successfully', {
            jobId: job.id,
            hasResultData: !!job.result_data,
            resultDataType: typeof job.result_data,
          });
          setCurrentJobId(null);
          return job.result_data;
        } else if (job.status === 'failed' || job.status === 'FAILED') {
          const errorMsg = job.error_message || job.error || 'Job failed';
          logError('Job failed:', errorMsg);
          setCurrentJobId(null);
          throw new Error(errorMsg);
        } else if (job.status === 'cancelled' || job.status === 'CANCELLED') {
          setCurrentJobId(null);
          throw new Error('Job was cancelled');
        }

        // Job still processing, wait and try again
        await new Promise(resolve => setTimeout(resolve, 5000)); // 5 second interval
        attempts++;
      } catch (error: any) {
        // If it's a job status error (failed/cancelled), throw it
        if (error.message && !error.response) {
          setCurrentJobId(null);
          throw error;
        }
        // Otherwise, it might be a network error, retry
        logError('Error polling job status:', error);
        await new Promise(resolve => setTimeout(resolve, 5000));
        attempts++;
      }
    }

    setCurrentJobId(null);
    throw new Error('Job timed out after 10 minutes');
  };

  const handleStudySpotClick = () => {
    // Show confirmation modal first
    setShowConfirmation(true);
  };

  const handleBackToConfirmation = () => {
    // Close results modal and show confirmation modal
    setShowResults(false);
    setSpotResults(null);
    setAnalysisError(null);
    setCurrentJobId(null);
    setFromRecentJob(false);
    setShowConfirmation(true);
  };

  const handleConfirmAnalysis = async () => {
    // Close confirmation modal
    setShowConfirmation(false);

    try {
      setIsAnalyzing(true);
      setAnalysisError(null);
      setShowResults(true);

      logInfo('Starting spot analysis by submitting job');

      // Prepare the data for the API
      const topBoard = [
        ...gameState.topFlop,
        ...(gameState.topTurn ? [gameState.topTurn] : []),
        ...(gameState.topRiver ? [gameState.topRiver] : []),
      ];

      const bottomBoard = [
        ...gameState.bottomFlop,
        ...(gameState.bottomTurn ? [gameState.bottomTurn] : []),
        ...(gameState.bottomRiver ? [gameState.bottomRiver] : []),
      ];

      const players = gameState.players
        .filter(
          (player, index) =>
            player.cards &&
            player.cards.length === 4 &&
            !gameState.foldedPlayers.has(index)
        )
        .map(player => convertCardsForBackend(player.cards));

      const foldedCardsRaw = gameState.players
        .map((player, index) => ({ player, index }))
        .filter(
          ({ player, index }) =>
            player.cards &&
            player.cards.length === 4 &&
            gameState.foldedPlayers.has(index)
        )
        .flatMap(({ player }) => player.cards);

      const requestBody: Record<string, unknown> = {
        top_board: convertCardsForBackend(topBoard),
        bottom_board: convertCardsForBackend(bottomBoard),
        players: players,
        simulation_runs: simulationSettings.simulation_runs,
        max_hand_combinations: simulationSettings.max_hand_combinations,
        name: 'Live Mode Spot Analysis',
        description: 'Analysis from live mode',
        from_spot_mode: true,
      };

      if (foldedCardsRaw.length > 0) {
        requestBody.folded_cards = convertCardsForBackend(foldedCardsRaw);
      }

      logInfo('Submitting job to /spots/simulate', requestBody);

      // Submit the job
      const submitResponse = await api.post('/spots/simulate', requestBody);
      const job = submitResponse.data.job || submitResponse.data;
      const jobId = job.id;

      logInfo(`Job submitted with ID: ${jobId}`, job);
      setCurrentJobId(jobId);

      // Poll for job completion
      const results = await pollJobStatus(jobId);

      logInfo('Job completed, received results', {
        resultsType: typeof results,
        isArray: Array.isArray(results),
        length: results?.length,
        results: results,
      });

      // Extract results from the response
      const finalResults = results.results || results;
      logInfo('Setting spot results:', {
        finalResultsType: typeof finalResults,
        finalResultsIsArray: Array.isArray(finalResults),
        finalResultsLength: finalResults?.length,
        finalResults: finalResults,
        firstResultKeys: finalResults?.[0]
          ? Object.keys(finalResults[0])
          : null,
        firstResult: finalResults?.[0],
      });
      setSpotResults(finalResults);
      setIsAnalyzing(false);
    } catch (error: any) {
      logError('Error analyzing spot:', error);
      setAnalysisError(
        error.response?.data?.error ||
          error.response?.data?.message ||
          error.message ||
          'Failed to analyze spot'
      );
      setIsAnalyzing(false);
    }
  };

  // Temporary: widen types for JSX usage until types consolidate
  const FeltAny = Felt as any;
  const SeatAny = Seat as any;

  return (
    <>
      <Hero />
      <GameControlButtons
        gameState={gameState}
        handleResetGameConfig={handleResetGameConfig}
        onEditCards={handleEditCards}
        isEditingCards={isEditingCards}
        onStudySpot={handleStudySpotClick}
      />

      <EmptyStateBanner players={gameState.players} />

      <FeltAny
        gameState={gameState}
        editMode={isEditingCards}
        onBoardCardClick={handleBoardCardClick}
      >
        {(() => {
          const seats = [] as Array<{
            i: number;
            cards: string[];
            chipStack: number;
          }>;
          const numToRender = Math.min(gameState.numActivePlayers, 8);
          for (let i = 0; i < numToRender; i++) {
            seats.push({
              i,
              cards: gameState.players[i]?.cards || [],
              chipStack: gameState.chipStacks?.[i] || 100,
            });
          }
          return seats.map(({ i, cards, chipStack }) => (
            <SeatAny
              key={i}
              i={i}
              cards={cards}
              chipStack={chipStack}
              gameState={gameState}
              editMode={isEditingCards}
              onPlayerCardClick={handlePlayerCardClick}
            />
          ));
        })()}
      </FeltAny>

      <ActionButtons
        activePlayer={gameState.activePlayer}
        showBetInput={gameState.showBetInput}
        currentBet={gameState.currentBet}
        playerInvested={gameState.playerInvested}
        foldedPlayers={gameState.foldedPlayers}
        allInPlayers={gameState.allInPlayers}
        onPlayerAction={gameState.handlePlayerAction}
      />

      {/* Inline Card Picker Modal */}
      <CardPickerModal
        isOpen={!!cardPicker}
        availableCards={availableCards}
        onClose={() => setCardPicker(null)}
        onSelect={handleSelectCard}
      />

      {/* Spot Analysis Confirmation Modal */}
      <SpotAnalysisConfirmationModal
        isOpen={showConfirmation}
        onClose={() => setShowConfirmation(false)}
        onConfirm={handleConfirmAnalysis}
        gameState={{
          players: gameState.players,
          topFlop: gameState.topFlop,
          bottomFlop: gameState.bottomFlop,
          topTurn: gameState.topTurn,
          bottomTurn: gameState.bottomTurn,
          topRiver: gameState.topRiver,
          bottomRiver: gameState.bottomRiver,
          numActivePlayers: gameState.numActivePlayers,
          foldedPlayers: gameState.foldedPlayers,
        }}
        simulationSettings={simulationSettings}
      />

      {/* Spot Results Modal */}
      <SpotResultsModal
        isOpen={showResults}
        onClose={() => {
          setShowResults(false);
          setSpotResults(null);
          setAnalysisError(null);
          setCurrentJobId(null);
          setFromRecentJob(false);
        }}
        results={spotResults}
        isLoading={isAnalyzing}
        error={analysisError}
        currentJobId={currentJobId}
        onCancelJob={cancelJob}
        showBackButton={fromRecentJob}
        onBack={handleBackToConfirmation}
      />
    </>
  );
};

export default LiveMode;
