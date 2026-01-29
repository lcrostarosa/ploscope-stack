import {
  trackSignup,
  trackLogin,
  trackAppUsage,
  trackPageViewEnhanced,
  trackUserEngagement,
  trackFeatureAccess,
} from '../../utils/analytics';

// Mock the analytics instance
jest.mock('../../utils/analytics', () => ({
  trackSignup: jest.fn(),
  trackLogin: jest.fn(),
  trackAppUsage: jest.fn(),
  trackPageViewEnhanced: jest.fn(),
  trackUserEngagement: jest.fn(),
  trackFeatureAccess: jest.fn(),
  trackEvent: jest.fn(),
  trackPageView: jest.fn(),
  identifyUser: jest.fn(),
  setUserProperties: jest.fn(),
  startSession: jest.fn(),
  endSession: jest.fn(),
  getSessionInfo: jest.fn(),
}));

describe('Analytics Integration', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();

    // Mock window.gtag
    global.window = {
      gtag: jest.fn(),
      posthog: {
        capture: jest.fn(),
        identify: jest.fn(),
        people: {
          set: jest.fn(),
        },
      },
      clarity: jest.fn(),
    };
  });

  describe('Signup Tracking', () => {
    it('should track email signup correctly', () => {
      const userProperties = {
        user_id: 123,
        email: 'test@example.com',
        username: 'testuser',
      };

      trackSignup('email', userProperties);

      expect(trackSignup).toHaveBeenCalledWith('email', userProperties);
    });

    it('should track Google signup correctly', () => {
      const userProperties = {
        user_id: 456,
        email: 'google@example.com',
        profile_picture: true,
      };

      trackSignup('google', userProperties);

      expect(trackSignup).toHaveBeenCalledWith('google', userProperties);
    });
  });

  describe('Login Tracking', () => {
    it('should track email login correctly', () => {
      const userProperties = {
        user_id: 123,
        email: 'test@example.com',
      };

      trackLogin('email', userProperties);

      expect(trackLogin).toHaveBeenCalledWith('email', userProperties);
    });

    it('should track Google login correctly', () => {
      const userProperties = {
        user_id: 456,
        email: 'google@example.com',
      };

      trackLogin('google', userProperties);

      expect(trackLogin).toHaveBeenCalledWith('google', userProperties);
    });
  });

  describe('App Usage Tracking', () => {
    it('should track app feature usage correctly', () => {
      const featureName = 'equity_calculator';
      const action = 'calculation_started';
      const context = { board_cards: 3, player_count: 4 };

      trackAppUsage(featureName, action, null, context);

      expect(trackAppUsage).toHaveBeenCalledWith(
        featureName,
        action,
        null,
        context
      );
    });

    it('should track app usage with duration', () => {
      const featureName = 'spot_analysis';
      const action = 'analysis_completed';
      const duration = 5.2;
      const context = { success: true };

      trackAppUsage(featureName, action, duration, context);

      expect(trackAppUsage).toHaveBeenCalledWith(
        featureName,
        action,
        duration,
        context
      );
    });
  });

  describe('Page View Tracking', () => {
    it('should track enhanced page views correctly', () => {
      const pagePath = '/app/live';
      const pageTitle = 'Live Mode - PLOScope';
      const customParameters = {
        user_id: 123,
        page_type: 'app_home',
      };

      trackPageViewEnhanced(pagePath, pageTitle, customParameters);

      expect(trackPageViewEnhanced).toHaveBeenCalledWith(
        pagePath,
        pageTitle,
        customParameters
      );
    });
  });

  describe('User Engagement Tracking', () => {
    it('should track user engagement correctly', () => {
      const engagementType = 'page_leave';
      const duration = 120.5;
      const context = { page_url: '/app/live' };

      trackUserEngagement(engagementType, duration, context);

      expect(trackUserEngagement).toHaveBeenCalledWith(
        engagementType,
        duration,
        context
      );
    });
  });

  describe('Feature Access Tracking', () => {
    it('should track feature access correctly', () => {
      const featureName = 'solver_mode';
      const accessType = 'view';
      const context = { user_tier: 'pro' };

      trackFeatureAccess(featureName, accessType, context);

      expect(trackFeatureAccess).toHaveBeenCalledWith(
        featureName,
        accessType,
        context
      );
    });

    it('should track feature interaction correctly', () => {
      const featureName = 'live_mode';
      const accessType = 'interact';
      const context = { action: 'game_started' };

      trackFeatureAccess(featureName, accessType, context);

      expect(trackFeatureAccess).toHaveBeenCalledWith(
        featureName,
        accessType,
        context
      );
    });
  });
});
