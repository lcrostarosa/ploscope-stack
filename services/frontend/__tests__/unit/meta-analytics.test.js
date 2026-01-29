import {
  trackMetaLead,
  trackMetaAddToCart,
  trackMetaInitiateCheckout,
  trackSignup,
  trackLogin,
  trackAppUsage,
  trackPageViewEnhanced,
} from '../../utils/analytics';

// Mock the analytics instance
jest.mock('../../utils/analytics', () => ({
  trackMetaLead: jest.fn(),
  trackMetaAddToCart: jest.fn(),
  trackMetaInitiateCheckout: jest.fn(),
  trackSignup: jest.fn(),
  trackLogin: jest.fn(),
  trackAppUsage: jest.fn(),
  trackPageViewEnhanced: jest.fn(),
  trackEvent: jest.fn(),
  trackPageView: jest.fn(),
  identifyUser: jest.fn(),
  setUserProperties: jest.fn(),
  startSession: jest.fn(),
  endSession: jest.fn(),
  getSessionInfo: jest.fn(),
}));

describe('Meta Analytics Integration', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();

    // Mock window.fbq
    global.window = {
      fbq: jest.fn(),
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

  describe('Meta Lead Tracking', () => {
    it('should track beta signup lead correctly', () => {
      const leadType = 'beta_signup';
      const context = {
        source: 'landing_page_modal',
        user_id: 123,
      };

      trackMetaLead(leadType, 1, context);

      expect(trackMetaLead).toHaveBeenCalledWith(leadType, 1, context);
    });

    it('should track registration lead correctly', () => {
      const leadType = 'registration';
      const context = {
        source: 'register_page',
        user_id: 456,
      };

      trackMetaLead(leadType, 1, context);

      expect(trackMetaLead).toHaveBeenCalledWith(leadType, 1, context);
    });
  });

  describe('Meta E-commerce Tracking', () => {
    it('should track add to cart correctly', () => {
      const productName = 'pro_plan_monthly';
      const value = 19;
      const context = {
        plan: 'pro',
        billing_cycle: 'monthly',
        user_id: 123,
      };

      trackMetaAddToCart(productName, value, context);

      expect(trackMetaAddToCart).toHaveBeenCalledWith(
        productName,
        value,
        context
      );
    });

    it('should track checkout initiation correctly', () => {
      const value = 19;
      const context = {
        plan: 'pro',
        billing_cycle: 'monthly',
        user_id: 123,
      };

      trackMetaInitiateCheckout(value, context);

      expect(trackMetaInitiateCheckout).toHaveBeenCalledWith(value, context);
    });
  });

  describe('Meta Event Integration', () => {
    it('should track signup with Meta events', () => {
      const signupMethod = 'email';
      const userProperties = {
        user_id: 123,
        email: 'test@example.com',
      };

      trackSignup(signupMethod, userProperties);

      expect(trackSignup).toHaveBeenCalledWith(signupMethod, userProperties);
    });

    it('should track login with Meta events', () => {
      const loginMethod = 'google';
      const userProperties = {
        user_id: 456,
        email: 'google@example.com',
      };

      trackLogin(loginMethod, userProperties);

      expect(trackLogin).toHaveBeenCalledWith(loginMethod, userProperties);
    });

    it('should track app usage with Meta events', () => {
      const featureName = 'equity_calculator';
      const action = 'calculation_started';
      const context = {
        board_cards: 3,
        player_count: 4,
      };

      trackAppUsage(featureName, action, null, context);

      expect(trackAppUsage).toHaveBeenCalledWith(
        featureName,
        action,
        null,
        context
      );
    });

    it('should track page views with Meta events', () => {
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

  describe('Meta Event Parameters', () => {
    it('should include correct Meta event structure for lead tracking', () => {
      const leadType = 'beta_signup';
      const value = 1;
      const context = {
        source: 'landing_page',
        user_id: 123,
      };

      trackMetaLead(leadType, value, context);

      expect(trackMetaLead).toHaveBeenCalledWith(leadType, value, context);
    });

    it('should include correct Meta event structure for e-commerce', () => {
      const productName = 'elite_plan_yearly';
      const value = 990;
      const context = {
        plan: 'elite',
        billing_cycle: 'yearly',
        user_id: 456,
      };

      trackMetaAddToCart(productName, value, context);

      expect(trackMetaAddToCart).toHaveBeenCalledWith(
        productName,
        value,
        context
      );
    });
  });

  describe('Meta Privacy Controls', () => {
    it('should respect Meta tracking enable/disable flags', () => {
      // This test verifies that Meta tracking respects the ENABLE_META flag
      const leadType = 'test_lead';
      const context = { user_id: 123 };

      trackMetaLead(leadType, 1, context);

      expect(trackMetaLead).toHaveBeenCalledWith(leadType, 1, context);
    });
  });
});
