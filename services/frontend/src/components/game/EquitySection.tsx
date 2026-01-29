import React, { memo } from 'react';

import { OrbitProgress } from 'react-loading-indicators';

import './EquitySection.scss';
import type { Equities } from '@/types/GameStateTypes';

type EquitySectionProps = {
  equities: Equities;
  index: number;
  isLoading: boolean;
  isFolded: boolean;
};

const EquitySection: React.FC<EquitySectionProps> = memo(
  ({ equities, index, isLoading, isFolded }) => {
    const renderValue = (value: number | string | undefined) => {
      if (isLoading) return 'Calculating...';
      if (!equities?.[index] || isFolded) return 'TBD';
      return typeof value === 'number' ? `${value}%` : value || 'TBD';
    };

    const playerEquity = equities?.[index];

    return (
      <div className="equity-section">
        {isLoading ? (
          <div className="equity-loading-indicator" role="status">
            <OrbitProgress color="#425742" size="small" text="" textColor="" />
          </div>
        ) : (
          <>
            {/* Board Equities Table */}
            <table className="equity-table">
              <thead>
                <tr>
                  <th>Board</th>
                  <th>Hand</th>
                  <th>Est</th>
                  <th>Act</th>
                </tr>
              </thead>
              <tbody>
                <tr data-testid="top-board-row">
                  <td className="board-label">Top</td>
                  <td className="hand-value" data-testid="top-hand-category">
                    {(playerEquity as any)?.top_hand_category || 'TBD'}
                  </td>
                  <td>{renderValue((playerEquity as any)?.top_estimated)}</td>
                  <td>{renderValue((playerEquity as any)?.top_actual)}</td>
                </tr>
                <tr data-testid="bottom-board-row">
                  <td className="board-label">Bottom</td>
                  <td className="hand-value" data-testid="bottom-hand-category">
                    {(playerEquity as any)?.bottom_hand_category || 'TBD'}
                  </td>
                  <td>
                    {renderValue((playerEquity as any)?.bottom_estimated)}
                  </td>
                  <td>{renderValue((playerEquity as any)?.bottom_actual)}</td>
                </tr>
              </tbody>
            </table>

            {/* Outcome Probabilities Table */}
            {playerEquity && (
              <table className="equity-table outcome-table">
                <thead>
                  <tr>
                    <th colSpan={2}>Outcome Probabilities</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td className="outcome-label">Split Top</td>
                    <td className="outcome-value">
                      {renderValue(playerEquity.split_top)}
                    </td>
                  </tr>
                  <tr>
                    <td className="outcome-label">Split Bottom</td>
                    <td className="outcome-value">
                      {renderValue(playerEquity.split_bottom)}
                    </td>
                  </tr>
                  <tr>
                    <td className="outcome-label">Scoop Both</td>
                    <td className="outcome-value">
                      {renderValue(playerEquity.scoop_both_boards)}
                    </td>
                  </tr>
                  <tr>
                    <td className="outcome-label">Lose Both</td>
                    <td className="outcome-value">
                      {renderValue(playerEquity.chop_both_boards)}
                    </td>
                  </tr>
                </tbody>
              </table>
            )}
          </>
        )}
      </div>
    );
  }
);

EquitySection.displayName = 'EquitySection';

export default EquitySection;
