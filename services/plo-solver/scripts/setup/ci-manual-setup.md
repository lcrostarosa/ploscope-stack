# Manual CI Environment Setup

## Repository: lcrostarosa/plo-solver

## Step 1: Create CI Environment (if not exists)

1. Go to: https://github.com/lcrostarosa/plo-solver/settings/environments
2. Click "New environment"
3. Name: `ci`
4. Leave protection rules unchecked
5. Click "Configure environment"

## Step 2: Set Environment Variables

### Option A: Use Generated Script
```bash
./ci-variables-commands.sh
```

### Option B: Manual Setup
Go to: https://github.com/lcrostarosa/plo-solver/settings/environments/ci

Add these variables from `env.development`:

- `NODE_ENV` = `development`
- `FLASK_DEBUG` = `true`
- `ENVIRONMENT` = `development`
- `BUILD_ENV` = `development`
- `VOLUME_MODE` = `rw`
- `RESTART_POLICY` = `unless-stopped`
- `FRONTEND_DOMAIN` = `localhost`
- `TRAEFIK_DOMAIN` = `localhost`
- `TRAEFIK_DASHBOARD_ENABLED` = `true`
- `TRAEFIK_DASHBOARD_PORT` = `8080`
- `TRAEFIK_HTTPS_ENABLED` = `false`
- `TRAEFIK_HTTPS_PORT` = `443`
- `TRAEFIK_LOG_LEVEL` = `INFO`
- `ACME_EMAIL` = `admin@example.com`
- `REACT_APP_API_URL` = `/api`
- `REACT_APP_GOOGLE_CLIENT_ID` = `your-google-client-id`
- `REACT_APP_FACEBOOK_APP_ID` = `your-facebook-app-id`
- `POSTGRES_USER` = `postgres`
- `POSTGRES_PASSWORD` = `postgres`
- `POSTGRES_DB` = `plosolver`
- `SECRET_KEY` = `dev-secret-key-change-in-production`
- `JWT_SECRET_KEY` = `your-jwt-secret-key-here`
- `LOG_LEVEL` = `DEBUG`
- `FRONTEND_URL` = `http://localhost:3000`
- `DISCOURSE_ENABLED` = `true`
- `DISCOURSE_URL` = `http://localhost:4080`
- `DISCOURSE_DOMAIN` = `forum.localhost`
- `DISCOURSE_PORT` = `4080`
- `DISCOURSE_VERSION` = `2.0.20241202-1135`
- `DISCOURSE_SSO_SECRET` = `36241cd9e33f8dbe7d768ff97164bc181a9070f0fc5bcc4e91ba5fef998b39c0`
- `DISCOURSE_WEBHOOK_SECRET` = `your-discourse-webhook-secret-here`
- `DISCOURSE_DB_PASSWORD` = `discourse_secure_password`
- `DISCOURSE_DEVELOPER_EMAILS` = `admin@plosolver.local`
- `STRIPE_SECRET_KEY` = `sk_test_your_stripe_secret_key_here`
- `STRIPE_PUBLISHABLE_KEY` = `pk_test_your_stripe_publishable_key_here`
- `STRIPE_WEBHOOK_SECRET` = `whsec_your_webhook_secret_here`
- `STRIPE_PRICE_PRO_MONTHLY` = `price_1234567890abcdef`
- `STRIPE_PRICE_PRO_YEARLY` = `price_1234567890abcdef`
- `STRIPE_PRICE_ELITE_MONTHLY` = `price_1234567890abcdef`
- `STRIPE_PRICE_ELITE_YEARLY` = `price_1234567890abcdef`
- `REACT_APP_FEATURE_TRAINING_MODE_ENABLED` = `false`
- `REACT_APP_FEATURE_SOLVER_MODE_ENABLED` = `true`
- `REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED` = `false`

## Step 3: Set Environment Secrets

### Option A: Use Generated Script
```bash
./ci-secrets-commands.sh
```

### Option B: Manual Setup
Go to: https://github.com/lcrostarosa/plo-solver/settings/environments/ci

Add these secrets:

- `DB_PASSWORD` = `postgres`
- `SECRET_KEY` = `dev-secret-key-change-in-production`
- `JWT_SECRET_KEY` = `your-jwt-secret-key-here`
- `STRIPE_SECRET_KEY` = `sk_test_your_stripe_secret_key_here`
- `STRIPE_PUBLISHABLE_KEY` = `pk_test_your_stripe_publishable_key_here`
- `STRIPE_WEBHOOK_SECRET` = `whsec_your_webhook_secret_here`

## Step 4: Verify Setup

1. Check that all variables and secrets are set
2. Test a workflow that uses the `ci` environment
3. Monitor the workflow to ensure it uses correct values

## Troubleshooting

If you get permission errors:
1. Ensure you have admin access to the repository
2. Check that your GitHub token has the right scopes
3. Try setting variables manually in the GitHub UI
