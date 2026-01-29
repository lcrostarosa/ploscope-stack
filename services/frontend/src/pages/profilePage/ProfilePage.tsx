import React from 'react';

import { useNavigate } from 'react-router-dom';

import { UserProfile } from '@/components/forms';
import { useAuth } from '@/contexts/AuthContext';

const ProfilePage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  // Redirect to login if not authenticated
  if (!user) {
    navigate('/');
    return null;
  }

  const handleClose = () => {
    navigate('/app/live');
  };

  return (
    <div className="profile-page">
      <div className="profile-page-container">
        <div className="profile-page-header">
          <button
            className="back-button"
            onClick={handleClose}
            aria-label="Back to home"
          >
            ← Back to Home
          </button>
          <h1>User Profile</h1>
        </div>

        <div className="profile-page-content">
          <UserProfile onClose={handleClose} />
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
