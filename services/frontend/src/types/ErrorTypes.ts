// Error Type System for PLO Analysis
// Provides type-safe error handling across the application

// Base error interface
export interface BaseError {
  message: string;
  code?: string;
  timestamp?: Date;
}

// API Error types
export interface ApiError extends BaseError {
  type: 'api';
  status?: number;
  statusText?: string;
  response?: {
    data?: {
      error?: string;
      message?: string;
      details?: any;
    };
  };
  request?: {
    url?: string;
    method?: string;
    data?: any;
  };
}

// Network Error types
export interface NetworkError extends BaseError {
  type: 'network';
  isOnline?: boolean;
  retryable?: boolean;
}

// Validation Error types
export interface ValidationError extends BaseError {
  type: 'validation';
  field?: string;
  value?: any;
  rule?: string;
}

// Game Logic Error types
export interface GameLogicError extends BaseError {
  type: 'game_logic';
  action?: string;
  player?: number;
  state?: string;
}

// Analysis Error types
export interface AnalysisError extends BaseError {
  type: 'analysis';
  jobId?: string;
  iteration?: number;
  algorithm?: string;
}

// Card Error types
export interface CardError extends BaseError {
  type: 'card';
  card?: string;
  position?: string;
  operation?: 'validation' | 'duplicate' | 'invalid_format';
}

// Job Error types
export interface JobError extends BaseError {
  type: 'job';
  jobId?: string;
  jobType?: string;
  status?: string;
  progress?: number;
}

// Authentication Error types
export interface AuthError extends BaseError {
  type: 'auth';
  action?: 'login' | 'logout' | 'register' | 'token_refresh';
  expired?: boolean;
}

// Database Error types
export interface DatabaseError extends BaseError {
  type: 'database';
  operation?: 'read' | 'write' | 'delete' | 'update';
  table?: string;
  constraint?: string;
}

// File Error types
export interface FileError extends BaseError {
  type: 'file';
  operation?: 'read' | 'write' | 'delete' | 'upload';
  filename?: string;
  size?: number;
  mimeType?: string;
}

// Configuration Error types
export interface ConfigError extends BaseError {
  type: 'config';
  key?: string;
  value?: any;
  environment?: string;
}

// Union type for all error types
export type AppError =
  | ApiError
  | NetworkError
  | ValidationError
  | GameLogicError
  | AnalysisError
  | CardError
  | JobError
  | AuthError
  | DatabaseError
  | FileError
  | ConfigError;

// Error factory functions
export const createApiError = (
  message: string,
  status?: number,
  response?: any
): ApiError => ({
  type: 'api',
  message,
  status,
  response,
  timestamp: new Date(),
});

export const createNetworkError = (
  message: string,
  isOnline?: boolean
): NetworkError => ({
  type: 'network',
  message,
  isOnline,
  retryable: true,
  timestamp: new Date(),
});

export const createValidationError = (
  message: string,
  field?: string,
  value?: any
): ValidationError => ({
  type: 'validation',
  message,
  field,
  value,
  timestamp: new Date(),
});

export const createGameLogicError = (
  message: string,
  action?: string,
  player?: number
): GameLogicError => ({
  type: 'game_logic',
  message,
  action,
  player,
  timestamp: new Date(),
});

export const createAnalysisError = (
  message: string,
  jobId?: string,
  algorithm?: string
): AnalysisError => ({
  type: 'analysis',
  message,
  jobId,
  algorithm,
  timestamp: new Date(),
});

export const createCardError = (
  message: string,
  card?: string,
  operation?: CardError['operation']
): CardError => ({
  type: 'card',
  message,
  card,
  operation,
  timestamp: new Date(),
});

export const createJobError = (
  message: string,
  jobId?: string,
  jobType?: string
): JobError => ({
  type: 'job',
  message,
  jobId,
  jobType,
  timestamp: new Date(),
});

export const createAuthError = (
  message: string,
  action?: AuthError['action']
): AuthError => ({
  type: 'auth',
  message,
  action,
  timestamp: new Date(),
});

export const createDatabaseError = (
  message: string,
  operation?: DatabaseError['operation'],
  table?: string
): DatabaseError => ({
  type: 'database',
  message,
  operation,
  table,
  timestamp: new Date(),
});

