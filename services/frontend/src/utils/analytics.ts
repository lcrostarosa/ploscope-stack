/* eslint-disable */
/**
 * Unified Analytics for PLO Analysis
 *
 * Integrates Google Analytics 4, Meta Pixel, and Grafana Faro
 * for comprehensive user behavior tracking and insights.
 */

import { logInfo, logError, logWarn, logDebug } from './logger';
import {
  getFeatureFlag as getEnvFeatureFlag,
  isFeatureEnabled as isEnvFeatureEnabled,
  getFeatureFlagSafe as getEnvFeatureFlagSafe,
  isFeatureEnabledSafe as isEnvFeatureEnabledSafe,
} from './featureFlags';

type GtagFunction = (...args: unknown[]) => void;
type DataLayer = unknown[];
import type { FaroApi, FaroModule } from '@/types/Faro';
import type { TelemetryBody } from '@/types/Telemetry';

import type { EquityParameters } from '@/types/Equity';
type EquityResults = unknown[] | null | undefined;
import type { SpotAnalysisData } from '@/types/SpotAnalysis';

// Configuration - Set these in your environment variables or config
const ANALYTICS_CONFIG = {
  // Google Analytics 4
  GA_MEASUREMENT_ID: process.env.REACT_APP_GA_MEASUREMENT_ID || 'G-XXXXXXXXXX',

  // Meta (Facebook) Pixel
  META_PIXEL_ID: process.env.REACT_APP_META_PIXEL_ID || '3613019098992917',

  // Grafana Faro (Telemetry)
  FARO_URL: process.env.REACT_APP_FARO_URL || '',
  FARO_APP_NAME: process.env.REACT_APP_FARO_APP_NAME || 'ploscope-frontend',
  FARO_APP_VERSION: process.env.REACT_APP_VERSION || '0.0.0',

  // Feature flags
  ENABLE_GA: process.env.REACT_APP_ENABLE_GA !== 'false',
  ENABLE_META: process.env.REACT_APP_ENABLE_META !== 'false',
  // ENABLE_CLARITY removed
  // ENABLE_POSTHOG removed
  ENABLE_FARO: process.env.REACT_APP_ENABLE_FARO !== 'false',

  // Debug mode
  DEBUG: process.env.NODE_ENV === 'development',
};

class UnifiedAnalytics {
  initialized: boolean;
  userId: string | null;
  sessionId: string;
  pageLoadTime: number;
  faroApi: FaroApi | null;
  // Telemetry controls
  private telemetryBackoffUntil: number | null;
  private lastEventSentAt: Map<string, number>;
  private readonly defaultMinEventIntervalMs: number;
  private readonly perEventMinIntervalMs: Record<string, number>;
  constructor() {
    this.initialized = false;
    this.userId = null;
    this.sessionId = this.generateSessionId();
    this.pageLoadTime = performance.now();
    this.faroApi = null;
    this.telemetryBackoffUntil = null;
    this.lastEventSentAt = new Map();
    this.defaultMinEventIntervalMs = 800; // Default de-dupe window
    this.perEventMinIntervalMs = {
      // Form change events can be noisy
      form_field_change: 3000,
      // Engagement interval has its own cadence but add a guard
      engagement_interval: 55000,
      user_engagement: 2000,
    };

    this.init();
  }

  generateSessionId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  async init(): Promise<void> {
    if (this.initialized) return;

    // Respect cookie consent: only initialize if analytics consent granted
    try {
      const consentRaw = localStorage.getItem('cookieConsent');
      if (!consentRaw) {
        return; // no consent choice yet
      }
      const consent = JSON.parse(consentRaw);
      // Require third_party ON to load external SDKs
      if (!consent || consent.third_party !== true) {
        return; // analytics not permitted
      }
    } catch (_e) {
      // If consent parsing fails, do not initialize
      return;
    }

    try {
      // Only initialize Grafana Faro (no PII) when explicitly consented to third-party tools
      if (ANALYTICS_CONFIG.ENABLE_FARO && ANALYTICS_CONFIG.FARO_URL) {
        await this.initFaro();
      }

      this.initialized = true;
      this.log('Analytics initialized successfully');
    } catch (error) {
      logError('Failed to initialize analytics:', error);
    }
  }

