# GitHub Variables and Secrets Setup

This document explains how to configure GitHub Variables and Secrets for the PLOSolver application workflows.

## Overview

GitHub Actions can read configuration from two sources:
- **Variables** (`${{ vars.VARIABLE_NAME }}`): For non-sensitive configuration
- **Secrets** (`${{ secrets.SECRET_NAME }}`): For sensitive data like tokens, passwords

## Setting Up GitHub Variables

### 1. Access Repository Settings

1. Go to your GitHub repository
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **Variables** tab

### 2. Configure Required Variables

Add these variables to your repository:

#### Core Configuration Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `NODE_ENV` | `production` | Node.js environment |
| `REACT_APP_API_URL` | `/api` | API endpoint for frontend |
| `BUILD_ENV` | `production` | Build environment for Docker |

#### Feature Flag Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `REACT_APP_FEATURE_TRAINING_MODE_ENABLED` | `false` | Enable training mode |
| `REACT_APP_FEATURE_SOLVER_MODE_ENABLED` | `true` | Enable solver mode |
| `REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED` | `false` | Enable player profiles |
| `REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED` | `false` | Enable hand history analyzer |
| `REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED` | `true` | Enable tournament mode |
| `REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED` | `false` | Enable cash game mode |
| `REACT_APP_FEATURE_CUSTOM_MODE_ENABLED` | `false` | Enable custom mode |

#### Environment-Specific Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `STAGING_FRONTEND_DOMAIN` | `ploscope.com` | Staging frontend domain |
| `STAGING_TRAEFIK_DOMAIN` | `ploscope.com` | Staging Traefik domain |
| `PRODUCTION_FRONTEND_DOMAIN` | `ploscope.com` | Production frontend domain |
| `PRODUCTION_TRAEFIK_DOMAIN` | `ploscope.com` | Production Traefik domain |
| `ACME_EMAIL` | `admin@crostamusic.com` | Email for Let's Encrypt certificates |

#### Test Environment Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `TEST_NODE_ENV` | `test` | Node.js environment for tests |
| `TEST_REACT_APP_API_URL` | `/api` | API endpoint for frontend tests |
| `TEST_REACT_APP_FEATURE_SOLVER_MODE_ENABLED` | `true` | Enable solver mode in tests |
| `TEST_REACT_APP_FEATURE_TRAINING_MODE_ENABLED` | `false` | Enable training mode in tests |

### 3. Adding Variables

1. Click **New repository variable**
2. Enter the **Name** and **Value**
3. Click **Add variable**

## Setting Up GitHub Secrets

### 1. Access Repository Secrets

1. Go to your GitHub repository
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **Secrets** tab

### 2. Configure Required Secrets

Add these secrets to your repository:

#### Deployment Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `STAGING_HOST` | Staging server IP/hostname | `192.168.1.100` |
| `STAGING_USER` | Staging server username | `deploy` |
| `STAGING_PATH` | Path to app on staging server | `/opt/plosolver` |
| `STAGING_SSH_KEY` | SSH private key for staging | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `PRODUCTION_HOST` | Production server IP/hostname | `192.168.1.200` |
| `PRODUCTION_USER` | Production server username | `deploy` |
| `PRODUCTION_PATH` | Path to app on production server | `/opt/plosolver` |
| `PRODUCTION_SSH_KEY` | SSH private key for production | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

#### OAuth Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | `123456789-abc.apps.googleusercontent.com` |
| `FACEBOOK_APP_ID` | Facebook OAuth app ID | `123456789012345` |

#### Database Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `POSTGRES_PASSWORD` | PostgreSQL password | `secure_password_123` |
| `SECRET_KEY` | Flask secret key | `your-super-secret-key-here` |
| `JWT_SECRET_KEY` | JWT signing key | `your-jwt-secret-key-here` |

#### External Service Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `NEW_RELIC_LICENSE_KEY` | New Relic license key | `abc123def456...` |
| `STRIPE_SECRET_KEY` | Stripe secret key | `sk_live_...` |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook secret | `whsec_...` |

### 3. Adding Secrets

1. Click **New repository secret**
2. Enter the **Name** and **Value**
3. Click **Add secret**

## Environment-Specific Configuration

### Test Environment Configuration

The project includes a `env.test` file for test environment variables. This file is used by:

1. **Local Development**: When running tests locally with `make test-unit` or `make test-frontend`
2. **CI/CD Pipelines**: GitHub Actions workflows load these variables for testing
3. **Test Scripts**: The test runner scripts automatically load `env.test` if available

#### Test Environment File Structure

```bash
# env.test
NODE_ENV=test
FLASK_ENV=testing
DATABASE_URL=postgresql://testuser:testpassword@localhost:5432/testdb
REACT_APP_API_URL=/api
REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
# ... other test-specific variables
```

#### Using Test Environment Variables in CI/CD

The CI workflow automatically sets test environment variables:

```yaml
- name: Set up test environment variables
  run: |
    echo "NODE_ENV=test" >> $GITHUB_ENV
    echo "REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || '/api' }}" >> $GITHUB_ENV
    echo "REACT_APP_FEATURE_SOLVER_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_SOLVER_MODE_ENABLED || 'true' }}" >> $GITHUB_ENV
    # ... other variables
```

### Using Environment Variables in Workflows

The workflows now use GitHub Variables with fallbacks:

