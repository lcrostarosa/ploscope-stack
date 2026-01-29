import React, { useState, useEffect } from 'react';

import { convertCardToEmojiFormat } from '../../utils/constants';
import { Card } from '../ui/Card';
import './CardEditorModal.scss';

type CardEditorModalProps = {
  isOpen: boolean;
  onClose: () => void;
  onSave: (editedGameState: EditedGameState) => void;
  initialGameState: {
    players: Array<{ cards: string[] }>;
    topFlop: string[];
    bottomFlop: string[];
    topTurn: string | null;
    bottomTurn: string | null;
    topRiver: string | null;
    bottomRiver: string | null;
    numActivePlayers: number;
  };
};

export type EditedGameState = {
  players: Array<{ cards: string[] }>;
  topFlop: string[];
  bottomFlop: string[];
  topTurn: string | null;
  bottomTurn: string | null;
  topRiver: string | null;
  bottomRiver: string | null;
};

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

const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'];
const suits = ['h', 'd', 'c', 's'];

export const CardEditorModal: React.FC<CardEditorModalProps> = ({
  isOpen,
  onClose,
  onSave,
  initialGameState,
}) => {
  const [editedState, setEditedState] = useState<EditedGameState>({
    players: [],
    topFlop: [],
    bottomFlop: [],
    topTurn: null,
    bottomTurn: null,
    topRiver: null,
    bottomRiver: null,
  });

  const [cardPicker, setCardPicker] = useState<CardPickerState>(null);

  // Initialize edited state when modal opens
  useEffect(() => {
    if (isOpen) {
      setEditedState({
        players: initialGameState.players.map(p => ({ cards: [...p.cards] })),
        topFlop: [...initialGameState.topFlop],
        bottomFlop: [...initialGameState.bottomFlop],
        topTurn: initialGameState.topTurn,
        bottomTurn: initialGameState.bottomTurn,
        topRiver: initialGameState.topRiver,
        bottomRiver: initialGameState.bottomRiver,
      });
    }
  }, [isOpen, initialGameState]);

  if (!isOpen) return null;

  const getUsedCards = (): Set<string> => {
    const used = new Set<string>();
    editedState.players.forEach(player => {
      player.cards.forEach(card => {
        if (card && card !== '') used.add(card);
      });
    });
    editedState.topFlop.forEach(card => {
      if (card) used.add(card);
    });
    editedState.bottomFlop.forEach(card => {
      if (card) used.add(card);
    });
    if (editedState.topTurn) used.add(editedState.topTurn);
    if (editedState.bottomTurn) used.add(editedState.bottomTurn);
    if (editedState.topRiver) used.add(editedState.topRiver);
    if (editedState.bottomRiver) used.add(editedState.bottomRiver);
    return used;
  };

  const allCards = suits.flatMap(suit => ranks.map(rank => `${rank}${suit}`));
  const usedCards = getUsedCards();
  const availableCards = allCards.filter(card => !usedCards.has(card));

  const handleCardClick = (type: 'player' | 'board', meta: any) => {
    setCardPicker({ type, ...meta });
  };

  const handleSelectCard = (card: string) => {
    if (!cardPicker) return;

    const newState = { ...editedState };

    if (
      cardPicker.type === 'player' &&
      cardPicker.playerIndex !== undefined &&
      cardPicker.cardIndex !== undefined
    ) {
      newState.players[cardPicker.playerIndex].cards[cardPicker.cardIndex] =
        card;
    } else if (cardPicker.type === 'board' && cardPicker.boardType) {
      if (cardPicker.boardType === 'topFlop') {
        newState.topFlop[cardPicker.flopIndex!] = card;
      } else if (cardPicker.boardType === 'bottomFlop') {
        newState.bottomFlop[cardPicker.flopIndex!] = card;
      } else if (cardPicker.boardType === 'topTurn') {
        newState.topTurn = card;
      } else if (cardPicker.boardType === 'bottomTurn') {
        newState.bottomTurn = card;
      } else if (cardPicker.boardType === 'topRiver') {
        newState.topRiver = card;
      } else if (cardPicker.boardType === 'bottomRiver') {
        newState.bottomRiver = card;
      }
    }

    setEditedState(newState);
    setCardPicker(null);
  };

  const handleSave = () => {
    onSave(editedState);
    onClose();
  };

  return (
    <div className="card-editor-modal-overlay" onClick={onClose}>
      <div className="card-editor-modal" onClick={e => e.stopPropagation()}>
        <div className="card-editor-header">
          <h2>✏️ Edit Cards</h2>
          <button className="close-btn" onClick={onClose}>
            ×
          </button>
        </div>

        <div className="card-editor-content">
          {/* Players Section */}
          <div className="editor-section">
            <h3>Players</h3>
            <div className="players-grid">
              {editedState.players
                .slice(0, initialGameState.numActivePlayers)
                .map((player, playerIndex) => (
                  <div key={playerIndex} className="player-editor">
                    <h4>Player {playerIndex + 1}</h4>
                    <div className="player-cards">
                      {player.cards.map((card, cardIndex) => (
                        <div
                          key={cardIndex}
                          className="card-slot"
                          onClick={() =>
                            handleCardClick('player', {
                              playerIndex,
                              cardIndex,
                            })
                          }
                        >
                          {card ? (
                            <Card card={card} isClickable />
                          ) : (
                            <div className="empty-card">?</div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
            </div>
          </div>

          {/* Board Section */}
          <div className="editor-section">
            <h3>Community Cards</h3>

            <div className="board-editor">
              <h4>Top Board</h4>
              <div className="board-cards">
                <div className="flop-cards">
                  <label>Flop:</label>
                  {editedState.topFlop.map((card, index) => (
                    <div
                      key={index}
                      className="card-slot"
                      onClick={() =>
                        handleCardClick('board', {
                          boardType: 'topFlop',
                          flopIndex: index,
                        })
                      }
                    >
                      {card ? (
                        <Card card={card} isClickable />
                      ) : (
                        <div className="empty-card">?</div>
                      )}
                    </div>
                  ))}
                </div>
                <div className="turn-river">
                  <label>Turn:</label>
                  <div
                    className="card-slot"
                    onClick={() =>
                      handleCardClick('board', { boardType: 'topTurn' })
                    }
                  >
                    {editedState.topTurn ? (
                      <Card card={editedState.topTurn} isClickable />
                    ) : (
                      <div className="empty-card">?</div>
                    )}
                  </div>
                  <label>River:</label>
                  <div
                    className="card-slot"
                    onClick={() =>
                      handleCardClick('board', { boardType: 'topRiver' })
                    }
                  >
                    {editedState.topRiver ? (
                      <Card card={editedState.topRiver} isClickable />
                    ) : (
                      <div className="empty-card">?</div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <div className="board-editor">
              <h4>Bottom Board</h4>
              <div className="board-cards">
                <div className="flop-cards">
                  <label>Flop:</label>
                  {editedState.bottomFlop.map((card, index) => (
                    <div
                      key={index}
                      className="card-slot"
                      onClick={() =>
                        handleCardClick('board', {
                          boardType: 'bottomFlop',
                          flopIndex: index,
                        })
                      }
                    >
                      {card ? (
                        <Card card={card} isClickable />
                      ) : (
                        <div className="empty-card">?</div>
                      )}
                    </div>
                  ))}
                </div>
                <div className="turn-river">
                  <label>Turn:</label>
                  <div
                    className="card-slot"
                    onClick={() =>
                      handleCardClick('board', { boardType: 'bottomTurn' })
                    }
                  >
                    {editedState.bottomTurn ? (
                      <Card card={editedState.bottomTurn} isClickable />
                    ) : (
                      <div className="empty-card">?</div>
                    )}
                  </div>
                  <label>River:</label>
                  <div
                    className="card-slot"
                    onClick={() =>
                      handleCardClick('board', { boardType: 'bottomRiver' })
                    }
                  >
                    {editedState.bottomRiver ? (
                      <Card card={editedState.bottomRiver} isClickable />
                    ) : (
                      <div className="empty-card">?</div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="card-editor-footer">
          <button className="cancel-btn" onClick={onClose}>
            Cancel
          </button>
          <button className="save-btn" onClick={handleSave}>
            Save Changes
          </button>
        </div>

        {/* Card Picker Modal */}
        {cardPicker && (
          <div
            className="card-picker-overlay"
            onClick={() => setCardPicker(null)}
          >
            <div
              className="card-picker-modal"
              onClick={e => e.stopPropagation()}
            >
              <h3>Select Card</h3>
              <div className="card-picker-grid">
                <div
                  className="card-picker-option"
                  onClick={() => handleSelectCard('')}
                >
                  <div className="empty-card">Clear</div>
                </div>
                {availableCards.map(card => (
                  <div
                    key={card}
                    className="card-picker-option"
                    onClick={() => handleSelectCard(card)}
                  >
                    <Card card={card} isClickable />
                  </div>
                ))}
              </div>
              <button
                className="close-picker-btn"
                onClick={() => setCardPicker(null)}
              >
                Cancel
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
