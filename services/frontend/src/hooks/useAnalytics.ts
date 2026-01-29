import { useEffect, useCallback, useRef, useMemo } from 'react';

import { EquityParameters } from '../types/Equity';
import {
  trackPageView,
  trackEvent,
  trackEquityCalculation,
  trackSpotAnalysis,
  trackFeatureUsage,
  trackUserAction,
  trackError,
  trackPerformance,
  trackConversion,
  identifyUser,
  setUserProperties,
  getFeatureFlag,
  isFeatureEnabled,
  getSessionInfo,
  trackSignup,
  trackLogin,
  trackAppUsage,
  trackPageViewEnhanced,
  trackUserEngagement,
  trackFeatureAccess,
  trackMetaLead,
  trackMetaAddToCart,
  trackMetaInitiateCheckout,
} from '../utils/analytics';

/**
 * Custom React hook for analytics integration
 * Provides easy-to-use analytics methods with React-specific optimizations
 */
export const useAnalytics = () => {
  // Sessions are now managed centrally to avoid duplicates

  // Memoized tracking functions to prevent unnecessary re-renders
  const analytics = {
    // Page tracking
    trackPage: useCallback((path: string, title: string) => {
      trackPageView(path, title);
    }, []),

    // Event tracking
    track: useCallback(
      (eventName: string, properties: Record<string, unknown> = {}) => {
        trackEvent(eventName, properties);
      },
      []
    ),

    // User identification
    identify: useCallback(
      (userId: string, properties: Record<string, unknown> = {}) => {
        // The underlying identifyUser doesn't accept parameters for privacy compliance
        identifyUser();
        if (properties && Object.keys(properties).length > 0) {
          setUserProperties(properties);
        }
      },
      []
    ),

    // User properties
    setProperties: useCallback((properties: Record<string, unknown>) => {
      setUserProperties(properties);
    }, []),

    // PLO Analysis specific tracking
    trackEquity: useCallback(
      (
        params: Record<string, unknown>,
        results: unknown[] | null | undefined,
        duration: number,
        success: boolean = true
      ) => {
        trackEquityCalculation(
          params as EquityParameters,
          results,
          duration,
          success
        );
      },
      []
    ),

    trackSpot: useCallback(
      (spotData: Record<string, unknown>, success: boolean = true) => {
        trackSpotAnalysis(spotData, success);
      },
      []
    ),

    trackFeature: useCallback(
      (
        featureName: string,
        category: string,
        duration: number | null = null,
        interactions: number = 1
      ) => {
        trackFeatureUsage(featureName, category, duration, interactions);
      },
      []
    ),

    trackAction: useCallback(
      (action: string, context: Record<string, unknown> = {}) => {
        trackUserAction(action, context);
      },
      []
    ),

    trackError: useCallback(
      (
        errorType: string,
        errorMessage: string,
        context: Record<string, unknown> = {}
      ) => {
        trackError(errorType, errorMessage, context);
      },
      []
    ),

    trackPerformance: useCallback(
      (
        metricName: string,
        value: number,
        context: Record<string, unknown> = {}
      ) => {
        trackPerformance(metricName, value, context);
      },
      []
    ),

    trackConversion: useCallback(
      (
        conversionName: string,
        value: number | null = null,
        context: Record<string, unknown> = {}
      ) => {
        trackConversion(conversionName, value, context);
      },
      []
    ),

    // Enhanced Google Analytics 4 tracking
    trackSignup: useCallback(
      (signupMethod: string, userProperties: Record<string, unknown> = {}) => {
        trackSignup(signupMethod, userProperties);
      },
      []
    ),

    trackLogin: useCallback(
      (loginMethod: string, userProperties: Record<string, unknown> = {}) => {
        trackLogin(loginMethod, userProperties);
      },
      []
    ),

    trackAppUsage: useCallback(
      (
        featureName: string,
        action: string,
        duration: number | null = null,
        context: Record<string, unknown> = {}
      ) => {
        trackAppUsage(featureName, action, duration, context);
      },
      []
    ),

    trackPageViewEnhanced: useCallback(
      (
        pagePath: string,
        pageTitle: string,
        customParameters: Record<string, unknown> = {}
      ) => {
        trackPageViewEnhanced(pagePath, pageTitle, customParameters);
      },
      []
    ),

    trackUserEngagement: useCallback(
      (
        engagementType: string,
        duration: number | null = null,
        context: Record<string, unknown> = {}
      ) => {
        trackUserEngagement(engagementType, duration, context);
      },
      []
    ),

    trackFeatureAccess: useCallback(
      (
        featureName: string,
        accessType: string = 'view',
        context: Record<string, unknown> = {}
      ) => {
        trackFeatureAccess(featureName, accessType, context);
      },
      []
    ),

    // Meta-specific tracking
    trackMetaLead: useCallback(
      (
        leadType: string,
        value: number | null = null,
        context: Record<string, unknown> = {}
      ) => {
        trackMetaLead(leadType, value, context);
      },
      []
    ),

    trackMetaAddToCart: useCallback(
      (
        productName: string,
        value: number | null = null,
        context: Record<string, unknown> = {}
      ) => {
        trackMetaAddToCart(productName, value, context);
      },
      []
    ),

    trackMetaInitiateCheckout: useCallback(
      (value: number | null = null, context: Record<string, unknown> = {}) => {
        trackMetaInitiateCheckout(value, context);
      },
      []
    ),

    // Feature flags
    getFlag: useCallback((flagKey: string) => {
      return getFeatureFlag(flagKey);
    }, []),

    isEnabled: useCallback((flagKey: string) => {
      return isFeatureEnabled(flagKey);
    }, []),

    // Session info
    getSession: useCallback(() => {
      return getSessionInfo();
    }, []),
  };

  return analytics;
};

