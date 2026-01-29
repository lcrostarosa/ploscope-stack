import { useEffect, useRef, useCallback } from 'react';

import type { PerfOptions } from '../types/PerformanceTypes';
import { logDebug, logInfo, logWarn } from '../utils/logger';
import performanceMonitor from '../utils/performance';

/**
 * Hook for monitoring component performance and render times
 */
export const usePerformanceMonitoring = (
  componentName: string,
  options: PerfOptions = {}
) => {
  const renderCount = useRef(0);
  const lastRenderTime = useRef(0);
  const { trackRenders = true, trackProps = false, threshold = 16 } = options;
  const idleThreshold = Math.max(threshold * 100, 5000); // treat very long gaps as idle, not slow render

  // Track component mount time
  useEffect(() => {
    const mountTime = performance.now();
    logDebug(
      `${componentName}: Component mounted in ${mountTime.toFixed(2)}ms`
    );

    // Track bundle loading performance
    if (window.performance && window.performance.getEntriesByType) {
      const navigationEntries =
        window.performance.getEntriesByType('navigation');
      if (navigationEntries.length > 0) {
        const navEntry: any = navigationEntries[0] as any;
        logInfo(
          `${componentName}: Page load time: ${navEntry.loadEventEnd - navEntry.loadEventStart}ms`
        );
      }
    }

    return () => {
      const unmountTime = performance.now();
      logDebug(
        `${componentName}: Component unmounted after ${(unmountTime - mountTime).toFixed(2)}ms`
      );
    };
  }, [componentName]);

  // Track render performance
  const trackRender = useCallback(() => {
    if (!trackRenders) return;

    const currentTime = performance.now();
    const prevTime = lastRenderTime.current;

    // First measurement: initialize baseline, do not count/log
    if (prevTime === 0) {
      lastRenderTime.current = currentTime;
      return;
    }

    const timeSinceLastRender = currentTime - prevTime;

    // Consider very long gaps as idle (navigation, background tab), not a slow render
    if (timeSinceLastRender > idleThreshold) {
      logDebug(
        `${componentName}: Long idle gap detected - ${timeSinceLastRender.toFixed(2)}ms; not treating as slow render`
      );
    } else if (timeSinceLastRender > threshold) {
      // Increment before logging so the counter matches the message
      renderCount.current += 1;
      // Do not warn on the first counted render after baseline initialization
      if (renderCount.current > 1) {
        logWarn(
          `${componentName}: Slow render detected - ${timeSinceLastRender.toFixed(2)}ms (render #${renderCount.current})`
        );
      }
    } else {
      renderCount.current += 1;
      logDebug(
        `${componentName}: Render #${renderCount.current} in ${timeSinceLastRender.toFixed(2)}ms`
      );
    }

    lastRenderTime.current = currentTime;
  }, [componentName, trackRenders, threshold, idleThreshold]);

  // Track prop changes
  const trackPropsChanges = useCallback(
    (props: Record<string, unknown>) => {
      if (!trackProps) return;

      logDebug(`${componentName}: Props changed`, props);
    },
    [componentName, trackProps]
  );

  return {
    trackRender,
    trackPropsChanges,
    renderCount: renderCount.current,
  };
};

/**
 * Hook for monitoring bundle loading performance
 */
export const useBundleMonitoring = () => {
  useEffect(() => {
    // Monitor initial bundle load
    const loadStart = performance.now();

    window.addEventListener('load', () => {
      const loadEnd = performance.now();
      const loadTime = loadEnd - loadStart;

      logInfo(`Bundle load time: ${loadTime.toFixed(2)}ms`);

      // Report to performance monitor
      performanceMonitor.reportMetric({
        label: 'bundle_load',
        category: 'bundle',
        duration: loadTime,
        startTime: 0,
        endTime: loadTime,
        id: 'bundle_load_0',
      });
    });

    // Monitor chunk loading
    if ((window as any).webpackChunkload) {
      const originalChunkLoad = (window as any).webpackChunkload;
      (window as any).webpackChunkload = function (chunkId: any) {
        const chunkStart = performance.now();
        return originalChunkLoad(chunkId).then(() => {
          const chunkEnd = performance.now();
          const chunkTime = chunkEnd - chunkStart;

          logDebug(`Chunk ${chunkId} loaded in ${chunkTime.toFixed(2)}ms`);

          performanceMonitor.reportMetric({
            label: `chunk_${chunkId}`,
            category: 'bundle',
            duration: chunkTime,
            startTime: 0,
            endTime: chunkTime,
            id: `chunk_${chunkId}_0`,
          });
        });
      };
    }
  }, []);
};

/**
 * Hook for monitoring React component re-renders
 */
export const useRenderMonitoring = (
  componentName: string,
  props: Record<string, unknown>
) => {
  const prevProps = useRef(props);
  const renderCount = useRef(0);

  useEffect(() => {
    renderCount.current += 1;

    // Check for unnecessary re-renders
    const changedProps = Object.keys(props).filter(key => {
      return prevProps.current[key] !== props[key];
    });

    if (changedProps.length > 0) {
      logDebug(
        `${componentName}: Re-render #${renderCount.current} due to props: ${changedProps.join(', ')}`
      );
    } else {
      logWarn(
        `${componentName}: Unnecessary re-render #${renderCount.current} - no prop changes`
      );
    }

    prevProps.current = props;
  });

  return renderCount.current;
};
