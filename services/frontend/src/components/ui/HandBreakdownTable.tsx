import React, { memo } from 'react';

import PropTypes, { object, string, oneOf } from 'prop-types';

import type {
  HandBreakdownTableProps,
  HandBreakdown,
  BreakdownMetrics,
} from '../../types/UITypes';

import HandBreakdownChart from './HandBreakdownChart';

/**
 * Renders a visual chart showing hand strength breakdowns with win/loss/tie percentages.
 * The breakdown object can be shaped as:
 *   {    "Flush": 12,                        // counts treated as wins
 *        "Full House": { wins: 3, ties: 1, losses: 2 },
 *        "Two Pair": { count: 7 }           // shorthand, treated as wins
 *   }
 */

const HandBreakdownTable: React.FC<HandBreakdownTableProps> = memo(
  ({ breakdown, title, context = 'hero' }) => {
    // Early return if no breakdown data
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

    // Convert old format to new format if needed
    const normalizedBreakdown: Record<string, BreakdownMetrics> = {};
    Object.entries(breakdown).forEach(([hand, val]) => {
      if (val == null) return;

      if (typeof val === 'number') {
        // Treat raw number as wins
        normalizedBreakdown[hand] = {
          wins: val,
          ties: 0,
          losses: 0,
          total: val,
        };
      } else if (typeof val === 'object') {
        const wins = (val.wins as number) || 0;
        const ties = (val.ties as number) || 0;
        const losses = (val.losses as number) || 0;
        const total =
          (val.total as number) || (val as any).count || wins + ties + losses;

        normalizedBreakdown[hand] = { wins, ties, losses, total };
      }
    });

    // Only render if we have valid data after normalization
    if (Object.keys(normalizedBreakdown).length === 0) {
      return (
        <div className="hand-breakdown-chart">
          {title && <h4 className="breakdown-chart-title">{title}</h4>}
          <div className="hand-breakdown-chart-empty">
            <p>No valid hand breakdown data available</p>
          </div>
        </div>
      );
    }

    return (
      <HandBreakdownChart
        breakdown={normalizedBreakdown}
        title={title}
        context={context}
      />
    );
  }
);

HandBreakdownTable.propTypes = {
  breakdown: object as any,
  title: string.isRequired,
  context: oneOf(['hero', 'opponents']) as any,
};

HandBreakdownTable.displayName = 'HandBreakdownTable';

export default HandBreakdownTable;
