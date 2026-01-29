#!/bin/bash
# ===========================================
# CI Environment Variables Setup Commands
# ===========================================
# Run these commands to set CI environment variables
# Make sure you have the right permissions first

set -euo pipefail

echo "Setting CI environment variables for lcrostarosa/plo-solver"
echo

echo "Setting NODE_ENV..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/NODE_ENV" \
  --field value="development"
echo "✅ Set NODE_ENV"

echo "Setting FLASK_DEBUG..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/FLASK_DEBUG" \
  --field value="true"
echo "✅ Set FLASK_DEBUG"

echo "Setting ENVIRONMENT..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/ENVIRONMENT" \
  --field value="development"
echo "✅ Set ENVIRONMENT"

echo "Setting BUILD_ENV..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/BUILD_ENV" \
  --field value="development"
echo "✅ Set BUILD_ENV"

echo "Setting VOLUME_MODE..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/VOLUME_MODE" \
  --field value="rw"
echo "✅ Set VOLUME_MODE"

echo "Setting RESTART_POLICY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/RESTART_POLICY" \
  --field value="unless-stopped"
echo "✅ Set RESTART_POLICY"

echo "Setting FRONTEND_DOMAIN..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/FRONTEND_DOMAIN" \
  --field value="localhost"
echo "✅ Set FRONTEND_DOMAIN"

echo "Setting TRAEFIK_DOMAIN..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/TRAEFIK_DOMAIN" \
  --field value="localhost"
echo "✅ Set TRAEFIK_DOMAIN"

echo "Setting TRAEFIK_DASHBOARD_ENABLED..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/TRAEFIK_DASHBOARD_ENABLED" \
  --field value="true"
echo "✅ Set TRAEFIK_DASHBOARD_ENABLED"

echo "Setting TRAEFIK_DASHBOARD_PORT..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/TRAEFIK_DASHBOARD_PORT" \
  --field value="8080"
echo "✅ Set TRAEFIK_DASHBOARD_PORT"

echo "Setting TRAEFIK_HTTPS_ENABLED..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/TRAEFIK_HTTPS_ENABLED" \
  --field value="false"
echo "✅ Set TRAEFIK_HTTPS_ENABLED"

echo "Setting TRAEFIK_HTTPS_PORT..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/TRAEFIK_HTTPS_PORT" \
  --field value="443"
echo "✅ Set TRAEFIK_HTTPS_PORT"

echo "Setting TRAEFIK_LOG_LEVEL..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/TRAEFIK_LOG_LEVEL" \
  --field value="INFO"
echo "✅ Set TRAEFIK_LOG_LEVEL"

echo "Setting ACME_EMAIL..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/ACME_EMAIL" \
  --field value="admin@example.com"
echo "✅ Set ACME_EMAIL"

echo "Setting REACT_APP_API_URL..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/REACT_APP_API_URL" \
  --field value="/api"
echo "✅ Set REACT_APP_API_URL"

echo "Setting REACT_APP_GOOGLE_CLIENT_ID..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/REACT_APP_GOOGLE_CLIENT_ID" \
  --field value="your-google-client-id"
echo "✅ Set REACT_APP_GOOGLE_CLIENT_ID"

echo "Setting REACT_APP_FACEBOOK_APP_ID..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/REACT_APP_FACEBOOK_APP_ID" \
  --field value="your-facebook-app-id"
echo "✅ Set REACT_APP_FACEBOOK_APP_ID"

echo "Setting POSTGRES_USER..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/POSTGRES_USER" \
  --field value="postgres"
echo "✅ Set POSTGRES_USER"

echo "Setting POSTGRES_PASSWORD..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/POSTGRES_PASSWORD" \
  --field value="postgres"
echo "✅ Set POSTGRES_PASSWORD"

echo "Setting POSTGRES_DB..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/POSTGRES_DB" \
  --field value="plosolver"
echo "✅ Set POSTGRES_DB"

echo "Setting SECRET_KEY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/SECRET_KEY" \
  --field value="dev-secret-key-change-in-production"
echo "✅ Set SECRET_KEY"

echo "Setting JWT_SECRET_KEY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/JWT_SECRET_KEY" \
  --field value="your-jwt-secret-key-here"
echo "✅ Set JWT_SECRET_KEY"

echo "Setting LOG_LEVEL..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/LOG_LEVEL" \
  --field value="DEBUG"
echo "✅ Set LOG_LEVEL"

echo "Setting FRONTEND_URL..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/FRONTEND_URL" \
  --field value="http://localhost:3000"
