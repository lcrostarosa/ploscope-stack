import React, { FormEvent, ChangeEvent, useState } from 'react';

import { useNavigate } from 'react-router-dom';

import { useAuth } from '../../contexts/AuthContext';

type UserProfileProps = { onClose?: () => void };

type ProfileData = {
  username: string;
  firstName: string;
  lastName: string;
};

type PasswordData = {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
};

const UserProfile: React.FC<UserProfileProps> = ({ onClose }) => {
  const { user, logout, logoutAll, updateProfile, changePassword } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('profile');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Profile form state
  const [profileData, setProfileData] = useState<ProfileData>({
    username: user?.username || '',
    firstName: user?.first_name || '',
    lastName: user?.last_name || '',
  });

  // Password form state
  const [passwordData, setPasswordData] = useState<PasswordData>({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });

  const handleProfileChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setProfileData(prev => ({
      ...prev,
      [name]: value,
    }));

    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: '',
      }));
    }
  };

  const handlePasswordChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setPasswordData(prev => ({
      ...prev,
      [name]: value,
    }));

    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: '',
      }));
    }
  };

  const handleUpdateProfile = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setMessage('');
    setErrors({});

    try {
      const result = await updateProfile({
        username: profileData.username || undefined,
        first_name: profileData.firstName || undefined,
        last_name: profileData.lastName || undefined,
      });

      if (result.success) {
        setMessage('Profile updated successfully!');
      } else {
        setErrors({ profile: String(result.error ?? 'Profile update failed') });
      }
    } catch (error) {
      setErrors({ profile: 'Profile update failed' });
    } finally {
      setLoading(false);
    }
  };

  const handleChangePassword = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    // Validate passwords match
    if (passwordData.newPassword !== passwordData.confirmPassword) {
      setErrors({ confirmPassword: 'Passwords do not match' });
      return;
    }

    setLoading(true);
    setMessage('');
    setErrors({});

    try {
      const result = await changePassword(
        passwordData.currentPassword,
        passwordData.newPassword
      );

      if (result.success) {
        setMessage('Password changed successfully!');
        setPasswordData({
          currentPassword: '',
          newPassword: '',
          confirmPassword: '',
        });
      } else {
        setErrors({
          password: String(result.error ?? 'Password change failed'),
        });
      }
    } catch (error) {
      setErrors({ password: 'Password change failed' });
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    await logout();
    if (onClose) onClose();
  };

  const handleLogoutAll = async () => {
    await logoutAll();
    if (onClose) onClose();
  };

  const formatDate = (dateString: string | null | undefined) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleDateString();
  };

  return (
    <div className="user-profile">
      <div className="profile-header">
        <div className="profile-avatar">
          {user?.profile_picture ? (
            <img src={user.profile_picture} alt="Profile" />
          ) : (
            <div className="avatar-placeholder">
              {user?.first_name?.[0] || user?.email?.[0] || 'U'}
            </div>
          )}
        </div>
        <div className="profile-info">
          <h2>
            {user?.first_name || user?.username || 'User'} {user?.last_name}
          </h2>
          <p>{user?.email}</p>
          <p className="member-since">
            Member since {formatDate(user?.created_at)}
          </p>

          {/* Subscription Tier and Upgrade CTA */}
          <div className="subscription-section">
            <div className="current-tier">
              <span className="tier-badge">
                {user?.subscription_tier === 'free' && '🆓 Free Plan'}
                {user?.subscription_tier === 'pro' && '💎 Pro Plan'}
                {user?.subscription_tier === 'elite' && '👑 Elite Plan'}
              </span>
            </div>
            {user?.subscription_tier !== 'elite' && (
              <button
                className="upgrade-cta"
                onClick={() => navigate('/pricing')}
              >
                💎 Upgrade Plan
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="profile-tabs">
        <button
          className={`tab ${activeTab === 'profile' ? 'active' : ''}`}
          onClick={() => setActiveTab('profile')}
        >
          Profile
        </button>
        <button
          className={`tab ${activeTab === 'security' ? 'active' : ''}`}
          onClick={() => setActiveTab('security')}
        >
          Security
        </button>
        <button
          className={`tab ${activeTab === 'sessions' ? 'active' : ''}`}
          onClick={() => setActiveTab('sessions')}
        >
          Sessions
        </button>
      </div>

      {message && <div className="success-message">{message}</div>}

      {activeTab === 'profile' && (
        <div className="tab-content">
          <form onSubmit={handleUpdateProfile}>
            {errors.profile && (
              <div className="error-message">{errors.profile}</div>
            )}

            <div className="form-group">
              <label htmlFor="username">Username</label>
              <input
                type="text"
                id="username"
                name="username"
                value={profileData.username}
                onChange={handleProfileChange}
                placeholder="Enter username"
                disabled={loading}
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label htmlFor="firstName">First Name</label>
                <input
                  type="text"
                  id="firstName"
                  name="firstName"
                  value={profileData.firstName}
                  onChange={handleProfileChange}
                  placeholder="First name"
                  disabled={loading}
                />
              </div>
              <div className="form-group">
                <label htmlFor="lastName">Last Name</label>
                <input
                  type="text"
                  id="lastName"
                  name="lastName"
                  value={profileData.lastName}
                  onChange={handleProfileChange}
                  placeholder="Last name"
                  disabled={loading}
                />
              </div>
            </div>

            <button
              type="submit"
              className="auth-button primary"
              disabled={loading}
            >
              {loading ? 'Updating...' : 'Update Profile'}
            </button>
          </form>
        </div>
      )}

      {activeTab === 'security' && (
        <div className="tab-content">
          <form onSubmit={handleChangePassword}>
            {errors.password && (
              <div className="error-message">{errors.password}</div>
            )}

            <div className="form-group">
              <label htmlFor="currentPassword">Current Password</label>
              <input
                type="password"
                id="currentPassword"
                name="currentPassword"
                value={passwordData.currentPassword}
                onChange={handlePasswordChange}
                placeholder="Enter current password"
                disabled={loading}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="newPassword">New Password</label>
              <input
                type="password"
                id="newPassword"
                name="newPassword"
                value={passwordData.newPassword}
                onChange={handlePasswordChange}
                placeholder="Enter new password"
                disabled={loading}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="confirmPassword">Confirm New Password</label>
              <input
                type="password"
                id="confirmPassword"
                name="confirmPassword"
                value={passwordData.confirmPassword}
                onChange={handlePasswordChange}
                className={errors.confirmPassword ? 'error' : ''}
                placeholder="Confirm new password"
                disabled={loading}
                required
              />
              {errors.confirmPassword && (
                <span className="error-message">{errors.confirmPassword}</span>
              )}
            </div>

            <button
              type="submit"
              className="auth-button primary"
              disabled={loading}
            >
              {loading ? 'Changing...' : 'Change Password'}
            </button>
          </form>
        </div>
      )}

      {activeTab === 'sessions' && (
        <div className="tab-content">
          <div className="session-info">
            <h3>Active Sessions</h3>
            <p>Manage your active login sessions across devices.</p>

            <div className="session-actions">
              <button onClick={handleLogout} className="auth-button secondary">
                Sign Out This Device
              </button>
              <button onClick={handleLogoutAll} className="auth-button danger">
                Sign Out All Devices
              </button>
            </div>
          </div>

          {/* Upgrade CTA for non-elite users */}
          {user?.subscription_tier !== 'elite' && (
            <div className="upgrade-promo">
              <div className="upgrade-promo-content">
                <h4>🚀 Unlock Premium Features</h4>
                <p>
                  Upgrade to Elite for unlimited access to all analysis
                  features, priority support, and advanced analytics.
                </p>
                <button
                  className="upgrade-cta-promo"
                  onClick={() => navigate('/pricing')}
                >
                  💎 Upgrade to Elite
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default UserProfile;