```yaml
# Example from docker-build.yml
build-args: |
  NODE_ENV=${{ vars.NODE_ENV || 'production' }}
  REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || '/api' }}
  REACT_APP_FEATURE_SOLVER_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_SOLVER_MODE_ENABLED || 'true' }}
```

### Environment-Specific Variables

You can create environment-specific variables by prefixing them:

```yaml
# Staging-specific variables
STAGING_NODE_ENV=production
STAGING_REACT_APP_API_URL=/api

# Production-specific variables  
PRODUCTION_NODE_ENV=production
PRODUCTION_REACT_APP_API_URL=/api
```

## Workflow Usage Examples

### 1. Docker Build Workflow

```yaml
- name: Build frontend image
  uses: docker/build-push-action@v5
  with:
    build-args: |
      NODE_ENV=${{ vars.NODE_ENV || 'production' }}
      REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || '/api' }}
      REACT_APP_FEATURE_SOLVER_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_SOLVER_MODE_ENABLED || 'true' }}
```

### 2. Deployment Workflow

```yaml
- name: Deploy to staging
  run: |
    echo "Deploying to ${{ secrets.STAGING_HOST }}"
    ssh ${{ secrets.STAGING_USER }}@${{ secrets.STAGING_HOST }} \
      "cd ${{ secrets.STAGING_PATH }} && docker compose up -d"
```

### 3. Environment-Specific Deployment

```yaml
- name: Deploy with environment variables
  run: |
    FRONTEND_DOMAIN=${{ vars.STAGING_FRONTEND_DOMAIN }} \
    TRAEFIK_DOMAIN=${{ vars.STAGING_TRAEFIK_DOMAIN }} \
    docker compose --env-file env.staging up -d
```

## Best Practices

### 1. Variable Naming

- Use descriptive names: `REACT_APP_API_URL` not `API_URL`
- Use consistent casing: `UPPER_SNAKE_CASE`
- Prefix environment-specific variables: `STAGING_`, `PRODUCTION_`

### 2. Security

- **Never** put secrets in Variables (use Secrets instead)
- **Never** commit secrets to version control
- Rotate secrets regularly
- Use least-privilege access for deployment keys

### 3. Organization

- Group related variables together
- Use consistent naming patterns
- Document all variables and their purposes
- Keep variables up to date

### 4. Fallbacks

Always provide fallback values in workflows:

```yaml
# Good: Has fallback
NODE_ENV=${{ vars.NODE_ENV || 'production' }}

# Bad: No fallback
NODE_ENV=${{ vars.NODE_ENV }}
```

## Troubleshooting

### Common Issues

#### 1. Variable Not Found

**Problem:** `${{ vars.MY_VARIABLE }}` returns empty

**Solution:**
- Check if variable exists in repository settings
- Verify variable name spelling
- Add fallback value: `${{ vars.MY_VARIABLE || 'default' }}`

#### 2. Secret Not Accessible

**Problem:** Secret not available in workflow

**Solution:**
- Check if secret exists in repository settings
- Verify workflow has correct permissions
- Check if secret is in the right environment

#### 3. Environment Variables Not Set

**Problem:** Environment variables not available in containers

**Solution:**
- Pass variables as build args in Docker builds
- Set environment variables in docker-compose files
- Use GitHub Variables in workflow steps

### Debugging Commands

```bash
# Check if variable is set
echo "NODE_ENV: ${{ vars.NODE_ENV }}"

# Check with fallback
echo "NODE_ENV: ${{ vars.NODE_ENV || 'not set' }}"

# List all environment variables
env | sort
```

## Migration from Hardcoded Values

### Before (Hardcoded)
```yaml
build-args: |
  NODE_ENV=production
  REACT_APP_API_URL=/api
```

### After (GitHub Variables)
```yaml
build-args: |
  NODE_ENV=${{ vars.NODE_ENV || 'production' }}
  REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || '/api' }}
```

### Migration Steps

1. **Add Variables**: Create all required variables in GitHub
2. **Update Workflows**: Replace hardcoded values with `${{ vars.VARIABLE_NAME }}`
3. **Add Fallbacks**: Include fallback values for all variables
4. **Test**: Run workflows to ensure variables are read correctly
5. **Document**: Update documentation with new variable requirements

## Environment-Specific Setup

### Development Environment

For local development, create a `.env.local` file:

```bash
# .env.local
NODE_ENV=development
REACT_APP_API_URL=http://localhost:5001/api
REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
```

### Staging Environment

Set these GitHub Variables for staging:

```bash
NODE_ENV=production
REACT_APP_API_URL=/api
REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false
```

### Production Environment

Set these GitHub Variables for production:

```bash
NODE_ENV=production
REACT_APP_API_URL=/api
REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false
```

## Security Considerations

### 1. Secret Management

- Use GitHub Secrets for all sensitive data
- Never expose secrets in logs or outputs
- Rotate secrets regularly
- Use environment-specific secrets when possible

### 2. Variable Security

- Variables are visible in workflow logs
- Don't put sensitive data in variables
- Use variables only for non-sensitive configuration

### 3. Access Control

- Limit who can view/edit secrets and variables
- Use repository environments for additional security
- Audit secret and variable access regularly

## References

- [GitHub Variables Documentation](https://docs.github.com/en/actions/learn-github-actions/variables)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)