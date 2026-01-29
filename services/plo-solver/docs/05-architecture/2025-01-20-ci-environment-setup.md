# CI Environment Setup for GitHub Actions

## Overview

This document describes the setup of a CI environment in GitHub that uses the `env.development` values for all CI/CD workflows.

## What We've Accomplished

### 1. Updated Workflow Files

All major workflow files have been updated to use the `ci` environment:

#### `.github/workflows/release.yml`
- **Job**: `deploy-release`
- **Environment**: `ci`
- **Changes**: 
  - Added `environment: ci` declaration
  - Updated to use environment variables: `${{ vars.ENVIRONMENT }}`, `${{ vars.FRONTEND_URL }}`
  - Updated to use environment secrets: `${{ secrets.DB_PASSWORD }}`, `${{ secrets.SECRET_KEY }}`, etc.

#### `.github/workflows/performance.yml`
- **Job**: `lighthouse-audit`
- **Environment**: `ci`
- **Changes**:
  - Added `environment: ci` declaration
  - Updated frontend environment variables to use `${{ vars.* }}` syntax with fallbacks

#### `.github/workflows/ci.yml`
- **Jobs**: `frontend-test`, `backend-test`
- **Environment**: `ci`
- **Changes**:
  - Added `environment: ci` declaration to both jobs
  - Updated frontend environment variables to use `${{ vars.* }}` syntax with fallbacks

#### `.github/workflows/security.yml`
- **Job**: `static-analysis`
- **Environment**: `ci`
- **Changes**:
  - Added `environment: ci` declaration

### 2. Created Setup Scripts

#### `scripts/setup/setup-ci-environment.sh`
- Automated script to create CI environment and set variables
- Handles GitHub CLI authentication and repository detection
- Sets all variables from `env.development`

#### `scripts/ci/set-ci-variables.sh`
- Script to set environment variables after manual environment creation
- Reads from `env.development` and sets each variable
- Provides validation and error handling

#### `scripts/setup/setup-ci-environment-manual.md`
- Manual setup guide for creating the CI environment
- Step-by-step instructions for GitHub UI
- Complete list of variables and secrets needed

## Environment Variables Used

The CI environment uses all variables from `env.development`:

### Core Configuration
- `NODE_ENV=development`
- `FLASK_DEBUG=true`
- `ENVIRONMENT=development`
- `BUILD_ENV=development`

### Domain & API
- `FRONTEND_DOMAIN=localhost`
- `TRAEFIK_DOMAIN=localhost`
- `REACT_APP_API_URL=/api`
- `FRONTEND_URL=http://localhost:3000`

### Database
- `POSTGRES_USER=postgres`
- `POSTGRES_PASSWORD=postgres`
- `POSTGRES_DB=plosolver`

### Security
- `SECRET_KEY=dev-secret-key-change-in-production`
- `JWT_SECRET_KEY=your-jwt-secret-key-here`

### Feature Flags
- `REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false`
- `REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true`
- `REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=false`
- `REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=false`

### Stripe Configuration
- `STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here`
- `STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here`
- `STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here`

## Required Secrets

The following secrets need to be set in the CI environment:

- `GITHUB_TOKEN` (usually auto-provided)
- `DB_PASSWORD=postgres`
- `SECRET_KEY=dev-secret-key-change-in-production`
- `JWT_SECRET_KEY=your-jwt-secret-key-here`
- `STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here`
- `STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here`
- `STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here`

## How to Set Up the CI Environment

### Option 1: Manual Setup (Recommended)

1. Go to GitHub repository: https://github.com/lcrostarosa/plo-solver
2. Navigate to Settings → Environments
3. Click "New environment"
4. Name it: `ci`
5. Leave protection rules unchecked
6. Click "Configure environment"
7. Add all variables from `env.development`
8. Add required secrets
9. Run `./scripts/set-ci-variables.sh` to set variables programmatically

### Option 2: Automated Setup

```bash
# Run the automated setup script
./scripts/setup-ci-environment.sh
```

## Benefits of This Setup

### 1. Environment Consistency
- All CI workflows use the same environment variables
- Consistent with development environment
- Easy to maintain and update

### 2. Security
- Sensitive values stored as secrets
- Environment-specific configuration
- No hardcoded values in workflows

### 3. Flexibility
- Easy to switch between different environment configurations
- Environment variables can be updated without code changes
- Fallback values for missing variables

### 4. Maintainability
- Single source of truth for environment configuration
- Automated setup scripts
- Clear documentation

## Workflow Integration

### Accessing Environment Variables

In workflows, environment variables are accessed using:

```yaml
env:
  MY_VAR: ${{ vars.MY_VAR || 'default_value' }}
```

### Accessing Environment Secrets

Secrets are accessed using:

```yaml
env:
  MY_SECRET: ${{ secrets.MY_SECRET }}
```

### Environment Declaration

Jobs that need the CI environment declare it:

```yaml
jobs:
  my-job:
    runs-on: self-hosted
    environment: ci
    steps:
      # ... job steps
```

## Troubleshooting

### Common Issues

1. **"Value 'ci' is not valid" error**
   - Ensure the CI environment exists in GitHub
   - Check environment name is exactly `ci` (lowercase)
   - Verify you have correct permissions

2. **Environment variables not found**
   - Check that variables are set in the CI environment
   - Verify variable names match exactly
   - Use fallback values in workflows

3. **Secrets not accessible**
   - Ensure secrets are set in the CI environment
   - Check that workflows have correct permissions
   - Verify secret names match exactly

### Validation

To validate the setup:

```bash
# Check if environment exists
gh api "repos/lcrostarosa/plo-solver/environments/ci"

# List environment variables
gh api "repos/lcrostarosa/plo-solver/environments/ci/variables"

# List environment secrets
gh api "repos/lcrostarosa/plo-solver/environments/ci/secrets"
```

## Next Steps

1. **Create the CI environment** in GitHub UI
2. **Set environment variables** using the provided script
3. **Set required secrets** manually in GitHub UI
4. **Test workflows** to ensure they can access the environment
5. **Monitor workflows** to verify they're using correct values

## Related Documentation

- [CI Environment Integration Guide](./2025-01-20-ci-environment-integration.md)
- [Environment Variables Documentation](../../frontend/ENVIRONMENT_VARIABLES.md)
- [Development Setup Guide](../02-setup/2025-06-20-setup-guide.md) 