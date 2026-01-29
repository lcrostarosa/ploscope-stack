# syntax=docker/dockerfile:1.4
# Multi-stage build for frontend - OPTIMIZED
FROM node:24-bullseye AS builder

WORKDIR /app


# Accept build arguments with default values
ARG NODE_ENV=production
ARG REACT_APP_API_URL=/api
ARG REACT_APP_GA_MEASUREMENT_ID=G-XXXXXXXXXX
ARG REACT_APP_CLARITY_PROJECT_ID=xxxxxxxxxx
ARG REACT_APP_POSTHOG_API_KEY=placeholder-posthog-key
ARG REACT_APP_POSTHOG_HOST=https://app.posthog.com
ARG REACT_APP_ENABLE_GA=false
ARG REACT_APP_ENABLE_CLARITY=false
ARG REACT_APP_ENABLE_POSTHOG=false
ARG REACT_APP_VERSION=1.0.0
ARG REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false
ARG REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
ARG REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=false
ARG REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=false
ARG REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED=false
ARG REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED=false

# Set environment variables from build arguments
ENV NODE_ENV=$NODE_ENV
ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV REACT_APP_GA_MEASUREMENT_ID=$REACT_APP_GA_MEASUREMENT_ID
ENV REACT_APP_CLARITY_PROJECT_ID=$REACT_APP_CLARITY_PROJECT_ID
ENV REACT_APP_POSTHOG_API_KEY=$REACT_APP_POSTHOG_API_KEY
ENV REACT_APP_POSTHOG_HOST=$REACT_APP_POSTHOG_HOST
ENV REACT_APP_ENABLE_GA=$REACT_APP_ENABLE_GA
ENV REACT_APP_ENABLE_CLARITY=$REACT_APP_ENABLE_CLARITY
ENV REACT_APP_ENABLE_POSTHOG=$REACT_APP_ENABLE_POSTHOG
ENV REACT_APP_VERSION=$REACT_APP_VERSION
ENV REACT_APP_FEATURE_TRAINING_MODE_ENABLED=$REACT_APP_FEATURE_TRAINING_MODE_ENABLED
ENV REACT_APP_FEATURE_SOLVER_MODE_ENABLED=$REACT_APP_FEATURE_SOLVER_MODE_ENABLED
ENV REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=$REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED
ENV REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=$REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED
ENV REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED=$REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED
ENV REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED=$REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED

# Copy package files first for better caching (context is src/frontend)
COPY package*.json ./

# Install dependencies with cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.npm \
    npm ci --include=dev --no-audit --no-fund

# Copy source code
COPY . ./
# Public assets now live within the frontend source tree at ./public

# Build the application with cache mount
RUN --mount=type=cache,target=/app/.next/cache \
    npm run build

# Production stage
FROM node:24-alpine AS production

WORKDIR /app

# Install only serve for serving static files
RUN npm install -g serve

# Create non-root user for production
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist

# Set permissions
RUN chown -R nextjs:nodejs /app
USER nextjs

# Health check for production
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Expose port
EXPOSE 3000

# Start serve with proper static file configuration
CMD ["serve", "-s", "dist", "-l", "3000", "--no-clipboard", "--no-compression", "--cors"]