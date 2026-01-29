import React, { useState, useEffect } from 'react';

import { useNavigate } from 'react-router-dom';

import { api } from '@/utils/auth';
import { logError, logInfo } from '@/utils/logger';

import { Card } from '../ui/Card';

import { CardPickerModal } from './CardPickerModal';
import './SpotAnalysisConfirmationModal.scss';

type Job = {
  id: string | number;
  status: string;
  created_at?: string;
  job_type?: string;
  progress?: number;
  result?: any;
  error_message?: string;
};

type SpotAnalysisConfirmationModalProps = {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  gameState: {
    players: Array<{ cards: string[] }>;
    topFlop: string[];
    bottomFlop: string[];
    topTurn: string | null;
    bottomTurn: string | null;
    topRiver: string | null;
    bottomRiver: string | null;
    numActivePlayers: number;
    foldedPlayers?: Set<number>;
  };
  simulationSettings: {
    simulation_runs: number;
  };
};

export const SpotAnalysisConfirmationModal: React.FC<
  SpotAnalysisConfirmationModalProps
> = ({ isOpen, onClose, onConfirm, gameState, simulationSettings }) => {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loadingJobs, setLoadingJobs] = useState(false);
  const [isEditingCards, setIsEditingCards] = useState(false);
  const [cardPicker, setCardPicker] = useState<{
    type: 'player' | 'foldedPlayer' | 'community';
    playerIndex?: number;
    cardIndex?: number;
    boardType?: 'top' | 'bottom';
    street?: 'flop' | 'turn' | 'river';
  } | null>(null);
  const [editedGameState, setEditedGameState] = useState(gameState);
  const [removedPlayers, setRemovedPlayers] = useState<Set<number>>(new Set());
  const navigate = useNavigate();

  useEffect(() => {
    if (isOpen) {
      fetchRecentJobs();
      setEditedGameState(gameState);
      setRemovedPlayers(new Set());
    }
  }, [isOpen, gameState]);

  // Card editing logic
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
    editedGameState.players.forEach(p => {
      (p.cards || []).forEach(c => {
        if (c) used.add(c);
      });
    });

    // Add community cards to used cards
    editedGameState.topFlop.forEach(c => {
      if (c) used.add(c);
    });
    editedGameState.bottomFlop.forEach(c => {
      if (c) used.add(c);
    });
    if (editedGameState.topTurn) used.add(editedGameState.topTurn);
    if (editedGameState.bottomTurn) used.add(editedGameState.bottomTurn);
    if (editedGameState.topRiver) used.add(editedGameState.topRiver);
    if (editedGameState.bottomRiver) used.add(editedGameState.bottomRiver);

    return used;
  };

  const getCurrentCommunityCard = (): string | null => {
    if (!cardPicker || cardPicker.type !== 'community') return null;
    const { boardType, street, cardIndex } = cardPicker;

    if (street === 'flop' && cardIndex !== undefined) {
      return boardType === 'top'
        ? editedGameState.topFlop[cardIndex]
        : editedGameState.bottomFlop[cardIndex];
    } else if (street === 'turn') {
      return boardType === 'top'
        ? editedGameState.topTurn
        : editedGameState.bottomTurn;
    } else if (street === 'river') {
      return boardType === 'top'
        ? editedGameState.topRiver
        : editedGameState.bottomRiver;
    }
    return null;
  };

  const availableCards = (() => {
    if (!cardPicker) return allCards.filter(c => !getUsedCards().has(c));
    const used = getUsedCards();
    if (cardPicker.type === 'player' || cardPicker.type === 'foldedPlayer') {
      const current =
        editedGameState.players[cardPicker.playerIndex!]?.cards?.[
          cardPicker.cardIndex!
        ];
      if (current) used.delete(current);
    } else if (cardPicker.type === 'community') {
      // Allow reusing the current card being edited
      const current = getCurrentCommunityCard();
      if (current) used.delete(current);
    }
    return allCards.filter(c => !used.has(c));
  })();

  const handleCardClick = (
    type: 'player' | 'foldedPlayer',
    playerIndex: number,
    cardIndex: number
  ) => {
    if (!isEditingCards) return;
    setCardPicker({ type, playerIndex, cardIndex });
  };

  const handleCommunityCardClick = (
    boardType: 'top' | 'bottom',
    street: 'flop' | 'turn' | 'river',
    cardIndex?: number
  ) => {
    if (!isEditingCards) return;
    setCardPicker({ type: 'community', boardType, street, cardIndex });
  };

  const handleSelectCard = (card: string) => {
    if (!cardPicker) return;
    const { type, playerIndex, cardIndex, boardType, street } = cardPicker;

    if (type === 'player' || type === 'foldedPlayer') {
      setEditedGameState(prev => ({
        ...prev,
        players: prev.players.map((player, index) =>
          index === playerIndex
            ? {
                ...player,
                cards: player.cards.map((c, i) => (i === cardIndex ? card : c)),
              }
            : player
        ),
      }));
    } else if (type === 'community') {
      setEditedGameState(prev => {
        const newState = { ...prev };

        if (street === 'flop' && cardIndex !== undefined) {
          if (boardType === 'top') {
            newState.topFlop = newState.topFlop.map((c, i) =>
              i === cardIndex ? card : c
            );
          } else {
            newState.bottomFlop = newState.bottomFlop.map((c, i) =>
              i === cardIndex ? card : c
            );
          }
        } else if (street === 'turn') {
          if (boardType === 'top') {
            newState.topTurn = card;
          } else {
            newState.bottomTurn = card;
          }
        } else if (street === 'river') {
          if (boardType === 'top') {
            newState.topRiver = card;
          } else {
            newState.bottomRiver = card;
          }
        }

        return newState;
      });
    }
    setCardPicker(null);
  };

  const handleRemovePlayer = (playerIndex: number) => {
    setRemovedPlayers(prev => {
      const newSet = new Set(prev);
      newSet.add(playerIndex);
      return newSet;
    });
    // Clear the player's cards
    setEditedGameState(prev => ({
      ...prev,
      players: prev.players.map((player, index) =>
        index === playerIndex ? { ...player, cards: ['', '', '', ''] } : player
      ),
    }));
  };

  const handleAddBackPlayer = (playerIndex: number) => {
    setRemovedPlayers(prev => {
      const newSet = new Set(prev);
      newSet.delete(playerIndex);
      return newSet;
    });
  };

  const addCommunityCard = (
    boardType: 'top' | 'bottom',
    street: 'flop' | 'turn' | 'river'
  ) => {
    setEditedGameState(prev => {
      const newState = { ...prev };

      if (street === 'flop') {
        if (boardType === 'top') {
          // Find first empty slot or add new one
          const emptyIndex = newState.topFlop.findIndex(card => !card);
          if (emptyIndex !== -1) {
            newState.topFlop[emptyIndex] = '';
          } else {
            newState.topFlop = [...newState.topFlop, ''];
          }
        } else {
          // Find first empty slot or add new one
          const emptyIndex = newState.bottomFlop.findIndex(card => !card);
          if (emptyIndex !== -1) {
            newState.bottomFlop[emptyIndex] = '';
          } else {
            newState.bottomFlop = [...newState.bottomFlop, ''];
          }
        }
      } else if (street === 'turn') {
        if (boardType === 'top') {
          newState.topTurn = '';
        } else {
          newState.bottomTurn = '';
        }
      } else if (street === 'river') {
        if (boardType === 'top') {
          newState.topRiver = '';
        } else {
          newState.bottomRiver = '';
        }
      }

      return newState;
    });
  };

  const removeCommunityCard = (
    boardType: 'top' | 'bottom',
    street: 'flop' | 'turn' | 'river',
    cardIndex?: number
  ) => {
    setEditedGameState(prev => {
      const newState = { ...prev };

      if (street === 'flop' && cardIndex !== undefined) {
        if (boardType === 'top') {
          newState.topFlop = newState.topFlop.map((card, i) =>
            i === cardIndex ? '' : card
          );
        } else {
          newState.bottomFlop = newState.bottomFlop.map((card, i) =>
            i === cardIndex ? '' : card
          );
        }
      } else if (street === 'turn') {
        if (boardType === 'top') {
          newState.topTurn = null;
        } else {
          newState.bottomTurn = null;
        }
      } else if (street === 'river') {
        if (boardType === 'top') {
          newState.topRiver = null;
        } else {
          newState.bottomRiver = null;
        }
      }

      return newState;
    });
  };

  const fetchRecentJobs = async () => {
    setLoadingJobs(true);
    try {
      const response = await api.get('/jobs/recent');
      const data = response.data;

      // Combine active and recent jobs
      const allJobs = [
        ...(data.active_jobs || []),
        ...(data.recent_jobs || []),
      ];

      // Filter for spot simulation jobs and sort by date
      const spotJobs = allJobs
        .filter(
          (job: Job) =>
            job.job_type?.toLowerCase().includes('spot') ||
            job.job_type?.toLowerCase().includes('simulation')
        )
        .sort((a: Job, b: Job) => {
          const dateA = new Date(a.created_at || 0).getTime();
          const dateB = new Date(b.created_at || 0).getTime();
          return dateB - dateA;
        })
        .slice(0, 5); // Show last 5 jobs

      setJobs(spotJobs);
      logInfo('Fetched recent spot jobs', { count: spotJobs.length });
    } catch (error) {
      logError('Error fetching recent jobs:', error);
    } finally {
      setLoadingJobs(false);
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'Unknown';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}d ago`;
  };

  const getStatusBadgeClass = (status: string) => {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'status-completed';
      case 'processing':
        return 'status-processing';
      case 'queued':
        return 'status-queued';
      case 'failed':
        return 'status-failed';
      default:
        return 'status-default';
    }
  };

  if (!isOpen) return null;

  const playersWithCards = editedGameState.players
    .filter(player => player.cards && player.cards.length === 4)
    .map((player, index) => ({
      ...player,
      playerIndex: index,
      isFolded: editedGameState.foldedPlayers?.has(index) || false,
      isRemoved: removedPlayers.has(index),
    }))
    .filter(player => !player.isRemoved);

  const removedPlayersList = editedGameState.players
    .map((player, index) => ({
      ...player,
      playerIndex: index,
      isRemoved: removedPlayers.has(index),
    }))
    .filter(player => player.isRemoved);

  const hasTopBoard =
    editedGameState.topFlop.some(c => c) ||
    editedGameState.topTurn ||
    editedGameState.topRiver;
  const hasBottomBoard =
    editedGameState.bottomFlop.some(c => c) ||
    editedGameState.bottomTurn ||
    editedGameState.bottomRiver;

  return (
    <div className="spot-confirmation-modal-overlay" onClick={onClose}>
      <div
        className="spot-confirmation-modal"
        onClick={e => e.stopPropagation()}
      >
        <div className="spot-confirmation-header">
          <h2>🎯 Confirm Spot Analysis</h2>
          <button className="close-btn" onClick={onClose}>
            ×
          </button>
        </div>

        <div className="spot-confirmation-content">
          {/* Configuration Preview */}
          <div className="confirmation-section">
            <h3>Analysis Configuration</h3>

            {/* Players */}
            <div className="players-preview">
              <div className="players-header">
                <h4>Players ({playersWithCards.length})</h4>
                <button
                  className={`edit-cards-btn ${isEditingCards ? 'active' : ''}`}
                  onClick={() => setIsEditingCards(!isEditingCards)}
                >
                  {isEditingCards ? 'Done Editing' : 'Edit Cards'}
                </button>
              </div>
              <div className="players-grid">
                {playersWithCards.map((player, index) => (
                  <div
                    key={player.playerIndex}
                    className={`player-preview ${player.isFolded ? 'folded' : ''}`}
                  >
                    <div className="player-header">
                      <span className="player-label">
                        Player {player.playerIndex + 1}
                        {player.isFolded && (
                          <span className="folded-indicator"> (Folded)</span>
                        )}
                      </span>
                      {isEditingCards && (
                        <button
                          className="remove-player-btn"
                          onClick={() => handleRemovePlayer(player.playerIndex)}
                          title="Remove player"
                        >
                          🗑️
                        </button>
                      )}
                    </div>
                    <div className="player-cards-preview">
                      {player.cards.map((card, cardIndex) => (
                        <div
                          key={cardIndex}
                          className={isEditingCards ? 'editable-card' : ''}
                          onClick={() =>
                            handleCardClick(
                              player.isFolded ? 'foldedPlayer' : 'player',
                              player.playerIndex,
                              cardIndex
                            )
                          }
                        >
                          {card ? (
                            <Card card={card} />
                          ) : (
                            <div className="empty-card-slot">
                              <span className="empty-card-text">+</span>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              {/* Removed Players Section */}
              {removedPlayersList.length > 0 && (
                <div className="removed-players-section">
                  <h5>Removed Players</h5>
                  <div className="removed-players-list">
                    {removedPlayersList.map(player => (
                      <div
                        key={player.playerIndex}
                        className="removed-player-item"
                      >
                        <span className="removed-player-label">
                          Player {player.playerIndex + 1}
                        </span>
                        <button
                          className="add-back-btn"
                          onClick={() =>
                            handleAddBackPlayer(player.playerIndex)
                          }
                          title="Add player back"
                        >
                          ↩️ Add Back
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Boards */}
            <div className="boards-preview">
              <div className="boards-header">
                <h4>Community Cards</h4>
                {isEditingCards && (
                  <div className="board-actions">
                    <button
                      className="add-board-btn"
                      onClick={() => {
                        if (!hasTopBoard) {
                          addCommunityCard('top', 'flop');
                        } else if (!hasBottomBoard) {
                          addCommunityCard('bottom', 'flop');
                        }
                      }}
                      disabled={
                        hasTopBoard && hasBottomBoard ? true : undefined
                      }
                      title="Add board"
                    >
                      + Add Board
                    </button>
                  </div>
                )}
              </div>

              {hasTopBoard && (
                <div className="board-preview">
                  <div className="board-header">
                    <span className="board-label">Top Board:</span>
                    {isEditingCards && (
                      <button
                        className="remove-board-btn"
                        onClick={() => {
                          setEditedGameState(prev => ({
                            ...prev,
                            topFlop: [],
                            topTurn: null,
                            topRiver: null,
                          }));
                        }}
                        title="Remove top board"
                      >
                        🗑️
                      </button>
                    )}
                  </div>
                  <div className="board-cards-preview">
                    {/* Flop cards */}
                    {editedGameState.topFlop.map((card, index) => (
                      <div
                        key={`flop-${index}`}
                        className={isEditingCards ? 'editable-card' : ''}
                        onClick={() =>
                          handleCommunityCardClick('top', 'flop', index)
                        }
                      >
                        {card ? (
                          <Card card={card} />
                        ) : (
                          <div className="empty-card-slot">
                            <span className="empty-card-text">+</span>
                          </div>
                        )}
                        {isEditingCards && card && (
                          <button
                            className="remove-card-btn"
                            onClick={e => {
                              e.stopPropagation();
                              removeCommunityCard('top', 'flop', index);
                            }}
                            title="Remove card"
                          >
                            ×
                          </button>
                        )}
                      </div>
                    ))}

                    {/* Add flop card button */}
                    {isEditingCards &&
                      (editedGameState.topFlop.some(card => !card) ||
                        editedGameState.topFlop.length < 3) && (
                        <button
                          className="add-card-btn"
                          onClick={() => addCommunityCard('top', 'flop')}
                          title="Add flop card"
                        >
                          + Flop
                        </button>
                      )}

                    {/* Turn card */}
                    {editedGameState.topTurn && (
                      <div
                        className={isEditingCards ? 'editable-card' : ''}
                        onClick={() => handleCommunityCardClick('top', 'turn')}
                      >
                        <Card card={editedGameState.topTurn} />
                        {isEditingCards && (
                          <button
                            className="remove-card-btn"
                            onClick={e => {
                              e.stopPropagation();
                              removeCommunityCard('top', 'turn');
                            }}
                            title="Remove turn card"
                          >
                            ×
                          </button>
                        )}
                      </div>
                    )}

                    {/* Add turn card button */}
                    {isEditingCards && !editedGameState.topTurn && (
                      <button
                        className="add-card-btn"
                        onClick={() => {
                          addCommunityCard('top', 'turn');
                          // Open card picker immediately for turn card
                          setTimeout(() => {
                            handleCommunityCardClick('top', 'turn');
                          }, 0);
                        }}
                        title="Add turn card"
                      >
                        + Turn
                      </button>
                    )}

                    {/* River card */}
                    {editedGameState.topRiver && (
                      <div
                        className={isEditingCards ? 'editable-card' : ''}
                        onClick={() => handleCommunityCardClick('top', 'river')}
                      >
                        <Card card={editedGameState.topRiver} />
                        {isEditingCards && (
                          <button
                            className="remove-card-btn"
                            onClick={e => {
                              e.stopPropagation();
                              removeCommunityCard('top', 'river');
                            }}
                            title="Remove river card"
                          >
                            ×
                          </button>
                        )}
                      </div>
                    )}

                    {/* Add river card button */}
                    {isEditingCards && !editedGameState.topRiver && (
                      <button
                        className="add-card-btn"
                        onClick={() => {
                          addCommunityCard('top', 'river');
                          // Open card picker immediately for river card
                          setTimeout(() => {
                            handleCommunityCardClick('top', 'river');
                          }, 0);
                        }}
                        title="Add river card"
                      >
                        + River
                      </button>
                    )}
                  </div>
                </div>
              )}

              {hasBottomBoard && (
                <div className="board-preview">
                  <div className="board-header">
                    <span className="board-label">Bottom Board:</span>
                    {isEditingCards && (
                      <button
                        className="remove-board-btn"
                        onClick={() => {
                          setEditedGameState(prev => ({
                            ...prev,
                            bottomFlop: [],
                            bottomTurn: null,
                            bottomRiver: null,
                          }));
                        }}
                        title="Remove bottom board"
                      >
                        🗑️
                      </button>
                    )}
                  </div>
                  <div className="board-cards-preview">
                    {/* Flop cards */}
                    {editedGameState.bottomFlop.map((card, index) => (
                      <div
                        key={`flop-${index}`}
                        className={isEditingCards ? 'editable-card' : ''}
                        onClick={() =>
                          handleCommunityCardClick('bottom', 'flop', index)
                        }
                      >
                        {card ? (
                          <Card card={card} />
                        ) : (
                          <div className="empty-card-slot">
                            <span className="empty-card-text">+</span>
                          </div>
                        )}
                        {isEditingCards && card && (
                          <button
                            className="remove-card-btn"
                            onClick={e => {
                              e.stopPropagation();
                              removeCommunityCard('bottom', 'flop', index);
                            }}
                            title="Remove card"
                          >
                            ×
                          </button>
                        )}
                      </div>
                    ))}

                    {/* Add flop card button */}
                    {isEditingCards &&
                      (editedGameState.bottomFlop.some(card => !card) ||
                        editedGameState.bottomFlop.length < 3) && (
                        <button
                          className="add-card-btn"
                          onClick={() => addCommunityCard('bottom', 'flop')}
                          title="Add flop card"
                        >
                          + Flop
                        </button>
                      )}

                    {/* Turn card */}
                    {editedGameState.bottomTurn && (
                      <div
                        className={isEditingCards ? 'editable-card' : ''}
                        onClick={() =>
                          handleCommunityCardClick('bottom', 'turn')
                        }
                      >
                        <Card card={editedGameState.bottomTurn} />
                        {isEditingCards && (
                          <button
                            className="remove-card-btn"
                            onClick={e => {
                              e.stopPropagation();
                              removeCommunityCard('bottom', 'turn');
                            }}
                            title="Remove turn card"
                          >
                            ×
                          </button>
                        )}
                      </div>
                    )}

                    {/* Add turn card button */}
                    {isEditingCards && !editedGameState.bottomTurn && (
                      <button
                        className="add-card-btn"
                        onClick={() => {
                          addCommunityCard('bottom', 'turn');
                          // Open card picker immediately for turn card
                          setTimeout(() => {
                            handleCommunityCardClick('bottom', 'turn');
                          }, 0);
                        }}
                        title="Add turn card"
                      >
                        + Turn
                      </button>
                    )}

                    {/* River card */}
                    {editedGameState.bottomRiver && (
                      <div
                        className={isEditingCards ? 'editable-card' : ''}
                        onClick={() =>
                          handleCommunityCardClick('bottom', 'river')
                        }
                      >
                        <Card card={editedGameState.bottomRiver} />
                        {isEditingCards && (
                          <button
                            className="remove-card-btn"
                            onClick={e => {
                              e.stopPropagation();
                              removeCommunityCard('bottom', 'river');
                            }}
                            title="Remove river card"
                          >
                            ×
                          </button>
                        )}
                      </div>
                    )}

                    {/* Add river card button */}
                    {isEditingCards && !editedGameState.bottomRiver && (
                      <button
                        className="add-card-btn"
                        onClick={() => {
                          addCommunityCard('bottom', 'river');
                          // Open card picker immediately for river card
                          setTimeout(() => {
                            handleCommunityCardClick('bottom', 'river');
                          }, 0);
                        }}
                        title="Add river card"
                      >
                        + River
                      </button>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Simulation Settings */}
            <div className="settings-preview">
              <h4>Simulation Settings</h4>
              <div className="settings-grid">
                <div className="setting-item">
                  <span className="setting-label">Simulation Runs:</span>
                  <span className="setting-value">
                    {simulationSettings.simulation_runs.toLocaleString()}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Recent Jobs */}
          <div className="confirmation-section">
            <h3>Recent Spot Analyses</h3>

            {loadingJobs ? (
              <div className="jobs-loading">
                <div className="small-spinner"></div>
                <span>Loading jobs...</span>
              </div>
            ) : jobs.length > 0 ? (
              <div className="jobs-list">
                {jobs.map(job => (
                  <div
                    key={job.id}
                    className={`job-item ${
                      job.status === 'completed' || job.status === 'COMPLETED'
                        ? 'clickable'
                        : ''
                    }`}
                    role={
                      job.status === 'completed' || job.status === 'COMPLETED'
                        ? 'button'
                        : undefined
                    }
                    tabIndex={
                      job.status === 'completed' || job.status === 'COMPLETED'
                        ? 0
                        : -1
                    }
                    title={
                      job.status === 'completed' || job.status === 'COMPLETED'
                        ? 'Open this spot analysis'
                        : undefined
                    }
                    onClick={async () => {
                      if (
                        !(
                          job.status === 'completed' ||
                          job.status === 'COMPLETED'
                        )
                      ) {
                        return;
                      }
                      try {
                        const response = await api.get(
                          `/jobs/${job.id}/details`
                        );
                        const fullJob = response.data.job;
                        const results =
                          fullJob?.result_data?.results || fullJob?.result_data;
                        navigate('/app/live', {
                          state: {
                            fromRecentJob: true,
                            jobId: job.id,
                            jobResults: results,
                            ts: Date.now(),
                          },
                        });
                      } catch (error) {
                        logError('Failed to open job results:', error);
                      }
                    }}
                    onKeyDown={async e => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        if (
                          !(
                            job.status === 'completed' ||
                            job.status === 'COMPLETED'
                          )
                        ) {
                          return;
                        }
                        try {
                          const response = await api.get(
                            `/jobs/${job.id}/details`
                          );
                          const fullJob = response.data.job;
                          const results =
                            fullJob?.result_data?.results ||
                            fullJob?.result_data;
                          navigate('/app/live', {
                            state: {
                              fromRecentJob: true,
                              jobId: job.id,
                              jobResults: results,
                              ts: Date.now(),
                            },
                          });
                        } catch (error) {
                          logError(
                            'Failed to open job results (keyboard):',
                            error
                          );
                        }
                      }
                    }}
                  >
                    <div className="job-info">
                      <div className="job-header-row">
                        <span className="job-id">
                          Job #{String(job.id).slice(-8)}
                        </span>
                        <span
                          className={`job-status ${getStatusBadgeClass(job.status)}`}
                        >
                          {job.status}
                        </span>
                      </div>
                      <div className="job-meta">
                        <span className="job-time">
                          {formatDate(job.created_at)}
                        </span>
                        {job.progress !== undefined &&
                          job.status === 'processing' && (
                            <span className="job-progress">
                              {job.progress}%
                            </span>
                          )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="no-jobs">
                <p>No recent spot analyses found</p>
              </div>
            )}
          </div>
        </div>

        <div className="spot-confirmation-footer">
          <button className="cancel-btn" onClick={onClose}>
            Cancel
          </button>
          <button
            className="confirm-btn"
            onClick={() => {
              // Update the original gameState with edited changes before confirming
              Object.assign(gameState, editedGameState);
              onConfirm();
            }}
          >
            🚀 Run Analysis
          </button>
        </div>

        {/* Card Picker Modal */}
        <CardPickerModal
          isOpen={!!cardPicker}
          availableCards={availableCards}
          onClose={() => setCardPicker(null)}
          onSelect={handleSelectCard}
        />
      </div>
    </div>
  );
};
