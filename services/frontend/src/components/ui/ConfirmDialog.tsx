import React, { MouseEvent, useEffect } from 'react';

import './ConfirmDialog.scss';

type ConfirmDialogProps = {
  isOpen: boolean;
  title?: string;
  message: React.ReactNode;
  onConfirm: () => void;
  onCancel: () => void;
  confirmText?: string;
  cancelText?: string;
};

const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  isOpen,
  title = 'Confirm',
  message,
  onConfirm,
  onCancel,
  confirmText = 'Yes',
  cancelText = 'No',
}) => {
  // Handle escape key and focus trap
  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onCancel();
      } else if (event.key === 'Enter') {
        onConfirm();
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onCancel, onConfirm]);

  // Prevent background scroll
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  if (!isOpen) return null;

  const handleOverlayClick = (e: MouseEvent<HTMLDivElement>) => {
    if (e.target === e.currentTarget) {
      onCancel();
    }
  };

  return (
    <div className="confirm-dialog-overlay dark" onClick={handleOverlayClick}>
      <div
        className="confirm-dialog-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="confirm-dialog-title"
      >
        <div className="confirm-dialog-header">
          <h2 id="confirm-dialog-title">{title}</h2>
        </div>
        <div className="confirm-dialog-content">
          <p>{message}</p>
        </div>
        <div className="confirm-dialog-actions">
          <button className="btn btn-primary" onClick={onConfirm} autoFocus>
            {confirmText}
          </button>
          <button className="btn btn-secondary" onClick={onCancel}>
            {cancelText}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
