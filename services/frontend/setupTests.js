// Jest setup file for React Testing Library
// Polyfill for TextEncoder/TextDecoder must be first
import { TextEncoder, TextDecoder } from 'util';

import '@testing-library/jest-dom';
// eslint-disable-next-line
// @ts-ignore
global.TextEncoder = TextEncoder;
// eslint-disable-next-line
// @ts-ignore
global.TextDecoder = TextDecoder;

// Internal state for token mocks
let mockAccessToken = null;
let mockRefreshToken = null;

// Mock logger utility
jest.mock('./src/utils/logger', () => ({
  logInfo: jest.fn(),
  logError: jest.fn(),
  logWarn: jest.fn(),
  logDebug: jest.fn(),
}));

// Mock localStorage for token storage
const localStorageMock = {
  getItem: jest.fn(key => {
    if (key === 'access_token') return mockAccessToken;
    if (key === 'refresh_token') return mockRefreshToken;
    return null;
  }),
  setItem: jest.fn((key, value) => {
    if (key === 'access_token') mockAccessToken = value;
    if (key === 'refresh_token') mockRefreshToken = value;
  }),
  removeItem: jest.fn(key => {
    if (key === 'access_token') mockAccessToken = null;
    if (key === 'refresh_token') mockRefreshToken = null;
  }),
  clear: jest.fn(() => {
    mockAccessToken = null;
    mockRefreshToken = null;
  }),
};
global.localStorage = localStorageMock;

// Only mock api and TokenManager, let ValidationUtils be real
jest.mock('./src/utils/auth', () => {
  const real = jest.requireActual('./src/utils/auth');
  return {
    ...real,
    api: {
      get: jest.fn(),
      post: jest.fn((url, data) => {
        if (url === '/simulated-equity') {
          const players = data.players || [];
          const mockResponse = players.map(player => ({
            player_number: player.player_number,
            top_estimated_equity: 0.5,
            top_actual_equity: 50.0,
            bottom_estimated_equity: 0.5,
            bottom_actual_equity: 50.0,
            chop_both_boards: 0.0,
            scoop_both_boards: 0.5,
            split_top: 0.0,
            split_bottom: 0.0,
            top_hand_category: 'Two Pair',
            bottom_hand_category: 'Flush Draw',
          }));
          return Promise.resolve({ data: mockResponse });
        }
        if (url === '/spots/simulate') {
          return Promise.resolve({
            data: {
              job: { id: 1, status: 'queued' },
              credits_info: { daily_remaining: 9, daily_limit: 10 },
            },
          });
        }
        return Promise.resolve({ data: {} });
      }),
      put: jest.fn(),
      delete: jest.fn(),
    },
    TokenManager: {
      isLoggedIn: jest.fn(() => !!mockAccessToken),
      getAccessToken: jest.fn(() => mockAccessToken),
      getRefreshToken: jest.fn(() => mockRefreshToken),
      setAccessToken: jest.fn(token => {
        mockAccessToken = token;
      }),
      setRefreshToken: jest.fn(token => {
        mockRefreshToken = token;
      }),
      removeAccessToken: jest.fn(() => {
        mockAccessToken = null;
      }),
      removeRefreshToken: jest.fn(() => {
        mockRefreshToken = null;
      }),
      isTokenExpired: jest.fn(() => false),
      setTokens: jest.fn((accessToken, refreshToken) => {
        mockAccessToken = accessToken;
        mockRefreshToken = refreshToken;
      }),
      clearTokens: jest.fn(() => {
        mockAccessToken = null;
        mockRefreshToken = null;
      }),
    },
  };
});

// (moved TextEncoder/TextDecoder polyfill to top)

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});

// Mock ResizeObserver
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}));

// Mock IntersectionObserver
global.IntersectionObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn(),
}));

// Mock sessionStorage
const sessionStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
};
global.sessionStorage = sessionStorageMock;

// Suppress console warnings during tests
// eslint-disable-next-line no-console
const originalError = console.error;
beforeAll(() => {
  // eslint-disable-next-line no-console
  console.error = (...args) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: ReactDOM.render is no longer supported')
    ) {
      return;
    }
    originalError.call(console, ...args);
  };
});

afterAll(() => {
  // eslint-disable-next-line no-console
  console.error = originalError;
});

// Clean up after each test
afterEach(() => {
  // Clear all mocks after each test
  jest.clearAllMocks();

  // Clear timers
  jest.clearAllTimers();

  // Reset localStorage and sessionStorage
  if (global.localStorage) {
    global.localStorage.clear();
  }
  if (global.sessionStorage) {
    global.sessionStorage.clear();
  }

  // Reset mock tokens
  mockAccessToken = null;
  mockRefreshToken = null;

  // Clean up any remaining intervals or timeouts
  // Note: This is handled by Jest's built-in cleanup
});

// No global wrapper injected; unit tests should use renderWithProviders helper when needed
