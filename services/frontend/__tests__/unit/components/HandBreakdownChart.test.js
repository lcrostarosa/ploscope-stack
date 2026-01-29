import React from 'react';

import { render, screen } from '@testing-library/react';

import HandBreakdownChart from '../../../components/ui/HandBreakdownChart';

describe('HandBreakdownChart', () => {
  const mockBreakdown = {
    'Full House': { wins: 15, ties: 2, losses: 3, total: 20 },
    Flush: { wins: 8, ties: 1, losses: 11, total: 20 },
    'Two Pair': { wins: 5, ties: 0, losses: 15, total: 20 },
  };

  describe('Hero Context Hover Text', () => {
    test('should display hero-specific hover text for win segments', () => {
      render(
        <HandBreakdownChart
          breakdown={mockBreakdown}
          title="Hero Hand Breakdown"
          context="hero"
        />
      );

      // Check that the component renders
      expect(screen.getByText('Hero Hand Breakdown')).toBeInTheDocument();
      expect(screen.getByText('Full House')).toBeInTheDocument();
      expect(screen.getByText('Flush')).toBeInTheDocument();
      expect(screen.getByText('Two Pair')).toBeInTheDocument();

      // Check that win segments have hero-specific hover text
      const winSegments = document.querySelectorAll('.win-segment');
      expect(winSegments.length).toBeGreaterThan(0);

      // Verify the first win segment has hero hover text
      const firstWinSegment = winSegments[0];
      expect(firstWinSegment).toHaveAttribute('title');
      const title = firstWinSegment.getAttribute('title');
      expect(title).toContain('You win');
      expect(title).toContain('times with');
    });
  });

  describe('Opponents Context Hover Text', () => {
    test('should display opponent-specific hover text for win segments', () => {
      render(
        <HandBreakdownChart
          breakdown={mockBreakdown}
          title="Opponents Hand Breakdown"
          context="opponents"
        />
      );

      // Check that the component renders
      expect(screen.getByText('Opponents Hand Breakdown')).toBeInTheDocument();
      expect(screen.getByText('Full House')).toBeInTheDocument();
      expect(screen.getByText('Flush')).toBeInTheDocument();
      expect(screen.getByText('Two Pair')).toBeInTheDocument();

      // Check that win segments have opponent-specific hover text
      const winSegments = document.querySelectorAll('.win-segment');
      expect(winSegments.length).toBeGreaterThan(0);

      // Verify the first win segment has opponent hover text
      const firstWinSegment = winSegments[0];
      expect(firstWinSegment).toHaveAttribute('title');
      const title = firstWinSegment.getAttribute('title');
      expect(title).toContain('Opponents win');
      expect(title).toContain('times with');
    });
  });

  describe('Default Context', () => {
    test('should default to hero context when no context is provided', () => {
      render(
        <HandBreakdownChart
          breakdown={mockBreakdown}
          title="Default Hand Breakdown"
        />
      );

      // Check that win segments default to hero hover text
      const winSegments = document.querySelectorAll('.win-segment');
      expect(winSegments.length).toBeGreaterThan(0);

      const firstWinSegment = winSegments[0];
      expect(firstWinSegment).toHaveAttribute('title');
      const title = firstWinSegment.getAttribute('title');
      expect(title).toContain('You win');
    });
  });

  describe('Empty Breakdown', () => {
    test('should handle empty breakdown gracefully', () => {
      render(<HandBreakdownChart breakdown={{}} title="Empty Breakdown" />);

      expect(screen.getByText('Empty Breakdown')).toBeInTheDocument();
      expect(
        screen.getByText('No hand breakdown data available')
      ).toBeInTheDocument();
    });

    test('should handle null breakdown gracefully', () => {
      render(<HandBreakdownChart breakdown={null} title="Null Breakdown" />);

      expect(screen.getByText('Null Breakdown')).toBeInTheDocument();
      expect(
        screen.getByText('No hand breakdown data available')
      ).toBeInTheDocument();
    });
  });

  describe('Percentage Calculations', () => {
    test('should calculate percentages correctly', () => {
      render(
        <HandBreakdownChart breakdown={mockBreakdown} title="Percentage Test" />
      );

      // Check that all expected percentages are present
      const allPercentages = screen.getAllByText(/\d+\.\d+%/);
      const percentageTexts = allPercentages.map(el => el.textContent);

      // Should have win percentages for all three hands
      expect(percentageTexts).toContain('75.0%');
      expect(percentageTexts).toContain('40.0%');
      expect(percentageTexts).toContain('25.0%');

      // Should also have tie and loss percentages
      expect(percentageTexts).toContain('10.0%');
      expect(percentageTexts).toContain('15.0%');
      expect(percentageTexts).toContain('5.0%');
      expect(percentageTexts).toContain('55.0%');
      expect(percentageTexts).toContain('0.0%');
    });
  });
});
