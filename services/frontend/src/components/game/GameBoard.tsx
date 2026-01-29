import React from 'react';

import type { SidePot } from '@/types/GameStateTypes';

import { Card, ActionButtons } from '../ui';

type GameBoardProps = {
  topFlop: string[];
  bottomFlop: string[];
  topTurn?: string;
  bottomTurn?: string;
  topRiver?: string;
  bottomRiver?: string;
  mainPot: number;
  pot: number;
  sidePots: SidePot[];
  editMode?: boolean;
  onBoardCardClick?: (
    meta:
      | { boardType: 'topFlop' | 'bottomFlop'; flopIndex: number }
      | { boardType: 'topTurn' | 'bottomTurn' | 'topRiver' | 'bottomRiver' }
  ) => void;
};

export const GameBoard: React.FC<GameBoardProps> = ({
  topFlop,
  bottomFlop,
  topTurn,
  bottomTurn,
  topRiver,
  bottomRiver,
  mainPot,
  pot,
  sidePots,
  editMode,
  onBoardCardClick,
}) => {
  return (
    <div className="board-container" data-testid="board-container">
      <div className="board" data-testid="board-section">
        <div className="boards-vertical">
          <div className="single-board">
            <h2>Top Board</h2>
            <div className="board-cards">
              {topFlop.map((card, i) =>
                card && card.length >= 2 ? (
                  <Card
                    key={i}
                    card={card}
                    isClickable={!!editMode}
                    onClick={
                      editMode
                        ? () =>
                            onBoardCardClick?.({
                              boardType: 'topFlop',
                              flopIndex: i,
                            })
                        : undefined
                    }
                  />
                ) : (
                  <Card
                    key={i}
                    card={'??'}
                    hidden
                    isClickable={!!editMode}
                    onClick={
                      editMode
                        ? () =>
                            onBoardCardClick?.({
                              boardType: 'topFlop',
                              flopIndex: i,
                            })
                        : undefined
                    }
                  />
                )
              )}
              {topTurn ? (
                <Card
                  card={topTurn}
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'topTurn' })
                      : undefined
                  }
                />
              ) : editMode ? (
                <Card
                  card={'??'}
                  hidden
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'topTurn' })
                      : undefined
                  }
                />
              ) : null}
              {topRiver ? (
                <Card
                  card={topRiver}
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'topRiver' })
                      : undefined
                  }
                />
              ) : editMode ? (
                <Card
                  card={'??'}
                  hidden
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'topRiver' })
                      : undefined
                  }
                />
              ) : null}
            </div>
          </div>
          <div className="single-board">
            <h2>Bottom Board</h2>
            <div className="board-cards">
              {bottomFlop.map((card, i) =>
                card && card.length >= 2 ? (
                  <Card
                    key={i}
                    card={card}
                    isClickable={!!editMode}
                    onClick={
                      editMode
                        ? () =>
                            onBoardCardClick?.({
                              boardType: 'bottomFlop',
                              flopIndex: i,
                            })
                        : undefined
                    }
                  />
                ) : (
                  <Card
                    key={i}
                    card={'??'}
                    hidden
                    isClickable={!!editMode}
                    onClick={
                      editMode
                        ? () =>
                            onBoardCardClick?.({
                              boardType: 'bottomFlop',
                              flopIndex: i,
                            })
                        : undefined
                    }
                  />
                )
              )}
              {bottomTurn ? (
                <Card
                  card={bottomTurn}
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'bottomTurn' })
                      : undefined
                  }
                />
              ) : editMode ? (
                <Card
                  card={'??'}
                  hidden
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'bottomTurn' })
                      : undefined
                  }
                />
              ) : null}
              {bottomRiver ? (
                <Card
                  card={bottomRiver}
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'bottomRiver' })
                      : undefined
                  }
                />
              ) : editMode ? (
                <Card
                  card={'??'}
                  hidden
                  isClickable={!!editMode}
                  onClick={
                    editMode
                      ? () => onBoardCardClick?.({ boardType: 'bottomRiver' })
                      : undefined
                  }
                />
              ) : null}
            </div>
          </div>
        </div>
      </div>
      <div className="pot-display">
        <div className="main-pot">
          <strong>Main Pot: {mainPot > 0 ? mainPot : pot} BB</strong>
        </div>
        {sidePots.length > 0 && (
          <div className="side-pots">
            {sidePots.map((sidePot, index) => (
              <div key={index} className="side-pot">
                <strong>
                  Side Pot {index + 1}: {sidePot.amount} BB
                </strong>
                <div className="eligible-players">
                  (
                  {sidePot.eligiblePlayers
                    .map((p: number) => `P${p + 1}`)
                    .join(', ')}
                  )
                </div>
              </div>
            ))}
          </div>
        )}
        <div className="total-pot">
          <strong>Total: {pot} BB</strong>
        </div>
      </div>
    </div>
  );
};
