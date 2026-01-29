import React from 'react';

import CheckmarkIcon from '../ui/icons/CheckmarkIcon';

type RegistrationConfirmationProps = {
  user: { username?: string; email?: string } | null;
  onContinue?: () => void;
};

const RegistrationConfirmation: React.FC<RegistrationConfirmationProps> = ({
  user,
  onContinue,
}) => {
  const handleContinue = () => {
    if (onContinue) {
      onContinue();
    }
  };

  return (
    <div className="auth-form dark">
      <div className="confirmation-content">
        <div className="confirmation-icon">
          <CheckmarkIcon />
        </div>

        <h2>Welcome to PLOScope!</h2>

        <div className="confirmation-message">
          <p>Your account has been successfully created.</p>
          {user?.username && (
            <p className="username-display">
              Welcome, <strong>{user.username}</strong>!
            </p>
          )}
          {user?.email && (
            <p className="email-display">
              We&apos;ve sent a confirmation email to{' '}
              <strong>{user.email}</strong>
            </p>
          )}
        </div>

        <div className="next-steps">
          <h3>What&apos;s Next?</h3>
          <ul>
            <li>Explore our PLO analysis tools and features</li>
            <li>Check your email to verify your account</li>
            <li>Complete your profile to get started</li>
          </ul>
        </div>

        <div className="confirmation-actions">
          <button
            type="button"
            onClick={handleContinue}
            className="auth-button primary"
          >
            Go to App
          </button>
        </div>
      </div>
    </div>
  );
};

export default RegistrationConfirmation;