/**
 * Hook for automatic page view tracking
 * Use this in components that represent pages/routes
 */
export const usePageTracking = (
  pagePath: string,
  pageTitle: string,
  dependencies: unknown[] = []
) => {
  const { trackPage } = useAnalytics();

  useEffect(() => {
    trackPage(pagePath, pageTitle);
  }, [trackPage, pagePath, pageTitle, dependencies]);
};

/**
 * Hook for tracking component mount/unmount and usage time
 */
export const useComponentTracking = (
  componentName: string,
  category: string = 'component'
) => {
  const { trackFeature } = useAnalytics();
  const mountTime = useRef<number | null>(null);

  useEffect(() => {
    mountTime.current = performance.now();

    // Track component mount
    trackFeature(componentName, category, null, 1);

    return () => {
      // Track component usage duration on unmount
      if (mountTime.current) {
        const duration = (performance.now() - mountTime.current) / 1000;
        trackFeature(`${componentName}_duration`, category, duration, 1);
      }
    };
  }, [componentName, category, trackFeature]);
};

/**
 * Hook for tracking user interactions with debouncing
 */
export const useInteractionTracking = (debounceMs: number = 300) => {
  const { trackAction } = useAnalytics();
  const timeoutRef = useRef<number | null>(null);

  const trackInteraction = useCallback(
    (action: string, context: Record<string, unknown> = {}) => {
      // Clear previous timeout
      if (timeoutRef.current) {
        window.clearTimeout(timeoutRef.current);
      }

      // Debounce the tracking call
      timeoutRef.current = window.setTimeout(() => {
        trackAction(action, context);
      }, debounceMs);
    },
    [trackAction, debounceMs]
  );

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (timeoutRef.current) {
        window.clearTimeout(timeoutRef.current);
      }
    };
  }, []);

  return trackInteraction;
};

/**
 * Hook for tracking form interactions
 */
export const useFormTracking = (formName: string) => {
  const { track } = useAnalytics();

  const trackFormStart = useCallback(() => {
    track('form_start', {
      category: 'form',
      form_name: formName,
    });
  }, [track, formName]);

  const trackFormSubmit = useCallback(
    (success: boolean = true, errors: string[] = []) => {
      track('form_submit', {
        category: 'form',
        form_name: formName,
        success: success,
        error_count: errors.length,
        errors: errors.join(', '),
      });
    },
    [track, formName]
  );

  const trackFieldChange = useCallback(
    (fieldName: string, value: unknown) => {
      track('form_field_change', {
        category: 'form',
        form_name: formName,
        field_name: fieldName,
        has_value: !!value,
      });
    },
    [track, formName]
  );

  return {
    trackFormStart,
    trackFormSubmit,
    trackFieldChange,
  };
};

/**
 * Hook for tracking performance metrics
 */
