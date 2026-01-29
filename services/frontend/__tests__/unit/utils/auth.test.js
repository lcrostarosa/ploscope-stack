import { ValidationUtils, TokenManager } from '../../../utils/auth';

describe('ValidationUtils', () => {
  describe('validateEmail', () => {
    test('should return true for valid email addresses', () => {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'user123@test-domain.com',
      ];

      validEmails.forEach(email => {
        expect(ValidationUtils.validateEmail(email)).toBe(true);
      });
    });

    test('should return false for invalid email addresses', () => {
      const invalidEmails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user@.com',
        '',
      ];

      invalidEmails.forEach(email => {
        expect(ValidationUtils.validateEmail(email)).toBe(false);
      });

      // Test null and undefined separately since they cause errors
      expect(ValidationUtils.validateEmail(null)).toBe(false);
      expect(ValidationUtils.validateEmail(undefined)).toBe(false);
    });
  });

  describe('validatePassword', () => {
    test('should return valid for strong passwords', () => {
      const strongPasswords = [
        'Password123',
        'MyStr0ngP@ss',
        'Test1234',
        'ComplexPass1',
      ];

      strongPasswords.forEach(password => {
        const result = ValidationUtils.validatePassword(password);
        expect(result.isValid).toBe(true);
        expect(result.errors).toHaveLength(0);
      });
    });

    test('should return invalid for passwords that are too short', () => {
      const result = ValidationUtils.validatePassword('Pass1');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain(
        'Password must be at least 8 characters long'
      );
    });

    test('should return invalid for passwords without lowercase letters', () => {
      const result = ValidationUtils.validatePassword('PASSWORD123');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain(
        'Password must contain at least one lowercase letter'
      );
    });

    test('should return invalid for passwords without uppercase letters', () => {
      const result = ValidationUtils.validatePassword('password123');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain(
        'Password must contain at least one uppercase letter'
      );
    });

    test('should return invalid for passwords without numbers', () => {
      const result = ValidationUtils.validatePassword('Password');
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain(
        'Password must contain at least one number'
      );
    });

    test('should return multiple errors for passwords with multiple issues', () => {
      const result = ValidationUtils.validatePassword('pass');
      expect(result.isValid).toBe(false);
      expect(result.errors).toHaveLength(3);
      expect(result.errors).toContain(
        'Password must be at least 8 characters long'
      );
      expect(result.errors).toContain(
        'Password must contain at least one uppercase letter'
      );
      expect(result.errors).toContain(
        'Password must contain at least one number'
      );
    });
  });
});

describe('TokenManager', () => {
  beforeEach(() => {
    // Clear the mock state before each test
    TokenManager.clearTokens();
    jest.clearAllMocks();
  });

  describe('getAccessToken', () => {
    test('should return access token from localStorage', () => {
      TokenManager.setTokens('mock-access-token', 'mock-refresh-token');
      const result = TokenManager.getAccessToken();
      expect(result).toBe('mock-access-token');
    });

    test('should return null if no token exists', () => {
      const result = TokenManager.getAccessToken();
      expect(result).toBeNull();
    });
  });

  describe('getRefreshToken', () => {
    test('should return refresh token from localStorage', () => {
      TokenManager.setTokens('mock-access-token', 'mock-refresh-token');
      const result = TokenManager.getRefreshToken();
      expect(result).toBe('mock-refresh-token');
    });
  });

  describe('setTokens', () => {
    test('should set both access and refresh tokens', () => {
      TokenManager.setTokens('access-token', 'refresh-token');
      expect(TokenManager.getAccessToken()).toBe('access-token');
      expect(TokenManager.getRefreshToken()).toBe('refresh-token');
    });
  });

  describe('clearTokens', () => {
    test('should remove both access and refresh tokens', () => {
      TokenManager.setTokens('access-token', 'refresh-token');
      TokenManager.clearTokens();
      expect(TokenManager.getAccessToken()).toBeNull();
      expect(TokenManager.getRefreshToken()).toBeNull();
    });
  });

  describe('isLoggedIn', () => {
    test('should return true if access token exists', () => {
      TokenManager.setTokens('mock-token', 'refresh-token');
      const result = TokenManager.isLoggedIn();
      expect(result).toBe(true);
    });

    test('should return false if no access token exists', () => {
      const result = TokenManager.isLoggedIn();
      expect(result).toBe(false);
    });

    test('should return false if access token is empty string', () => {
      TokenManager.setTokens('', 'refresh-token');
      const result = TokenManager.isLoggedIn();
      expect(result).toBe(false);
    });
  });
});
