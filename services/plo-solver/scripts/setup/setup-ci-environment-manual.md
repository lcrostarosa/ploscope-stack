# Manual CI Environment Setup Guide

Since the automated script is having issues with repository access, here's how to set up the CI environment manually:

## Step 1: Create the CI Environment

1. Go to your GitHub repository: https://github.com/lcrostarosa/plo-solver
2. Navigate to Settings → Environments
3. Click "New environment"
4. Name it: `ci`
5. Leave protection rules unchecked (since this is for CI)
6. Click "Configure environment"

## Step 2: Set Environment Variables

Add the following variables from `env.development`:

### Core Environment Variables
- `NODE_ENV` = `development`
- `FLASK_DEBUG` = `true`
- `ENVIRONMENT` = `development`
- `BUILD_ENV` = `development`
- `VOLUME_MODE` = `rw`
- `RESTART_POLICY` = `unless-stopped`

### Domain Configuration
- `FRONTEND_DOMAIN` = `localhost`
- `TRAEFIK_DOMAIN` = `localhost`

### Traefik Configuration
- `TRAEFIK_DASHBOARD_ENABLED` = `true`
- `TRAEFIK_DASHBOARD_PORT` = `8080`
- `TRAEFIK_HTTPS_ENABLED` = `false`
- `TRAEFIK_HTTPS_PORT` = `443`
- `TRAEFIK_LOG_LEVEL` = `INFO`
- `ACME_EMAIL` = `admin@example.com`

### API Configuration
- `REACT_APP_API_URL` = `/api`

### OAuth Configuration
- `REACT_APP_GOOGLE_CLIENT_ID` = `your-google-client-id`
- `REACT_APP_FACEBOOK_APP_ID` = `your-facebook-app-id`

### Database Configuration
- `POSTGRES_USER` = `postgres`
- `POSTGRES_PASSWORD` = `postgres`
- `POSTGRES_DB` = `plosolver`

### Security
- `SECRET_KEY` = `dev-secret-key-change-in-production`
- `JWT_SECRET_KEY` = `your-jwt-secret-key-here`

### Flask Configuration
- `LOG_LEVEL` = `DEBUG`
- `FRONTEND_URL` = `http://localhost:3000`

### Forum Configuration
- `DISCOURSE_ENABLED` = `true`
- `DISCOURSE_URL` = `http://localhost:4080`
- `DISCOURSE_DOMAIN` = `forum.localhost`
- `DISCOURSE_PORT` = `4080`
- `DISCOURSE_VERSION` = `2.0.20241202-1135`
- `DISCOURSE_SSO_SECRET` = `36241cd9e33f8dbe7d768ff97164bc181a9070f0fc5bcc4e91ba5fef998b39c0`
- `DISCOURSE_WEBHOOK_SECRET` = `your-discourse-webhook-secret-here`
- `DISCOURSE_DB_PASSWORD` = `discourse_secure_password`
- `DISCOURSE_DEVELOPER_EMAILS` = `admin@plosolver.local`

### Stripe Configuration
- `STRIPE_SECRET_KEY` = `sk_test_your_stripe_secret_key_here`
- `STRIPE_PUBLISHABLE_KEY` = `pk_test_your_stripe_publishable_key_here`
- `STRIPE_WEBHOOK_SECRET` = `whsec_your_webhook_secret_here`
- `STRIPE_PRICE_PRO_MONTHLY` = `price_1234567890abcdef`
- `STRIPE_PRICE_PRO_YEARLY` = `price_1234567890abcdef`
- `STRIPE_PRICE_ELITE_MONTHLY` = `price_1234567890abcdef`
- `STRIPE_PRICE_ELITE_YEARLY` = `price_1234567890abcdef`

### Feature Flags
- `REACT_APP_FEATURE_TRAINING_MODE_ENABLED` = `false`
- `REACT_APP_FEATURE_SOLVER_MODE_ENABLED` = `true`
- `REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED` = `false`
- `REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED` = `false`

## Step 3: Set Environment Secrets

Add the following secrets (you'll need to provide actual values):

### Required Secrets
- `GITHUB_TOKEN` (usually auto-provided)
- `DB_PASSWORD` = `postgres`
- `SECRET_KEY` = `dev-secret-key-change-in-production`
- `JWT_SECRET_KEY` = `your-jwt-secret-key-here`
- `STRIPE_SECRET_KEY` = `sk_test_your_stripe_secret_key_here`
- `STRIPE_PUBLISHABLE_KEY` = `pk_test_your_stripe_publishable_key_here`
- `STRIPE_WEBHOOK_SECRET` = `whsec_your_webhook_secret_here`

## Step 4: Verify Setup

After setting up the environment:

1. Go to Settings → Environments → ci
2. Verify all variables and secrets are set
3. Test by running a workflow that uses the `ci` environment

## Step 5: Update Workflows

The workflows have already been updated to use the `ci` environment:

- `.github/workflows/release.yml` - Uses `environment: ci` for deployment
- `.github/workflows/performance.yml` - Uses `environment: ci` for performance testing
- `.github/workflows/ci.yml` - Uses `environment: ci` for frontend and backend testing
- `.github/workflows/security.yml` - Uses `environment: ci` for security analysis

## Troubleshooting

If you get "Value 'ci' is not valid" errors in the workflow linter:
1. Make sure the CI environment exists in GitHub
2. Check that you have the correct permissions
3. Verify the environment name is exactly `ci` (lowercase)

## Next Steps

Once the environment is set up:
1. Commit and push the updated workflow files
2. Test the workflows to ensure they can access the environment variables
3. Monitor the workflows to ensure they're using the correct environment values 