/**
 * Cookie consent utility functions
 */

// Get the current cookie consent status
export const getCookieConsent = (): any | null => {
  try {
    const consent = localStorage.getItem('cookieConsent');
    return consent ? JSON.parse(consent) : null;
  } catch (error) {
    return null;
  }
};

// Check if a specific type of cookie is allowed
export const isCookieAllowed = (type: string): boolean => {
  const consent = getCookieConsent();
  if (!consent) return false;

  return consent[type] === true;
};

// Check if user has made any consent choice
export const hasConsentChoiceMade = (): boolean => {
  return getCookieConsent() !== null;
};

// Get consent timestamp
export const getConsentTimestamp = (): string | null => {
  const consent = getCookieConsent();
  return consent?.timestamp || null;
};

// Check if consent is still valid (optional: implement expiry logic)
export const isConsentValid = (): boolean => {
  const consent = getCookieConsent();
  if (!consent) return false;

  // Optional: Check if consent is older than X days
  const consentDate = new Date(consent.timestamp);
  const now = new Date();
  const daysDiff = (Number(now) - Number(consentDate)) / (1000 * 60 * 60 * 24);

  // Consent valid for 365 days
  return daysDiff < 365;
};

// Update specific cookie preferences
export const updateCookiePreferences = (
  preferences: Record<string, any>
): boolean => {
  try {
    const currentConsent = getCookieConsent() || {};
    const updatedConsent = {
      ...currentConsent,
      ...preferences,
      timestamp: new Date().toISOString(),
    };

    localStorage.setItem('cookieConsent', JSON.stringify(updatedConsent));
    return true;
  } catch (error) {
    return false;
  }
};

// Clear all cookie consent data
export const clearCookieConsent = (): boolean => {
  try {
    localStorage.removeItem('cookieConsent');
    return true;
  } catch (error) {
    return false;
  }
};

// Initialize analytics based on consent
export const initializeAnalyticsIfAllowed = (): boolean => {
  const consent = getCookieConsent();
  if (!consent) return false;

  // Third-party SDKs require the 'third_party' toggle
  if (consent.third_party === true) {
    import('./analytics')
      .then(({ optIn }) => {
        optIn();
      })
      .catch(() => {
        // Non-blocking
      });
    return true;
  }
  return false;
};

// Initialize marketing tools based on consent
export const initializeMarketingIfAllowed = (): boolean => {
  if (isCookieAllowed('marketing')) {
    // Example: Initialize marketing pixels, ad tracking, etc.
    // initializeFacebookPixel();
    // initializeGoogleAds();

    return true;
  }

  return false;
};

// Initialize functional features based on consent
export const initializeFunctionalIfAllowed = (): boolean => {
  if (isCookieAllowed('functional')) {
    // Dispatch event to notify components
    window.dispatchEvent(
      new CustomEvent('cookieConsentChanged', {
        detail: { functional: true },
      })
    );

    return true;
  }

  return false;
};

// Consent status for debugging
export const getConsentStatus = (): Record<string, any> => {
  const consent = getCookieConsent();

  return {
    hasConsent: hasConsentChoiceMade(),
    isValid: isConsentValid(),
    preferences: consent,
    analytics: isCookieAllowed('analytics'),
    marketing: isCookieAllowed('marketing'),
    functional: isCookieAllowed('functional'),
    necessary: isCookieAllowed('necessary'),
  };
};

// Cookie categories and their descriptions
export const COOKIE_CATEGORIES = {
  necessary: {
    name: 'Necessary Cookies',
    description:
      'Essential for the website to function properly. These cookies enable basic features like page navigation, access to secure areas, and authentication.',
    required: true,
  },
  analytics: {
    name: 'Usage Analytics',
    description:
      'Anonymous, first-party usage metrics to improve the app. No identifiers, no third-party sharing.',
    required: false,
  },
  functional: {
    name: 'Functional Cookies',
    description:
      'Enable enhanced functionality and personalization, such as remembering your preferences and settings.',
    required: false,
  },
  third_party: {
    name: 'Third-Party Tools',
    description:
      'Enable Google Analytics, Meta Pixel, and Grafana Faro. May use cookies and share data with third parties.',
    required: false,
  },
  marketing: {
    name: 'Marketing Cookies',
    description:
      'Used to track visitors across websites to display relevant advertisements and measure campaign effectiveness.',
    required: false,
  },
};
