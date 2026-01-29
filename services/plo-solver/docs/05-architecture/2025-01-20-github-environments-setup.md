# GitHub Environments Setup Guide

This guide explains how to set up GitHub environments for the PLO Solver project using automated scripts.

## Overview

GitHub Environments provide a way to configure deployment settings, protection rules, and environment-specific secrets. This project includes two scripts to automate the setup process:

1. **`setup-github-environments.sh`** - Creates and configures environments
2. **`setup-github-secrets.sh`** - Manages environment secrets

## Prerequisites

### 1. GitHub CLI Installation

Install the GitHub CLI (`gh`) on your system:

```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Windows (with Chocolatey)
choco install gh

# Or download from: https://cli.github.com/
```

### 2. Authentication

Authenticate with GitHub:

```bash
gh auth login
```

Follow the prompts to authenticate with your GitHub account.

### 3. Repository Access

Ensure you have admin access to the repository where you want to set up environments.

## Environment Structure

The project supports three environments:

| Environment | Purpose | Protection | Wait Timer | Required Reviewers |
|-------------|---------|------------|------------|-------------------|
| `development` | Local testing and development | No | 0 minutes | None |
| `staging` | Pre-production testing | Yes | 5 minutes | `lucascrostarosa` |
| `production` | Live deployment | Yes | 10 minutes | `lucascrostarosa` |

## Quick Start

### 1. Set Up All Environments

```bash
# Create all environments with basic configuration
./scripts/setup-github-environments.sh --all

# Create environments only (skip variables and secrets)
./scripts/setup-github-environments.sh --create-only --all
```

### 2. Set Up Specific Environments

```bash
# Set up staging and production only
./scripts/setup-github-environments.sh staging production

# Set up development environment only
./scripts/setup-github-environments.sh development
```

### 3. Configure Secrets

```bash
# Set secrets from environment file
./scripts/setup-github-secrets.sh staging --file env.staging

# Set secrets interactively
./scripts/setup-github-secrets.sh production --interactive

# Set specific secrets
./scripts/setup-github-secrets.sh staging DB_PASSWORD=mypass API_KEY=abc123
```

## Detailed Usage

### Environment Setup Script

#### Basic Commands

```bash
# Show help
./scripts/setup-github-environments.sh --help

# List existing environments
./scripts/setup-github-environments.sh --list

# Validate environment configuration
./scripts/setup-github-environments.sh --validate staging

# Set up all environments
./scripts/setup-github-environments.sh --all

# Set up specific environments
./scripts/setup-github-environments.sh development staging
```

#### Options

- `-h, --help` - Show help message
- `-l, --list` - List all existing environments
- `-v, --validate` - Validate existing environments
- `-a, --all` - Set up all environments (development, staging, production)
- `-c, --create-only` - Only create environments, skip variables and secrets
- `-f, --force` - Force recreation of existing environments

### Secrets Setup Script

#### Basic Commands

```bash
# Show help
./scripts/setup-github-secrets.sh --help

# List secrets for an environment
./scripts/setup-github-secrets.sh staging --list

# Set secrets from file
./scripts/setup-github-secrets.sh staging --file env.staging

# Set secrets interactively
./scripts/setup-github-secrets.sh production --interactive

# Set specific secrets
./scripts/setup-github-secrets.sh staging DB_PASSWORD=mypass API_KEY=abc123

# Delete a secret
./scripts/setup-github-secrets.sh staging --delete OLD_SECRET
```

#### Options

- `-h, --help` - Show help message
- `-l, --list` - List all secrets for the specified environment
- `-f, --file FILE` - Set secrets from environment file
- `-i, --interactive` - Set secrets interactively (prompt for each value)
- `-d, --delete SECRET` - Delete a specific secret
- `-a, --all` - Set all common secrets for the environment

## Environment Configuration

### Development Environment

- **Protection**: None
- **Wait Timer**: 0 minutes
- **Required Reviewers**: None
- **Common Secrets**: `GITHUB_TOKEN`, `DB_PASSWORD`

### Staging Environment

- **Protection**: Enabled
- **Wait Timer**: 5 minutes
- **Required Reviewers**: `lucascrostarosa`
- **Common Secrets**: `GITHUB_TOKEN`, `STAGING_DEPLOY_KEY`, `STAGING_DB_PASSWORD`, `STRIPE_SECRET_KEY`

### Production Environment

- **Protection**: Enabled
- **Wait Timer**: 10 minutes
- **Required Reviewers**: `lucascrostarosa`
- **Common Secrets**: `GITHUB_TOKEN`, `PRODUCTION_DEPLOY_KEY`, `PRODUCTION_DB_PASSWORD`, `STRIPE_SECRET_KEY`, `JWT_SECRET_KEY`

## Environment Variables

Each environment is configured with specific variables:

### Development
- `ENVIRONMENT=development`
- `FRONTEND_URL=http://localhost:3000`

### Staging
- `ENVIRONMENT=staging`
- `FRONTEND_URL=https://staging.plosolver.com`

### Production
- `ENVIRONMENT=production`
- `FRONTEND_URL=https://plosolver.com`

## Protection Rules

Protected environments have the following rules:

1. **Wait Timer**: Prevents immediate deployment (5-10 minutes)
2. **Required Reviewers**: Requires approval from specified users
3. **Deployment Branch Policy**: Only allows deployments from the `main` branch

