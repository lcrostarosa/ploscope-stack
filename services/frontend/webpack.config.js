const _fs = require('fs');
const path = require('path');

const CopyWebpackPlugin = require('copy-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const webpack = require('webpack');

// Load environment variables from .env file
require('dotenv').config();

// Import logger utility
const { logError, logWarn, logDebug } = require('./src/utils/logger');

// Always use the public directory inside the frontend source tree
const publicPath = path.resolve(__dirname, 'src/public');

// Environment variable validation
const validateEnvironmentVariables = () => {
  // Required variables - build will fail if these are missing
  const requiredVars = ['NODE_ENV', 'REACT_APP_API_URL'];

  // Critical feature flags that should be explicitly set
  const criticalFeatureFlags = [
    'REACT_APP_FEATURE_TRAINING_MODE_ENABLED',
    'REACT_APP_FEATURE_SOLVER_MODE_ENABLED',
    'REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED',
    'REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED',
    'REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED',
    'REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED',
  ];

  // Analytics and monitoring variables that should be validated
  const analyticsVars = [
    'REACT_APP_GA_MEASUREMENT_ID',
    'REACT_APP_ENABLE_GA',
    // Meta Pixel
    'REACT_APP_META_PIXEL_ID',
    'REACT_APP_ENABLE_META',
    // Faro
    'REACT_APP_ENABLE_FARO',
    'REACT_APP_FARO_URL',
    'REACT_APP_FARO_APP_NAME',
  ];

  // New Relic monitoring variables
  const _newRelicVars = ['REACT_APP_VERSION'];

  // OAuth and authentication variables
  const _authVars = [];

  // Check for missing required variables
  const missingRequired = requiredVars.filter(varName => !process.env[varName]);

  if (missingRequired.length > 0) {
    logError('❌ Missing required environment variables:');
    missingRequired.forEach(varName => {
      logError(`   - ${varName}`);
    });
    logError(
      '\n💡 Please set these variables in your .env file or environment.'
    );
    process.exit(1);
  }

  // Validate feature flag values
  const invalidFeatureFlags = [];
  criticalFeatureFlags.forEach(varName => {
    const value = process.env[varName];
    if (value !== undefined && value !== 'true' && value !== 'false') {
      invalidFeatureFlags.push(
        `${varName}=${value} (must be 'true' or 'false')`
      );
    }
  });

  if (invalidFeatureFlags.length > 0) {
    logError('❌ Invalid feature flag values:');
    invalidFeatureFlags.forEach(flag => {
      logError(`   - ${flag}`);
    });
    logError('\n💡 Feature flags must be set to "true" or "false".');
    process.exit(1);
  }

  // Validate analytics configuration
  const analyticsWarnings = [];
  analyticsVars.forEach(varName => {
    const value = process.env[varName];
    if (
      varName.includes('ENABLE_') &&
      value !== undefined &&
      value !== 'true' &&
      value !== 'false'
    ) {
      analyticsWarnings.push(
        `${varName}=${value} (should be 'true' or 'false')`
      );
    }
    if (
      varName === 'REACT_APP_FARO_URL' &&
      process.env.REACT_APP_ENABLE_FARO === 'true' &&
      !value
    ) {
      analyticsWarnings.push(
        'Faro is enabled but REACT_APP_FARO_URL is missing'
      );
    }
  });

  if (analyticsWarnings.length > 0) {
    logWarn('⚠️  Analytics configuration warnings:');
    analyticsWarnings.forEach(warning => {
      logWarn(`   - ${warning}`);
    });
  }

  logDebug('✅ Environment variables validated successfully');
  logDebug(`📊 Environment: ${process.env.NODE_ENV}`);
  logDebug(`🔗 API URL: ${process.env.REACT_APP_API_URL}`);

  // Log feature flag status
  const enabledFeatures = criticalFeatureFlags.filter(
    varName => process.env[varName] === 'true'
  );
  if (enabledFeatures.length > 0) {
    logDebug(
      `🚀 Enabled features: ${enabledFeatures.map(f => f.replace('REACT_APP_FEATURE_', '').replace('_ENABLED', '')).join(', ')}`
    );
  }
};

// Run validation
validateEnvironmentVariables();

// Resolve devServer proxy target dynamically from REACT_APP_API_URL
// If REACT_APP_API_URL is absolute (e.g. https://staging.ploscope.com/api),
// we proxy to its origin so that relative "/api" requests hit the correct backend.
const proxyTarget = (() => {
  const apiUrl = process.env.REACT_APP_API_URL;
  if (apiUrl && /^https?:\/\//.test(apiUrl)) {
    try {
      const urlObj = new URL(apiUrl);
      return `${urlObj.protocol}//${urlObj.host}`;
    } catch (_err) {
      // fall through to default
    }
  }
  return 'http://localhost:5001';
})();

logDebug(`🧩 devServer proxy target: ${proxyTarget}`);

module.exports = {
  entry: './src/index.tsx',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js',
    chunkFilename: '[name].[contenthash].chunk.js',
    publicPath: '/',
    clean: true,
  },
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
          priority: 10,
        },
        common: {
          name: 'common',
          minChunks: 2,
          chunks: 'all',
          priority: 5,
          reuseExistingChunk: true,
        },
      },
    },
    runtimeChunk: 'single',
    moduleIds: 'deterministic',
  },
  module: {
    rules: [
      {
        test: /\.(ts|tsx|js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
      {
        test: /\.mdx?$/,
        use: [
          {
            loader: 'babel-loader',
          },
          {
            loader: '@mdx-js/loader',
            options: {
              // Keep minimal: authors export metadata via `export const meta = {}` in MDX
            },
          },
        ],
      },
      {
        test: /\.css$/,
        use: [
          process.env.NODE_ENV === 'production'
            ? MiniCssExtractPlugin.loader
            : 'style-loader',
          'css-loader',
        ],
      },
      {
        test: /\.scss$/,
        use: [
          process.env.NODE_ENV === 'production'
            ? MiniCssExtractPlugin.loader
            : 'style-loader',
          'css-loader',
          {
            loader: 'sass-loader',
            options: {
              sassOptions: {
                // Silence deprecation warnings for mixed declarations after nested rules
                // See https://sass-lang.com/d/mixed-decls
                silenceDeprecations: ['mixed-decls'],
              },
            },
          },
        ],
      },
      {
        test: /\.(png|jpg|jpeg|gif|svg)$/,
        type: 'asset/resource',
        generator: {
          filename: 'assets/[name].[hash][ext]',
        },
      },
    ],
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.jsx', '.md', '.mdx'],
    modules: [path.resolve(__dirname, 'src'), 'node_modules'],
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
    fallback: {
      http: require.resolve('stream-http'),
      https: require.resolve('https-browserify'),
      stream: require.resolve('stream-browserify'),
      zlib: require.resolve('browserify-zlib'),
      util: require.resolve('util/'),
      url: require.resolve('url/'),
      crypto: require.resolve('crypto-browserify'),
      assert: require.resolve('assert/'),
      buffer: require.resolve('buffer/'),
      events: require.resolve('events/'),
      fs: false,
      path: false,
      os: false,
    },
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.resolve(publicPath, 'index.html'),
    }),
    new CopyWebpackPlugin({
      patterns: [
        { from: path.resolve(publicPath, '*.svg'), to: '[name][ext]' },
        { from: path.resolve(publicPath, 'favicon.ico'), to: 'favicon.ico' },
        { from: path.resolve(publicPath, 'favicon*.png'), to: '[name][ext]' },
        {
          from: path.resolve(publicPath, 'og-preview.png'),
          to: 'og-preview.png',
        },
      ],
    }),
    new webpack.DefinePlugin({
      'process.env': (() => {
        const envVars = {};

        // Set NODE_ENV
        envVars.NODE_ENV = JSON.stringify(
          process.env.NODE_ENV || 'development'
        );

        // Get all environment variables that start with REACT_APP_
        Object.keys(process.env).forEach(key => {
          if (key.startsWith('REACT_APP_')) {
            envVars[key] = JSON.stringify(process.env[key]);
          }
        });

        return envVars;
      })(),
    }),
    new webpack.ProvidePlugin({
      process: 'process/browser.js',
      Buffer: ['buffer', 'Buffer'],
    }),
    ...(process.env.NODE_ENV === 'production'
      ? [
          new MiniCssExtractPlugin({
            filename: '[name].[contenthash].css',
            chunkFilename: '[name].[contenthash].chunk.css',
          }),
        ]
      : []),
  ],
  devServer: {
    static: { directory: publicPath },
    historyApiFallback: true,
    port: 3001,
    host: '0.0.0.0',
    hot: true,
    liveReload: true,
    watchFiles: {
      paths: ['src/**/*'],
      options: {
        usePolling: true,
        interval: 1000,
      },
    },
    proxy: [
      {
        context: [
          '/api',
          '/auth',
          '/spots',
          '/simulated-equity',
          '/spot-simulation',
          '/health',
          '/jobs',
        ],
        target: proxyTarget,
        changeOrigin: true,
        secure: false,
      },
    ],
  },
};
