import axios from 'axios';

import { logDebug } from './logger';

// Simple API configuration
const API_URL = process.env.REACT_APP_API_URL || '/api';

if (process.env.NODE_ENV === 'development')
  logDebug('🔧 API Configuration:', {
    REACT_APP_API_URL: process.env.REACT_APP_API_URL,
    API_URL: API_URL,
    NODE_ENV: process.env.NODE_ENV,
  });

// Create axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Validation utilities
export const ValidationUtils = {
  validateEmail: (email: string) => {
    if (!email || typeof email !== 'string') {
      return false;
    }

    // Basic email regex pattern
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  },

  validatePassword: (password: string) => {
    const errors: string[] = [];

    if (!password || password.length < 8) {
      errors.push('Password must be at least 8 characters long');
    }

    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }

    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }

    if (!/\d/.test(password)) {
      errors.push('Password must contain at least one number');
    }

    return {
      isValid: errors.length === 0,
      errors: errors,
    };
  },
};

// Simple token management
export const TokenManager = {
  getAccessToken: (): string | null => localStorage.getItem('access_token'),
  getRefreshToken: (): string | null => localStorage.getItem('refresh_token'),

  setTokens: (accessToken: string, refreshToken: string) => {
    localStorage.setItem('access_token', accessToken);
    localStorage.setItem('refresh_token', refreshToken);
  },

  clearTokens: () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
  },

  isLoggedIn: (): boolean => {
    return !!TokenManager.getAccessToken();
  },
};

// Simple request interceptor - just add the token
api.interceptors.request.use(
  config => {
    const token = TokenManager.getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => Promise.reject(error)
);

// Simple response interceptor - clear tokens on 401
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      TokenManager.clearTokens();

      // Dispatch global auth error event
      window.dispatchEvent(
        new CustomEvent('auth-error', {
          detail: { error: 'Authentication failed' },
        })
      );
    }
    return Promise.reject(error);
  }
);

// Authentication API functions
export const AuthAPI = {
  register: async (userData: Record<string, any>) => {
    try {
      const response = await api.post('/auth/register', userData);
      const { access_token, refresh_token, user } = response.data;

      TokenManager.setTokens(access_token, refresh_token);
      return { success: true, user, message: response.data.message };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || 'Registration failed',
      };
    }
  },

  login: async (email: string, password: string) => {
    try {
      const response = await api.post('/auth/login', { email, password });
      const { access_token, refresh_token, user } = response.data;

      TokenManager.setTokens(access_token, refresh_token);
      return { success: true, user, message: response.data.message };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || 'Login failed',
      };
    }
  },

  logout: async () => {
    try {
      await api.post('/auth/logout');
    } catch (error) {
      // if (process.env.NODE_ENV === 'development') logError('Logout error:', error);
    } finally {
      TokenManager.clearTokens();
    }
  },

  logoutAll: async () => {
    try {
      await api.post('/auth/logout-all');
    } catch (error) {
      // if (process.env.NODE_ENV === 'development') logError('Logout all error:', error);
    } finally {
      TokenManager.clearTokens();
    }
  },

  getCurrentUser: async () => {
    try {
      const response = await api.get('/auth/me');
      return { success: true, user: response.data };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || 'Failed to get user data',
      };
    }
  },

  updateProfile: async (profileData: Record<string, any>) => {
    try {
      const response = await api.put('/auth/update-profile', profileData);
      return {
        success: true,
        user: response.data.user,
        message: response.data.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || 'Profile update failed',
      };
    }
  },

  changePassword: async (currentPassword: string, newPassword: string) => {
    try {
      const response = await api.put('/auth/change-password', {
        current_password: currentPassword,
        new_password: newPassword,
      });
      return { success: true, message: response.data.message };
    } catch (error: any) {
      return {
        success: false,
        error: error.response?.data?.error || 'Password change failed',
      };
    }
  },
};

export { api };
