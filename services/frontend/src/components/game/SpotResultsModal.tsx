import React from 'react';

import type { HandBreakdown } from '../../types/UITypes';
import { Card } from '../ui/Card';
import HandBreakdownTable from '../ui/HandBreakdownTable';
import './SpotResultsModal.scss';

type PlayerResult = {
  player_number: number;
  cards: string[];
  top_estimated_equity: number;
  bottom_estimated_equity: number;
  chop_both_boards: number;
  scoop_both_boards: number;
  split_top: number;
  split_bottom: number;
  top_detailed_stats?: {
    win_rate: number;
    tie_rate: number;
    [key: string]: any;
  };
  bottom_detailed_stats?: {
    win_rate: number;
    tie_rate: number;
    [key: string]: any;
  };
  top_hand_breakdown?: HandBreakdown;
  bottom_hand_breakdown?: HandBreakdown;
  [key: string]: any;
};

type SpotResultsModalProps = {
  isOpen: boolean;
  onClose: () => void;
  results: PlayerResult[] | null;
  isLoading: boolean;
  error: string | null;
  currentJobId?: string | number | null;
  onCancelJob?: (jobId: string | number) => void;
  showBackButton?: boolean;
  onBack?: () => void;
};

export const SpotResultsModal: React.FC<SpotResultsModalProps> = ({
  isOpen,
  onClose,
  results,
  isLoading,
  error,
  currentJobId,
  onCancelJob,
  showBackButton = false,
  onBack,
}) => {
  if (!isOpen) return null;

  const formatPercent = (value: any) => {
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (typeof num !== 'number' || isNaN(num)) {
      return 'N/A';
    }
    return `${(num * 100).toFixed(2)}%`;
  };

  const formatValue = (value: any) => {
    if (value === null || value === undefined) {
      return 'N/A';
    }
    // Allow numeric strings
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (typeof num === 'number') {
      if (isNaN(num)) {
        return 'N/A';
      }
      // If it's already a percentage (0-1 range), format as percentage
      if (num <= 1 && num >= 0) {
        return `${(num * 100).toFixed(2)}%`;
      }
      // Otherwise, format as regular number
      return num.toFixed(2);
    }
    if (typeof value === 'object') {
      return JSON.stringify(value);
    }
    return String(value);
  };

  const formatCount = (value: any) => {
    if (value === null || value === undefined) return 'N/A';
    if (Array.isArray(value)) return String(value.length);
    const num = typeof value === 'string' ? parseFloat(value) : value;
    if (typeof num !== 'number' || isNaN(num)) return 'N/A';
    return String(Math.round(num));
  };

  const formatHandRank = (key: string) => {
    return key.replace(/_/g, ' ').replace(/\b\w/g, char => char.toUpperCase());
  };

  const sumBreakdownTotal = (breakdown?: HandBreakdown): number | null => {
    if (!breakdown || Object.keys(breakdown).length === 0) return null;
    try {
      let total = 0;
      for (const val of Object.values(breakdown)) {
        if (val == null) continue;
        if (typeof val === 'number') {
          total += val;
        } else if (typeof val === 'object') {
          const wins = (val as any).wins || 0;
          const ties = (val as any).ties || 0;
          const losses = (val as any).losses || 0;
          const t = (val as any).total ?? wins + ties + losses;
          total += t;
        }
      }
      return total;
    } catch {
      return null;
    }
  };

  return (
    <div className="spot-results-modal-overlay" onClick={onClose}>
      <div className="spot-results-modal" onClick={e => e.stopPropagation()}>
        <div className="spot-results-header">
          <div className="header-left">
            {showBackButton && onBack && (
              <button
                className="back-btn"
                onClick={onBack}
                title="Go back to previous modal"
              >
                ← Back
              </button>
            )}
            <h2>📊 Spot Analysis Results</h2>
          </div>
          <button className="close-btn" onClick={onClose}>
            ×
          </button>
        </div>

        <div className="spot-results-content">
          {isLoading && (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Analyzing spot... This may take a few minutes.</p>
              <p className="loading-subtext">
                Running simulations and calculating equity...
              </p>
              {currentJobId && onCancelJob && (
                <button
                  className="cancel-job-btn"
                  onClick={() => onCancelJob(currentJobId)}
                  style={{
                    marginTop: '16px',
                    padding: '8px 16px',
                    backgroundColor: '#dc3545',
                    color: 'white',
                    border: 'none',
                    borderRadius: '4px',
                    cursor: 'pointer',
                    fontSize: '14px',
                  }}
                >
                  Cancel Job
                </button>
              )}
            </div>
          )}

          {error && (
            <div className="error-state">
              <p className="error-message">❌ {error}</p>
            </div>
          )}

          {results && results.length > 0 && (
            <div className="results-container">
              {results.map((result, index) => {
                // Check if this looks like a valid result object
                const hasExpectedFields =
                  result &&
                  typeof result === 'object' &&
                  (result.player_number !== undefined ||
                    result.cards !== undefined ||
                    result.top_estimated_equity !== undefined ||
                    result.bottom_estimated_equity !== undefined);

                if (!hasExpectedFields) {
                  // If it doesn't look like a valid result, show it as raw data
                  return (
                    <div key={index} className="player-result">
                      <h3>Result {index + 1}</h3>
                      <div className="raw-data">
                        <pre
                          style={{
                            fontSize: '12px',
                            color: '#ccc',
                            overflow: 'auto',
                          }}
                        >
                          {JSON.stringify(result, null, 2)}
                        </pre>
                      </div>
                    </div>
                  );
                }

                return (
                  <div key={index} className="player-result">
                    <div className="player-header">
                      <h3>Player {result.player_number || 'Unknown'}</h3>
                      <div className="player-cards">
                        {result.cards && Array.isArray(result.cards) ? (
                          result.cards.map((card, cardIndex) => (
                            <Card key={cardIndex} card={card || ''} />
                          ))
                        ) : (
                          <span style={{ color: '#888' }}>
                            No cards available
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="equity-section">
                      <div className="equity-row">
                        <div className="equity-item">
                          <label>Top Board Equity:</label>
                          <span className="equity-value">
                            {formatValue(result.top_estimated_equity)}
                          </span>
                        </div>
                        <div className="equity-item">
                          <label>Bottom Board Equity:</label>
                          <span className="equity-value">
                            {formatValue(result.bottom_estimated_equity)}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="double-board-stats">
                      <h4>Double Board Stats</h4>
                      <div className="stats-grid">
                        <div className="stat-item">
                          <label>Scoop Both:</label>
                          <span>{formatValue(result.scoop_both_boards)}</span>
                        </div>
                        <div className="stat-item">
                          <label>Chop Both:</label>
                          <span>{formatValue(result.chop_both_boards)}</span>
                        </div>
                        <div className="stat-item">
                          <label>Split Top:</label>
                          <span>{formatValue(result.split_top)}</span>
                        </div>
                        <div className="stat-item">
                          <label>Split Bottom:</label>
                          <span>{formatValue(result.split_bottom)}</span>
                        </div>
                      </div>
                    </div>

                    {(() => {
                      // Collect outs fields - prefer known names, but also show any *outs* keys
                      const knownOutsKeys = [
                        'scoop_both_outs',
                        'chop_both_outs',
                        'split_top_outs',
                        'split_bottom_outs',
                      ];
                      const dynamicOutsKeys = Object.keys(result || {})
                        .filter(k => /outs/i.test(k))
                        .filter(
                          k => !['outs', 'outs_count'].includes(k.toLowerCase())
                        );
                      const outsKeys = Array.from(
                        new Set([...knownOutsKeys, ...dynamicOutsKeys]).values()
                      ).filter(k => k in (result || {}));

                      if (outsKeys.length === 0) return null;

                      const labelFor = (key: string) => {
                        const map: Record<string, string> = {
                          scoop_both_outs: 'Scoop Both Outs',
                          chop_both_outs: 'Chop Both Outs',
                          split_top_outs: 'Split Top Outs',
                          split_bottom_outs: 'Split Bottom Outs',
                        };
                        if (map[key]) return map[key];
                        // Fallback: prettify
                        return formatHandRank(key.replace(/_/g, ' '));
                      };

                      return (
                        <div className="outs-stats">
                          <h4>Outs</h4>
                          <div className="stats-grid">
                            {outsKeys.map(key => (
                              <div key={key} className="stat-item">
                                <label>{labelFor(key)}:</label>
                                <span
                                  className="outs-count"
                                  data-testid="outs-count"
                                >
                                  {formatCount((result as any)[key])}
                                </span>
                              </div>
                            ))}
                          </div>
                        </div>
                      );
                    })()}

                    {result.top_detailed_stats && (
                      <div className="detailed-stats">
                        <h4>Top Board Detailed Stats</h4>
                        {result.top_hand_breakdown &&
                          Object.keys(result.top_hand_breakdown).length > 0 && (
                            <HandBreakdownTable
                              breakdown={result.top_hand_breakdown}
                              title=""
                              context="hero"
                            />
                          )}
                      </div>
                    )}

                    {result.bottom_detailed_stats && (
                      <div className="detailed-stats">
                        <h4>Bottom Board Detailed Stats</h4>
                        {result.bottom_hand_breakdown &&
                          Object.keys(result.bottom_hand_breakdown).length >
                            0 && (
                            <HandBreakdownTable
                              breakdown={result.bottom_hand_breakdown}
                              title=""
                              context="hero"
                            />
                          )}
                      </div>
                    )}

                    {/* Fallback: Show all available data if expected structure isn't found */}
                    {!result.top_detailed_stats &&
                      !result.bottom_detailed_stats &&
                      !result.top_hand_breakdown &&
                      !result.bottom_hand_breakdown && (
                        <div className="fallback-stats">
                          <h4>Additional Statistics</h4>
                          <div className="stats-grid">
                            {Object.entries(result)
                              .filter(
                                ([key]) =>
                                  ![
                                    'player_number',
                                    'cards',
                                    'top_estimated_equity',
                                    'bottom_estimated_equity',
                                    'chop_both_boards',
                                    'scoop_both_boards',
                                    'split_top',
                                    'split_bottom',
                                  ].includes(key) && !/outs/i.test(key)
                              )
                              .map(([key, value]) => (
                                <div key={key} className="stat-item">
                                  <label>{formatHandRank(key)}:</label>
                                  <span>{formatValue(value)}</span>
                                </div>
                              ))}
                          </div>
                        </div>
                      )}
                  </div>
                );
              })}
            </div>
          )}

          {!isLoading && !error && (!results || results.length === 0) && (
            <div className="empty-state">
              <p>No results to display.</p>
            </div>
          )}
        </div>

        <div className="spot-results-footer">
          <button className="close-footer-btn" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
