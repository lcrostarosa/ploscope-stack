import React, { useState, useEffect } from 'react';

import type { CardProps } from '../../types/UITypes';
import { getSuitClass, convertCardToEmojiFormat } from '../../utils/constants';

export const Card: React.FC<CardProps> = ({
  card,
  onClick,
  isClickable = false,
  hidden = false,
}) => {
  // Local animation state – toggled whenever the card value changes
  const [animate, setAnimate] = useState(false);

  // Trigger animation when a (non-empty) card is received / updated
  useEffect(() => {
    if (card && card.length >= 2) {
      setAnimate(true);

      // Remove the animation class after it finishes so hover/other transforms aren't affected
      const timer = setTimeout(() => setAnimate(false), 400);
      return () => clearTimeout(timer);
    }
  }, [card]);

  // Handle hidden cards
  if (hidden) {
    return (
      <div
        className={`card hidden ${isClickable ? 'clickable' : ''} ${animate ? 'deal-animation' : ''}`}
        onClick={isClickable ? onClick : undefined}
        style={{ cursor: isClickable ? 'pointer' : 'default' }}
      >
        ?
      </div>
    );
  }

  // Do not render empty / placeholder cards
  if (!card || card.length < 2) {
    return null;
  }

  // Convert card to emoji format for display
  const displayCard = (convertCardToEmojiFormat(card) || '') as string;
  const rank = displayCard ? displayCard[0] : '';
  const suit = displayCard ? displayCard[1] : '';

  return (
    <div
      className={`card ${getSuitClass((suit || '') as any)} ${isClickable ? 'clickable' : ''} ${animate ? 'deal-animation' : ''}`}
      onClick={isClickable ? onClick : undefined}
      style={{ cursor: isClickable ? 'pointer' : 'default' }}
    >
      <div className="card-suit">{suit}</div>
      <div className="card-rank">{rank}</div>
    </div>
  );
};
