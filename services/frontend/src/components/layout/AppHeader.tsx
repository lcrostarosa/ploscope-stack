/* @ts-nocheck */

import React, { useState, useEffect, useRef } from 'react';

import { useNavigate, useLocation } from 'react-router-dom';

import { useAuth } from '../../contexts/AuthContext';
import { useJobContext } from '../../contexts/JobContext';
import { isLiveModeEnabled, isBlogEnabled } from '../../utils/featureFlags';
import { AuthModal } from '../forms';
import { TierIndicator } from '../ui';
import './AppHeader.scss';

export const AppHeader = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuth();
  const { activeJobCount } = useJobContext();
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);
  const mobileMenuRef = useRef(null);
  const userMenuRef = useRef(null);

  // Determine current mode
  const isSpotMode = location.pathname.includes('/app/spotMode');
  const isLiveMode = location.pathname.includes('/app/live');
  const isLandingPage = location.pathname === '/';

  // Get user display name
  const getUserDisplayName = () => {
    if (!user) return '';
    if (user.first_name && user.last_name) {
      return `${user.first_name} ${user.last_name}`;
    }
    return user.first_name || user.username || user.email;
  };

  // Handle scroll effect
  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 10);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Handle body overflow when mobile menu is open
  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.style.overflow = 'hidden';
      document.body.style.position = 'fixed';
      document.body.style.width = '100%';
      document.body.style.top = `-${window.scrollY}px`;

      // Scroll mobile menu to top
      const menu = mobileMenuRef.current as unknown as HTMLElement | null;
      if (menu) {
        menu.scrollTop = 0;
      }
    } else {
      const scrollY = document.body.style.top;
      document.body.style.overflow = '';
      document.body.style.position = '';
      document.body.style.width = '';
      document.body.style.top = '';
      if (scrollY) {
        window.scrollTo(0, parseInt(scrollY || '0') * -1);
      }
    }
    return () => {
      document.body.style.overflow = '';
      document.body.style.position = '';
      document.body.style.width = '';
      document.body.style.top = '';
    };
  }, [isMobileMenuOpen]);

  // Handle click outside user menu to close it
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node;
      const menu = userMenuRef.current as unknown as HTMLElement | null;
      if (menu && !menu.contains(target)) {
        setShowUserMenu(false);
      }
    };

    if (showUserMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showUserMenu]);

  const handleLogout = () => {
    logout();
    setIsMobileMenuOpen(false);
    navigate('/');
  };

  const handleNavClick = (path: string) => {
    navigate(path);
    setIsMobileMenuOpen(false);
  };

  const closeMobileMenu = () => {
    setIsMobileMenuOpen(false);
  };

  const openMobileMenu = () => {
    setIsMobileMenuOpen(true);
  };

  return (
    <>
      <nav className={`app-nav ${isScrolled ? 'scrolled' : ''}`}>
        <div className="nav-left">
          <div className="logo" onClick={() => navigate('/')}>
            <img
              src="/logo-no-text.svg"
              alt="PLOScope Logo"
              width="36"
              height="36"
            />
            <span className="logo-text">PLOScope</span>
          </div>
        </div>

        <div className="nav-right">
          <div className="desktop-nav-elements app-navigation">
            {/* Landing page - show Launch App for authenticated users, Sign In for unauthenticated */}
            {isLandingPage ? (
              user ? (
                <button
                  className="launch-app-button"
                  onClick={() => navigate('/app/live')}
                  title="Launch PLOScope App"
                >
                  🚀 Launch App
                </button>
              ) : (
                <button
                  className="auth-button"
                  onClick={() => setShowAuthModal(true)}
                >
                  Sign In
                </button>
              )
            ) : (
              <>
                {user && <TierIndicator />}
                {isBlogEnabled() && (
                  <button
                    className={`mode-chip ${location.pathname.startsWith('/blog') ? 'active' : ''}`}
                    onClick={() => handleNavClick('/blog')}
                    title="Read our Blog"
                  >
                    📚 Blog
                  </button>
                )}
                {/* ThemeToggle removed - using dark mode only */}
                {user ? (
                  <div className="user-menu-container" ref={userMenuRef}>
                    <button
                      className={`user-menu-button ${showUserMenu ? 'menu-open' : ''}`}
                      onClick={() => setShowUserMenu(!showUserMenu)}
                    >
                      {getUserDisplayName()}
                    </button>
                    {showUserMenu && (
                      <div className="user-menu">
                        <button
                          className="user-menu-item"
                          onClick={() => {
                            navigate('/app/live');
                            setShowUserMenu(false);
                          }}
                        >
                          🎲 Live Play
                        </button>
                        {/* Spot Analysis removed from dropdown */}
                        <button
                          className="user-menu-item"
                          onClick={() => {
                            navigate('/app/jobs');
                            setShowUserMenu(false);
                          }}
                        >
                          ⏳ Jobs{' '}
                          {activeJobCount > 0 ? `(${activeJobCount})` : ''}
                        </button>
                        <div className="user-menu-divider"></div>
                        <button
                          className="user-menu-item"
                          onClick={() => {
                            navigate('/profile');
                            setShowUserMenu(false);
                          }}
                        >
                          👤 Profile
                        </button>
                        <button
                          className="user-menu-item"
                          onClick={() => {
                            handleLogout();
                            setShowUserMenu(false);
                          }}
                        >
                          🚪 Logout
                        </button>
                      </div>
                    )}
                  </div>
                ) : (
                  <button
                    className="auth-button"
                    onClick={() => setShowAuthModal(true)}
                  >
                    Login
                  </button>
                )}
              </>
            )}
          </div>

          <button
            className="mobile-menu-toggle"
            onClick={openMobileMenu}
            aria-label="Open mobile menu"
          >
            <span></span>
            <span></span>
            <span></span>
          </button>
        </div>
      </nav>

      {/* Mobile Menu Overlay */}
      {isMobileMenuOpen && (
        <div className="mobile-menu-overlay" onClick={closeMobileMenu} />
      )}

      {/* Mobile Navigation Menu */}
      <div
        ref={mobileMenuRef}
        className={`mobile-nav-menu ${isMobileMenuOpen ? 'mobile-open' : ''}`}
      >
        <div className="mobile-menu-header">
          <h2>Menu</h2>
          <button
            className="mobile-menu-close"
            onClick={closeMobileMenu}
            aria-label="Close mobile menu"
          >
            ✕
          </button>
        </div>

        <div className="mobile-menu-content">
          {user && (
            <div className="mobile-user-info">
              <div className="user-name">{getUserDisplayName()}</div>
              <div className="user-email">{user.email}</div>
            </div>
          )}

          {user && (
            <div className="mobile-tier-section">
              <div className="mobile-tier-indicator">
                <TierIndicator
                  user={{ subscription_tier: user.subscription_tier as string }}
                  hideUpgradeButton={true}
                />
              </div>
              {user.subscription_tier === 'free' && (
                <button
                  className="upgrade-plan-btn"
                  onClick={() => {
                    navigate('/pricing');
                    closeMobileMenu();
                  }}
                >
                  💎 Upgrade Plan
                </button>
              )}
            </div>
          )}

          <div className="nav-links">
            <button
              className={`nav-link ${location.pathname === '/' ? 'active' : ''}`}
              onClick={() => handleNavClick('/')}
            >
              🏠 Home
            </button>
            {/* Landing page - show Launch App for authenticated users, Sign In for unauthenticated */}
            {isLandingPage &&
              (user ? (
                <button
                  className="nav-link launch-app-mobile"
                  onClick={() => handleNavClick('/app/live')}
                >
                  🚀 Launch App
                </button>
              ) : (
                <button
                  className="nav-link"
                  onClick={() => {
                    setShowAuthModal(true);
                    closeMobileMenu();
                  }}
                >
                  👤 Sign In
                </button>
              ))}
            {/* Protected routes - only show for authenticated users */}
            {user && (
              <>
                {isLiveModeEnabled() && (
                  <button
                    className={`nav-link ${isLiveMode ? 'active' : ''}`}
                    onClick={() => handleNavClick('/app/live')}
                  >
                    🎲 Live Mode
                  </button>
                )}
              </>
            )}
          </div>

          {user && (
            <div className="user-section">
              <button
                className="nav-link"
                onClick={() => handleNavClick('/profile')}
              >
                👤 Profile
              </button>
              <button className="logout-btn" onClick={handleLogout}>
                🚪 Logout
              </button>
            </div>
          )}

          {!user && (
            <div className="auth-section">
              <button
                className="auth-button mobile"
                onClick={() => {
                  setShowAuthModal(true);
                  closeMobileMenu();
                }}
              >
                👤 Login
              </button>
            </div>
          )}
        </div>
      </div>

      {showAuthModal && (
        <AuthModal
          isOpen={true}
          onClose={() => setShowAuthModal(false)}
          onSuccess={() => setShowAuthModal(false)}
          defaultMode="login"
        />
      )}
    </>
  );
};
