import React from 'react';

import { Link } from 'react-router-dom';
import './MobilePreview.scss';

const MobilePreview = () => (
  <div className="mobile-preview">
    <div className="mobile-frame">
      <div className="mobile-screen">
        <div className="mobile-content">
          <div className="mobile-header">Practice Mode</div>
          <div className="mobile-cards">
            <div className="mini-card">A♠</div>
            <div className="mini-card">K♥</div>
            <div className="mini-card">Q♦</div>
            <div className="mini-card">J♣</div>
          </div>
          <div className="mobile-question">What&apos;s the best play?</div>
          <div className="mobile-actions">
            <button className="mobile-btn">Fold</button>
            <button className="mobile-btn">Call</button>
            <button className="mobile-btn">Raise</button>
          </div>
        </div>
      </div>
    </div>
  </div>
);

export default MobilePreview;
