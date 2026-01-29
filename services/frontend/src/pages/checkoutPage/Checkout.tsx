import React, { useState, useEffect } from 'react';

import { useNavigate, useSearchParams } from 'react-router-dom';

import { LoadingSpinner } from '@/components/ui';
import { useAuth } from '@/contexts/AuthContext';
import { useAnalytics } from '@/hooks/useAnalytics';

const Checkout = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const { trackMetaInitiateCheckout, trackMetaAddToCart } = useAnalytics();

  const selectedPlan = (searchParams.get('plan') || 'pro') as
    | 'pro'
    | 'elite'
    | 'free'
    | string;
  const billingCycle = (searchParams.get('cycle') || 'monthly') as
    | 'monthly'
    | 'yearly'
    | string;

  const planPrices: Record<
    'pro' | 'elite',
    { monthly: number; yearly: number }
  > = {
    pro: { monthly: 19, yearly: 190 },
    elite: { monthly: 99, yearly: 990 },
  };

  const currentPrice =
    planPrices[selectedPlan as 'pro' | 'elite']?.[
      billingCycle as 'monthly' | 'yearly'
    ] || 0;

  // Redirect if user not logged in
  useEffect(() => {
    if (!user) {
      navigate('/');
      return;
    }

    // Redirect if trying to subscribe to free plan
    if (selectedPlan === 'free') {
      navigate('/app/live');
      return;
    }
  }, [user, selectedPlan, navigate]);

  const handleCheckout = async () => {
    setLoading(true);
    setError(null);

    // Track Meta events for checkout process
    trackMetaAddToCart(`${selectedPlan}_plan_${billingCycle}`, currentPrice, {
      plan: selectedPlan,
      billing_cycle: billingCycle,
      user_id: user?.id,
    });

    trackMetaInitiateCheckout(currentPrice, {
      plan: selectedPlan,
      billing_cycle: billingCycle,
      user_id: user?.id,
    });

    try {
      const response = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${localStorage.getItem('access_token')}`,
        },
        body: JSON.stringify({
          plan: selectedPlan,
          billing_cycle: billingCycle,
        }),
      });

      const result: any = await response.json();

      if (result.error) {
        setError(result.error);
        setLoading(false);
        return;
      }

      // Redirect to Stripe Checkout
      if ((result as any).checkout_url) {
        window.location.href = (result as any).checkout_url as string;
      } else {
        setError('Failed to create checkout session');
        setLoading(false);
      }
    } catch (err) {
      setError('Something went wrong. Please try again.');
      setLoading(false);
    }
  };

  if (!user) {
    return null;
  }

  return (
    <div className="checkout-page">
      <div className="checkout-container">
        <button className="back-button" onClick={() => navigate('/pricing')}>
          ← Back to Pricing
        </button>

        <div className="checkout-form">
          <div className="checkout-header">
            <h2>Complete Your Subscription</h2>
            <div className="plan-summary">
              <div className="plan-info">
                <span className="plan-name">
                  {selectedPlan.charAt(0).toUpperCase() + selectedPlan.slice(1)}{' '}
                  Plan
                </span>
                <span className="plan-cycle">{billingCycle}</span>
              </div>
              <div className="plan-price">
                ${currentPrice}
                {billingCycle === 'monthly' ? '/mo' : '/year'}
              </div>
            </div>
          </div>

          <div className="checkout-content">
            <div className="secure-payment-info">
              <div className="security-badge">
                <span className="security-icon">🔒</span>
                <div>
                  <h4>Secure Payment</h4>
                  <p>
                    Your payment is processed securely by Stripe. We never store
                    your credit card information.
                  </p>
                </div>
              </div>

              <div className="payment-features">
                <div className="feature">
                  <span className="feature-icon">✅</span>
                  <span>256-bit SSL encryption</span>
                </div>
                <div className="feature">
                  <span className="feature-icon">✅</span>
                  <span>PCI DSS compliant</span>
                </div>
                <div className="feature">
                  <span className="feature-icon">✅</span>
                  <span>Cancel anytime</span>
                </div>
                <div className="feature">
                  <span className="feature-icon">✅</span>
                  <span>30-day money-back guarantee</span>
                </div>
              </div>
            </div>

            {error && <div className="error-message">{error}</div>}

            <button
              onClick={handleCheckout}
              disabled={loading}
              className="checkout-button"
              data-analytics-id="checkout_subscribe"
              data-analytics-label={`Subscribe ${selectedPlan} ${billingCycle}`}
            >
              {loading ? (
                <span className="loading-inline">
                  <LoadingSpinner size="small" />
                  Redirecting to secure payment...
                </span>
              ) : (
                `Subscribe for $${currentPrice} - Secure Checkout`
              )}
            </button>

            <div className="checkout-footer">
              <p>
                By clicking &quot;Subscribe&quot;, you&apos;ll be redirected to
                Stripe&apos;s secure payment page to complete your subscription.
                You agree to our Terms of Service and Privacy Policy. You can
                cancel your subscription at any time.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Checkout;
