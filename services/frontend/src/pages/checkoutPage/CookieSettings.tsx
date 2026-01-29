import React, { useState, useEffect } from 'react';

import { Link } from 'react-router-dom';

import {
  getCookieConsent,
  updateCookiePreferences,
  COOKIE_CATEGORIES,
} from '@/utils/cookieConsent';

const CookieSettings = () => {
  const [preferences, setPreferences] = useState<{
    necessary: boolean;
    analytics: boolean;
    functional: boolean;
    marketing: boolean;
  }>({
    necessary: true,
    analytics: false,
    functional: false,
    marketing: false,
  });
  const [saveStatus, setSaveStatus] = useState('');

  useEffect(() => {
    // Load current preferences
    const currentConsent = getCookieConsent();
    if (currentConsent) {
      setPreferences({
        necessary: currentConsent.necessary || true,
        analytics: currentConsent.analytics || false,
        functional: currentConsent.functional || false,
        marketing: currentConsent.marketing || false,
      });
    }
  }, []);

  const handlePreferenceChange = (
    category: keyof typeof preferences,
    value: boolean
  ) => {
    setPreferences(prev => ({
      ...prev,
      [category]: value,
    }));
  };

  const handleSavePreferences = () => {
    const success = updateCookiePreferences(preferences);
    if (success) {
      setSaveStatus('success');
      setTimeout(() => setSaveStatus(''), 3000);
    } else {
      setSaveStatus('error');
      setTimeout(() => setSaveStatus(''), 3000);
    }
  };

  const handleAcceptAll = () => {
    const allAccepted = {
      necessary: true,
      analytics: true,
      functional: true,
      marketing: true,
    };
    setPreferences(allAccepted);
    updateCookiePreferences(allAccepted);
    setSaveStatus('success');
    setTimeout(() => setSaveStatus(''), 3000);
  };

  const handleRejectAll = () => {
    const onlyNecessary = {
      necessary: true,
      analytics: false,
      functional: false,
      marketing: false,
    };
    setPreferences(onlyNecessary);
    updateCookiePreferences(onlyNecessary);
    setSaveStatus('success');
    setTimeout(() => setSaveStatus(''), 3000);
  };

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold mb-4">Cookie Settings</h1>
            <p className="text-lg text-gray-300">
              Manage your cookie preferences and understand how we use cookies
              on PLOScope
            </p>
          </div>

          {/* Save Status */}
          {saveStatus && (
            <div
              className={`p-4 rounded-lg mb-6 ${
                saveStatus === 'success'
                  ? 'bg-green-900 text-green-100 border border-green-700'
                  : 'bg-red-900 text-red-100 border border-red-700'
              }`}
            >
              {saveStatus === 'success'
                ? '✅ Your cookie preferences have been saved successfully!'
                : '❌ There was an error saving your preferences. Please try again.'}
            </div>
          )}

          {/* Quick Actions */}
          <div className="flex flex-wrap gap-4 mb-8 justify-center">
            <button
              onClick={handleAcceptAll}
              className="px-6 py-3 rounded-lg font-medium transition-colors bg-blue-600 hover:bg-blue-700 text-white"
            >
              Accept All Cookies
            </button>
            <button
              onClick={handleRejectAll}
              className="px-6 py-3 rounded-lg font-medium transition-colors bg-gray-600 hover:bg-gray-700 text-white"
            >
              Reject All (Necessary Only)
            </button>
          </div>

          {/* Cookie Categories */}
          <div className="space-y-6">
            {Object.entries(COOKIE_CATEGORIES).map(([key, category]) => (
              <div
                key={key}
                className="p-6 rounded-lg border bg-gray-800 border-gray-700"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold mb-2">
                      {category.name}
                    </h3>
                    <p className="text-sm leading-relaxed text-gray-300">
                      {category.description}
                    </p>
                  </div>
                  <div className="ml-4">
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={preferences[key as keyof typeof preferences]}
                        onChange={e =>
                          handlePreferenceChange(
                            key as keyof typeof preferences,
                            e.target.checked
                          )
                        }
                        disabled={category.required}
                        className="sr-only peer"
                      />
                      <div
                        className={`relative w-11 h-6 rounded-full peer 
                        ${
                          category.required
                            ? 'bg-gray-400 cursor-not-allowed'
                            : 'bg-gray-700 peer-checked:bg-blue-600'
                        } 
                        peer-focus:outline-none peer-focus:ring-4 
                        peer-focus:ring-blue-800
                        transition-colors duration-200`}
                      >
                        <div
                          className={`absolute top-[2px] left-[2px] bg-white border 
                          border-gray-300 
                          border rounded-full h-5 w-5 transition-all duration-200 
                          ${preferences[key as keyof typeof preferences] ? 'translate-x-full' : 'translate-x-0'}`}
                        ></div>
                      </div>
                    </label>
                  </div>
                </div>

                {category.required && (
                  <div className="text-xs font-medium px-3 py-1 rounded-full inline-block bg-gray-700 text-gray-300">
                    Required for basic functionality
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Save Button */}
          <div className="mt-8 text-center">
            <button
              onClick={handleSavePreferences}
              className="px-8 py-3 rounded-lg font-medium transition-colors bg-green-600 hover:bg-green-700 text-white"
            >
              Save Cookie Preferences
            </button>
          </div>

          {/* Information Section */}
          <div className="mt-12 p-6 rounded-lg bg-gray-800 border border-gray-700">
            <h3 className="text-lg font-semibold mb-4">About Cookies</h3>
            <div className="space-y-4 text-sm">
              <p>
                Cookies are small text files that are stored on your device when
                you visit our website. They help us provide you with a better
                experience by remembering your preferences and analyzing how you
                use our site.
              </p>

              <p>
                You can change your cookie preferences at any time by returning
                to this page. Please note that disabling certain cookies may
                affect the functionality of our website.
              </p>

              <p>
                For more information about how we use cookies and process your
                data, please read our{' '}
                <Link
                  to="/privacy"
                  className="font-medium text-blue-400 hover:text-blue-300"
                >
                  Privacy Policy
                </Link>
                .
              </p>
            </div>
          </div>

          {/* Back Button */}
          <div className="text-center mt-8">
            <Link
              to="/"
              className="inline-flex items-center px-6 py-3 rounded-lg font-medium transition-colors bg-gray-700 hover:bg-gray-600 text-white"
            >
              ← Back to Home
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CookieSettings;
