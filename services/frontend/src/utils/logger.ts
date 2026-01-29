type LogLevelName = 'error' | 'warn' | 'info' | 'debug';
/**
 * Frontend Logger Utility
 *
 * Provides consistent logging across the frontend application with
 * environment-aware logging levels and structured output.
 * Includes request ID tracking for correlating requests between frontend and backend.
 */

// Configuration
const LOG_CONFIG = {
  // Log level (error, warn, info, debug)
  LEVEL: process.env.REACT_APP_LOG_LEVEL || 'info',

  // Enable/disable logging
  ENABLED:
    process.env.NODE_ENV !== 'production' ||
    process.env.REACT_APP_ENABLE_LOGGING === 'true',

  // Include timestamps
  INCLUDE_TIMESTAMP: true,

  // Include component context
  INCLUDE_CONTEXT: true,

  // Include request ID
  INCLUDE_REQUEST_ID: true,

  // Log levels in order of severity
  LEVELS: {
    error: 0,
    warn: 1,
    info: 2,
    debug: 3,
  },
};

// Request ID tracking
let currentRequestId: string | null = null;

/**
 * Generate a unique request ID
 */
export const generateRequestId = (): string => {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

/**
 * Set the current request ID
 */
export const setCurrentRequestId = (requestId: string): void => {
  currentRequestId = requestId;
};

/**
 * Get the current request ID
 */
export const getCurrentRequestId = (): string | null => {
  return currentRequestId;
};

/**
 * Clear the current request ID
 */
export const clearCurrentRequestId = (): void => {
  currentRequestId = null;
};

class Logger {
  context: string;
  level: number;

  constructor(context: string = 'App') {
    this.context = context;
    this.level =
      LOG_CONFIG.LEVELS[LOG_CONFIG.LEVEL as LogLevelName] ??
      LOG_CONFIG.LEVELS.info;
  }

  /**
   * Get current timestamp
   */
  getTimestamp(): string {
    if (!LOG_CONFIG.INCLUDE_TIMESTAMP) return '';
    return new Date().toISOString();
  }

  /**
   * Format log message with context and timestamp
   */
  formatMessage(level: LogLevelName, message: string): string {
    const parts = [];

    if (LOG_CONFIG.INCLUDE_TIMESTAMP) {
      parts.push(`[${this.getTimestamp()}]`);
    }

    parts.push(`[${level.toUpperCase()}]`);

    if (LOG_CONFIG.INCLUDE_REQUEST_ID && currentRequestId) {
      parts.push(`[${currentRequestId}]`);
    }

    if (LOG_CONFIG.INCLUDE_CONTEXT && this.context) {
      parts.push(`[${this.context}]`);
    }

    parts.push(message);

    return parts.join(' ');
  }

  /**
   * Check if logging is enabled for the given level
   */
  shouldLog(level: LogLevelName): boolean {
    if (!LOG_CONFIG.ENABLED) return false;
    return LOG_CONFIG.LEVELS[level] <= this.level;
  }

  /**
   * Log error messages
   */
  error(message: string, ...args: unknown[]): void {
    if (this.shouldLog('error')) {
      // Use console.error for actual error logging
      // eslint-disable-next-line no-console
      console.error(this.formatMessage('error', message), ...args);
    }
  }

  /**
   * Log warning messages
   */
  warn(message: string, ...args: unknown[]): void {
    if (this.shouldLog('warn')) {
      // Use console.warn for actual warning logging
      // eslint-disable-next-line no-console
      console.warn(this.formatMessage('warn', message), ...args);
    }
  }

  /**
   * Log info messages
   */
  info(message: string, ...args: unknown[]): void {
    if (this.shouldLog('info')) {
      // Use console.info for actual info logging
      // eslint-disable-next-line no-console
      console.info(this.formatMessage('info', message), ...args);
    }
  }

  /**
   * Log debug messages
   */
  debug(message: string, ...args: unknown[]): void {
    if (this.shouldLog('debug')) {
      // Use console.debug for actual debug logging
      // eslint-disable-next-line no-console
      console.debug(this.formatMessage('debug', message), ...args);
    }
  }

  /**
   * Log messages (alias for info)
   */
  log(message: string, ...args: unknown[]): void {
    this.info(message, ...args);
  }

  /**
   * Create a new logger instance with a specific context
   */
  createLogger(context: string): Logger {
    return new Logger(context);
  }

  /**
   * Log user actions
   */
  logUserAction(action: string, context: Record<string, unknown> = {}): void {
    this.info(`User action: ${action}`, context);
  }

  /**
   * Log API calls
   */
  logApiCall(
    method: string,
    url: string,
    status: number | string,
    duration: number | null = null
  ): void {
    const message = `API call: ${method} ${url} -> ${status}`;
    const extra = duration ? ` (${duration.toFixed(3)}s)` : '';
    this.info(message + extra);
  }

  /**
   * Log errors with context
   */
  logError(error: Error, context: Record<string, unknown> = {}): void {
    this.error(`Error: ${error.message}`, {
      stack: error.stack,
      ...context,
    });
  }

  /**
   * Log performance metrics
   */
  logPerformance(
    metric: string,
    value: number | string,
    context: Record<string, unknown> = {}
  ): void {
    this.info(`Performance: ${metric} = ${value}`, context);
  }

  /**
   * Log feature usage
   */
  logFeatureUsage(
    feature: string,
    context: Record<string, unknown> = {}
  ): void {
    this.info(`Feature used: ${feature}`, context);
  }
}

// Type definitions for fetch options
interface FetchOptions {
  method?: string;
  headers?: Record<string, string> | Headers;
  body?: string | FormData | Blob | ArrayBuffer;
  mode?: 'cors' | 'no-cors' | 'same-origin';
  credentials?: 'omit' | 'same-origin' | 'include';
  cache?:
    | 'default'
    | 'no-store'
    | 'reload'
    | 'no-cache'
    | 'force-cache'
    | 'only-if-cached';
  redirect?: 'follow' | 'error' | 'manual';
  referrer?: string;
  referrerPolicy?:
    | 'no-referrer'
    | 'no-referrer-when-downgrade'
    | 'origin'
    | 'origin-when-cross-origin'
    | 'same-origin'
    | 'strict-origin'
    | 'strict-origin-when-cross-origin'
    | 'unsafe-url';
  integrity?: string;
  keepalive?: boolean;
  signal?: AbortSignal;
}

/**
 * Enhanced fetch function that automatically adds request ID headers
 */
export const fetchWithRequestId = async (
  url: string,
  options: FetchOptions = {}
): Promise<Response> => {
  const requestId = generateRequestId();
  setCurrentRequestId(requestId);

  // Add request ID header
  const enhancedOptions: FetchOptions = {
    ...options,
    headers: {
      ...(options.headers as Record<string, string>),
      'X-Request-ID': requestId,
    },
  };

  const response = await fetch(url, enhancedOptions);
  return response;
};

/**
 * Setup axios interceptors to add request IDs
 */
export const setupAxiosRequestId = (axiosInstance: {
  interceptors: {
    request: {
      use: (
        onFulfilled: (config: any) => any,
        onRejected: (error: unknown) => Promise<never>
      ) => void;
    };
    response: {
      use: (
        onFulfilled: (response: any) => any,
        onRejected: (error: any) => Promise<never>
      ) => void;
    };
  };
}) => {
  // Request interceptor to add request ID
  axiosInstance.interceptors.request.use(
    (config: any) => {
      const requestId = generateRequestId();
      setCurrentRequestId(requestId);
      config.headers = config.headers || {};
      config.headers['X-Request-ID'] = requestId;
      config.requestId = requestId;
      return config;
    },
    (error: unknown) => {
      defaultLogger.error('Request interceptor error:', error);
      return Promise.reject(error);
    }
  );

  // Response interceptor for logging
  axiosInstance.interceptors.response.use(
    (response: any) => {
      return response;
    },
    (error: any) => {
      const requestId = error.config?.requestId || 'unknown';
      defaultLogger.error(`Response [${requestId}] error:`, {
        method: error.config?.method?.toUpperCase(),
        url: error.config?.url,
        status: error.response?.status,
        statusText: error.response?.statusText,
        message: error.message,
      });
      return Promise.reject(error);
    }
  );

  return axiosInstance;
};

// Create default logger instance
const defaultLogger = new Logger();

// Export convenience functions
export const logError = (message: string, ...args: unknown[]) =>
  defaultLogger.error(message, ...args);
export const logWarn = (message: string, ...args: unknown[]) =>
  defaultLogger.warn(message, ...args);
export const logInfo = (message: string, ...args: unknown[]) =>
  defaultLogger.info(message, ...args);
export const logDebug = (message: string, ...args: unknown[]) =>
  defaultLogger.debug(message, ...args);
export const log = (message: string, ...args: unknown[]) =>
  defaultLogger.log(message, ...args);

// Export logger class and default instance
export { Logger };
export default defaultLogger;
