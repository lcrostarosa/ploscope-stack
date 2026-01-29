import React from 'react';

import { Card } from '../ui/Card';
import './CardEditorModal.scss';

type CardPickerModalProps = {
  isOpen: boolean;
  availableCards: string[];
  onClose: () => void;
  onSelect: (card: string) => void;
  showClear?: boolean;
};

export const CardPickerModal: React.FC<CardPickerModalProps> = ({
  isOpen,
  availableCards,
  onClose,
  onSelect,
  showClear = true,
}) => {
  if (!isOpen) return null;

  return (
    <div className="card-picker-overlay" onClick={onClose}>
      <div className="card-picker-modal" onClick={e => e.stopPropagation()}>
        <h3>Select Card</h3>
        <div className="card-picker-grid">
          {showClear && (
            <div className="card-picker-option" onClick={() => onSelect('')}>
              <div className="empty-card">Clear</div>
            </div>
          )}
          {availableCards.map(card => (
            <div
              key={card}
              className="card-picker-option"
              onClick={() => onSelect(card)}
            >
              <Card card={card} isClickable />
            </div>
          ))}
        </div>
        <button className="close-picker-btn" onClick={onClose}>
          Cancel
        </button>
      </div>
    </div>
  );
};

export default CardPickerModal;





