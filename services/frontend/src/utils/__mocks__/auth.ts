// Manual mock for auth utils
const mockApi = {
  post: jest.fn(),
  get: jest.fn(),
};

export const api = mockApi;

export const TokenManager = {
  getAccessToken: jest.fn(),
  getRefreshToken: jest.fn(),
  setTokens: jest.fn(),
  clearTokens: jest.fn(),
  isLoggedIn: jest.fn(),
};

export const AuthAPI = {
  register: jest.fn(),
  login: jest.fn(),
  logout: jest.fn(),
  logoutAll: jest.fn(),
  getCurrentUser: jest.fn(),
  updateProfile: jest.fn(),
  changePassword: jest.fn(),
};

export const ValidationUtils = {
  validateEmail: jest.fn(),
  validatePassword: jest.fn(),
};

export default AuthAPI;
