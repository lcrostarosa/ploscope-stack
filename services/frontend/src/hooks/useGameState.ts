import { useState, useEffect, useCallback } from 'react';

import type { Equities } from '@/types/GameStateTypes';

import { api } from '../utils/auth';
import {
  generateDeck,
  shuffle,
  convertCardsForBackend,
} from '../utils/constants';

export const useGameState = () => {
  // Core game state
  const [players, setPlayers] = useState<
    Array<{ cards: string[]; isInHand: boolean }>
  >(
    Array(8)
      .fill(null)
      .map(() => ({ cards: [], isInHand: true }))
  );
  const [numActivePlayers, setNumActivePlayers] = useState<number>(8);
  const [deck, setDeck] = useState<string[]>([]);
  const [topFlop, setTopFlop] = useState<string[]>([]);
  const [bottomFlop, setBottomFlop] = useState<string[]>([]);
  const [topTurn, setTopTurn] = useState<string | null>(null);
  const [bottomTurn, setBottomTurn] = useState<string | null>(null);
  const [topRiver, setTopRiver] = useState<string | null>(null);
  const [bottomRiver, setBottomRiver] = useState<string | null>(null);
  const [nextCardIndex, setNextCardIndex] = useState<number>(40);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [equities, setEquities] = useState<Equities>(Array(8).fill(null));
  const [error, setError] = useState<string | null>(null);

  // Authentication state to prevent infinite loops
  const [authFailed, setAuthFailed] = useState<boolean>(false);
  const [lastAuthError, setLastAuthError] = useState<string | null>(null);

  // Poker hand simulation state
  const [dealerPosition, setDealerPosition] = useState<number>(0);
  const [activePlayer, setActivePlayer] = useState<number | null>(null);
  const [foldedPlayers, setFoldedPlayers] = useState<Set<number>>(new Set());
  const [handPhase, setHandPhase] = useState<
    'preflop' | 'flop' | 'turn' | 'river' | 'showdown'
  >('preflop');
  const [actionComplete, setActionComplete] = useState<boolean>(false);
  const [actionSequence, setActionSequence] = useState<
    Array<{ playerId: number; action: string; amount: number; street: string }>
  >([]);

  // Betting state
  const [lastPlayerToAct, setLastPlayerToAct] = useState<number | null>(null);
  const [hasBetThisRound, setHasBetThisRound] = useState<boolean>(false);
  const [playersActed, setPlayersActed] = useState<Set<number>>(new Set());

  // Chip and pot management
  const [chipStacks, setChipStacksState] = useState<number[]>(
    Array(8).fill(100)
  );
  const [defaultStackSize, setDefaultStackSize] = useState<number>(100);
  const [pot, setPot] = useState<number>(0);
  const [currentBet, setCurrentBet] = useState<number>(0);
  const [lastRaiseAmount, setLastRaiseAmount] = useState<number>(0);
  const [showBetInput, setShowBetInput] = useState<number | null>(null);
  const [betInputValue, setBetInputValue] = useState<number>(1);
  const [playerInvested, setPlayerInvested] = useState<number[]>(
    Array(8).fill(0)
  );

  // All-in and side pot management
  const [sidePots, setSidePots] = useState<
    Array<{ amount: number; eligiblePlayers: number[] }>
  >([]);
  const [allInPlayers, setAllInPlayers] = useState<Set<number>>(new Set());
  const [mainPot, setMainPot] = useState<number>(0);

  // Chip reduction functionality
  const [chipReductionPercentage, setChipReductionPercentage] =
    useState<number>(10);

  // Card visibility management
  const [cardsHidden, setCardsHidden] = useState<boolean>(false);
  const [revealedPlayers, setRevealedPlayers] = useState<Set<number>>(
    new Set()
  );

  // Winner state management
  const [winner, setWinner] = useState<number | null>(null);
  const [showWinnerNotification, setShowWinnerNotification] =
    useState<boolean>(false);

  // Removed seats management
  const [removedSeats, setRemovedSeats] = useState<Set<number>>(new Set());

  // Chip and pot management functions
  const setAllChipStacks = () => {
    setChipStacksState(Array(8).fill(defaultStackSize));
  };

  const collectAntes = () => {
    const newChipStacks = [...chipStacks];
    const newPlayerInvested = [...playerInvested];
    let antesCollected = 0;

    // Collect antes from all active players (those in hand)
    newChipStacks.forEach((stack, index) => {
      if (stack > 0 && players[index].isInHand) {
        const ante = Math.min(1, stack);
        newChipStacks[index] -= ante;
        newPlayerInvested[index] += ante;
        antesCollected += ante;
      }
    });

    setChipStacksState(newChipStacks);
    setPlayerInvested(newPlayerInvested);
    setMainPot(antesCollected);
    setPot(antesCollected);
    setCurrentBet(0);
    setLastRaiseAmount(0);
    setHasBetThisRound(false);
    setLastPlayerToAct(null);
  };

  const calculateMaxBet = (playerIndex: number) => {
    const maxBet = Math.min(chipStacks[playerIndex] || 0, pot || 0);
    return Math.max(maxBet, 1);
  };

  const calculateMaxRaise = (playerIndex: number) => {
    if (currentBet === 0) {
      return calculateMaxBet(playerIndex);
    }

    const callAmount = Math.max(
      0,
      currentBet - (playerInvested[playerIndex] || 0)
    );
    const potAfterCall = (pot || 0) + callAmount;
    const maxRaise = callAmount + potAfterCall;

    const maxRaiseAmount = Math.min(chipStacks[playerIndex] || 0, maxRaise);
    return Math.max(maxRaiseAmount, 1);
  };

  const calculateMinRaise = useCallback((): number => {
    if (currentBet === 0) {
      return 1;
    }

    // If no active player, return a default minimum raise
    if (activePlayer === null || activePlayer === undefined) {
      return Math.max(1, lastRaiseAmount);
    }

    const callAmount = currentBet - playerInvested[activePlayer];
    const minRaise = callAmount + Math.max(lastRaiseAmount, 1);

    return Math.max(minRaise, 1);
  }, [currentBet, playerInvested, activePlayer, lastRaiseAmount]);

  const getNextActivePlayer = useCallback(
    (currentPlayer: number, allInPlayersSet: Set<number> = allInPlayers) => {
      const activePlayers = players
        .map((cards, index) => ({ index, hasCards: cards.cards.length === 4 }))
        .filter(
          p =>
            p.hasCards &&
            !foldedPlayers.has(p.index) &&
            !allInPlayersSet.has(p.index)
        );

      if (activePlayers.length <= 1) return null;

      const currentIndex = activePlayers.findIndex(
        p => p.index === currentPlayer
      );
      const nextIndex = (currentIndex + 1) % activePlayers.length;
      return activePlayers[nextIndex].index;
    },
    [players, foldedPlayers, allInPlayers]
  );

  const calculateSidePots = useCallback(
    (invested: number[], allInPlayersSet: Set<number>) => {
      const newSidePots: Array<{ amount: number; eligiblePlayers: number[] }> =
        [];

      const allInInvestments = Array.from(allInPlayersSet)
        .map(playerIndex => invested[playerIndex])
        .filter(amount => amount > 0)
        .sort((a, b) => a - b);

      if (allInInvestments.length === 0) {
        setSidePots([]);
        return;
      }

      const playersInHand: number[] = players
        .map((player, index) => ({ index, cards: player.cards }))
        .filter(
          player =>
            player.cards.length === 4 && !foldedPlayers.has(player.index)
        )
        .map(player => player.index);

      let previousLevel = 0;

      allInInvestments.forEach(level => {
        if (level > previousLevel) {
          const potContribution = level - previousLevel;
          const eligiblePlayers = playersInHand.filter(
            playerIndex => invested[playerIndex] >= level
          );

          if (eligiblePlayers.length > 1) {
            const potAmount = potContribution * eligiblePlayers.length;
            newSidePots.push({
              amount: potAmount,
              eligiblePlayers: [...eligiblePlayers],
            });
          }

          previousLevel = level;
        }
      });

      setSidePots(newSidePots);
    },
    [players, foldedPlayers, setSidePots]
  );

  const dealTurnAuto = useCallback(() => {
    let index = nextCardIndex;
    index++; // Burn
    setTopTurn(deck[index++]);
    setBottomTurn(deck[index++]);
    setNextCardIndex(index);
    setHandPhase('turn');
    setHasBetThisRound(false);
    setLastPlayerToAct(null);
    setPlayersActed(new Set());
    setActivePlayer(null);
    setActionComplete(false);
  }, [
    deck,
    setTopTurn,
    setBottomTurn,
    setNextCardIndex,
    setHandPhase,
    setHasBetThisRound,
    setLastPlayerToAct,
    setPlayersActed,
    setActivePlayer,
    setActionComplete,
    nextCardIndex,
  ]);

  const dealRiverAuto = useCallback(() => {
    let index = nextCardIndex;
    index++; // Burn
    setTopRiver(deck[index++]);
    setBottomRiver(deck[index++]);
    setNextCardIndex(index);
    setHandPhase('river');
    setHasBetThisRound(false);
    setLastPlayerToAct(null);
    setPlayersActed(new Set());
    setActivePlayer(null);
    setActionComplete(false);
  }, [
    deck,
    setTopRiver,
    setBottomRiver,
    setNextCardIndex,
    setHandPhase,
    setHasBetThisRound,
    setLastPlayerToAct,
    setPlayersActed,
    setActivePlayer,
    setActionComplete,
    nextCardIndex,
  ]);

  const distributePot = useCallback(async () => {
    // If no pot accumulated, nothing to do
    if ((pot || 0) <= 0 && (mainPot || 0) <= 0 && sidePots.length === 0) {
      return;
    }

    try {
      const playersWithCards: Array<{
        player_number: number;
        cards: string[];
      }> = [];
      players.forEach((p, index) => {
        if (p.cards.length === 4) {
          playersWithCards.push({
            player_number: index + 1,
            cards: convertCardsForBackend(p.cards) as string[],
          });
        }
      });

      const body = {
        players: playersWithCards,
        topBoard: convertCardsForBackend(
          [...(topFlop || []), topTurn, topRiver].filter(Boolean) as string[]
        ),
        bottomBoard: convertCardsForBackend(
          [...(bottomFlop || []), bottomTurn, bottomRiver].filter(
            Boolean
          ) as string[]
        ),
        playerInvested: playerInvested,
        foldedPlayers: Array.from(foldedPlayers),
      };

      const resp = await api.post('/resolve-showdown', body);
      const { payouts } = resp.data || {};

      if (Array.isArray(payouts) && payouts.length === chipStacks.length) {
        const newChipStacks = [...chipStacks];
        payouts.forEach((amount: number, idx: number) => {
          newChipStacks[idx] += Math.max(0, Math.floor(amount || 0));
        });
        setChipStacksState(newChipStacks);
      } else {
        // Fallback to refund invested if payouts malformed
        const fallbackStacks = [...chipStacks];
        playerInvested.forEach((invested, index) => {
          fallbackStacks[index] += invested;
        });
        setChipStacksState(fallbackStacks);
      }
    } catch (e) {
      // On error, fallback to simple refund to avoid breaking UX
      const newChipStacks = [...chipStacks];
      playerInvested.forEach((invested, index) => {
        newChipStacks[index] += invested;
      });
      setChipStacksState(newChipStacks);
    } finally {
      // Reset pots and investments
      setPot(0);
      setMainPot(0);
      setSidePots([]);
      setPlayerInvested(Array(8).fill(0));
    }
  }, [
    players,
    chipStacks,
    playerInvested,
    foldedPlayers,
    topFlop,
    bottomFlop,
    topTurn,
    bottomTurn,
    topRiver,
    bottomRiver,
    pot,
    mainPot,
    sidePots,
    setChipStacksState,
    setPot,
    setMainPot,
    setSidePots,
    setPlayerInvested,
  ]);

  const dealNextStreet = useCallback(() => {
    if (handPhase === 'flop') {
      dealTurnAuto();
    } else if (handPhase === 'turn') {
      dealRiverAuto();
    } else if (handPhase === 'river') {
      setHandPhase('showdown');
      setTimeout(() => {
        distributePot();
      }, 1000);
    }
  }, [handPhase, dealTurnAuto, dealRiverAuto, setHandPhase, distributePot]);

  const startBettingAction = useCallback(() => {
    setHasBetThisRound(false);
    setLastPlayerToAct(null);
    setPlayersActed(new Set());
    setCurrentBet(0);
    setLastRaiseAmount(0);

    const activePlayers = players
      .map((cards, index) => ({ index, hasCards: cards.cards.length === 4 }))
      .filter(
        p =>
          p.hasCards &&
          !foldedPlayers.has(p.index) &&
          !allInPlayers.has(p.index)
      );

    if (activePlayers.length > 1) {
      let firstPlayer = (dealerPosition + 1) % 8;

      let attempts = 0;
      while (
        !activePlayers.some(p => p.index === firstPlayer) &&
        attempts < 8
      ) {
        firstPlayer = (firstPlayer + 1) % 8;
        attempts++;
      }

      if (activePlayers.some(p => p.index === firstPlayer)) {
        setActivePlayer(firstPlayer);
      }
    }
  }, [players, foldedPlayers, allInPlayers, dealerPosition]);

  const deal = () => {
    const newDeck = shuffle(generateDeck());
    const newPlayers = Array(8)
      .fill(null)
      .map(() => ({ cards: [] as string[], isInHand: false }));
    // Only deal cards to active players (excluding removed seats)
    let cardIndex = 0;
    for (let i = 0; i < numActivePlayers; i++) {
      if (!removedSeats.has(i)) {
        newPlayers[i] = {
          cards: newDeck.slice(cardIndex * 4, (cardIndex + 1) * 4),
          isInHand: true,
        };
        cardIndex++;
      }
    }
    const cardsUsed = cardIndex * 4;
    const top: string[] = newDeck.slice(cardsUsed + 1, cardsUsed + 4);
    const bottom: string[] = newDeck.slice(cardsUsed + 5, cardsUsed + 8);

    setDeck(newDeck);
    setPlayers(newPlayers);
    setTopFlop(top);
    setBottomFlop(bottom);
    setTopTurn(null);
    setBottomTurn(null);
    setTopRiver(null);
    setBottomRiver(null);
    setNextCardIndex(cardsUsed + 8); // After player cards + flop cards
    setFoldedPlayers(new Set());
    setHandPhase('flop');
    setActionComplete(false);
    setActionSequence([]);

    setHasBetThisRound(false);
    setLastPlayerToAct(null);
    setPlayersActed(new Set());
    setCurrentBet(0);
    setLastRaiseAmount(0);
    setPlayerInvested(Array(8).fill(0));
    setShowBetInput(null);
    setActivePlayer(null);

    setAllInPlayers(new Set());
    setSidePots([]);
    setMainPot(0);
    setPot(0);
    // No collectAntes here; handled by useEffect below

    // Reset winner state
    setWinner(null);
    setShowWinnerNotification(false);
  };

  // Collect antes after cards are dealt (all active players are in hand, pot is 0)
  useEffect(() => {
    // Only run if a hand was just dealt (all active players are in hand, pot is 0)
    const allActiveInHand = players
      .slice(0, numActivePlayers)
      .every(p => p.isInHand);
    if (allActiveInHand && pot === 0 && mainPot === 0) {
      collectAntes();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [players, numActivePlayers, pot, mainPot]);

  const nextHand = () => {
    setDealerPosition(prev => (prev + 1) % 8);
    setActivePlayer(null);
    setActionComplete(false);
    setHandPhase('flop');
    setFoldedPlayers(new Set());
    setActionSequence([]);

    setLastPlayerToAct(null);
    setHasBetThisRound(false);
    setPlayersActed(new Set());
    setPot(0);
    setCurrentBet(0);
    setLastRaiseAmount(0);
    setPlayerInvested(Array(8).fill(0));
    setShowBetInput(null);

    setAllInPlayers(new Set());
    setSidePots([]);
    setMainPot(0);

    setPlayers(
      Array(8)
        .fill(null)
        .map(() => ({ cards: [] as string[], isInHand: false }))
    );
    setTopFlop([] as string[]);
    setBottomFlop([] as string[]);
    setTopTurn(null);
    setBottomTurn(null);
    setTopRiver(null);
    setBottomRiver(null);
    setEquities(Array(8).fill(null));

    // Reset winner state
    setWinner(null);
    setShowWinnerNotification(false);
  };

  const handleBetInputSubmit = (
    playerIndex: number,
    action: 'bet' | 'raise'
  ) => {
    const betValue = Number(betInputValue);
    if (isNaN(betValue) || betValue <= 0) {
      setError('Please enter a valid bet amount');
      return;
    }

    if (action === 'bet') {
      const maxBet = calculateMaxBet(playerIndex);
      if (betValue > maxBet) {
        setError(`Maximum bet is ${maxBet} BB`);
        return;
      }
    } else if (action === 'raise') {
      const maxRaise = calculateMaxRaise(playerIndex);
      const minRaise = calculateMinRaise();
      if (betValue < minRaise) {
        setError(`Minimum raise is ${minRaise} BB`);
        return;
      }
      if (betValue > maxRaise) {
        setError(`Maximum raise is ${maxRaise} BB`);
        return;
      }
    }

    setBetInputValue(1);
    handlePlayerAction(playerIndex, action, betValue);
  };

  const handleBetInputCancel = () => {
    setBetInputValue(1);
    setShowBetInput(null);
  };

  const rebuyPlayer = (playerIndex: number) => {
    const newChipStacks = [...chipStacks];
    newChipStacks[playerIndex] = defaultStackSize;
    setChipStacksState(newChipStacks);
  };

  const reduceAllChips = () => {
    if (chipReductionPercentage <= 0 || chipReductionPercentage >= 100) {
      setError('Please enter a valid percentage between 1 and 99');
      return;
    }

    const newChipStacks = chipStacks.map(stack => {
      const reduction = Math.floor(stack * (chipReductionPercentage / 100));
      return Math.max(0, stack - reduction);
    });

    setChipStacksState(newChipStacks);
  };

  const toggleGlobalCardVisibility = () => {
    setCardsHidden(!cardsHidden);
    if (cardsHidden) {
      setRevealedPlayers(new Set());
    }
  };

  const togglePlayerReveal = (playerIndex: number) => {
    const newRevealedPlayers = new Set(revealedPlayers);
    if (newRevealedPlayers.has(playerIndex)) {
      newRevealedPlayers.delete(playerIndex);
    } else {
      newRevealedPlayers.add(playerIndex);
    }
    setRevealedPlayers(newRevealedPlayers);
  };

  const checkBettingComplete = useCallback(
    (
      currentPlayer: number,
      action: string,
      remainingPlayers: Array<{ index: number }>,
      actedPlayers: Set<number>,
      allInPlayersSet: Set<number>,
      foldedPlayersSet: Set<number>,
      playerInvestedArray: number[],
      currentBetAmount: number
    ) => {
      const playersWhoCanAct = remainingPlayers.filter(
        p => !allInPlayersSet.has(p.index)
      );

      if (!hasBetThisRound && action !== 'bet') {
        const allActed = playersWhoCanAct.every(p => actedPlayers.has(p.index));
        return allActed;
      }

      if (hasBetThisRound && currentBetAmount > 0) {
        const playersInHand = playersWhoCanAct.filter(
          p => !foldedPlayersSet.has(p.index)
        );

        if (playersInHand.length <= 1) {
          return true;
        }

        const allPlayersMatched = playersInHand.every(p => {
          const hasMatchedBet =
            playerInvestedArray[p.index] >= currentBetAmount;
          const hasActed = actedPlayers.has(p.index);
          return hasMatchedBet && hasActed;
        });

        return allPlayersMatched;
      }

      return false;
    },
    [hasBetThisRound]
  );

  const awardPotToWinner = useCallback(
    (winnerIndex: number) => {
      const newChipStacks = [...chipStacks];

      // Award the entire pot to the winner
      newChipStacks[winnerIndex] += pot;

      setChipStacksState(newChipStacks);
      setPot(0);
      setMainPot(0);
      setSidePots([]);
      setPlayerInvested(Array(8).fill(0));

      // Set winner state
      setWinner(winnerIndex);
      setShowWinnerNotification(true);

      // Clear winner notification after 3 seconds
      setTimeout(() => {
        setShowWinnerNotification(false);
        setWinner(null);
      }, 3000);
    },
    [
      chipStacks,
      pot,
      setChipStacksState,
      setPot,
      setMainPot,
      setSidePots,
      setPlayerInvested,
      setWinner,
      setShowWinnerNotification,
    ]
  );

  const handlePlayerAction = useCallback(
    (
      playerIndex: number,
      action: 'fold' | 'call' | 'check' | 'bet' | 'raise',
      betAmount: number = 0
    ) => {
      const newChipStacks = [...chipStacks];
      const newPlayerInvested = [...playerInvested];
      let newPot = pot;
      let newCurrentBet = currentBet;
      let newLastRaiseAmount = lastRaiseAmount;
      const newAllInPlayers = new Set([...allInPlayers]);
      const newFoldedPlayers = new Set([...foldedPlayers]);

      // Add action to sequence
      const newAction = {
        playerId: playerIndex,
        action: action,
        amount: betAmount || 0,
        street: handPhase,
      };
      setActionSequence(prev => [...prev, newAction]);

      if (action === 'fold') {
        newFoldedPlayers.add(playerIndex);
        setFoldedPlayers(newFoldedPlayers);
        setPlayers(prev => {
          const updated = prev.map((p, i) =>
            i === playerIndex ? { ...p, isInHand: false } : p
          );
          return updated;
        });
      } else if (action === 'call') {
        const callAmount = currentBet - playerInvested[playerIndex];
        const availableChips = newChipStacks[playerIndex];

        if (availableChips <= callAmount) {
          newChipStacks[playerIndex] = 0;
          newPlayerInvested[playerIndex] += availableChips;
          newPot += availableChips;
          newAllInPlayers.add(playerIndex);
        } else {
          newChipStacks[playerIndex] -= callAmount;
          newPlayerInvested[playerIndex] += callAmount;
          newPot += callAmount;
        }
      } else if (action === 'check') {
        // No chips moved for check
      } else if (action === 'bet') {
        if (betAmount > 0) {
          const availableChips = newChipStacks[playerIndex];
          const actualBet = Math.min(betAmount, availableChips);

          newChipStacks[playerIndex] -= actualBet;
          newPlayerInvested[playerIndex] += actualBet;
          newPot += actualBet;
          newCurrentBet = newPlayerInvested[playerIndex];
          newLastRaiseAmount = actualBet;
          setHasBetThisRound(true);
          setLastPlayerToAct(playerIndex);
          setShowBetInput(null);

          if (availableChips === actualBet) {
            newAllInPlayers.add(playerIndex);
          }
        } else {
          setShowBetInput(playerIndex);
          setBetInputValue(1);
          return;
        }
      } else if (action === 'raise') {
        if (betAmount > 0) {
          const availableChips = newChipStacks[playerIndex];
          const actualRaise = Math.min(betAmount, availableChips);

          newChipStacks[playerIndex] -= actualRaise;
          newPlayerInvested[playerIndex] += actualRaise;
          newPot += actualRaise;
          newLastRaiseAmount = newPlayerInvested[playerIndex] - currentBet;
          newCurrentBet = newPlayerInvested[playerIndex];
          setLastPlayerToAct(playerIndex);
          setShowBetInput(null);

          if (availableChips === actualRaise) {
            newAllInPlayers.add(playerIndex);
          }
        } else {
          const minRaise = calculateMinRaise();
          setShowBetInput(playerIndex);
          setBetInputValue(minRaise);
          return;
        }
      }

      setChipStacksState(newChipStacks);
      setPlayerInvested(newPlayerInvested);
      setPot(newPot);
      setCurrentBet(newCurrentBet);
      setLastRaiseAmount(newLastRaiseAmount);
      setAllInPlayers(newAllInPlayers);

      if (newAllInPlayers.size > 0) {
        calculateSidePots(newPlayerInvested, newAllInPlayers);
      }

      const newPlayersActed = new Set([...playersActed, playerIndex]);
      setPlayersActed(newPlayersActed);

      const remainingPlayers = players
        .map((cards, index) => ({ index, hasCards: cards.cards.length === 4 }))
        .filter(p => p.hasCards && !newFoldedPlayers.has(p.index));

      const playersWhoCanAct = remainingPlayers.filter(
        p => !newAllInPlayers.has(p.index)
      );
      if (playersWhoCanAct.length <= 1) {
        setActivePlayer(null);
        setActionComplete(true);
        // Award immediately only if there is exactly ONE remaining player in hand
        // (everyone else folded). If others are all-in, proceed to next street.
        if (remainingPlayers.length === 1) {
          const winnerIndex = remainingPlayers[0].index;
          awardPotToWinner(winnerIndex);
        } else {
          // Either all players are all-in, or only one can act while others are all-in
          // -> advance the board to showdown for proper split handling.
          dealNextStreet();
        }
        return;
      }

      const isBettingComplete = checkBettingComplete(
        playerIndex,
        action,
        remainingPlayers,
        newPlayersActed,
        newAllInPlayers,
        newFoldedPlayers,
        newPlayerInvested,
        newCurrentBet
      );

      if (isBettingComplete) {
        setActivePlayer(null);
        setActionComplete(true);
        dealNextStreet();
      } else {
        const nextPlayer = getNextActivePlayer(playerIndex, newAllInPlayers);
        setActivePlayer(nextPlayer);
      }
    },
    [
      chipStacks,
      playerInvested,
      pot,
      currentBet,
      lastRaiseAmount,
      allInPlayers,
      foldedPlayers,
      setFoldedPlayers,
      setPlayers,
      setHasBetThisRound,
      setLastPlayerToAct,
      setShowBetInput,
      setBetInputValue,
      setChipStacksState,
      setPlayerInvested,
      setPot,
      setCurrentBet,
      setLastRaiseAmount,
      setAllInPlayers,
      calculateSidePots,
      players,
      playersActed,
      setPlayersActed,
      setActivePlayer,
      setActionComplete,
      awardPotToWinner,
      dealNextStreet,
      checkBettingComplete,
      getNextActivePlayer,
      calculateMinRaise,
      handPhase,
    ]
  );

  const fetchEquities = useCallback(async () => {
    // Prevent multiple simultaneous calls
    if (isLoading) {
      return;
    }

    // Prevent calls if authentication has failed
    if (authFailed) {
      return;
    }

    setIsLoading(true);
    // Clear previous equities to avoid showing stale categories while fetching
    setEquities(Array(8).fill(null));
    try {
      const playersWithCards: Array<{
        player_number: number;
        cards: string[];
      }> = [];
      players.forEach((cards, index) => {
        if (cards.cards.length === 4 && !foldedPlayers.has(index)) {
          playersWithCards.push({
            player_number: index + 1,
            cards: convertCardsForBackend(cards.cards) as string[],
          });
        }
      });

      const requestBody = {
        players: playersWithCards,
        topBoard: convertCardsForBackend(
          [...topFlop, topTurn, topRiver].filter(Boolean) as string[]
        ),
        bottomBoard: convertCardsForBackend(
          [...bottomFlop, bottomTurn, bottomRiver].filter(Boolean) as string[]
        ),
        quick_mode: true,
        num_iterations: 1000,
      };

      const response = await api.post('/simulated-equity', requestBody);
      const data = response.data;

      const newEquities = Array(8).fill(null);

      const validPlayerNumbers = new Set(
        playersWithCards.map(p => p.player_number)
      );
      data.forEach(
        (playerResult: {
          player_number: number;
          top_estimated_equity: number;
          top_actual_equity: number;
          bottom_estimated_equity: number;
          bottom_actual_equity: number;
          chop_both_boards: number;
          scoop_both_boards: number;
          split_top: number;
          split_bottom: number;
          top_hand_category?: string;
          bottom_hand_category?: string;
        }) => {
          if (!validPlayerNumbers.has(playerResult.player_number)) {
            return;
          }
          const playerIndex = playerResult.player_number - 1;
          newEquities[playerIndex] = {
            // Backend returns actual equity as percentages, estimated equity as decimals
            top_estimated: (playerResult.top_estimated_equity * 100).toFixed(1),
            top_actual: playerResult.top_actual_equity.toFixed(1),
            bottom_estimated: (
              playerResult.bottom_estimated_equity * 100
            ).toFixed(1),
            bottom_actual: playerResult.bottom_actual_equity.toFixed(1),
            // Whole hand analysis - backend returns these as decimals, convert to percentages
            chop_both_boards: (playerResult.chop_both_boards * 100).toFixed(1),
            scoop_both_boards: (playerResult.scoop_both_boards * 100).toFixed(
              1
            ),
            split_top: (playerResult.split_top * 100).toFixed(1),
            split_bottom: (playerResult.split_bottom * 100).toFixed(1),
            // Hand categories passthrough from backend if present (no relabeling on frontend)
            top_hand_category: playerResult.top_hand_category,
            bottom_hand_category: playerResult.bottom_hand_category,
          };
        }
      );

      setEquities(newEquities);
      // Reset auth failure state on successful call
      setAuthFailed(false);
      setLastAuthError(null);
    } catch (error) {
      // Check if this is an authentication error first
      const anyErr = error as
        | { isAuthError?: boolean; message?: unknown }
        | undefined;
      if (anyErr && anyErr.isAuthError === true) {
        setAuthFailed(true);
        setLastAuthError(String(anyErr.message ?? ''));
        // Set default equities and continue
        const defaultEquities = Array(8).fill(null) as Equities;
        setEquities(defaultEquities);
        return;
      }

      // For other errors, just set default equities and continue
      const defaultEquities = Array(8).fill(null) as Equities;
      setEquities(defaultEquities);
    } finally {
      setIsLoading(false);
    }
  }, [
    players,
    foldedPlayers,
    topFlop,
    bottomFlop,
    topTurn,
    bottomTurn,
    topRiver,
    bottomRiver,
    authFailed,
    isLoading,
  ]);

  // Effects
  useEffect(() => {
    // Only fetch equities if we have players with cards and auth hasn't failed
    // Note: fetchEquities already checks isLoading internally to prevent multiple calls
    if (players.some(player => player.cards.length === 4) && !authFailed) {
      fetchEquities();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    players,
    foldedPlayers,
    topFlop,
    bottomFlop,
    topTurn,
    bottomTurn,
    topRiver,
    bottomRiver,
    authFailed,
  ]);

  // Listen for authentication success to reset auth state
  useEffect(() => {
    const handleAuthSuccess = () => {
      setAuthFailed(false);
      setLastAuthError(null);
    };

    // Listen for custom auth success event
    window.addEventListener('auth-success', handleAuthSuccess);

    return () => {
      window.removeEventListener('auth-success', handleAuthSuccess);
    };
  }, []);

  useEffect(() => {
    const shouldStartBetting =
      (handPhase === 'flop' || handPhase === 'turn' || handPhase === 'river') &&
      players.some(player => player.cards.length === 4) &&
      activePlayer === null &&
      !actionComplete;

    if (shouldStartBetting) {
      startBettingAction();
    }
  }, [
    players,
    activePlayer,
    actionComplete,
    currentBet,
    startBettingAction,
    handPhase,
  ]);

  // Reset authentication state (call this when user logs in)
  const resetAuthState = () => {
    setAuthFailed(false);
    setLastAuthError(null);
  };

  // Remove seat functionality
  const removeSeat = (seatIndex: number) => {
    setRemovedSeats(prev => {
      const newSet = new Set(prev);
      newSet.add(seatIndex);
      return newSet;
    });
    // Clear the player's cards
    setPlayers(prev => {
      const newPlayers = [...prev];
      newPlayers[seatIndex] = { cards: [], isInHand: false };
      return newPlayers;
    });
  };

  const addBackSeat = (seatIndex: number) => {
    setRemovedSeats(prev => {
      const newSet = new Set(prev);
      newSet.delete(seatIndex);
      return newSet;
    });
  };

  return {
    // State
    players,
    numActivePlayers,
    deck,
    topFlop,
    bottomFlop,
    topTurn,
    bottomTurn,
    topRiver,
    bottomRiver,
    isLoading,
    equities,
    dealerPosition,
    activePlayer,
    foldedPlayers,
    handPhase,
    actionComplete,
    actionSequence,
    lastPlayerToAct,
    hasBetThisRound,
    playersActed,
    chipStacks,
    defaultStackSize,
    pot,
    currentBet,
    lastRaiseAmount,
    showBetInput,
    betInputValue,
    playerInvested,
    sidePots,
    allInPlayers,
    mainPot,
    chipReductionPercentage,
    setChipReductionPercentage,
    cardsHidden,
    revealedPlayers,
    error,

    // Authentication state
    authFailed,
    lastAuthError,

    // Winner state
    winner,
    showWinnerNotification,

    // Removed seats
    removedSeats,

    // Actions
    setAllChipStacks,
    setChipStacks: (stacks: number[]) => {
      setChipStacksState(stacks);
    },
    setNumActivePlayers: (count: number) => {
      setNumActivePlayers(count);
    },
    setPlayers,
    collectAntes,
    calculateMaxBet,
    calculateMaxRaise,
    calculateMinRaise,
    deal,
    nextHand,
    handleBetInputSubmit,
    handleBetInputCancel,
    rebuyPlayer,
    reduceAllChips,
    toggleGlobalCardVisibility,
    togglePlayerReveal,
    handlePlayerAction,
    setBetInputValue: (newValue: number) => {
      if (typeof newValue === 'number' && !isNaN(newValue)) {
        setBetInputValue(newValue);
      }
    },
    setDefaultStackSize,
    resetAuthState,
    distributePot,
    awardPotToWinner,
    removeSeat,
    addBackSeat,
    dealTurn: dealTurnAuto,
    dealRiver: dealRiverAuto,
  };
};