## Workflow Integration

### Using Environments in GitHub Actions

```yaml
# Example workflow using environments
name: Deploy to Staging

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: self-hosted
    environment: staging  # This will trigger protection rules
    
    steps:
    - name: Deploy
      run: echo "Deploying to staging..."
```

### Environment-Specific Variables

```yaml
# Access environment variables in workflows
- name: Use environment variable
  run: echo "Environment: ${{ vars.ENVIRONMENT }}"
  env:
    ENVIRONMENT: ${{ vars.ENVIRONMENT }}
```

### Environment-Specific Secrets

```yaml
# Access environment secrets in workflows
- name: Use environment secret
  run: echo "Using secret..."
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

## Common Workflows

### Complete Setup for New Repository

```bash
# 1. Set up all environments
./scripts/setup-github-environments.sh --all

# 2. Set secrets for staging
./scripts/setup-github-secrets.sh staging --file env.staging

# 3. Set secrets for production interactively
./scripts/setup-github-secrets.sh production --interactive

# 4. Validate setup
./scripts/setup-github-environments.sh --validate staging
./scripts/setup-github-environments.sh --validate production
```

### Update Environment Configuration

```bash
# Update protection rules and variables
./scripts/setup-github-environments.sh staging production

# Update secrets from files
./scripts/setup-github-secrets.sh staging --file env.staging
./scripts/setup-github-secrets.sh production --file env.production
```

### Add New Secret

```bash
# Add a new secret interactively
./scripts/setup-github-secrets.sh production --interactive

# Or add specific secret
./scripts/setup-github-secrets.sh production NEW_SECRET=value
```

## Troubleshooting

### Common Issues

#### 1. GitHub CLI Not Installed

```bash
# Install GitHub CLI
brew install gh  # macOS
sudo apt install gh  # Ubuntu
```

#### 2. Not Authenticated

```bash
# Authenticate with GitHub
gh auth login
```

#### 3. Insufficient Permissions

Ensure you have admin access to the repository. You need:
- `repo` scope for private repositories
- `public_repo` scope for public repositories

#### 4. Environment Already Exists

The script will update existing environments. If you want to recreate:

```bash
# Delete and recreate (manual process)
gh api --method DELETE "repos/OWNER/REPO/environments/ENVIRONMENT_NAME"
./scripts/setup-github-environments.sh ENVIRONMENT_NAME
```

#### 5. Secret Already Exists

The script will update existing secrets. To delete first:

```bash
./scripts/setup-github-secrets.sh ENVIRONMENT_NAME --delete SECRET_NAME
./scripts/setup-github-secrets.sh ENVIRONMENT_NAME SECRET_NAME=new_value
```

### Debugging

#### Enable Debug Output

```bash
# Set debug mode for GitHub CLI
export GH_DEBUG=1

# Run script with debug
./scripts/setup-github-environments.sh --all
```

#### Check Environment Status

```bash
# List all environments
./scripts/setup-github-environments.sh --list

# Validate specific environment
./scripts/setup-github-environments.sh --validate staging

# List secrets for environment
./scripts/setup-github-secrets.sh staging --list
```

## Security Best Practices

### 1. Secret Management

- Use interactive mode for sensitive secrets to avoid shell history
- Rotate secrets regularly
- Use environment-specific secrets
- Never commit secrets to version control

### 2. Access Control

- Limit environment access to necessary users
- Use required reviewers for production deployments
- Implement wait timers for critical environments

### 3. Audit Trail

- Monitor environment deployments
- Review protection rule effectiveness
- Log secret access and changes

## Integration with CI/CD

### GitHub Actions Workflow Example

```yaml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v4
    - name: Run tests
      run: make test

  deploy-staging:
    needs: test
    runs-on: self-hosted
    if: github.ref == 'refs/heads/main'
    environment: staging
    
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to staging
      run: |
        echo "Deploying to staging..."
        echo "Environment: ${{ vars.ENVIRONMENT }}"
        # Add deployment logic here

  deploy-production:
    needs: [test, deploy-staging]
    runs-on: self-hosted
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    - name: Deploy to production
      run: |
        echo "Deploying to production..."
        echo "Environment: ${{ vars.ENVIRONMENT }}"
        # Add deployment logic here
```

## Maintenance

### Regular Tasks

1. **Monthly**: Review and rotate secrets
2. **Quarterly**: Update protection rules and reviewers
3. **As needed**: Add new environments or modify existing ones

### Monitoring

- Monitor deployment success rates
- Review protection rule effectiveness
- Track secret usage and access

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review GitHub CLI documentation: https://cli.github.com/
3. Check GitHub Environments documentation: https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment

## Script Maintenance

The scripts are located in the `scripts/` directory:

- `setup-github-environments.sh` - Main environment setup script
- `setup-github-secrets.sh` - Secrets management script

To modify environment configurations, edit the associative arrays at the top of each script:

```bash
# In setup-github-environments.sh
declare -A ENVIRONMENTS=(
    ["development"]="Development environment for local testing and development"
    ["staging"]="Staging environment for pre-production testing"
    ["production"]="Production environment for live deployment"
)
```

Remember to test changes in a development environment before applying to production. 