export const usePerformanceTracking = () => {
  const { trackPerformance } = useAnalytics();

  const trackLoadTime = useCallback(
    (metricName: string, startTime: number) => {
      const loadTime = (performance.now() - startTime) / 1000;
      trackPerformance(metricName, loadTime, {
        metric_type: 'load_time',
      });
    },
    [trackPerformance]
  );

  const trackApiCall = useCallback(
    async <T>(apiName: string, apiCall: () => Promise<T>): Promise<T> => {
      const startTime = performance.now();

      try {
        const result = await apiCall();
        const duration = (performance.now() - startTime) / 1000;

        trackPerformance(`api_${apiName}`, duration, {
          metric_type: 'api_call',
          success: true,
        });

        return result;
      } catch (error) {
        const duration = (performance.now() - startTime) / 1000;

        trackPerformance(`api_${apiName}`, duration, {
          metric_type: 'api_call',
          success: false,
          error: error instanceof Error ? error.message : String(error),
        });

        throw error;
      }
    },
    [trackPerformance]
  );

  return {
    trackLoadTime,
    trackApiCall,
  };
};

/**
 * Hook for A/B testing with feature flags
 */
export const useFeatureFlag = (
  flagKey: string,
  defaultValue: unknown = null
) => {
  const { getFlag, track } = useAnalytics();
  const flagValue = getFlag(flagKey) || defaultValue;
  const exposureTracked = useRef<boolean>(false);

  // Track feature flag exposure
  useEffect(() => {
    if (flagValue !== null && !exposureTracked.current) {
      track('feature_flag_exposure', {
        category: 'experiment',
        flag_key: flagKey,
        flag_value: flagValue,
      });
      exposureTracked.current = true;
    }
  }, [flagKey, flagValue, track]);

  return flagValue;
};

/**
 * Hook for error boundary integration
 */
export const useErrorTracking = () => {
  const { trackError } = useAnalytics();

  const trackComponentError = useCallback(
    (error: Error, errorInfo: { componentStack: string }) => {
      trackError('react_error', error.message, {
        component_stack: errorInfo.componentStack,
        error_stack: error.stack,
        error_name: error.name,
      });
    },
    [trackError]
  );

  const trackAsyncError = useCallback(
    (error: Error, context: Record<string, unknown> = {}) => {
      trackError('async_error', error.message, {
        error_stack: error.stack,
        error_name: error.name,
        ...context,
      });
    },
    [trackError]
  );

  return {
    trackComponentError,
    trackAsyncError,
  };
};

/**
 * Hook for tracking user engagement
 */
export const useEngagementTracking = () => {
  const { track } = useAnalytics();
  const engagementStartTime = useRef<number>(performance.now());
  const isEngaged = useRef<boolean>(true);

  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // User left the page
        if (isEngaged.current) {
          const engagementTime =
            (performance.now() - engagementStartTime.current) / 1000;
          track('engagement_end', {
            category: 'engagement',
            duration: engagementTime,
          });
          isEngaged.current = false;
        }
      } else {
        // User returned to the page
        if (!isEngaged.current) {
          track('engagement_start', {
            category: 'engagement',
          });
          engagementStartTime.current = performance.now();
          isEngaged.current = true;
        }
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);

      // Track final engagement time
      if (isEngaged.current) {
        const engagementTime =
          (performance.now() - engagementStartTime.current) / 1000;
        track('engagement_end', {
          category: 'engagement',
          duration: engagementTime,
        });
      }
    };
  }, [track]);

  const trackEngagementAction = useCallback(
    (action: string, context: Record<string, unknown> = {}) => {
      track('engagement_action', {
        category: 'engagement',
        action: action,
        ...context,
      });
    },
    [track]
  );

  return {
    trackEngagementAction,
  };
};

/**
 * Hook for enhanced page tracking with Google Analytics
 * Use this in components that represent pages/routes
 */
