import React from 'react';
import './EmptyStateBanner.scss';

type EmptyStateBannerProps = {
  players: { cards?: string[] }[];
};

const EmptyStateBanner: React.FC<EmptyStateBannerProps> = ({ players }) => {
  if (players.some(p => (p.cards || []).length > 0)) {
    return null;
  }

  return null;
};

export default EmptyStateBanner;