  async initFaro(): Promise<void> {
    try {
      const [
        { initializeFaro, getWebInstrumentations, faro },
        { TracingInstrumentation },
      ] = await Promise.all([
        import(/* webpackChunkName: "faro-sdk" */ '@grafana/faro-web-sdk'),
        import(
          /* webpackChunkName: "faro-tracing" */ '@grafana/faro-web-tracing'
        ),
      ]);

      initializeFaro({
        url: ANALYTICS_CONFIG.FARO_URL as string,
        app: {
          name: ANALYTICS_CONFIG.FARO_APP_NAME,
          version: ANALYTICS_CONFIG.FARO_APP_VERSION,
        },
        instrumentations: [
          ...getWebInstrumentations(),
          new TracingInstrumentation(),
        ],
      });

      // Save API for later usage
      // eslint-disable-next-line
      this.faroApi = (faro as FaroModule)?.api ?? null;
      this.log('Grafana Faro initialized');
    } catch (error) {
      logError('Failed to initialize Grafana Faro', error);
    }
  }

  async initGoogleAnalytics(): Promise<void> {
    return new Promise<void>(resolve => {
      // Check if gtag is already loaded (from HTML head)
      if (window.gtag) {
        // Update consent mode to allow analytics
        window.gtag('consent', 'update', {
          analytics_storage: 'granted',
        });

        this.log('Google Analytics consent updated');
        resolve();
        return;
      }

      // Fallback: Load gtag script if not already present
      const script = document.createElement('script');
      script.async = true;
      script.src = `https://www.googletagmanager.com/gtag/js?id=${ANALYTICS_CONFIG.GA_MEASUREMENT_ID}`;
      document.head.appendChild(script);

      script.onload = () => {
        // Initialize gtag
        (window as typeof window & { dataLayer?: DataLayer }).dataLayer =
          (window as typeof window & { dataLayer?: DataLayer }).dataLayer || [];
        const gtag: GtagFunction = (...args: unknown[]) => {
          (
            (window as typeof window & { dataLayer?: DataLayer })
              .dataLayer as DataLayer
          ).push(args);
        };
        (window as typeof window & { gtag?: GtagFunction }).gtag = gtag;

        gtag('js', new Date());
        gtag('config', ANALYTICS_CONFIG.GA_MEASUREMENT_ID, {
          page_title: document.title,
          page_location: window.location.href,
          custom_map: {
            custom_parameter_1: 'session_id',
          },
        });

        this.log('Google Analytics initialized');
        resolve();
      };
    });
  }

  // Clarity and PostHog helpers removed

  // User identification (suppressed for GDPR compliance)
  identifyUser() {
    // Do not store or forward any user identifiers
    this.userId = null;
    this.log('identifyUser suppressed for privacy');
  }

  private getMinIntervalMs(eventName: string): number {
    return (
      this.perEventMinIntervalMs[eventName] ?? this.defaultMinEventIntervalMs
    );
  }

  private shouldThrottleEvent(eventName: string): boolean {
    const now = Date.now();
    const minInterval = this.getMinIntervalMs(eventName);
    const last = this.lastEventSentAt.get(eventName) ?? 0;
    if (now - last < minInterval) {
      return true;
    }
    this.lastEventSentAt.set(eventName, now);
    return false;
  }

  private setBackoffFromHeaders(resp: Response) {
    try {
      // Prefer Retry-After (seconds) if present
      const retryAfter = resp.headers.get('Retry-After');
      const resetHeader = resp.headers.get('X-RateLimit-Reset');
      const now = Date.now();

      if (retryAfter) {
        const retryMs = Math.max(0, parseInt(retryAfter, 10)) * 1000;
        this.telemetryBackoffUntil =
          now + (Number.isFinite(retryMs) ? retryMs : 60000);
        return;
      }

      if (resetHeader) {
        const resetEpoch = parseInt(resetHeader, 10) * 1000; // header is seconds
        if (Number.isFinite(resetEpoch) && resetEpoch > now) {
          this.telemetryBackoffUntil = resetEpoch;
          return;
        }
      }

      // Fallback backoff
      this.telemetryBackoffUntil = now + 60000; // 60s
    } catch (_e) {
      this.telemetryBackoffUntil = Date.now() + 60000;
    }
  }