export const useEnhancedPageTracking = (
  pagePath: string,
  pageTitle: string,
  customParameters: Record<string, unknown> = {},
  dependencies: unknown[] = []
) => {
  const { trackPageViewEnhanced } = useAnalytics();

  // Stable, deep key for customParameters to avoid unnecessary re-runs on new object refs
  const stableStringify = useCallback((value: unknown): string => {
    if (value === null || typeof value !== 'object') {
      return JSON.stringify(value);
    }
    if (Array.isArray(value)) {
      return `[${value.map(stableStringify).join(',')}]`;
    }
    const entries = Object.entries(value as Record<string, unknown>).sort(
      ([a], [b]) => a.localeCompare(b)
    );
    return `{${entries.map(([k, v]) => `${JSON.stringify(k)}:${stableStringify(v)}`).join(',')}}`;
  }, []);

  const customParamsKey = useMemo(
    () => stableStringify(customParameters),
    [stableStringify, customParameters]
  );

  useEffect(() => {
    trackPageViewEnhanced(pagePath, pageTitle, customParameters);
    // Only re-run when path/title/custom params CONTENT actually change
    // Spread user-provided dependencies to respect caller intent without causing referential churn issues
  }, [
    trackPageViewEnhanced,
    pagePath,
    pageTitle,
    customParamsKey,
    customParameters,
    // eslint-disable-next-line react-hooks/exhaustive-deps
    ...dependencies,
  ]);
};

/**
 * Hook for tracking app feature usage
 */
export const useAppUsageTracking = (featureName: string) => {
  const { trackAppUsage, trackFeatureAccess } = useAnalytics();
  const startTime = useRef<number | null>(null);

  const startUsage = useCallback(() => {
    startTime.current = performance.now();
    trackFeatureAccess(featureName, 'view');
  }, [trackFeatureAccess, featureName]);

  const trackInteraction = useCallback(
    (action: string, context: Record<string, unknown> = {}) => {
      trackAppUsage(featureName, action, null, context);
    },
    [trackAppUsage, featureName]
  );

  const endUsage = useCallback(
    (context: Record<string, unknown> = {}) => {
      if (startTime.current) {
        const duration = (performance.now() - startTime.current) / 1000;
        trackAppUsage(featureName, 'session_end', duration, context);
        trackFeatureAccess(featureName, 'complete', { duration, ...context });
        startTime.current = null;
      }
    },
    [trackAppUsage, trackFeatureAccess, featureName]
  );

  // Auto-start tracking on mount
  useEffect(() => {
    startUsage();
    return () => {
      endUsage();
    };
  }, [startUsage, endUsage]);

  return {
    startUsage,
    trackInteraction,
    endUsage,
  };
};

/**
 * Hook for tracking user engagement with time-based events
 */
export const useEngagementTimeTracking = () => {
  const { trackUserEngagement } = useAnalytics();
  const engagementStartTime = useRef<number>(performance.now());
  const isEngaged = useRef<boolean>(true);
  const engagementIntervals = useRef<number[]>([]);

  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // User left the page
        if (isEngaged.current) {
          const engagementTime =
            (performance.now() - engagementStartTime.current) / 1000;
          trackUserEngagement('page_leave', engagementTime);
          isEngaged.current = false;
        }
      } else {
        // User returned to the page
        if (!isEngaged.current) {
          trackUserEngagement('page_return');
          engagementStartTime.current = performance.now();
          isEngaged.current = true;
        }
      }
    };

    const handleBeforeUnload = () => {
      if (isEngaged.current) {
        const engagementTime =
          (performance.now() - engagementStartTime.current) / 1000;
        trackUserEngagement('session_end', engagementTime);
      }
    };

    // Track engagement at regular intervals (reduce cadence to lower server load)
    const intervalId = window.setInterval(() => {
      if (isEngaged.current) {
        const engagementTime =
          (performance.now() - engagementStartTime.current) / 1000;
        if (engagementTime >= 60) {
          // Track every 60 seconds
          trackUserEngagement('engagement_interval', engagementTime);
          engagementIntervals.current.push(engagementTime);
        }
      }
    }, 60000);

    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.clearInterval(intervalId);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('beforeunload', handleBeforeUnload);

      // Track final engagement time
      if (isEngaged.current) {
        const engagementTime =
          (performance.now() - engagementStartTime.current) / 1000;
        trackUserEngagement('session_end', engagementTime);
      }
    };
  }, [trackUserEngagement]);

  const trackEngagementAction = useCallback(
    (action: string, context: Record<string, unknown> = {}) => {
      trackUserEngagement('user_action', null, { action, ...context });
    },
    [trackUserEngagement]
  );

  return {
    trackEngagementAction,
  };
};

export default useAnalytics;
