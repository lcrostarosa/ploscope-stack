// New Relic integration removed
import type {
  PerformanceMetric,
  ApiMonitorReturn,
  InteractionMonitorReturn,
  SimulationMonitorReturn,
  PerfOptions,
  PerformanceThresholds,
  PerformanceReport,
} from '../types/PerformanceTypes';

import { logDebug, logWarn } from './logger';

const reportError = () => {};

class PerformanceMonitor {
  private metrics: Map<
    string,
    {
      label: string;
      category: string;
      startTime: number;
      id: string;
      duration?: number;
      endTime?: number;
    }
  >;
  private observers: Map<string, PerformanceObserver>;
  private thresholds: {
    simulation: number;
    api: number;
    render: number;
    interaction: number;
    general: number;
  };
  constructor() {
    this.metrics = new Map();
    this.observers = new Map();
    this.thresholds = {
      simulation: 10000,
      api: 5000,
      render: 100,
      interaction: 300,
      general: 1000,
    };
  }

  // Start timing a metric
  startTiming(
    label: string,
    category:
      | 'general'
      | 'simulation'
      | 'api'
      | 'render'
      | 'interaction' = 'general'
  ) {
    const id = `${category}_${label}_${Date.now()}`;
    this.metrics.set(id, {
      label,
      category,
      startTime: performance.now(),
      id,
    });
    return id;
  }

  // End timing and optionally report
  endTiming(id: string, shouldReport: boolean = true) {
    const metric = this.metrics.get(id);
    if (!metric) return null;

    const endTime = performance.now();
    const duration = endTime - metric.startTime;

    metric.duration = duration;
    metric.endTime = endTime;

    if (shouldReport && metric.duration !== undefined) {
      if (
        metric &&
        typeof metric.duration === 'number' &&
        typeof metric.startTime === 'number' &&
        typeof metric.endTime === 'number' &&
        metric.id
      ) {
        this.reportMetric({
          label: metric.label,
          category: metric.category,
          duration: metric.duration,
          startTime: metric.startTime,
          endTime: metric.endTime,
          id: metric.id,
        });
      }
    }

    this.metrics.delete(id);
    return metric;
  }

  // Report metric to monitoring services
  reportMetric(metric: {
    label: string;
    category: string;
    duration: number;
    startTime: number;
    endTime: number;
    id: string;
    success?: boolean;
    statusCode?: number | null;
    url?: string;
    method?: string;
  }) {
    // Check against thresholds
    const threshold =
      (this.thresholds as Record<string, number>)[metric.category] ||
      this.thresholds.general;
    const isSlowPerformance = metric.duration > threshold;

    // Log performance data
    logDebug(
      `Performance [${metric.category}]: ${metric.label} took ${metric.duration.toFixed(2)}ms`
    );

    // New Relic reporting removed

    // Report slow performance as errors
    if (isSlowPerformance) {
      reportError();
    }

    // Forward to analytics event pipeline
    try {
      const { trackPerformance } = require('./analytics');
      trackPerformance('performance_metric', metric.duration, {
        label: metric.label,
        category: metric.category,
        is_slow: isSlowPerformance,
      });
    } catch (_e) {
      // no-op
    }
  }

  // Monitor API calls
  monitorApiCall(url: string, method: string = 'GET') {
    const timingId = this.startTiming(`${method} ${url}`, 'api');

    return {
      end: (success = true, statusCode = null) => {
        const metric = this.endTiming(timingId, false);
        if (metric && metric.duration !== undefined) {
          if (metric) {
            this.reportMetric({
              label: metric.label,
              category: metric.category,
              duration: metric.duration as number,
              startTime: metric.startTime,
              endTime: metric.endTime as number,
              id: metric.id,
              success,
              statusCode,
              url,
              method,
            });
          }
        }
      },
    };
  }

  // Monitor React component renders
  monitorRender(componentName: string) {
    const timingId = this.startTiming(componentName, 'render');

    return () => {
      this.endTiming(timingId);
    };
  }

  // Monitor user interactions
  monitorInteraction(actionName: string) {
    const timingId = this.startTiming(actionName, 'interaction');

    return {
      end: (success = true, details = {}) => {
        const metric = this.endTiming(timingId, false);
        if (metric) {
          this.reportMetric({
            label: metric.label,
            category: metric.category,
            duration: metric.duration as number,
            startTime: metric.startTime,
            endTime: metric.endTime as number,
            id: metric.id,
            success,
            ...(details as Record<string, unknown>),
          });
        }
      },
    };
  }

  // Monitor simulation performance
  monitorSimulation(
    simulationType: string,
    parameters: Record<string, unknown> = {}
  ) {
    const timingId = this.startTiming(
      `${simulationType}_simulation`,
      'simulation'
    );

    return {
      end: (success = true, results = null) => {
        const metric = this.endTiming(timingId, false);
        if (metric) {
          this.reportMetric({
            label: metric.label,
            category: metric.category,
            duration: metric.duration as number,
            startTime: metric.startTime,
            endTime: metric.endTime as number,
            id: metric.id,
            success,
          });
        }
      },
    };
  }

