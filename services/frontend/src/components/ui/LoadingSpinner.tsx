import React, { HTMLAttributes } from 'react';

import { OrbitProgress } from 'react-loading-indicators';

import type { LoadingSpinnerProps } from '../../types/UITypes';
import './LoadingSpinner.scss';

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'medium',
  text = '',
  textColor = '',
  color = '#425742',
  className = '',
  ...props
}) => {
  return (
    <div className={`loading-spinner-container ${className}`} {...props}>
      <OrbitProgress
        color={color}
        size={size as any}
        text={text}
        textColor={textColor}
      />
    </div>
  );
};

export default LoadingSpinner;