  private isInBackoff(): boolean {
    return (
      this.telemetryBackoffUntil !== null &&
      Date.now() < this.telemetryBackoffUntil
    );
  }

  private async sendTelemetry(body: TelemetryBody): Promise<void> {
    // In tests, bypass consent check so unit tests can validate behavior
    let allowUsage = false;
    try {
      if (process.env.NODE_ENV === 'test') {
        allowUsage = true;
      } else {
        const consent = JSON.parse(
          localStorage.getItem('cookieConsent') || '{}'
        );
        allowUsage = consent && consent.analytics === true;
      }
    } catch (_e) {
      allowUsage = process.env.NODE_ENV === 'test';
    }

    if (!allowUsage) return;

    // Global backoff handling
    if (this.isInBackoff()) {
      logDebug('Telemetry backoff active, dropping event:', body.event_name);
      return;
    }

    // Per-event throttling
    if (this.shouldThrottleEvent(body.event_name)) {
      logDebug('Telemetry throttled event:', body.event_name);
      return;
    }

    try {
      const resp = await fetch('/api/telemetry/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        keepalive: true,
      });

      if (resp.status === 429) {
        logWarn('Telemetry 429 received. Applying client backoff.');
        this.setBackoffFromHeaders(resp);
      }
    } catch (_e) {
      // Network errors are ignored; do not block app flow
    }
  }

  // Page view tracking
  trackPageView(
    pagePath: string | null = null,
    pageTitle: string | null = null
  ) {
    const path = pagePath || window.location.pathname;
    const title = pageTitle || document.title;

    // First-party anonymous telemetry
    void this.sendTelemetry({
      event_name: 'page_view',
      event_time: new Date().toISOString(),
      page_path: path,
      analytics_id: undefined,
      properties: {
        page_title: title,
        page_location: window.location.href,
      },
    });

    // Grafana Faro - page view event (no PII)
    if (this.faroApi && ANALYTICS_CONFIG.ENABLE_FARO) {
      try {
        this.faroApi.pushEvent?.('page_view', {
          page_title: title,
          page_location: window.location.href,
          page_path: path,
        });
      } catch (_e) {
        // Non-blocking
      }
    }

    this.log('Page view tracked:', path);
  }

  // Event tracking
  trackEvent(eventName: string, properties: Record<string, unknown> = {}) {
    // Always send minimal, anonymous first-party telemetry when usage analytics is allowed
    const body: TelemetryBody = {
      event_name: eventName,
      event_time: new Date().toISOString(),
      page_path: window.location.pathname,
      analytics_id:
        (properties as { analytics_id?: string }).analytics_id ?? undefined,
      properties: {
        ...properties,
        user_id: undefined,
        session_id: undefined,
      },
    };
    void this.sendTelemetry(body);

    // Forward to Faro if available (no PII)
    if (this.faroApi && ANALYTICS_CONFIG.ENABLE_FARO) {
      try {
        const eventData = {
          ...properties,
          timestamp: new Date().toISOString(),
        };
        this.faroApi.pushEvent?.(eventName, eventData);
      } catch (_e) {
        // Non-blocking
      }
    }

    this.log('Event tracked:', eventName, properties);
  }

  // PLO Analysis specific tracking methods
  trackEquityCalculation(
    parameters: EquityParameters,
    results: EquityResults,
    duration: number,
    success = true
  ) {
    this.trackEvent('equity_calculation', {
      category: 'calculation',
      success: success,
      duration_seconds: duration,
      board_cards: parameters.board_cards?.length || 0,
      player_count: parameters.players?.length || 0,
      iterations: parameters.iterations || 0,
      result_count: results?.length || 0,
      value: success ? 1 : 0,
    });
  }

  trackSpotAnalysis(spotData: SpotAnalysisData, success = true) {
    this.trackEvent('spot_analysis', {
      category: 'analysis',
      success: success,
      position: spotData.position,
      action: spotData.action,
      has_description: !!spotData.description,
      value: success ? 1 : 0,
    });
  }

  trackFeatureUsage(
    featureName: string,
    category: string,
    duration: number | null = null,
    interactions = 1
  ) {
    this.trackEvent('feature_usage', {
      category: category,
      feature_name: featureName,
      duration_seconds: duration,
      interactions: interactions,
      value: interactions,
    });
  }

  trackUserAction(action: string, context: Record<string, unknown> = {}) {
    this.trackEvent('user_action', {
      category: 'interaction',
      action: action,
      ...context,
    });
  }

  trackError(
    errorType: string,
    errorMessage: string,
    errorContext: Record<string, unknown> = {}
  ) {
    this.trackEvent('error_occurred', {
      category: 'error',
      error_type: errorType,
      error_message: errorMessage,
      page_url: window.location.href,
      ...errorContext,
    });

    // PostHog removed

    // Grafana Faro - error reporting
    if (this.faroApi && ANALYTICS_CONFIG.ENABLE_FARO) {
      try {
        // Prefer pushError if available
        if (this.faroApi.pushError) {
          this.faroApi.pushError(new Error(errorMessage), {
            error_type: errorType,
            ...errorContext,
          });
        } else if (this.faroApi.pushEvent) {
          this.faroApi.pushEvent('error_occurred', {
            error_type: errorType,
            error_message: errorMessage,
            page_url: window.location.href,
            ...errorContext,
          });
        }
      } catch (e) {
        // Non-blocking
      }
    }
  }

  // Performance tracking
  trackPerformance(
    metricName: string,
    value: number,
    context: Record<string, unknown> = {}
  ) {
    this.trackEvent('performance_metric', {
      category: 'performance',
      metric_name: metricName,
      value: value,
      ...context,
    });

    // Grafana Faro - performance metric
    if (this.faroApi && ANALYTICS_CONFIG.ENABLE_FARO) {
      try {
        this.faroApi.pushEvent?.('performance_metric', {
          metric_name: metricName,
          value,
          ...context,
        });
      } catch (e) {
        // Non-blocking
      }
    }
  }

  // Conversion tracking
  trackConversion(
    conversionName: string,
    value: number | null = null,
    context: Record<string, unknown> = {}
  ) {
    // First-party conversion telemetry only (no PII)
    this.trackEvent('conversion', {
      category: 'conversion',
      conversion_name: conversionName,
      value: value,
      ...context,
    });
  }

  // Meta-specific tracking methods
  trackMetaLead(
    leadType: string,
    value: number | null = null,
    context: Record<string, unknown> = {}
  ) {
    // Re-map to first-party anonymous telemetry
    this.trackEvent('meta_lead', {
      content_name: `Lead - ${leadType}`,
      content_category: 'Lead Generation',
      value: value || 1,
      currency: 'USD',
      lead_type: leadType,
      ...context,
    });
    this.log('Meta lead tracked (first-party only):', leadType, context);
  }

  trackMetaAddToCart(
    productName: string,
    value: number | null = null,
    context: Record<string, unknown> = {}
  ) {
    // Re-map to first-party anonymous telemetry
    this.trackEvent('meta_add_to_cart', {
      content_name: productName,
      content_category: 'Product',
      value: value || 1,
      currency: 'USD',
      product_name: productName,
      ...context,
    });
    this.log(
      'Meta add to cart tracked (first-party only):',
      productName,
      context
    );
  }

  trackMetaInitiateCheckout(
    value: number | null = null,
    context: Record<string, unknown> = {}
  ) {
    // Re-map to first-party anonymous telemetry
    this.trackEvent('meta_initiate_checkout', {
      content_name: 'Checkout Initiated',
      content_category: 'E-commerce',
      value: value || 1,
      currency: 'USD',
      ...context,
    });
    this.log('Meta checkout initiated tracked (first-party only):', context);
  }

  // Feature flags via env
  getFeatureFlag(flagKey: string) {
    return getEnvFeatureFlagSafe(flagKey);
  }

  isFeatureEnabled(flagKey: string) {
    return isEnvFeatureEnabledSafe(flagKey);
  }

  // User properties
  setUserProperties(properties: Record<string, unknown>) {
    // Do not forward to third parties; optionally record locally if needed
    this.log('User properties set (not forwarded):', properties);
  }

  // Session management
  startSession() {
    this.sessionId = this.generateSessionId();
    this.trackEvent('session_start', {
      category: 'session',
      session_id: this.sessionId,
    });
  }

  endSession() {
    this.trackEvent('session_end', {
      category: 'session',
      session_id: this.sessionId,
      session_duration: (performance.now() - this.pageLoadTime) / 1000,
    });
  }

  // Privacy controls
  optOut() {
    // No third-party SDK calls; rely on consent flags and first-party behavior
    this.log('User opted out of analytics');
  }

  optIn() {
    // Ensure SDKs are initialized after opt-in (only Faro, no PII)
    if (!this.initialized) {
      this.init();
    }
    this.log('User opted in to analytics');
  }

  // Enhanced Google Analytics 4 and Meta tracking methods
  trackSignup(signupMethod: string, userProperties: Record<string, any> = {}) {
    this.trackEvent('sign_up', {
      method: signupMethod,
      ...userProperties,
    });
    this.log(
      'Signup tracked (first-party only):',
      signupMethod,
      userProperties
    );
  }

  trackLogin(loginMethod: string, userProperties: Record<string, any> = {}) {
    this.trackEvent('login', {
      method: loginMethod,
      ...userProperties,
    });
    this.log('Login tracked (first-party only):', loginMethod, userProperties);
  }

  trackAppUsage(
    featureName: string,
    action: string,
    duration: number | null = null,
    context: Record<string, any> = {}
  ) {
    this.trackEvent('app_usage', {
      feature_name: featureName,
      action: action,
      duration_seconds: duration,
      ...context,
    });
    this.log(
      'App usage tracked (first-party only):',
      featureName,
      action,
      context
    );
  }

  trackPageViewEnhanced(
    pagePath: string | null = null,
    pageTitle: string | null = null,
    customParameters: Record<string, any> = {}
  ) {
    const path = pagePath || window.location.pathname;
    const title = pageTitle || document.title;
    this.trackEvent('page_view', {
      page_title: title,
      page_location: window.location.href,
      page_path: path,
      ...customParameters,
    });
    this.log(
      'Enhanced page view tracked (first-party only):',
      path,
      customParameters
    );
  }

  trackUserEngagement(
    engagementType: string,
    duration: number | null = null,
    context: Record<string, any> = {}
  ) {
    this.trackEvent('user_engagement', {
      engagement_type: engagementType,
      duration_seconds: duration,
      ...context,
    });
    this.log(
      'User engagement tracked (first-party only):',
      engagementType,
      context
    );
  }

  trackFeatureAccess(
    featureName: string,
    accessType: string = 'view',
    context: Record<string, any> = {}
  ) {
    this.trackEvent('feature_access', {
      feature_name: featureName,
      access_type: accessType,
      ...context,
    });
    this.log(
      'Feature access tracked (first-party only):',
      featureName,
      accessType,
      context
    );
  }

  // Utility methods
  log(...args: unknown[]) {
    if (ANALYTICS_CONFIG.DEBUG) {
      logInfo('[Analytics]', ...args);
    }
  }

  getSessionInfo() {
    return {
      sessionId: this.sessionId,
      userId: this.userId,
      initialized: this.initialized,
      enabledServices: {
        googleAnalytics: ANALYTICS_CONFIG.ENABLE_GA,
        metaPixel: ANALYTICS_CONFIG.ENABLE_META,
        // Removed services
        microsoftClarity: false,
        postHog: false,
        faro: ANALYTICS_CONFIG.ENABLE_FARO,
      },
    };
  }
}