  // Set up Web Vitals monitoring
  setupWebVitals() {
    if (!window.PerformanceObserver) return;

    // Monitor Largest Contentful Paint (LCP)
    try {
      const lcpObserver = new PerformanceObserver(list => {
        const entries = list.getEntries();
        const lastEntry = entries[entries.length - 1];

        logDebug(`LCP: ${lastEntry.startTime.toFixed(2)}ms`);

        // New Relic reporting removed
      });

      lcpObserver.observe({ entryTypes: ['largest-contentful-paint'] });
      this.observers.set('lcp', lcpObserver);
    } catch (e) {
      logWarn('LCP monitoring failed:', e);
    }

    // Monitor First Input Delay (FID)
    try {
      const fidObserver = new PerformanceObserver(list => {
        const entries = list.getEntries();
        entries.forEach(entry => {
          const e = entry as PerformanceEntry & { processingStart?: number };
          const processingStart = e.processingStart ?? e.startTime;
          logDebug(`FID: ${processingStart - entry.startTime}ms`);

          // New Relic reporting removed
        });
      });

      fidObserver.observe({ entryTypes: ['first-input'] });
      this.observers.set('fid', fidObserver);
    } catch (e) {
      logWarn('FID monitoring failed:', e);
    }

    // Monitor Cumulative Layout Shift (CLS)
    try {
      let clsScore = 0;
      const clsObserver = new PerformanceObserver(list => {
        const entries = list.getEntries();
        entries.forEach(entry => {
          const e = entry as PerformanceEntry & {
            hadRecentInput?: boolean;
            value?: number;
          };
          if (!e.hadRecentInput) {
            clsScore += e.value ?? 0;
          }
        });

        logDebug(`CLS: ${clsScore}`);

        // New Relic reporting removed
      });

      clsObserver.observe({ entryTypes: ['layout-shift'] });
      this.observers.set('cls', clsObserver);
    } catch (e) {
      logWarn('CLS monitoring failed:', e);
    }
  }

  // Memory usage monitoring
  monitorMemoryUsage() {
    if (
      !(window as unknown as { performance?: { memory?: unknown } }).performance
        ?.memory
    )
      return;

    const memory = (
      window as unknown as {
        performance: {
          memory: {
            usedJSHeapSize: number;
            totalJSHeapSize: number;
            jsHeapSizeLimit: number;
          };
        };
      }
    ).performance.memory;
    const memoryUsage = {
      used: memory.usedJSHeapSize,
      total: memory.totalJSHeapSize,
      limit: memory.jsHeapSizeLimit,
      usage_percentage: (memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100,
    };

    logDebug('Memory Usage:', memoryUsage);

    // New Relic reporting removed

    // Warn if memory usage is high
    if (memoryUsage.usage_percentage > 80) {
      reportError();
    }

    return memoryUsage;
  }

  // Bundle size monitoring
  monitorBundleSize() {
    if (!window.performance?.getEntriesByType) return;

    const resources = window.performance.getEntriesByType('resource') as Array<{
      name: string;
      transferSize?: number;
    }>;
    let totalBundleSize = 0;
    let jsSize = 0;
    let cssSize = 0;

    resources.forEach(resource => {
      if (resource.name.includes('bundle') || resource.name.includes('chunk')) {
        totalBundleSize += resource.transferSize || 0;

        if (resource.name.endsWith('.js')) {
          jsSize += resource.transferSize || 0;
        } else if (resource.name.endsWith('.css')) {
          cssSize += resource.transferSize || 0;
        }
      }
    });

    const bundleInfo = {
      total_size: totalBundleSize,
      js_size: jsSize,
      css_size: cssSize,
      total_size_mb: (totalBundleSize / 1024 / 1024).toFixed(2),
    };

    logDebug('Bundle Size:', bundleInfo);

    // New Relic reporting removed

    return bundleInfo;
  }

  // Cleanup observers
  cleanup() {
    this.observers.forEach(observer => {
      observer.disconnect();
    });
    this.observers.clear();
    this.metrics.clear();
  }
}

// Create singleton instance
const performanceMonitor = new PerformanceMonitor();

// Initialize monitoring
if (typeof window !== 'undefined') {
  performanceMonitor.setupWebVitals();

  // Monitor initial page load
  window.addEventListener('load', () => {
    setTimeout(() => {
      performanceMonitor.monitorMemoryUsage();
      performanceMonitor.monitorBundleSize();
    }, 1000);
  });
}

export default performanceMonitor;

// Convenience exports
export const {
  startTiming,
  endTiming,
  monitorApiCall,
  monitorRender,
  monitorInteraction,
  monitorSimulation,
  monitorMemoryUsage,
  monitorBundleSize,
} = performanceMonitor;
