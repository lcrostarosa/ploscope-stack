import React, { useState } from 'react';

import { Link, useNavigate } from 'react-router-dom';

import { AuthModal } from '@/components/forms';
import { useAuth } from '@/contexts/AuthContext';
// ThemeToggle removed - using dark mode only
import { useAnalytics } from '@/hooks/useAnalytics';
import './PricingPage.scss';

const PricingPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { track } = useAnalytics();
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>(
    'monthly'
  ); // 'monthly' or 'yearly'
  const [showAuthModal, setShowAuthModal] = useState(false);

  const plans = {
    free: {
      name: 'Free Beta',
      price: { monthly: 0, yearly: 0 },
      description: "Get full access while we're still building",
      features: [
        'Unlimited equity calculations',
        'Full spotMode analysis tools',
        'Live mode simulations',
        'Hand history uploads',
        'Advanced analytics',
        'Save & revisit your spots',
        'Priority feedback channel',
      ],
      limitations: [],
      cta: 'Start Free',
      popular: false,
      color: 'green',
      betaNote:
        '🔓 All features unlocked during beta\n⏳ Limited-time offer — access ends when beta closes',
    },
    pro: {
      name: 'Pro',
      price: { monthly: 300, yearly: 3000 },
      description: 'For serious PLO players and students',
      features: [
        'Unlimited equity calculations',
        'Advanced spotMode analysis',
        'Save unlimited spots',
        'Detailed hand breakdowns',
        'Opponent range analysis',
        'Export results to CSV',
        'Priority email support',
        'Advanced filtering',
      ],
      limitations: [],
      cta: 'Start Pro Trial',
      popular: false, // Commented out: popular: true,
      color: 'blue',
    },
    elite: {
      name: 'Elite',
      price: { monthly: 600, yearly: 6000 },
      description: 'For coaches and professional players',
      features: [
        'Everything in Pro',
        'Batch analysis tools',
        'Custom opponent models',
        'API access',
        'White-label options',
        'Phone support',
        'Custom integrations',
        'Team collaboration tools',
        'Advanced reporting',
      ],
      limitations: [],
      cta: 'Contact Sales',
      popular: false,
      color: 'purple',
    },
  } as const;

  const handlePlanSelect = (planKey: keyof typeof plans) => {
    // Track marketing event
    track('plan_selected', {
      category: 'marketing',
      plan: planKey,
      billing_cycle: billingCycle,
      user_logged_in: !!user,
    });

    if (planKey === 'free') {
      // Redirect to registration page or app
      if (!user) {
        setShowAuthModal(true);
      } else {
        navigate('/app/live');
      }
      return;
    }

    if (planKey === 'elite') {
      // Open contact form or redirect to contact
      window.location.href =
        'mailto:sales@ploscope.com?subject=Elite Plan Inquiry';
      return;
    }

    // Handle Pro plan signup - redirect to registration page
    if (!user) {
      setShowAuthModal(true);
      return;
    }

    navigate(`/checkout?plan=${planKey}&cycle=${billingCycle}`);
  };

  const getSavings = (plan: { price: { monthly: number; yearly: number } }) => {
    if (billingCycle === 'yearly' && plan.price.yearly > 0) {
      const monthlyTotal = plan.price.monthly * 12;
      const savings = monthlyTotal - plan.price.yearly;
      const percentage = Math.round((savings / monthlyTotal) * 100);
      return { amount: savings, percentage };
    }
    return null;
  };

  return (
    <div className="pricing-page">
      {/* Squares Background Pattern */}
      <div className="squares-background"></div>

      {/* Header */}
      <div className="page-header">
        <div className="container">
          <div className="page-header-top">
            <Link to="/" className="back-link">
              ← Back to Home
            </Link>
            {/* ThemeToggle removed - using dark mode only */}
          </div>
          <h1>Choose your PLOScope plan</h1>
          <p>
            Start with our free beta, then upgrade when you&apos;re ready for
            more advanced features.
          </p>

          {/* Billing Toggle */}
          <div className="billing-toggle">
            <span className={billingCycle === 'monthly' ? 'active' : ''}>
              Monthly
            </span>
            <button
              className="toggle-switch"
              onClick={() =>
                setBillingCycle(
                  billingCycle === 'monthly' ? 'yearly' : 'monthly'
                )
              }
            >
              <div
                className={`toggle-slider ${billingCycle === 'yearly' ? 'yearly' : 'monthly'}`}
              ></div>
            </button>
            <span className={billingCycle === 'yearly' ? 'active' : ''}>
              Yearly <span className="savings-badge">Save up to 20%</span>
            </span>
          </div>
        </div>
      </div>

      {/* Pricing Cards */}
      <div className="pricing-cards">
        <div className="container">
          <div className="plans-grid">
            {Object.entries(plans).map(([key, plan]) => {
              const savings = getSavings(plan as any);
              const currentPrice = (plan as any).price[billingCycle];

              return (
                <div
                  key={key}
                  className={`pricing-card ${plan.popular ? 'popular' : ''} ${plan.color} ${key !== 'free' ? 'disabled' : ''}`}
                >
                  {/* {plan.popular && <div className="popular-badge">Most Popular</div>} */}

                  <div className="plan-header">
                    <h3>{plan.name}</h3>
                    <div className={`price ${key !== 'free' ? 'blurred' : ''}`}>
                      <span className="currency">$</span>
                      <span className="amount">{currentPrice}</span>
                      <span className="period">
                        /{billingCycle === 'monthly' ? 'mo' : 'yr'}
                      </span>
                    </div>
                    {savings && (
                      <div className="savings">
                        Save ${savings.amount}/year ({savings.percentage}% off)
                      </div>
                    )}
                    <p className="plan-description">{plan.description}</p>
                  </div>

                  <div className="plan-features">
                    <h4>
                      What&apos;s included
                      {'betaNote' in plan ? ' (for a limited time):' : ':'}
                    </h4>
                    <ul className="features-list">
                      {plan.features.map((feature, index) => (
                        <li key={index} className="feature-item">
                          <span className="check-icon">✅</span>
                          {feature}
                        </li>
                      ))}
                    </ul>

                    {plan.limitations.length > 0 && (
                      <>
                        <h4>Limitations:</h4>
                        <ul className="limitations-list">
                          {plan.limitations.map((limitation, index) => (
                            <li key={index} className="limitation-item">
                              <span className="x-icon">❌</span>
                              {limitation}
                            </li>
                          ))}
                        </ul>
                      </>
                    )}

                    {'betaNote' in plan && (
                      <div className="beta-note">
                        <h4>Note:</h4>
                        <div className="beta-note-content">
                          {(plan as any).betaNote
                            .split('\n')
                            .map((line: string, index: number) => (
                              <p key={index}>{line}</p>
                            ))}
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="plan-footer">
                    <button
                      className={`plan-cta ${plan.color} ${key !== 'free' ? 'disabled' : ''}`}
                      data-analytics-id={`pricing_plan_${key}`}
                      data-analytics-label={`${plan.name} ${billingCycle}`}
                      onClick={() => key === 'free' && handlePlanSelect(key)}
                      disabled={key !== 'free'}
                    >
                      {key !== 'free' ? 'Coming Soon' : plan.cta}
                    </button>

                    <p className="trial-info">
                      {key === 'free' && '🔓 All features unlocked during beta'}
                      {key === 'pro' &&
                        '14-day free trial • No credit card required'}
                      {key === 'elite' && 'Contact sales for custom pricing'}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* FAQ Section */}
      <div className="pricing-faq">
        <div className="container">
          <h2>Frequently Asked Questions</h2>
          <div className="faq-grid">
            <div className="faq-item">
              <h4>Is the beta really free?</h4>
              <p>
                Yes! During our beta period, you can use PLOScope completely
                free with full access to all features. However, beta access may
                end at any time and a paid plan will be required to continue
                using the service.
              </p>
            </div>

            <div className="faq-item">
              <h4>What happens when the beta ends?</h4>
              <p>
                When the beta period ends, you&apos;ll need to upgrade to a paid
                plan to continue using PLOScope. We&apos;ll provide advance
                notice before the beta ends and help you transition to the plan
                that best fits your needs.
              </p>
            </div>

            <div className="faq-item">
              <h4>Can I upgrade or downgrade anytime?</h4>
              <p>
                Absolutely. You can change your plan at any time. Upgrades take
                effect immediately, and downgrades take effect at the end of
                your current billing cycle.
              </p>
            </div>

            <div className="faq-item">
              <h4>What payment methods do you accept?</h4>
              <p>
                We accept all major credit cards (Visa, MasterCard, American
                Express) and PayPal. All payments are processed securely through
                Stripe.
              </p>
            </div>

            <div className="faq-item">
              <h4>Is there a free trial for paid plans?</h4>
              <p>
                Yes! The Pro plan comes with a 14-day free trial. No credit card
                required to start. The Elite plan includes a consultation call
                to ensure it&apos;s right for you.
              </p>
            </div>

            <div className="faq-item">
              <h4>What&apos;s the difference between Pro and Elite?</h4>
              <p>
                Elite is designed for coaches, analysis sites, and professional
                players who need advanced features like API access, custom
                integrations, and team collaboration tools.
              </p>
            </div>

            <div className="faq-item">
              <h4>Do you offer refunds?</h4>
              <p>
                Yes, we offer a 30-day money-back guarantee on all paid plans.
                If you&apos;re not satisfied, contact us for a full refund.
              </p>
            </div>

            <div className="faq-item">
              <h4>What are the terms for beta access?</h4>
              <p>
                Beta access is provided free of charge but may end at any time.
                When the beta ends, users will need to upgrade to a paid plan to
                continue using the service. We reserve the right to modify or
                terminate beta access with reasonable notice.
              </p>
            </div>
          </div>

          {/* FAQ Link */}
          <div className="faq-link-section">
            <Link to="/faq" className="faq-link">
              View Complete FAQ →
            </Link>
          </div>
        </div>
      </div>

      {/* Bottom CTA */}
      <div className="pricing-bottom-cta">
        <div className="container">
          <h2>Ready to Start?</h2>
          <p>
            Join thousands of PLO players already improving their game with
            PLOScope.
          </p>

          {user ? (
            <Link to="/app/live" className="cta-button primary large">
              🎲 Launch PLOScope
            </Link>
          ) : (
            <div className="cta-buttons">
              <button
                className="cta-button primary large"
                onClick={() => handlePlanSelect('free')}
              >
                🚀 Start Free Beta
              </button>
              <button
                className="cta-button secondary large"
                onClick={() => setShowAuthModal(true)}
              >
                👤 Login
              </button>
              <button
                className="cta-button tertiary large"
                onClick={() => handlePlanSelect('pro')}
                disabled={true}
              >
                💎 Try Pro Free (Coming Soon)
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Auth Modal */}
      <AuthModal
        isOpen={showAuthModal}
        onClose={() => setShowAuthModal(false)}
        onSuccess={() => {
          setShowAuthModal(false);
          if (user) {
            navigate('/app/live');
          }
        }}
      />
    </div>
  );
};

export default PricingPage;
