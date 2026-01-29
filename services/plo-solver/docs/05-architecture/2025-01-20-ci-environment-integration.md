# CI Pipeline Environment Integration Guide

This guide explains how to ensure your CI pipeline jobs can access environment variables and secrets that are set up by the GitHub environment scripts.

## Overview

When you set up GitHub environments using the scripts, you create:
- **Environment Variables**: Non-sensitive configuration data
- **Environment Secrets**: Sensitive data like passwords and API keys
- **Protection Rules**: Deployment controls and approval workflows

Your CI pipeline can access these through GitHub Actions using specific syntax and environment declarations.

## Key Concepts

### 1. Environment Declaration
```yaml
jobs:
  deploy:
    environment: staging  # This gives access to staging environment variables/secrets
```

### 2. Variable Access
```yaml
# Access environment variables
${{ vars.VARIABLE_NAME }}

# With fallback values
${{ vars.VARIABLE_NAME || 'default_value' }}
```

### 3. Secret Access
```yaml
# Access environment secrets
${{ secrets.SECRET_NAME }}
```

## Integration Patterns

### Pattern 1: Environment-Specific Jobs

```yaml
jobs:
  deploy-staging:
    runs-on: self-hosted
    environment: staging  # Triggers protection rules
    steps:
    - name: Deploy
      env:
        ENVIRONMENT: ${{ vars.ENVIRONMENT }}
        FRONTEND_URL: ${{ vars.FRONTEND_URL }}
        DB_PASSWORD: ${{ secrets.STAGING_DB_PASSWORD }}
      run: |
        echo "Deploying to $ENVIRONMENT"
        echo "Frontend URL: $FRONTEND_URL"
```

### Pattern 2: Conditional Environment Access

```yaml
jobs:
  deploy:
    runs-on: self-hosted
    environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
    steps:
    - name: Deploy
      env:
        ENVIRONMENT: ${{ vars.ENVIRONMENT }}
        DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
      run: |
        echo "Deploying to $ENVIRONMENT"
```

### Pattern 3: Multi-Environment Workflow

```yaml
jobs:
  test:
    runs-on: self-hosted
    steps:
    - name: Test
      run: make test

  deploy-staging:
    needs: test
    runs-on: self-hosted
    environment: staging
    if: github.ref == 'refs/heads/develop'
    steps:
    - name: Deploy to staging
      env:
        ENVIRONMENT: ${{ vars.ENVIRONMENT }}
      run: echo "Deploying to staging"

  deploy-production:
    needs: [test, deploy-staging]
    runs-on: self-hosted
    environment: production
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to production
      env:
        ENVIRONMENT: ${{ vars.ENVIRONMENT }}
      run: echo "Deploying to production"
```

## Environment Variables Available

### Development Environment
```yaml
env:
  ENVIRONMENT: development
  FRONTEND_URL: http://localhost:3000
```

### Staging Environment
```yaml
env:
  ENVIRONMENT: staging
  FRONTEND_URL: https://staging.plosolver.com
```

### Production Environment
```yaml
env:
  ENVIRONMENT: production
  FRONTEND_URL: https://plosolver.com
```

## Secrets Available by Environment

### Development
- `GITHUB_TOKEN`
- `DB_PASSWORD`

### Staging
- `GITHUB_TOKEN`
- `STAGING_DEPLOY_KEY`
- `STAGING_DB_PASSWORD`
- `STRIPE_SECRET_KEY`

### Production
- `GITHUB_TOKEN`
- `PRODUCTION_DEPLOY_KEY`
- `PRODUCTION_DB_PASSWORD`
- `STRIPE_SECRET_KEY`
- `JWT_SECRET_KEY`

## Integration Examples

### 1. Frontend Build with Environment Variables

```yaml
- name: Build frontend
  env:
    NODE_ENV: production
    REACT_APP_API_URL: ${{ vars.REACT_APP_API_URL || '/api' }}
    REACT_APP_FEATURE_TRAINING_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_TRAINING_MODE_ENABLED || 'false' }}
    REACT_APP_FEATURE_SOLVER_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_SOLVER_MODE_ENABLED || 'true' }}
    REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED: ${{ vars.REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED || 'false' }}
    REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED: ${{ vars.REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED || 'false' }}
    REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED || 'false' }}
    REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED || 'false' }}
    REACT_APP_FEATURE_CUSTOM_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_CUSTOM_MODE_ENABLED || 'false' }}
  run: cd src/frontend && npm run build
```

### 2. Backend Deployment with Secrets

```yaml
- name: Deploy backend
  env:
    ENVIRONMENT: ${{ vars.ENVIRONMENT }}
    FRONTEND_URL: ${{ vars.FRONTEND_URL }}
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
    STRIPE_SECRET_KEY: ${{ secrets.STRIPE_SECRET_KEY }}
    JWT_SECRET_KEY: ${{ secrets.JWT_SECRET_KEY }}
  run: |
    echo "Deploying to $ENVIRONMENT"
    echo "Frontend URL: $FRONTEND_URL"
    # Add deployment logic here
```

### 3. Docker Build with Environment Variables

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
            file: ./src/backend/Dockerfile
    build-args: |
      BUILD_ENV=${{ vars.ENVIRONMENT }}
      REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || '/api' }}
    push: true
    tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME_BACKEND }}:${{ vars.ENVIRONMENT }}
```

### 4. SSH Deployment with Environment-Specific Keys

```yaml
- name: Setup SSH
  uses: webfactory/ssh-agent@v0.8.0
  with:
    ssh-private-key: ${{ secrets.STAGING_DEPLOY_KEY }}  # or PRODUCTION_DEPLOY_KEY

