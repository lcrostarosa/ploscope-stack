import React from 'react';

import { Card } from './Card';
import './HeroAppPreview.scss';

const HeroAppPreview = () => (
  <div className="hero-app-preview">
    <div className="preview-window">
      <div className="window-header">
        <div className="window-controls">
          <span className="control-dot red"></span>
          <span className="control-dot yellow"></span>
          <span className="control-dot green"></span>
        </div>
        <span className="window-title">PLOScope - Spot Analysis</span>
      </div>

      <div className="preview-content">
        <div className="preview-cards-section">
          <div className="hero-hand">
            <Card card="Ah" />
            <Card card="Qs" />
            <Card card="Jd" />
            <Card card="Tc" />
          </div>

          <div className="vs-indicator">VS</div>

          <div className="opponent-hand">
            <Card card="" hidden />
            <Card card="" hidden />
            <Card card="" hidden />
            <Card card="" hidden />
          </div>
        </div>

        <div className="preview-cards-section">
          <div className="board-label">Board</div>
          <div className="board-cards">
            <Card card="Kh" />
            <Card card="8c" />
            <Card card="7d" />
          </div>
        </div>

        <div className="preview-cards-section">
          <div className="board-label">Board 2</div>
          <div className="board-cards">
            <Card card="As" />
            <Card card="Td" />
            <Card card="9c" />
          </div>
        </div>

        <div className="equity-display">
          <div className="equity-bar">
            <div className="equity-fill" style={{ width: '67%' }}></div>
            <div className="equity-text">67.2% Equity</div>
          </div>
        </div>
      </div>
    </div>
  </div>
);

export default HeroAppPreview;
