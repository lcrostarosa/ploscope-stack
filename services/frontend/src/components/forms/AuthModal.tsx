import React, { MouseEvent, useEffect, useState, useCallback } from 'react';

import { useFormTracking } from '../../hooks/useAnalytics';

import Login from './Login';
import Register from './Register';
import './AuthModal.scss';

type AuthModalProps = {
  isOpen: boolean;
  onClose: () => void;
  defaultMode?: 'login' | 'register';
  onSuccess?: () => void;
};

const AuthModal: React.FC<AuthModalProps> = ({
  isOpen,
  onClose,
  defaultMode = 'login',
  onSuccess,
}) => {
  const [isLogin, setIsLogin] = useState(defaultMode === 'login');
  const { trackFormStart, trackFormSubmit } = useFormTracking('auth_modal');
  const [submittedSuccess, setSubmittedSuccess] = useState(false);

  // Reset state when modal opens
  useEffect(() => {
    if (isOpen) {
      setIsLogin(defaultMode === 'login');
      // Start form tracking on open
      trackFormStart();
    }
  }, [isOpen, defaultMode, trackFormStart]);

  // Unified close handler to track drop-offs
  const handleClose = useCallback(
    (reason = 'manual_close') => {
      if (!submittedSuccess) {
        trackFormSubmit(false, [reason]);
      }
      onClose();
    },
    [submittedSuccess, trackFormSubmit, onClose]
  );

  // Handle escape key
  useEffect(() => {
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        handleClose('escape');
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      // Prevent body scroll when modal is open
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, handleClose]);

  const handleAuthSuccess = () => {
    // Successful submit
    setSubmittedSuccess(true);
    trackFormSubmit(true, []);
    if (onSuccess) {
      onSuccess();
    } else {
      onClose();
    }
  };

  if (!isOpen) return null;

  // Handle click outside to close
  const handleOverlayClick = (event: MouseEvent<HTMLDivElement>) => {
    if (event.target === event.currentTarget) {
      handleClose('overlay_close');
    }
  };

  return (
    <div className="modal-overlay" onClick={handleOverlayClick}>
      <div className="modal-content">
        <button
          className="close-button"
          onClick={() => handleClose('close_button')}
        >
          ×
        </button>
        {isLogin ? (
          <Login
            onSwitchToRegister={() => setIsLogin(false)}
            onClose={handleAuthSuccess}
          />
        ) : (
          <Register
            onSwitchToLogin={() => setIsLogin(true)}
            onClose={handleAuthSuccess}
          />
        )}
      </div>
    </div>
  );
};

export default AuthModal;
