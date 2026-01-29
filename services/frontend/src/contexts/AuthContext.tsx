import React, { createContext, useContext, useState, useEffect } from 'react';

import type { AuthContextValue, AuthUser } from '../types/AuthTypes';
import { trackSignup, trackLogin } from '../utils/analytics';
import { AuthAPI, TokenManager } from '../utils/auth';
import { logDebug, logError } from '../utils/logger';

const AuthContext = createContext<AuthContextValue | null>(null);

export const useAuth = (): AuthContextValue => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [user, setUser] = useState<AuthUser>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [token, setToken] = useState<string | null>(null);
  const [authError, setAuthError] = useState<string | null>(null);

  // Update token when authentication status changes
  useEffect(() => {
    setToken(TokenManager.getAccessToken());
  }, [isAuthenticated]);

  // Check auth status on app startup
  useEffect(() => {
    const checkAuthStatus = async () => {
      if (process.env.NODE_ENV === 'development')
        logDebug('🔍 Checking auth status on app startup...');
      if (process.env.NODE_ENV === 'development')
        logDebug('🔍 TokenManager.isLoggedIn():', TokenManager.isLoggedIn());
      if (process.env.NODE_ENV === 'development')
        logDebug('🔍 Access token exists:', !!TokenManager.getAccessToken());
      if (process.env.NODE_ENV === 'development')
        logDebug('🔍 Refresh token exists:', !!TokenManager.getRefreshToken());

      if (TokenManager.isLoggedIn()) {
        if (process.env.NODE_ENV === 'development')
          logDebug(
            '🔍 User appears to be logged in, validating with backend...'
          );
        try {
          const result = await AuthAPI.getCurrentUser();
          if (process.env.NODE_ENV === 'development')
            logDebug('🔍 Backend validation result:', result);

          if (result.success) {
            setUser(result.user);
            setIsAuthenticated(true);
            setToken(TokenManager.getAccessToken());
            if (process.env.NODE_ENV === 'development')
              logDebug('✅ Session restored successfully');
          } else {
            if (process.env.NODE_ENV === 'development')
              logDebug('❌ Backend validation failed:', result.error);
            // Do not clear tokens here; interceptor will clear on 401
          }
        } catch (error) {
          if (process.env.NODE_ENV === 'development')
            logDebug('❌ Backend validation error:', error);
          // Do not clear tokens here; interceptor will clear on 401
        }
      } else {
        if (process.env.NODE_ENV === 'development')
          logDebug('🔍 No tokens found, user not logged in');
      }
      setLoading(false);
    };

    checkAuthStatus();
  }, []);

  // Listen for global auth errors
  useEffect(() => {
    const handleAuthErrorEvent = (event: Event) => {
      const customEvent = event as CustomEvent<{ error?: unknown }>;
      if (process.env.NODE_ENV === 'development')
        logDebug('Global auth error caught:', customEvent.detail?.error);
      setUser(null);
      setIsAuthenticated(false);
      setToken(null);
      TokenManager.clearTokens();
    };

    window.addEventListener('auth-error', handleAuthErrorEvent);
    return () => window.removeEventListener('auth-error', handleAuthErrorEvent);
  }, []);

  // Handle authentication errors from API calls
  const handleAuthError = (error: unknown) => {
    if ((error as { isAuthError?: boolean }).isAuthError) {
      setUser(null);
      setIsAuthenticated(false);
      setToken(null);

      // Provide specific message for no refresh token scenario
      if ((error as { noRefreshToken?: boolean }).noRefreshToken) {
        setAuthError(
          'Your session has expired. Please log in again to continue.'
        );
      } else {
        setAuthError('Your session has expired. Please log in again.');
      }
      return true; // Indicates this was an auth error
    }
    return false; // Not an auth error
  };

  const login = async (email: string, password: string) => {
    try {
      setAuthError(null);
      const result = await AuthAPI.login(email, password);
      if (result.success) {
        setUser(result.user);
        setIsAuthenticated(true);
        setToken(TokenManager.getAccessToken());

        // Track login event
        trackLogin('email', {
          user_id: result.user.id,
          email: result.user.email,
          username: result.user.username,
        });

        // Dispatch auth success event for other components
        window.dispatchEvent(new CustomEvent('auth-success'));
        return { success: true, message: result.message };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      if (handleAuthError(error)) {
        return { success: false, error: 'Authentication failed' };
      }
      return { success: false, error: 'Login failed' };
    }
  };

  const register = async (userData: Record<string, unknown>) => {
    try {
      setAuthError(null);
      const result = await AuthAPI.register(userData);
      if (result.success) {
        setUser(result.user);
        setIsAuthenticated(true);
        setToken(TokenManager.getAccessToken());

        // Track signup event
        trackSignup('email', {
          user_id: result.user.id,
          email: result.user.email,
          username: result.user.username,
          has_first_name: !!result.user.first_name,
          has_last_name: !!result.user.last_name,
        });

        // Dispatch auth success event for other components
        window.dispatchEvent(new CustomEvent('auth-success'));
        return { success: true, message: result.message, user: result.user };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      if (handleAuthError(error)) {
        return { success: false, error: 'Authentication failed' };
      }
      return { success: false, error: 'Registration failed' };
    }
  };

  const logout = async () => {
    try {
      await AuthAPI.logout();
    } catch (error) {
      logError('Logout error:', error);
    } finally {
      setUser(null);
      setIsAuthenticated(false);
      setToken(null);
      setAuthError(null);
    }
  };

  const logoutAll = async () => {
    try {
      await AuthAPI.logoutAll();
    } catch (error) {
      logError('Logout all error:', error);
    } finally {
      setUser(null);
      setIsAuthenticated(false);
      setToken(null);
      setAuthError(null);
    }
  };

  const updateProfile = async (profileData: Record<string, unknown>) => {
    try {
      const result = await AuthAPI.updateProfile(profileData);
      if (result.success) {
        setUser(result.user);
        return { success: true, message: result.message };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error) {
      if (handleAuthError(error)) {
        return { success: false, error: 'Authentication failed' };
      }
      return { success: false, error: 'Profile update failed' };
    }
  };

  const changePassword = async (
    currentPassword: string,
    newPassword: string
  ) => {
    try {
      const result = await AuthAPI.changePassword(currentPassword, newPassword);
      return result;
    } catch (error) {
      if (handleAuthError(error)) {
        return { success: false, error: 'Authentication failed' };
      }
      return { success: false, error: 'Password change failed' };
    }
  };

  const refreshUserData = async () => {
    try {
      if (isAuthenticated) {
        const result = await AuthAPI.getCurrentUser();
        if (result.success) {
          setUser(result.user);
        }
      }
    } catch (error) {
      logError('Failed to refresh user data:', error);
      if (handleAuthError(error)) {
        // Auth error handled by handleAuthError
      }
    }
  };

  const clearAuthError = () => {
    setAuthError(null);
  };

  const value = {
    user,
    isAuthenticated,
    loading,
    token,
    authError,
    login,
    register,
    logout,
    logoutAll,
    updateProfile,
    changePassword,
    refreshUserData,
    clearAuthError,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export default AuthContext;