// Create singleton instance
const analytics = new UnifiedAnalytics();

// Export convenience methods
export const identifyUser = () => analytics.identifyUser();
export const trackPageView = (path?: string, title?: string) =>
  analytics.trackPageView(path ?? null, title ?? null);
export const trackEvent = (
  eventName: string,
  properties: Record<string, unknown>
) => analytics.trackEvent(eventName, properties);
export const trackEquityCalculation = (
  params: EquityParameters,
  results: EquityResults,
  duration: number,
  success?: boolean
) => analytics.trackEquityCalculation(params, results, duration, success);
export const trackSpotAnalysis = (
  spotData: SpotAnalysisData,
  success?: boolean
) => analytics.trackSpotAnalysis(spotData, success);
export const trackFeatureUsage = (
  featureName: string,
  category: string,
  duration?: number | null,
  interactions?: number
) =>
  analytics.trackFeatureUsage(
    featureName,
    category,
    duration ?? null,
    interactions ?? 1
  );
export const trackUserAction = (
  action: string,
  context: Record<string, unknown>
) => analytics.trackUserAction(action, context);
export const trackError = (
  errorType: string,
  errorMessage: string,
  context?: Record<string, unknown>
) => analytics.trackError(errorType, errorMessage, context ?? {});
export const trackPerformance = (
  metricName: string,
  value: number,
  context?: Record<string, unknown>
) => analytics.trackPerformance(metricName, value, context ?? {});
export const trackConversion = (
  conversionName: string,
  value?: number | null,
  context?: Record<string, unknown>
) => analytics.trackConversion(conversionName, value ?? null, context ?? {});
export const getFeatureFlag = (flagKey: string) =>
  analytics.getFeatureFlag(flagKey);
