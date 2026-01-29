#!/bin/bash
# ===========================================
# CI Environment Secrets Setup Commands
# ===========================================
# Run these commands to set CI environment secrets
# You'll need to provide the actual secret values

set -euo pipefail

echo "Setting CI environment secrets for lcrostarosa/plo-solver"
echo "Note: You'll need to provide the actual secret values"
echo

echo "Setting DB_PASSWORD..."
echo "Enter value for DB_PASSWORD (default: postgres):"
read -p "> " secret_value
if [[ -z "$secret_value" ]]; then
  secret_value="postgres"
fi
gh secret set DB_PASSWORD --env ci --body "$secret_value"
echo "✅ Set DB_PASSWORD"

echo "Setting SECRET_KEY..."
echo "Enter value for SECRET_KEY (default: dev-secret-key-change-in-production):"
read -p "> " secret_value
if [[ -z "$secret_value" ]]; then
  secret_value="dev-secret-key-change-in-production"
fi
gh secret set SECRET_KEY --env ci --body "$secret_value"
echo "✅ Set SECRET_KEY"

echo "Setting JWT_SECRET_KEY..."
echo "Enter value for JWT_SECRET_KEY (default: your-jwt-secret-key-here):"
read -p "> " secret_value
if [[ -z "$secret_value" ]]; then
  secret_value="your-jwt-secret-key-here"
fi
gh secret set JWT_SECRET_KEY --env ci --body "$secret_value"
echo "✅ Set JWT_SECRET_KEY"

echo "Setting STRIPE_SECRET_KEY..."
echo "Enter value for STRIPE_SECRET_KEY (default: sk_test_your_stripe_secret_key_here):"
read -p "> " secret_value
if [[ -z "$secret_value" ]]; then
  secret_value="sk_test_your_stripe_secret_key_here"
fi
gh secret set STRIPE_SECRET_KEY --env ci --body "$secret_value"
echo "✅ Set STRIPE_SECRET_KEY"

echo "Setting STRIPE_PUBLISHABLE_KEY..."
echo "Enter value for STRIPE_PUBLISHABLE_KEY (default: pk_test_your_stripe_publishable_key_here):"
read -p "> " secret_value
if [[ -z "$secret_value" ]]; then
  secret_value="pk_test_your_stripe_publishable_key_here"
fi
gh secret set STRIPE_PUBLISHABLE_KEY --env ci --body "$secret_value"
echo "✅ Set STRIPE_PUBLISHABLE_KEY"

echo "Setting STRIPE_WEBHOOK_SECRET..."
echo "Enter value for STRIPE_WEBHOOK_SECRET (default: whsec_your_webhook_secret_here):"
read -p "> " secret_value
if [[ -z "$secret_value" ]]; then
  secret_value="whsec_your_webhook_secret_here"
fi
gh secret set STRIPE_WEBHOOK_SECRET --env ci --body "$secret_value"
echo "✅ Set STRIPE_WEBHOOK_SECRET"

echo "🎉 Set all CI environment secrets successfully!"
echo
echo "Next steps:"
echo "1. Test the CI pipeline"
echo "2. Monitor workflows to ensure they use the correct environment values"
