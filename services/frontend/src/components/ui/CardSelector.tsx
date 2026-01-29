import React from 'react';

import { CardSelectorProps } from '../../types';
import {
  shortSuits,
  ranks,
  convertCardToEmojiFormat,
} from '../../utils/constants';

import { Card } from './Card';
import './CardSelector.scss';

export const CardSelector: React.FC<CardSelectorProps> = ({
  value,
  onChange,
  disabled = false,
  placeholder = 'Select card',
  usedCards = new Set(),
}) => {
  // Use shortSuits for internal values (text format: As, Kh, etc.)
  const allCards = shortSuits.flatMap(suit =>
    ranks.map(rank => `${rank}${suit}`)
  );
  const availableCards = allCards.filter(
    card => !usedCards.has(card) || card === value
  );

  return (
    <div className="card-selector-container">
      <select
        className="card-selector"
        value={value}
        onChange={e => onChange(e.target.value)}
        disabled={disabled}
      >
        <option value="">{placeholder}</option>
        <option value="RANDOM">🎲 Random</option>
        {availableCards.map(card => (
          <option key={card} value={card}>
            {convertCardToEmojiFormat(card)}
          </option>
        ))}
      </select>
    </div>
  );
};

// Enhanced CardSelector with preview
export const CardSelectorWithPreview: React.FC<CardSelectorProps> = ({
  value,
  onChange,
  disabled = false,
  placeholder = 'Select card',
  usedCards = new Set(),
}) => {
  // Use shortSuits for internal values (text format: As, Kh, etc.)
  const allCards = shortSuits.flatMap(suit =>
    ranks.map(rank => `${rank}${suit}`)
  );
  const availableCards = allCards.filter(
    card => !usedCards.has(card) || card === value
  );

  return (
    <div className="card-selector-with-preview">
      <Card card={value || ''} />
      <select
        className="card-selector"
        value={value}
        onChange={e => onChange(e.target.value)}
        disabled={disabled}
      >
        <option value="">{placeholder}</option>
        <option value="RANDOM">🎲 Random</option>
        {availableCards.map(card => (
          <option key={card} value={card}>
            {convertCardToEmojiFormat(card)}
          </option>
        ))}
      </select>
    </div>
  );
};
