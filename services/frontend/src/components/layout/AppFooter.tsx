import React from 'react';

import { Link } from 'react-router-dom';

import { isBlogEnabled } from '../../utils/featureFlags';
import './AppFooter.scss';

const AppFooter: React.FC = () => {
  return (
    <footer className="landing-footer">
      <div className="footer-container">
        <div className="footer-content">
          <div className="footer-brand">
            <div className="footer-logo">
              <div className="logo-icon">
                <img
                  src="/logo-no-text.svg"
                  alt="PLOScope Logo"
                  width="32"
                  height="32"
                />
              </div>
              <span>PLOScope</span>
            </div>
            <p>
              The most advanced PLO equity calculator and analysis platform.
            </p>
          </div>

          <div className="footer-links">
            <div className="footer-column">
              <h4>Product</h4>
              <Link to="/pricing">Pricing</Link>
              {isBlogEnabled() && <Link to="/blog">Blog</Link>}
              <Link to="/faq">FAQ</Link>
              <a
                href="https://docs.google.com/forms/d/1kHyjal2SPWs4KfaJWPdnvKeUhOZPSr05P96uUVh_8aA/viewform"
                target="_blank"
                rel="noopener noreferrer"
                data-discover
              >
                Feedback
              </a>
            </div>

            <div className="footer-column">
              <h4>Legal</h4>
              <Link to="/privacy">Privacy Policy</Link>
              <Link to="/terms">Terms of Service</Link>
            </div>

            <div className="footer-column">
              <h4>Social</h4>
              <a
                href="https://twitter.com/PLOScope"
                target="_blank"
                rel="noopener noreferrer"
              >
                X (Twitter)
              </a>
              <a
                href="https://instagram.com/PLOScope"
                target="_blank"
                rel="noopener noreferrer"
              >
                Instagram
              </a>
              <a
                href="https://discord.gg/ploscope"
                target="_blank"
                rel="noopener noreferrer"
              >
                Join Discord
              </a>
            </div>
          </div>
        </div>

        <div className="footer-bottom">
          <p>&copy; 2025 PLOScope. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default AppFooter;