echo "✅ Set FRONTEND_URL"

echo "Setting DISCOURSE_ENABLED..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_ENABLED" \
  --field value="true"
echo "✅ Set DISCOURSE_ENABLED"

echo "Setting DISCOURSE_URL..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_URL" \
  --field value="http://localhost:4080"
echo "✅ Set DISCOURSE_URL"

echo "Setting DISCOURSE_DOMAIN..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_DOMAIN" \
  --field value="forum.localhost"
echo "✅ Set DISCOURSE_DOMAIN"

echo "Setting DISCOURSE_PORT..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_PORT" \
  --field value="4080"
echo "✅ Set DISCOURSE_PORT"

echo "Setting DISCOURSE_VERSION..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_VERSION" \
  --field value="2.0.20241202-1135"
echo "✅ Set DISCOURSE_VERSION"

echo "Setting DISCOURSE_SSO_SECRET..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_SSO_SECRET" \
  --field value="36241cd9e33f8dbe7d768ff97164bc181a9070f0fc5bcc4e91ba5fef998b39c0"
echo "✅ Set DISCOURSE_SSO_SECRET"

echo "Setting DISCOURSE_WEBHOOK_SECRET..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_WEBHOOK_SECRET" \
  --field value="your-discourse-webhook-secret-here"
echo "✅ Set DISCOURSE_WEBHOOK_SECRET"

echo "Setting DISCOURSE_DB_PASSWORD..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_DB_PASSWORD" \
  --field value="discourse_secure_password"
echo "✅ Set DISCOURSE_DB_PASSWORD"

echo "Setting DISCOURSE_DEVELOPER_EMAILS..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/DISCOURSE_DEVELOPER_EMAILS" \
  --field value="admin@plosolver.local"
echo "✅ Set DISCOURSE_DEVELOPER_EMAILS"

echo "Setting STRIPE_SECRET_KEY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_SECRET_KEY" \
  --field value="sk_test_your_stripe_secret_key_here"
echo "✅ Set STRIPE_SECRET_KEY"

echo "Setting STRIPE_PUBLISHABLE_KEY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_PUBLISHABLE_KEY" \
  --field value="pk_test_your_stripe_publishable_key_here"
echo "✅ Set STRIPE_PUBLISHABLE_KEY"

echo "Setting STRIPE_WEBHOOK_SECRET..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_WEBHOOK_SECRET" \
  --field value="whsec_your_webhook_secret_here"
echo "✅ Set STRIPE_WEBHOOK_SECRET"

echo "Setting STRIPE_PRICE_PRO_MONTHLY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_PRICE_PRO_MONTHLY" \
  --field value="price_1234567890abcdef"
echo "✅ Set STRIPE_PRICE_PRO_MONTHLY"

echo "Setting STRIPE_PRICE_PRO_YEARLY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_PRICE_PRO_YEARLY" \
  --field value="price_1234567890abcdef"
echo "✅ Set STRIPE_PRICE_PRO_YEARLY"

echo "Setting STRIPE_PRICE_ELITE_MONTHLY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_PRICE_ELITE_MONTHLY" \
  --field value="price_1234567890abcdef"
echo "✅ Set STRIPE_PRICE_ELITE_MONTHLY"

echo "Setting STRIPE_PRICE_ELITE_YEARLY..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/STRIPE_PRICE_ELITE_YEARLY" \
  --field value="price_1234567890abcdef"
echo "✅ Set STRIPE_PRICE_ELITE_YEARLY"

echo "Setting REACT_APP_FEATURE_TRAINING_MODE_ENABLED..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/REACT_APP_FEATURE_TRAINING_MODE_ENABLED" \
  --field value="false"
echo "✅ Set REACT_APP_FEATURE_TRAINING_MODE_ENABLED"

echo "Setting REACT_APP_FEATURE_SOLVER_MODE_ENABLED..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/REACT_APP_FEATURE_SOLVER_MODE_ENABLED" \
  --field value="true"
echo "✅ Set REACT_APP_FEATURE_SOLVER_MODE_ENABLED"

echo "Setting REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED..."
gh api --method PUT "repos/lcrostarosa/plo-solver/environments/ci/variables/REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED" \
  --field value="false"
echo "✅ Set REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED"

echo "🎉 Set 43 CI environment variables successfully!"
echo
echo "Next steps:"
echo "1. Set required secrets in GitHub UI:"
echo "   https://github.com/lcrostarosa/plo-solver/settings/environments/ci"
echo "2. Test the CI pipeline"
