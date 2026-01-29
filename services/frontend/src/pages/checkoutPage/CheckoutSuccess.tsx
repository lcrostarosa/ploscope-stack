import React, { useState, useEffect } from 'react';

import { useNavigate, useSearchParams } from 'react-router-dom';

import { LoadingSpinner } from '@/components/ui';
import { useAuth } from '@/contexts/AuthContext';
import { useAnalytics } from '@/hooks/useAnalytics';

const CheckoutSuccess = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { user, refreshUserData } = useAuth();
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [subscriptionData, setSubscriptionData] = useState<{
    plan?: string;
    billing_cycle?: string;
    amount?: number;
  } | null>(null);
  const { trackConversion } = useAnalytics();

  useEffect(() => {
    const verifyCheckout = async () => {
      const sessionId = searchParams.get('session_id');

      if (!sessionId) {
        setError('No session ID found');
        setLoading(false);
        return;
      }

      if (!user) {
        // User needs to be logged in to verify
        navigate('/');
        return;
      }

      try {
        const response = await fetch(
          `/api/checkout-success?session_id=${sessionId}`,
          {
            method: 'GET',
            headers: {
              Authorization: `Bearer ${localStorage.getItem('access_token')}`,
            },
          }
        );

        const result = await response.json();

        if (result.error) {
          setError(result.error);
        } else if (result.success) {
          setSubscriptionData(result);
          // Refresh user data to get updated subscription info
          await refreshUserData();

          // Track successful conversion
          trackConversion(
            'subscription_purchase',
            (result.amount as number) || 0,
            {
              plan: result.plan,
              billing_cycle: result.billing_cycle,
              user_id: user?.id,
            }
          );
        }
      } catch (err) {
        setError('Failed to verify checkout. Please contact support.');
      } finally {
        setLoading(false);
      }
    };

    verifyCheckout();
  }, [searchParams, user, navigate, refreshUserData, trackConversion]);

  const handleContinue = () => {
    navigate('/app/live');
  };

  if (loading) {
    return (
      <div className="checkout-success-page">
        <div className="checkout-success-container">
          <div className="loading-state">
            <LoadingSpinner
              size="large"
              text="Verifying your subscription..."
            />
            <h2>Verifying your subscription...</h2>
            <p>Please wait while we confirm your payment.</p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="checkout-success-page">
        <div className="checkout-success-container">
          <div className="error-state">
            <div className="error-icon">❌</div>
            <h2>Verification Failed</h2>
            <p>{error}</p>
            <div className="error-actions">
              <button
                onClick={() => navigate('/pricing')}
                className="secondary-button"
              >
                Back to Pricing
              </button>
              <button
                onClick={() => navigate('/app/live')}
                className="primary-button"
              >
                Continue to App
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="checkout-success-page">
      <div className="checkout-success-container">
        <div className="success-state">
          <div className="success-icon">🎉</div>
          <h1>
            Welcome to{' '}
            {subscriptionData?.plan
              ? subscriptionData.plan.charAt(0).toUpperCase() +
                subscriptionData.plan.slice(1)
              : ''}
            !
          </h1>
          <h2>Subscription Activated Successfully</h2>

          <div className="subscription-details">
            <div className="detail-card">
              <h3>Subscription Details</h3>
              <div className="detail-row">
                <span className="label">Plan:</span>
                <span className="value">
                  {subscriptionData?.plan
                    ? subscriptionData.plan.charAt(0).toUpperCase() +
                      subscriptionData.plan.slice(1)
                    : ''}
                </span>
              </div>
              <div className="detail-row">
                <span className="label">Status:</span>
                <span className="value status-active">Active</span>
              </div>
            </div>
          </div>

          <div className="success-features">
            <h3>What&apos;s Next?</h3>
            <div className="features-grid">
              <div className="feature-item">
                <span className="feature-icon">🚀</span>
                <div>
                  <h4>Start Analyzing</h4>
                  <p>Begin using advanced PLO analysis tools immediately</p>
                </div>
              </div>
              <div className="feature-item">
                <span className="feature-icon">💾</span>
                <div>
                  <h4>Save Your Spots</h4>
                  <p>Store unlimited hand scenarios for future reference</p>
                </div>
              </div>
              <div className="feature-item">
                <span className="feature-icon">📊</span>
                <div>
                  <h4>Detailed Analytics</h4>
                  <p>Access comprehensive equity breakdowns and insights</p>
                </div>
              </div>
              <div className="feature-item">
                <span className="feature-icon">🎯</span>
                <div>
                  <h4>Advanced Features</h4>
                  <p>Unlock all premium analysis capabilities</p>
                </div>
              </div>
            </div>
          </div>

          <div className="success-actions">
            <button
              onClick={handleContinue}
              className="continue-button"
              data-analytics-id="checkout_success_continue"
              data-analytics-label="Start Using PLO Analysis"
            >
              Start Using PLO Analysis →
            </button>
          </div>

          <div className="success-footer">
            <p>
              <strong>Need help?</strong> Check out our{' '}
              <a href="/docs" target="_blank" rel="noopener noreferrer">
                documentation
              </a>{' '}
              or <a href="mailto:support@ploscope.com">contact support</a>.
            </p>
            <p>
              You can manage your subscription anytime from your account
              settings.
            </p>
            <p className="text-sm text-gray-600 mb-4">
              You&apos;ll receive a confirmation email shortly with your
              subscription details.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CheckoutSuccess;
