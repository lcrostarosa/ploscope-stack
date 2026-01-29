import React, { FormEvent, useState } from 'react';

import { useAuth } from '../../contexts/AuthContext';
import './AuthErrorModal.scss';

type AuthErrorModalProps = {
  isOpen: boolean;
  onClose: () => void;
  onLoginSuccess?: () => void;
};

const AuthErrorModal: React.FC<AuthErrorModalProps> = ({
  isOpen,
  onClose,
  onLoginSuccess,
}) => {
  const { authError, clearAuthError, login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [loginError, setLoginError] = useState('');

  const handleLogin = async (e: FormEvent) => {
    e.preventDefault();
    setIsLoggingIn(true);
    setLoginError('');

    try {
      const result = await login(email, password);
      if (result.success) {
        clearAuthError();
        onLoginSuccess?.();
        onClose();
      } else {
        setLoginError(result.error ?? 'Login failed. Please try again.');
      }
    } catch (error) {
      setLoginError('Login failed. Please try again.');
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleClose = () => {
    clearAuthError();
    onClose();
  };

  if (!isOpen || !authError) {
    return null;
  }

  return (
    <div className="auth-error-modal-overlay">
      <div className="auth-error-modal">
        <div className="auth-error-modal-header">
          <h2>🔐 Session Expired</h2>
          <button className="close-button" onClick={handleClose}>
            ×
          </button>
        </div>

        <div className="auth-error-modal-content">
          <div className="auth-error-message">
            <p>{authError}</p>
            <p className="auth-error-subtitle">
              Please log in again to continue your session.
            </p>
          </div>

          <form onSubmit={handleLogin} className="auth-error-login-form">
            <div className="form-group">
              <label htmlFor="email">Email</label>
              <input
                type="email"
                id="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
                placeholder="Enter your email"
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password</label>
              <input
                type="password"
                id="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                placeholder="Enter your password"
              />
            </div>

            {loginError && <div className="login-error">{loginError}</div>}

            <div className="auth-error-modal-actions">
              <button
                type="submit"
                className="btn btn-primary"
                disabled={isLoggingIn}
              >
                {isLoggingIn ? 'Logging in...' : 'Log In'}
              </button>

              <button
                type="button"
                className="btn btn-secondary"
                onClick={handleClose}
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AuthErrorModal;
