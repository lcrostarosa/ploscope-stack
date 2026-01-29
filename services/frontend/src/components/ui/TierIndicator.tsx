import React from 'react';

import './TierIndicator.scss';
import { useNavigate } from 'react-router-dom';

import type {
  TierIndicatorProps,
  SubscriptionTier,
  TierInfo,
} from '../../types/UITypes';

const TierIndicator: React.FC<TierIndicatorProps> = ({
  user,
  className = '',
  hideUpgradeButton = false,
}) => {
  const navigate = useNavigate();

  const getTierInfo = (tier: SubscriptionTier): TierInfo => {
    switch (tier) {
      case 'free':
        return {
          name: 'Free',
          color: 'green',
          icon: '🆓',
          canUpgrade: true,
        };
      case 'pro':
        return {
          name: 'Pro',
          color: 'blue',
          icon: '💎',
          canUpgrade: true,
        };
      case 'elite':
        return {
          name: 'Elite',
          color: 'purple',
          icon: '👑',
          canUpgrade: false,
        };
      default:
        return {
          name: 'Free',
          color: 'green',
          icon: '🆓',
          canUpgrade: true,
        };
    }
  };

  const handleUpgrade = () => {
    navigate('/pricing');
  };

  if (!user) return null;

  const tierInfo = getTierInfo(user.subscription_tier ?? 'free');

  return (
    <div className={`tier-indicator ${className}`}>
      <div className={`tier-badge ${tierInfo.color}`}>
        <span className="tier-icon">{tierInfo.icon}</span>
        <span className="tier-name">{tierInfo.name}</span>
      </div>
      {tierInfo.canUpgrade && !hideUpgradeButton && (
        <button
          className="upgrade-button"
          onClick={handleUpgrade}
          title="Upgrade your subscription"
        >
          ⬆️ Upgrade
        </button>
      )}
    </div>
  );
};

export default TierIndicator;
