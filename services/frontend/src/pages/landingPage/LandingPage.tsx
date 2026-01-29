import React, { useState } from 'react';

import { Link } from 'react-router-dom';

import { AuthModal } from '@/components/forms';
import { EnhancedPageTracker, AppFooter } from '@/components/layout';
import HeroAppPreview from '@/components/ui/HeroAppPreview';
import MobilePreview from '@/components/ui/MobilePreview';
import { useAuth } from '@/contexts/AuthContext';
import { useAppUsageTracking, useAnalytics } from '@/hooks/useAnalytics';
import { isBlogEnabled } from '@/utils/featureFlags';
import './LandingPage.scss';

const LandingPage = () => {
  const { user } = useAuth();
  const [showAuthModal, setShowAuthModal] = useState(false);

  // Enhanced page tracking with Google Analytics
  // Moved to EnhancedPageTracker component

  // App usage tracking for landing page interactions
  useAppUsageTracking('landing_page');
  const { trackMetaLead } = useAnalytics();

  return (
    <div className="landing-page">
      {/* Squares Background Pattern */}
      <div className="squares-background"></div>

      {/* Hero Section */}
      <section className="hero-section">
        <EnhancedPageTracker
          path="/"
          title="PLOScope - Advanced PLO Analysis for Double Board Bomb Pots"
          params={{
            user_id: user?.id,
            is_authenticated: !!user,
            page_type: 'landing',
          }}
          deps={[user?.id]}
        />
        <div className="hero-container">
          <div className="hero-content">
            <h1 className="hero-title">
              Dominate PLO with
              <span className="hero-highlight"> Advanced Equity Analysis</span>
            </h1>
            <p className="hero-subtitle">
              The most sophisticated Pot Limit Omaha equity calculator and
              analysis tool. Analyze complex spots, master opponent ranges, and
              elevate your PLO game to the next level.
            </p>

            <div className="hero-actions">
              {user ? (
                <Link to="/app/live" className="hero-cta-primary">
                  🚀 Launch PLO Analysis
                </Link>
              ) : (
                <>
                  <Link
                    to="/pricing"
                    className="hero-cta-primary"
                    data-analytics-id="hero_get_started"
                    data-analytics-label="Get Started for Free"
                  >
                    Get Started for Free
                  </Link>
                  <Link
                    to="/pricing"
                    className="hero-cta-secondary"
                    data-analytics-id="hero_view_pricing"
                    data-analytics-label="View Pricing"
                  >
                    View Pricing
                  </Link>
                </>
              )}
            </div>

            <div className="hero-stats">
              <div className="stat-item">
                <span className="stat-number">1M+</span>
                <span className="stat-label">Hands Analyzed</span>
              </div>
              <div className="stat-item">
                <span className="stat-number">99.9%</span>
                <span className="stat-label">Accuracy</span>
              </div>
              <div className="stat-item">
                <span className="stat-number">Real-time</span>
                <span className="stat-label">Calculations</span>
              </div>
            </div>
          </div>

          <div className="hero-visual">
            <HeroAppPreview />
          </div>
        </div>
      </section>

      {/* Loom Video Placeholder */}
      <section className="loom-section">
        <div className="section-container">
          <div className="section-header">
            <h2>See PLOScope in Action</h2>
            <p>
              Watch a quick overview of how to analyze spots and train your
              game.
            </p>
          </div>
          <div
            className="loom-embed-placeholder"
            role="region"
            aria-label="Product demo video placeholder"
          >
            {/* Replace src below with your Loom embed URL. Example:
                <iframe src="https://www.loom.com/embed/VIDEO_ID" frameBorder="0" allowFullScreen></iframe>
              */}
            <div className="loom-placeholder-frame">
              <div className="loom-placeholder-content">
                <span className="loom-play-icon">▶</span>
                <div>
                  <div className="loom-title">
                    Product demo will appear here
                  </div>
                  <div className="loom-subtitle">
                    Paste your Loom embed URL in this section
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="features-section">
        <div className="section-container">
          <div className="section-header">
            <h2>Instantly access any PLO spot you can imagine</h2>
            <p>
              From preflop to any river you want, we have all the possible
              situations covered.
            </p>
          </div>

          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">🎯</div>
              <h3>Precise Spot Analysis</h3>
              <p>
                Analyze specific PLO scenarios with mathematical precision.
                Input exact cards and board textures to get detailed equity
                breakdowns and optimal play recommendations.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">⚡</div>
              <h3>Real-Time Calculations</h3>
              <p>
                Lightning-fast equity calculations as you play. Perfect for
                analysis sessions and understanding complex hand dynamics in
                live situations.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">📊</div>
              <h3>Advanced Range Analysis</h3>
              <p>
                Study opponent ranges with sophisticated modeling. Understand
                how different ranges perform against various board textures and
                betting patterns.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">🎲</div>
              <h3>Monte Carlo Simulation</h3>
              <p>
                Run millions of simulations to get accurate results. Our
                advanced engine processes complex PLO scenarios with
                industry-leading precision.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">📈</div>
              <h3>Spot Mode</h3>
              <p>
                Practice decision-making with guided scenarios. Improve your PLO
                skills through structured learning paths and instant feedback.
              </p>
            </div>

            <div className="feature-card">
              <div className="feature-icon">💾</div>
              <h3>Hand History Analysis</h3>
              <p>
                Upload your hand histories and instantly see your PLO mistakes.
                The most efficient way to find leaks and improve your game.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Practice Section */}
      <section className="practice-section">
        <div className="section-container">
          <div className="practice-content">
            <div className="practice-text">
              <h2>Practice any situation anywhere you go</h2>
              <p>
                Challenge yourself and practice any preflop or postflop
                situation. Mastering PLO has never been this accessible.
              </p>

              <div className="practice-features">
                <div className="practice-feature">
                  <span className="checkmark">✓</span>
                  <span>Works seamlessly on desktop and mobile</span>
                </div>
                <div className="practice-feature">
                  <span className="checkmark">✓</span>
                  <span>Offline mode for analysis anywhere</span>
                </div>
                <div className="practice-feature">
                  <span className="checkmark">✓</span>
                  <span>Progress tracking and statistics</span>
                </div>
                <div className="practice-feature">
                  <span className="checkmark">✓</span>
                  <span>Customizable difficulty levels</span>
                </div>
              </div>

              <Link to="/pricing" className="practice-cta">
                Start practicing for free
              </Link>
            </div>

            <div className="practice-visual">
              <MobilePreview />
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="cta-section">
        <div className="section-container">
          <div className="cta-content">
            <h2>Ready to dominate PLO?</h2>
            <p>
              Join thousands of players who are already using PLOScope to
              improve their game.
            </p>

            <div className="cta-actions">
              {user ? (
                <Link to="/app/live" className="cta-primary">
                  Launch PLO Analysis
                </Link>
              ) : (
                <>
                  <Link
                    to="/pricing"
                    className="cta-primary"
                    data-analytics-id="cta_launch_or_get_started"
                    data-analytics-label="Get Started CTA"
                  >
                    Get Started for Free
                  </Link>
                  <Link
                    to="/pricing"
                    className="cta-secondary"
                    data-analytics-id="cta_view_pricing_plans"
                    data-analytics-label="View Pricing Plans"
                  >
                    View Pricing Plans
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Modals */}

      <AuthModal
        isOpen={showAuthModal}
        onClose={() => setShowAuthModal(false)}
        defaultMode="login"
        onSuccess={() => setShowAuthModal(false)}
      />
    </div>
  );
};

export default LandingPage;
