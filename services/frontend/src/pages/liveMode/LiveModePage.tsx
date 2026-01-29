import React from 'react';

import { useOutletContext } from 'react-router-dom';

import LiveMode from './LiveMode';

export const LiveModePage: React.FC = () => {
  const { gameState, handleResetGameConfig } =
    useOutletContext<any>();

  return (
    <LiveMode
      gameState={gameState}
      handleResetGameConfig={handleResetGameConfig}
    />
  );
};

export default LiveModePage;
