import React, { useState, useEffect, useRef, useCallback } from 'react';

import { useAuth } from '../../contexts/AuthContext';

type OnboardingCompletePayload = { skipped: boolean; completedStep: number };
const OnboardingTour: React.FC<{
  onComplete?: (payload: OnboardingCompletePayload) => void;
}> = ({ onComplete }) => {
  const { user } = useAuth();
  const [currentStep, setCurrentStep] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const [isSkipped, setIsSkipped] = useState(false);
  const overlayRef = useRef(null);

  const handleComplete = useCallback(() => {
    if (user) {
      localStorage.setItem(`onboarding_completed_${user.id}`, 'true');
      localStorage.setItem(
        `onboarding_completed_date_${user.id}`,
        new Date().toISOString()
      );
    }
    setIsVisible(false);
    if (onComplete) {
      onComplete({ skipped: isSkipped, completedStep: currentStep });
    }
  }, [user, isSkipped, currentStep, onComplete]);

  // Check if user needs onboarding
  useEffect(() => {
    if (user && !localStorage.getItem(`onboarding_completed_${user.id}`)) {
      // Start tour after a short delay
      const timer = setTimeout(() => {
        setIsVisible(true);

        // Auto-hide tour after 10 seconds if user doesn't interact
        const autoHideTimer = setTimeout(() => {
          if (isVisible) {
            handleComplete();
          }
        }, 10000);

        return () => clearTimeout(autoHideTimer);
      }, 1500);
      return () => clearTimeout(timer);
    }
  }, [user, handleComplete, isVisible]);

  // Tour steps configuration
  const tourSteps = [
    {
      id: 'welcome',
      title: 'Welcome to PLOScope! 🎉',
      content: `Hi ${user?.first_name || 'there'}! Let's take a quick tour to get you started with our powerful PLO analysis tools.`,
      target: null,
      position: 'center',
      action: 'next',
    },
    {
      id: 'navigation',
      title: 'Navigation Menu',
      content:
        'Use these tabs to switch between different analysis modes. Each mode is designed for specific use cases.',
      target: '.app-navigation',
      position: 'bottom',
      action: 'next',
    },
    {
      id: 'spotMode-mode',
      title: 'Spot Mode 🎯',
      content:
        'Analyze specific poker situations. Perfect for studying hand ranges and equity calculations.',
      target: '[data-tour="spotMode-mode"]',
      position: 'bottom',
      action: 'next',
    },
    {
      id: 'profile',
      title: 'Your Profile & Settings ⚙️',
      content:
        'Access your account settings, subscription details, and customize your experience.',
      target: '.user-button',
      position: 'bottom-left',
      action: 'next',
    },
    {
      id: 'getting-started',
      title: 'Ready to Get Started! 🚀',
      content:
        "You're all set! We recommend starting with Spot Mode to analyze your first hand. Need help? Check our documentation.",
      target: null,
      position: 'center',
      action: 'finish',
    },
  ];

  const currentStepData = tourSteps[currentStep];

  const handleNext = () => {
    if (currentStep < tourSteps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      handleComplete();
    }
  };

  const handlePrevious = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSkip = () => {
    setIsSkipped(true);
    handleComplete();
  };

  const getTargetElement = (selector: string | null) => {
    if (!selector) return null;
    return document.querySelector(selector);
  };

  const getTooltipPosition = (target: Element | null, position: string) => {
    if (!target)
      return { top: '50%', left: '50%', transform: 'translate(-50%, -50%)' };

    const rect = target.getBoundingClientRect();
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const scrollLeft =
      window.pageXOffset || document.documentElement.scrollLeft;

    switch (position) {
      case 'top':
        return {
          top: rect.top + scrollTop - 10,
          left: rect.left + scrollLeft + rect.width / 2,
          transform: 'translate(-50%, -100%)',
        };
      case 'bottom':
        return {
          top: rect.bottom + scrollTop + 10,
          left: rect.left + scrollLeft + rect.width / 2,
          transform: 'translate(-50%, 0)',
        };
      case 'left':
        return {
          top: rect.top + scrollTop + rect.height / 2,
          left: rect.left + scrollLeft - 10,
          transform: 'translate(-100%, -50%)',
        };
      case 'right':
        return {
          top: rect.top + scrollTop + rect.height / 2,
          left: rect.right + scrollLeft + 10,
          transform: 'translate(0, -50%)',
        };
      case 'bottom-left':
        return {
          top: rect.bottom + scrollTop + 10,
          left: rect.left + scrollLeft,
          transform: 'translate(0, 0)',
        };
      case 'center':
      default:
        return {
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
        };
    }
  };

  const highlightTarget = (target: Element | null) => {
    if (!target) return {};

    const rect = target.getBoundingClientRect();
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const scrollLeft =
      window.pageXOffset || document.documentElement.scrollLeft;

    return {
      top: rect.top + scrollTop - 4,
      left: rect.left + scrollLeft - 4,
      width: rect.width + 8,
      height: rect.height + 8,
    };
  };

  if (!isVisible || !currentStepData) return null;

  const targetElement = getTargetElement(currentStepData.target);
  const tooltipStyle = getTooltipPosition(
    targetElement,
    currentStepData.position
  );
  const highlightStyle = targetElement ? highlightTarget(targetElement) : {};

  return (
    <div
      className="onboarding-overlay dark"
      ref={overlayRef}
      onClick={e => e.target === overlayRef.current && handleSkip()}
    >
      {/* Background overlay */}
      <div className="onboarding-backdrop" />

      {/* Highlight target element */}
      {targetElement && (
        <div
          className="onboarding-highlight"
          style={{
            position: 'absolute',
            ...highlightStyle,
            zIndex: 10001,
          }}
        />
      )}

      {/* Tooltip */}
      <div
        className="onboarding-tooltip"
        style={{
          position: 'absolute',
          ...tooltipStyle,
          zIndex: 10002,
        }}
      >
        <div className="tooltip-header">
          <h3>{currentStepData.title}</h3>
          <div className="step-indicator">
            {currentStep + 1} of {tourSteps.length}
          </div>
        </div>

        <div className="tooltip-content">
          <p>{currentStepData.content}</p>
        </div>

        <div className="tooltip-actions">
          <div className="step-dots">
            {tourSteps.map((_, index) => (
              <div
                key={index}
                className={`step-dot ${index === currentStep ? 'active' : ''} ${index < currentStep ? 'completed' : ''}`}
                onClick={() => setCurrentStep(index)}
              />
            ))}
          </div>

          <div className="action-buttons">
            <button className="btn-skip" onClick={handleSkip}>
              Skip Tour
            </button>

            {currentStep > 0 && (
              <button className="btn-previous" onClick={handlePrevious}>
                Previous
              </button>
            )}

            <button className="btn-next" onClick={handleNext}>
              {currentStepData.action === 'finish' ? 'Get Started!' : 'Next'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// Hook to manually trigger onboarding
export const useOnboarding = () => {
  const { user } = useAuth();

  const startOnboarding = () => {
    if (user) {
      localStorage.removeItem(`onboarding_completed_${user.id}`);
      window.location.reload(); // Simple way to restart the tour
    }
  };

  const isOnboardingCompleted = () => {
    if (!user) return false;
    return localStorage.getItem(`onboarding_completed_${user.id}`) === 'true';
  };

  return {
    startOnboarding,
    isOnboardingCompleted,
  };
};

export default OnboardingTour;
