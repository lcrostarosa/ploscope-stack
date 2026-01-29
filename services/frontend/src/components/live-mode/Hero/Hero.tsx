import React from 'react';
import './Hero.scss';

const Hero = () => {
  return (
    <>
      {/* Live Mode Header */}
      <div className="live-mode-welcome">
        <div className="mode-chip-inline">🎲 Live Play</div>
        <h1>Live Play - Hand Generation</h1>
        <p>
          Deal a hand and use &#34;Study This Spot&#34; to analyze it in Spot
          Analysis.
        </p>
        <div className="support-link">
          <a
            href="/support"
            target="_blank"
            rel="noopener noreferrer"
            className="support-btn"
          >
            🆘 Need Help?
          </a>
        </div>
      </div>
      {/* Mobile disclaimer */}
      <div className="live-mode-mobile-disclaimer" role="note">
        Mobile layout is a work in progress. For the best experience, please use
        desktop.
      </div>
    </>
  );
};

export default Hero;
