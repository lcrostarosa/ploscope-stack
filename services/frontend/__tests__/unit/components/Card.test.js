import React from 'react';

import { render, act } from '@testing-library/react';

import { Card } from '../../../components/ui';

jest.useFakeTimers();

describe('Card Component - Dealing Animation', () => {
  it('applies and then removes the dealing animation class', () => {
    const { container } = render(<Card card="As" />);
    const cardElement = container.querySelector('.card');

    // Animation class should be present immediately after render
    expect(cardElement).toHaveClass('deal-animation');

    // Fast-forward timers to let the animation finish (400ms in component)
    act(() => {
      jest.advanceTimersByTime(500);
    });

    // The class should be removed after the timeout
    expect(cardElement).not.toHaveClass('deal-animation');
  });
});