export const createFileError = (
  message: string,
  operation?: FileError['operation'],
  filename?: string
): FileError => ({
  type: 'file',
  message,
  operation,
  filename,
  timestamp: new Date(),
});

export const createConfigError = (
  message: string,
  key?: string,
  environment?: string
): ConfigError => ({
  type: 'config',
  message,
  key,
  environment,
  timestamp: new Date(),
});

// Error type guards
export const isApiError = (error: unknown): error is ApiError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'api'
  );
};

export const isNetworkError = (error: unknown): error is NetworkError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'network'
  );
};

export const isValidationError = (error: unknown): error is ValidationError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'validation'
  );
};

export const isGameLogicError = (error: unknown): error is GameLogicError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'game_logic'
  );
};

export const isAnalysisError = (error: unknown): error is AnalysisError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'analysis'
  );
};

export const isCardError = (error: unknown): error is CardError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'card'
  );
};

export const isJobError = (error: unknown): error is JobError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'job'
  );
};

export const isAuthError = (error: unknown): error is AuthError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'auth'
  );
};

export const isDatabaseError = (error: unknown): error is DatabaseError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'database'
  );
};

export const isFileError = (error: unknown): error is FileError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'file'
  );
};

export const isConfigError = (error: unknown): error is ConfigError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    error.type === 'config'
  );
};

export const isAppError = (error: unknown): error is AppError => {
  return (
    typeof error === 'object' &&
    error !== null &&
    'type' in error &&
    'message' in error
  );
};

// Error conversion utilities
export const convertToAppError = (error: unknown): AppError => {
  if (isAppError(error)) {
    return error;
  }

  // Handle axios errors
  if (typeof error === 'object' && error !== null && 'isAxiosError' in error) {
    const axiosError = error as any;
    return createApiError(
      axiosError.message || 'API request failed',
      axiosError.response?.status,
      axiosError.response
    );
  }

  // Handle fetch errors
  if (error instanceof TypeError && error.message.includes('fetch')) {
    return createNetworkError('Network request failed');
  }

  // Handle generic errors
  if (error instanceof Error) {
    return {
      type: 'api',
      message: error.message,
      timestamp: new Date(),
    };
  }

  // Handle unknown errors
  return {
    type: 'api',
    message: typeof error === 'string' ? error : 'An unknown error occurred',
    timestamp: new Date(),
  };
};

// Error message extraction
export const getErrorMessage = (error: unknown): string => {
  const appError = convertToAppError(error);

  switch (appError.type) {
    case 'api':
      return (
        appError.response?.data?.error ||
        appError.response?.data?.message ||
        appError.message
      );
    case 'validation':
      return appError.field
        ? `${appError.field}: ${appError.message}`
        : appError.message;
    case 'card':
      return appError.card
        ? `Card ${appError.card}: ${appError.message}`
        : appError.message;
    case 'job':
      return appError.jobId
        ? `Job ${appError.jobId}: ${appError.message}`
        : appError.message;
    default:
      return appError.message;
  }
};

// Error severity levels
export type ErrorSeverity = 'low' | 'medium' | 'high' | 'critical';

export const getErrorSeverity = (error: AppError): ErrorSeverity => {
  switch (error.type) {
    case 'network':
      return 'medium';
    case 'validation':
      return 'low';
    case 'auth':
      return 'high';
    case 'database':
      return 'high';
    case 'analysis':
      return 'medium';
    case 'job':
      return 'medium';
    case 'card':
      return 'low';
    case 'game_logic':
      return 'medium';
    case 'file':
      return 'medium';
    case 'config':
      return 'high';
    case 'api':
      return error.status && error.status >= 500 ? 'high' : 'medium';
    default:
      return 'medium';
  }
};

// Error retry logic
export const isRetryableError = (error: AppError): boolean => {
  switch (error.type) {
    case 'network':
      return error.retryable ?? true;
    case 'api':
      return error.status ? error.status >= 500 || error.status === 429 : false;
    case 'job':
      return error.status === 'failed' || error.status === 'timeout';
    default:
      return false;
  }
};
