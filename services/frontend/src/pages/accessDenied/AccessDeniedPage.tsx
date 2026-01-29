import React from 'react';

import { useNavigate } from 'react-router-dom';

import './AccessDeniedPage.scss';

const AccessDeniedPage: React.FC = () => {
  const navigate = useNavigate();

  const handleLoginClick = () => {
    navigate('/');
  };

  return (
    <div className="access-denied-page">
      <div className="access-denied-container">
        <div className="access-denied-content">
          <div className="access-denied-icon">🔒</div>
          <h1 className="access-denied-title">Access Denied</h1>
          <p className="access-denied-message">
            You need to be logged in to access this page. Please sign in to continue.
          </p>
          <div className="access-denied-actions">
            <button
              className="login-button btn-primary"
              onClick={handleLoginClick}
            >
              Sign In
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AccessDeniedPage;
