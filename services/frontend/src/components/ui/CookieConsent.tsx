import React, { useState, useEffect } from 'react';

import { Link } from 'react-router-dom';

import {
  hasConsentChoiceMade,
  updateCookiePreferences,
  initializeAnalyticsIfAllowed,
} from '../../utils/cookieConsent';
import './CookieConsent.scss';

const CookieConsent = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [showDetails, setShowDetails] = useState(false);

  useEffect(() => {
    // Check if user has already made a choice
    if (!hasConsentChoiceMade()) {
      // Show banner after a short delay for better UX
      const timer = setTimeout(() => {
        setIsVisible(true);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, []);

  const handleAcceptAll = () => {
    // Default Accept = Essential + Usage Analytics ON, Third-Party OFF
    updateCookiePreferences({
      necessary: true,
      analytics: true,
      functional: true,
      third_party: false,
      marketing: false,
    });
    setIsVisible(false);
    initializeAnalyticsIfAllowed();
  };

  // Replace Reject with Customize CTA (remove Necessary Only button)

  const handleCustomize = () => {
    setShowDetails(!showDetails);
  };

  const handleSavePreferences = () => {
    const preferences = {
      necessary: true, // Always true - required for basic functionality
      analytics:
        (
          document.getElementById(
            'analytics-cookies'
          ) as HTMLInputElement | null
        )?.checked || false,
      marketing:
        (
          document.getElementById(
            'marketing-cookies'
          ) as HTMLInputElement | null
        )?.checked || false,
      functional:
        (
          document.getElementById(
            'functional-cookies'
          ) as HTMLInputElement | null
        )?.checked || false,
      third_party:
        (
          document.getElementById(
            'third-party-cookies'
          ) as HTMLInputElement | null
        )?.checked || false,
    };

    updateCookiePreferences(preferences);
    setIsVisible(false);

    // Initialize analytics if accepted
    initializeAnalyticsIfAllowed();
  };

  if (!isVisible) return null;

  return (
    <div className="cookie-consent-overlay dark">
      <div className="cookie-consent-banner">
        <div className="cookie-consent-content">
          <div className="cookie-header">
            <div className="cookie-icon">🍪</div>
            <h3>We value your privacy</h3>
          </div>

          <div className="cookie-text">
            <p>
              We use cookies to enhance your experience, analyze site usage, and
              assist in our marketing efforts. By continuing to browse, you
              consent to our use of cookies.
            </p>

            {showDetails && (
              <div className="cookie-details">
                <div className="cookie-category">
                  <label className="cookie-category-label">
                    <input
                      type="checkbox"
                      id="necessary-cookies"
                      checked={true}
                      disabled={true}
                    />
                    <span className="cookie-category-title">
                      <strong>Necessary Cookies</strong> (Required)
                    </span>
                  </label>
                  <p className="cookie-category-desc">
                    Essential for the website to function properly. These
                    cookies enable basic features like page navigation, access
                    to secure areas, and authentication.
                  </p>
                </div>

                <div className="cookie-category">
                  <label className="cookie-category-label">
                    <input
                      type="checkbox"
                      id="analytics-cookies"
                      defaultChecked={true}
                    />
                    <span className="cookie-category-title">
                      <strong>Usage Analytics (first-party)</strong>
                    </span>
                  </label>
                  <p className="cookie-category-desc">
                    Anonymous, first-party usage metrics to improve the app. No
                    identifiers, no third-party sharing.
                  </p>
                </div>

                <div className="cookie-category">
                  <label className="cookie-category-label">
                    <input
                      type="checkbox"
                      id="functional-cookies"
                      defaultChecked={true}
                    />
                    <span className="cookie-category-title">
                      <strong>Functional Cookies</strong>
                    </span>
                  </label>
                  <p className="cookie-category-desc">
                    Enable enhanced functionality and personalization, such as
                    remembering your preferences and settings.
                  </p>
                </div>

                <div className="cookie-category">
                  <label className="cookie-category-label">
                    <input
                      type="checkbox"
                      id="third-party-cookies"
                      defaultChecked={false}
                    />
                    <span className="cookie-category-title">
                      <strong>Third-Party Tools</strong>
                    </span>
                  </label>
                  <p className="cookie-category-desc">
                    Enable Google Analytics, Meta Pixel, and Grafana Faro. May
                    use cookies and share data with third parties.
                  </p>
                </div>

                <div className="cookie-category">
                  <label className="cookie-category-label">
                    <input
                      type="checkbox"
                      id="marketing-cookies"
                      defaultChecked={false}
                    />
                    <span className="cookie-category-title">
                      <strong>Marketing Cookies</strong>
                    </span>
                  </label>
                  <p className="cookie-category-desc">
                    Used to track visitors across websites to display relevant
                    advertisements and measure campaign effectiveness.
                  </p>
                </div>
              </div>
            )}
          </div>

          <div className="cookie-actions">
            {!showDetails ? (
              <>
                <button
                  className="cookie-btn cookie-btn-primary"
                  onClick={handleAcceptAll}
                >
                  Accept All Cookies
                </button>
                {/* Removed Reject/Necessary Only CTA in favor of Customize */}
                <button
                  className="cookie-btn cookie-btn-link"
                  onClick={handleCustomize}
                >
                  Customize
                </button>
              </>
            ) : (
              <>
                <button
                  className="cookie-btn cookie-btn-primary"
                  onClick={handleSavePreferences}
                >
                  Save Preferences
                </button>
                <button
                  className="cookie-btn cookie-btn-secondary"
                  onClick={handleAcceptAll}
                >
                  Accept All
                </button>
                <button
                  className="cookie-btn cookie-btn-link"
                  onClick={() => setShowDetails(false)}
                >
                  Back
                </button>
              </>
            )}
          </div>

          <div className="cookie-footer">
            <p>
              Learn more in our{' '}
              <Link
                to="/privacy"
                className="cookie-link"
                target="_blank"
                rel="noopener noreferrer"
              >
                Privacy Policy
              </Link>{' '}
              and{' '}
              <Link
                to="/terms"
                className="cookie-link"
                target="_blank"
                rel="noopener noreferrer"
              >
                Terms of Service
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CookieConsent;