export const isFeatureEnabled = (flagKey: string) =>
  analytics.isFeatureEnabled(flagKey);
export const setUserProperties = (properties: Record<string, unknown>) =>
  analytics.setUserProperties(properties);
export const startSession = () => analytics.startSession();
export const endSession = () => analytics.endSession();
export const optOut = () => analytics.optOut();
export const optIn = () => analytics.optIn();
export const getSessionInfo = () => analytics.getSessionInfo();

// Enhanced Google Analytics 4 and Meta tracking exports
export const trackSignup = (
  signupMethod: string,
  userProperties: Record<string, unknown>
) => analytics.trackSignup(signupMethod, userProperties);
export const trackLogin = (
  loginMethod: string,
  userProperties: Record<string, unknown>
) => analytics.trackLogin(loginMethod, userProperties);
export const trackAppUsage = (
  featureName: string,
  action: string,
  duration?: number | null,
  context?: Record<string, unknown>
) =>
  analytics.trackAppUsage(featureName, action, duration ?? null, context ?? {});
export const trackPageViewEnhanced = (
  pagePath?: string,
  pageTitle?: string,
  customParameters?: Record<string, unknown>
) =>
  analytics.trackPageViewEnhanced(
    pagePath ?? null,
    pageTitle ?? null,
    customParameters ?? {}
  );
