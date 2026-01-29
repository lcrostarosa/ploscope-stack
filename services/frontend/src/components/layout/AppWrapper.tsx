import React, { useCallback, useMemo, memo } from 'react';

import { useNavigate, useLocation, Outlet } from 'react-router-dom';

import { useAuth } from '../../contexts/AuthContext';
import {
  useAppUsageTracking,
  useEngagementTimeTracking,
} from '../../hooks/useAnalytics';
import AuthErrorModal from '../ui/AuthErrorModal';

import EnhancedPageTracker from './EnhancedPageTracker';
import { useAppGameState } from './useAppGameState';

export const AppWrapperComponent = memo(() => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, authError } = useAuth();

  // Setup mode is no longer used

  // Enhanced page tracking with Google Analytics

  // App usage tracking
  useAppUsageTracking('app_wrapper');

  // Engagement tracking
  useEngagementTimeTracking();

  // Determine mode from URL - memoized to prevent recalculation
  const modeInfo = useMemo(() => {
    const isLiveMode = location.pathname === '/app/live';

    return {
      isLiveMode,
    };
  }, [location.pathname]);

  // Use the custom game state hook
  const {
    showLiveModeSetup,
    gameState,
    handleResetGameConfig,
  } = useAppGameState(modeInfo);

  // Handle authentication error modal - memoized with useCallback
  const handleAuthErrorClose = useCallback(() => {
    // Optionally redirect to home or stay on current page
    if (!user) {
      navigate('/');
    }
  }, [user, navigate]);

  const handleAuthErrorLoginSuccess = useCallback(() => {
    // Refresh the current page or re-fetch data
    window.location.reload();
  }, []);

  return (
    <div className="app">
      <EnhancedPageTracker
        path={location.pathname}
        title={document.title}
        params={{
          user_id: user?.id,
          is_authenticated: !!user,
          mode: 'app',
        }}
        deps={[location.pathname, user?.id]}
      />

      {/* Main Content */}
      <div className={`app-content ${modeInfo.isLiveMode ? 'live-mode' : ''}`}>
        <Outlet
          context={{
            gameState,
            handleResetGameConfig,
            showLiveModeSetup,
          }}
        />
      </div>

      {/* Authentication Error Modal */}
      <AuthErrorModal
        isOpen={!!authError}
        onClose={handleAuthErrorClose}
        onLoginSuccess={handleAuthErrorLoginSuccess}
      />
    </div>
  );
});

AppWrapperComponent.displayName = 'AppWrapper';
