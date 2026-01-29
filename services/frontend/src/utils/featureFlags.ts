import { logDebug } from './logger';

/**
 * Feature Flags Configuration
 *
 * Controls which features are selectable on the home page.
 * Features can be enabled/disabled via environment variables.
 * If environment variables are not set, defaults to the specified values.
 */

// TypeScript-native feature flag types
export interface FeatureFlagConfig {
  readonly key: string;
  readonly defaultValue: boolean;
  readonly description: string;
}

export type FeatureFlagName =
  | 'HAND_HISTORY_ANALYZER'
  | 'TOURNAMENT_MODE'
  | 'CASH_GAME_MODE'
  | 'LIVE_MODE'
  | 'BLOG';

export type FeatureFlags = Record<FeatureFlagName, FeatureFlagConfig>;

// Feature flag configuration with defaults
const FEATURE_FLAGS: FeatureFlags = {
  // Hand History Analyzer - Upload and analyze hand histories
  HAND_HISTORY_ANALYZER: {
    key: 'REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED',
    defaultValue: false,
    description: 'Hand History Analyzer - Upload and analyze hand histories',
  },

  // Tournament Mode - Tournament-style game setup
  TOURNAMENT_MODE: {
    key: 'REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED',
    defaultValue: true,
    description: 'Tournament Mode - Tournament-style game setup',
  },

  // Cash Game Mode - Cash game setup
  CASH_GAME_MODE: {
    key: 'REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED',
    defaultValue: false,
    description: 'Cash Game Mode - Cash game setup',
  },

  // Live Mode - Real-time poker gameplay
  LIVE_MODE: {
    key: 'REACT_APP_FEATURE_LIVE_MODE_ENABLED',
    defaultValue: true,
    description: 'Live Mode - Real-time poker gameplay',
  },

  // Blog - Public blog visibility
  BLOG: {
    key: 'REACT_APP_FEATURE_BLOG_ENABLED',
    defaultValue: false,
    description: 'Public blog visibility and navigation links',
  },
} as const;

/**
 * Validate environment variables are properly loaded
 */
const validateEnvironment = () => {
  if (typeof process === 'undefined' || !process.env) {
    return false;
  }

  // Check if any REACT_APP_ variables are available
  const hasReactAppVars = Object.keys(process.env).some(key =>
    key.startsWith('REACT_APP_')
  );

  if (!hasReactAppVars) {
    return false;
  }

  return true;
};

/**
 * Type guard to check if a string is a valid feature flag name
 */
const isValidFeatureFlagName = (name: string): name is FeatureFlagName => {
  return name in FEATURE_FLAGS;
};

/**
 * Get the value of a feature flag
 * @param flagName - The name of the feature flag
 * @returns Whether the feature is enabled
 */
export const getFeatureFlag = (flagName: FeatureFlagName): boolean => {
  const flag = FEATURE_FLAGS[flagName];

  // Validate environment is available
  if (!validateEnvironment()) {
    return flag.defaultValue;
  }

  const envValue = process.env[flag.key];

  // If environment variable is not set, use default
  if (envValue === undefined) {
    return flag.defaultValue;
  }

  // Parse environment variable value
  const result = envValue.toLowerCase() === 'true';

  // Log in development for debugging
  if (process.env.NODE_ENV === 'development') {
    logDebug(`🔧 Feature flag: ${flagName} = ${result} (env: ${envValue})`);
  }

  return result;
};

/**
 * Get the value of a feature flag with runtime validation
 * @param flagName - The name of the feature flag (string)
 * @returns Whether the feature is enabled, or false if invalid flag name
 */
export const getFeatureFlagSafe = (flagName: string): boolean => {
  if (!isValidFeatureFlagName(flagName)) {
    logDebug(`⚠️ Invalid feature flag name: ${flagName}`);
    return false;
  }
  return getFeatureFlag(flagName);
};

/**
 * Check if a feature is enabled
 * @param flagName - The name of the feature flag
 * @returns Whether the feature is enabled
 */
export const isFeatureEnabled = (flagName: FeatureFlagName): boolean => {
  return getFeatureFlag(flagName);
};

/**
 * Check if a feature is enabled with runtime validation
 * @param flagName - The name of the feature flag (string)
 * @returns Whether the feature is enabled, or false if invalid flag name
 */
export const isFeatureEnabledSafe = (flagName: string): boolean => {
  return getFeatureFlagSafe(flagName);
};

/**
 * Get all feature flags and their current values
 * @returns Object with feature flag names as keys and boolean values
 */
export const getAllFeatureFlags = (): Record<FeatureFlagName, boolean> => {
  const result = {} as Record<FeatureFlagName, boolean>;

  // Use Object.keys with proper typing
  (Object.keys(FEATURE_FLAGS) as FeatureFlagName[]).forEach(flagName => {
    result[flagName] = getFeatureFlag(flagName);
  });

  return result;
};

/**
 * Get feature flag configuration for debugging
 * @returns Complete feature flag configuration
 */
export const getFeatureFlagConfig = () => {
  return {
    flags: FEATURE_FLAGS,
    currentValues: getAllFeatureFlags(),
    environment: process.env.NODE_ENV,
    envValidation: validateEnvironment(),
  } as const;
};

// Export individual flag getters for convenience with proper typing
export const isHandHistoryAnalyzerEnabled = (): boolean =>
  getFeatureFlag('HAND_HISTORY_ANALYZER');
export const isTournamentModeEnabled = (): boolean =>
  getFeatureFlag('TOURNAMENT_MODE');
export const isCashGameModeEnabled = (): boolean =>
  getFeatureFlag('CASH_GAME_MODE');
export const isLiveModeEnabled = (): boolean => getFeatureFlag('LIVE_MODE');
export const isBlogEnabled = (): boolean => getFeatureFlag('BLOG');

// Export feature flag names for use in components with proper typing
export const FEATURE_FLAG_NAMES: Record<FeatureFlagName, FeatureFlagName> = {
  HAND_HISTORY_ANALYZER: 'HAND_HISTORY_ANALYZER',
  TOURNAMENT_MODE: 'TOURNAMENT_MODE',
  CASH_GAME_MODE: 'CASH_GAME_MODE',
  LIVE_MODE: 'LIVE_MODE',
  BLOG: 'BLOG',
} as const;