export const trackUserEngagement = (
  engagementType: string,
  duration?: number | null,
  context?: Record<string, unknown>
) =>
  analytics.trackUserEngagement(
    engagementType,
    duration ?? null,
    context ?? {}
  );
export const trackFeatureAccess = (
  featureName: string,
  accessType: string,
  context?: Record<string, unknown>
) => analytics.trackFeatureAccess(featureName, accessType, context ?? {});

// Meta-specific tracking exports
export const trackMetaLead = (
  leadType: string,
  value?: number | null,
  context?: Record<string, unknown>
) => analytics.trackMetaLead(leadType, value ?? null, context ?? {});
export const trackMetaAddToCart = (
  productName: string,
  value?: number | null,
  context?: Record<string, unknown>
) => analytics.trackMetaAddToCart(productName, value ?? null, context ?? {});
export const trackMetaInitiateCheckout = (
  value?: number | null,
  context?: Record<string, unknown>
) => analytics.trackMetaInitiateCheckout(value ?? null, context ?? {});

export default analytics;

// Test-only helpers to inject/mutate internal state
// These are no-ops in non-test environments
export const __setFaroApiForTest = (api: FaroApi) => {
  if (process.env.NODE_ENV === 'test') {
    // eslint-disable-next-line
    (analytics as unknown as { faroApi: FaroApi | null }).faroApi = api;
  }
};

export const __setInitializedForTest = (initialized: boolean) => {
  if (process.env.NODE_ENV === 'test') {
    // eslint-disable-next-line
    (analytics as unknown as { initialized: boolean }).initialized =
      initialized;
  }
};
