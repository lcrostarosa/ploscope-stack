import React, { memo } from 'react';

import PropTypes, { object, string, oneOf } from 'prop-types';

import type {
  HandBreakdownChartProps,
  HandBreakdown,
  BreakdownMetrics,
} from '../../types/UITypes';
import './HandBreakdownChart.scss';

/**
 * Renders a visual bar chart showing hand strength breakdowns with win/loss/tie percentages
 * The breakdown object structure:
 *   {
 *     "Two Pair": { wins: 10, ties: 2, losses: 15, total: 27 },
 *     "Full House": { wins: 5, ties: 0, losses: 1, total: 6 },
 *     ...
 *   }
 */

const HandBreakdownChart: React.FC<HandBreakdownChartProps> = memo(
  ({ breakdown, title, context = 'hero' }) => {
    if (!breakdown || Object.keys(breakdown).length === 0) {
      return (
        <div className="hand-breakdown-chart">
          {title && <h4 className="breakdown-chart-title">{title}</h4>}
          <div className="hand-breakdown-chart-empty">
            <p>No hand breakdown data available</p>
          </div>
        </div>
      );
    }

    // Helper for safely extracting metrics
    const getMetrics = (val: any): BreakdownMetrics => {
      if (!val || typeof val !== 'object')
        return { wins: 0, ties: 0, losses: 0, total: 0 };

      const wins = (val.wins as number) || 0;
      const ties = (val.ties as number) || 0;
      const losses = (val.losses as number) || 0;
      const total = (val.total as number) || wins + ties + losses;

      return { wins, ties, losses, total };
    };

    // Helper to generate descriptive hover text
    const getHoverText = (
      hand: string,
      wins: number,
      ties: number,
      losses: number,
      total: number,
      context: 'hero' | 'opponents'
    ) => {
      const winPercent = total > 0 ? (wins / total) * 100 : 0;

      if (context === 'opponents') {
        return `Opponents win ${wins.toLocaleString()} times with ${hand} (${winPercent.toFixed(1)}%)`;
      } else {
        return `You win ${wins.toLocaleString()} times with ${hand} (${winPercent.toFixed(1)}%)`;
      }
    };

    // Sort hands by total frequency (most common first)
    const sortedHands = Object.entries(breakdown)
      .map(([hand, data]) => ({ hand, ...getMetrics(data) }))
      .filter(item => item.total > 0)
      .sort((a, b) => b.total - a.total);

    if (sortedHands.length === 0) {
      return (
        <div className="hand-breakdown-chart">
          {title && <h4 className="breakdown-chart-title">{title}</h4>}
          <div className="hand-breakdown-chart-empty">
            <p>No hand breakdown data available</p>
          </div>
        </div>
      );
    }

    // Compute max total to scale bar lengths by how often each hand occurs
    const maxTotal = Math.max(...sortedHands.map(h => h.total));

    return (
      <div className="hand-breakdown-chart">
        {title && <h4 className="breakdown-chart-title">{title}</h4>}

        <div className="breakdown-chart-container">
          {sortedHands.map(({ hand, wins, ties, losses, total }) => {
            const winPercent = total > 0 ? (wins / total) * 100 : 0;
            const barWidthPct = maxTotal > 0 ? (total / maxTotal) * 100 : 0;

            return (
              <div key={hand} className="breakdown-chart-row">
                <div className="hand-name">
                  <span className="hand-label">{hand}</span>
                  <span className="hand-frequency">
                    ({total.toLocaleString()})
                  </span>
                </div>

                <div className="percentage-bar-container">
                  <div className="percentage-bar" style={{ width: `${barWidthPct}%` }}>
                    <div
                      className="bar-segment win-segment"
                      style={{ width: `${winPercent}%` }}
                      title={getHoverText(
                        hand,
                        wins,
                        ties,
                        losses,
                        total,
                        context
                      )}
                    />
                    <div
                      className="bar-segment tie-segment"
                      style={{
                        width: `${total > 0 ? (ties / total) * 100 : 0}%`,
                      }}
                      title={`${total > 0 ? (ties / total) * 100 : 0}% ties (${ties.toLocaleString()})`}
                    />
                    <div
                      className="bar-segment loss-segment"
                      style={{
                        width: `${total > 0 ? (losses / total) * 100 : 0}%`,
                      }}
                      title={`${total > 0 ? (losses / total) * 100 : 0}% losses (${losses.toLocaleString()})`}
                    />
                  </div>

                  <div className="percentage-labels">
                    <span className="win-label">{winPercent.toFixed(1)}%</span>
                    <span className="tie-label">
                      {(total > 0 ? (ties / total) * 100 : 0).toFixed(1)}%
                    </span>
                    <span className="loss-label">
                      {(total > 0 ? (losses / total) * 100 : 0).toFixed(1)}%
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="chart-legend">
          <div className="legend-item">
            <div className="legend-color win-color"></div>
            <span>Wins</span>
          </div>
          <div className="legend-item">
            <div className="legend-color tie-color"></div>
            <span>Ties</span>
          </div>
          <div className="legend-item">
            <div className="legend-color loss-color"></div>
            <span>Losses</span>
          </div>
        </div>
      </div>
    );
  }
);

HandBreakdownChart.propTypes = {
  breakdown: object as any,
  title: string.isRequired,
  context: oneOf(['hero', 'opponents']) as any,
};

HandBreakdownChart.displayName = 'HandBreakdownChart';

export default HandBreakdownChart;