- name: Deploy
  env:
    ENVIRONMENT: ${{ vars.ENVIRONMENT }}
    FRONTEND_URL: ${{ vars.FRONTEND_URL }}
  run: |
    echo "Deploying to $ENVIRONMENT"
    # SSH deployment logic
```

## Protection Rules and Approval Workflow

### How Protection Rules Work

When you declare an environment in a job, GitHub enforces the protection rules:

```yaml
jobs:
  deploy-production:
    environment: production  # Triggers 10-minute wait timer + required reviewer approval
    steps:
    - name: Deploy
      run: echo "This will wait for approval"
```

### Approval Process

1. **Wait Timer**: Job waits for specified time (5-10 minutes)
2. **Review Required**: You must approve the deployment
3. **Branch Policy**: Only allows deployments from `main` branch

### Manual Approval

You can approve deployments:
- Via GitHub UI: Repository → Environments → Production → Review deployments
- Via GitHub CLI: `gh run watch` and approve when prompted

## Environment Validation

### Validate Environment Variables

```yaml
- name: Validate environment variables
  run: |
    echo "🔍 Validating environment variables..."
    
    if [ -n "${{ vars.ENVIRONMENT }}" ]; then
      echo "✅ ENVIRONMENT variable is set: ${{ vars.ENVIRONMENT }}"
    else
      echo "❌ ENVIRONMENT variable is not set"
      exit 1
    fi
    
    if [ -n "${{ vars.FRONTEND_URL }}" ]; then
      echo "✅ FRONTEND_URL variable is set: ${{ vars.FRONTEND_URL }}"
    else
      echo "❌ FRONTEND_URL variable is not set"
      exit 1
    fi
```

### Validate Environment Secrets

```yaml
- name: Validate environment secrets
  run: |
    echo "🔍 Validating environment secrets..."
    
    # Check if required secrets are available (without exposing values)
    if [ -n "${{ secrets.GITHUB_TOKEN }}" ]; then
      echo "✅ GITHUB_TOKEN secret is available"
    else
      echo "❌ GITHUB_TOKEN secret is not available"
      exit 1
    fi
    
    # Environment-specific secret validation
    if [ "${{ vars.ENVIRONMENT }}" = "staging" ]; then
      if [ -n "${{ secrets.STAGING_DEPLOY_KEY }}" ]; then
        echo "✅ STAGING_DEPLOY_KEY secret is available"
      else
        echo "❌ STAGING_DEPLOY_KEY secret is not available"
        exit 1
      fi
    fi
```

## Troubleshooting

### Common Issues

#### 1. Environment Variables Not Available

**Problem**: `${{ vars.VARIABLE_NAME }}` returns empty
**Solution**: 
- Ensure the environment is declared: `environment: staging`
- Check if variables are set in GitHub UI: Settings → Environments → Staging → Environment variables
- Use fallback values: `${{ vars.VARIABLE_NAME || 'default' }}`

#### 2. Secrets Not Available

**Problem**: `${{ secrets.SECRET_NAME }}` returns empty
**Solution**:
- Ensure the environment is declared: `environment: staging`
- Check if secrets are set in GitHub UI: Settings → Environments → Staging → Environment secrets
- Verify secret names match exactly (case-sensitive)

#### 3. Protection Rules Blocking Deployment

**Problem**: Deployment stuck waiting for approval
**Solution**:
- Go to GitHub UI: Repository → Environments → Environment Name → Review deployments
- Click "Review deployments" and approve
- Or use GitHub CLI: `gh run watch` and approve when prompted

#### 4. Environment Not Found

**Problem**: Error "Environment 'staging' not found"
**Solution**:
- Run the setup script: `./scripts/setup/setup-github-environments.sh staging`
- Check environment exists: `./scripts/setup/setup-github-environments.sh --list`

### Debug Environment Access

```yaml
- name: Debug environment access
  run: |
    echo "Environment: ${{ vars.ENVIRONMENT }}"
    echo "Frontend URL: ${{ vars.FRONTEND_URL }}"
    echo "GitHub Token available: ${{ secrets.GITHUB_TOKEN != '' && 'Yes' || 'No' }}"
    echo "Deploy Key available: ${{ secrets.STAGING_DEPLOY_KEY != '' && 'Yes' || 'No' }}"
```

## Best Practices

### 1. Environment Declaration
- Always declare the environment at the job level
- Use conditional logic for different environments
- Ensure environment names match exactly

### 2. Variable Access
- Use fallback values for optional variables
- Validate required variables before use
- Keep sensitive data in secrets, not variables

### 3. Secret Management
- Use environment-specific secrets
- Rotate secrets regularly
- Never log or expose secret values

### 4. Protection Rules
- Use protection rules for production environments
- Set appropriate wait timers
- Require reviewer approval for critical deployments

### 5. Validation
- Validate environment variables and secrets before deployment
- Use health checks after deployment
- Monitor deployment success rates

## Integration Checklist

Before deploying to production, ensure:

- [ ] Environments are set up: `./scripts/setup/setup-github-environments.sh --all`
- [ ] Secrets are configured: `./scripts/setup/setup-github-secrets.sh production --interactive`
- [ ] Environment variables are set in GitHub UI
- [ ] Protection rules are configured
- [ ] Workflow uses correct environment declarations
- [ ] Fallback values are provided for optional variables
- [ ] Validation steps are included
- [ ] Health checks are implemented

## Example Complete Workflow

See `/.github/workflows/environment-integration-example.yml` for a complete example that demonstrates all these patterns.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GitHub Environments documentation
3. Validate environment setup with the provided scripts
4. Check GitHub Actions logs for detailed error messages 