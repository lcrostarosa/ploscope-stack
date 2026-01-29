# Environment Variables Setup Guide

## Overview

This guide explains how to properly set up and use environment variables in the PLO Solver project to keep secrets secure and manage different environments.

## Security Best Practices

1. **Never commit secrets to git** - All environment files with secrets are ignored by `.gitignore`
2. **Use templates** - Template files are provided for each environment
3. **Generate secure secrets** - Use the provided script to generate cryptographically secure secrets
4. **Rotate secrets regularly** - Change production secrets periodically
5. **Use different secrets per environment** - Never reuse secrets between environments

## Environment Files Structure

```
├── env.example              # Example template (committed to git)
├── env.development          # Development environment (committed to git)
├── env.test                 # Test environment (committed to git)
├── env.production.template  # Production template (committed to git)
├── env.production          # Production environment (NOT committed - contains secrets)
├── env.staging.template    # Staging template (committed to git)
└── env.staging             # Staging environment (NOT committed - contains secrets)
```

## Setting Up Production Environment

### Step 1: Create Production Environment File

```bash
# Copy the template to create your production environment file
cp env.production.template env.production
```

### Step 2: Generate Secure Secrets

```bash
# Run the secrets generator script
./scripts/setup/generate-production-secrets.sh
```

This will output secure random secrets that you can copy into your `env.production` file.

### Step 3: Update Production Environment File

Edit `env.production` and replace the placeholder values with:

1. **Your actual secrets** (from the generator script)
2. **Your domain names** (replace `your-production-domain.com`)
3. **Your API keys** (Stripe, New Relic, OAuth, etc.)
4. **Your email addresses**

### Step 4: Verify Setup

```bash
# Check that env.production is ignored by git
git check-ignore env.production

# Should output: env.production
```

## Docker Compose Integration

The `docker-compose.production.yml` file is configured to use environment variables from `env.production`:

```yaml
services:
  backend:
    env_file:
      - env.production
    environment:
      - PGPASSWORD=${POSTGRES_PASSWORD}
      - DATABASE_URL=${DATABASE_URL}
```

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `secure-password-32-chars` |
| `DATABASE_URL` | Full database connection string | `postgresql://user:pass@host:5432/db` |
| `SECRET_KEY` | Flask secret key | `64-character-random-string` |
| `JWT_SECRET_KEY` | JWT signing key | `64-character-random-string` |
| `RABBITMQ_DEFAULT_PASS` | RabbitMQ password | `32-character-random-string` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FRONTEND_DOMAIN` | Your production domain | `localhost` |
| `TRAEFIK_DOMAIN` | Traefik domain | `localhost` |
| `ACME_EMAIL` | Let's Encrypt email | `admin@domain.com` |
| `STRIPE_SECRET_KEY` | Stripe secret key | `sk_test_...` |
| `NEW_RELIC_LICENSE_KEY` | New Relic license key | `your-key` |

## Development vs Production

### Development
- Uses `env.development` (committed to git)
- Contains non-sensitive defaults
- Suitable for local development

### Production
- Uses `env.production` (NOT committed to git)
- Contains real secrets and production values
- Must be manually created from template

## Troubleshooting

### Common Issues

1. **Environment file not found**
   ```bash
   # Error: Could not find env.production
   # Solution: Copy from template
   cp env.production.template env.production
   ```

2. **Secrets not working**
   ```bash
   # Error: Database connection failed
   # Solution: Check DATABASE_URL format
   DATABASE_URL=postgresql://postgres:password@db:5432/plosolver
   ```

3. **Git trying to commit secrets**
   ```bash
   # Error: env.production shows in git status
   # Solution: Check .gitignore
   git check-ignore env.production
   ```

### Validation Script

Run this to validate your environment setup:

```bash
# Check if required variables are set
source env.production
echo "Database URL: $DATABASE_URL"
echo "Secret Key: ${SECRET_KEY:0:10}..."
echo "JWT Secret: ${JWT_SECRET_KEY:0:10}..."
```

## CI/CD Integration

For automated deployments, environment variables should be stored in your CI/CD system (GitHub Actions, GitLab CI, etc.) and injected during deployment.

### GitHub Actions Example

```yaml
- name: Deploy to Production
  env:
    POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
    SECRET_KEY: ${{ secrets.SECRET_KEY }}
    JWT_SECRET_KEY: ${{ secrets.JWT_SECRET_KEY }}
  run: |
    echo "$POSTGRES_PASSWORD" > env.production
    # ... deployment steps
```

## Security Checklist

- [ ] `env.production` is not committed to git
- [ ] Secrets are cryptographically secure (use generator script)
- [ ] Different secrets for each environment
- [ ] Secrets are rotated regularly
- [ ] Access to secrets is limited to authorized personnel
- [ ] Backup and recovery procedures for secrets
- [ ] Monitoring for unauthorized access attempts

## Related Documentation

- [Docker Setup Guide](../02-setup/2025-06-20-docker-setup.md)
- [Deployment Architecture](../04-deployment/2025-06-16-deployment-architecture.md)
- [CI Environment Setup](../05-architecture/2025-01-20-ci-environment-setup.md) 