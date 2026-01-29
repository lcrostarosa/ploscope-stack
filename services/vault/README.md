# HashiCorp Vault Configuration

This directory contains the configuration for HashiCorp Vault integration with the PLO Solver application.

## Overview

HashiCorp Vault is used to securely store and manage environment variables, secrets, and configuration data for the PLO Solver application across different environments (development, staging, production).

## Directory Structure

```
server/vault/
├── README.md                 # This file
├── config/                   # Vault configuration files
│   ├── vault.hcl            # Main Vault server configuration
│   └── policies/            # Vault access policies
│       ├── plo-solver-policy.hcl
│       └── admin-policy.hcl
├── scripts/                  # Vault management scripts
│   ├── setup-vault.sh       # Initial Vault setup
│   ├── load-secrets.sh      # Load secrets from env files
│   ├── get-secrets.sh       # Retrieve secrets for application
│   └── rotate-secrets.sh    # Secret rotation utilities
├── docker-compose.yml       # Vault service definition
└── secrets/                 # Secret templates and examples
    ├── development.json
    ├── staging.json
    └── production.json
```

## Quick Start

### Option 1: Isolated Network (Recommended for Development)
```bash
# Start Vault in isolated network
make vault-network-isolated

# Initialize Vault
make vault-setup

# Load environment secrets
make vault-load-dev

# Connect application containers to Vault
make vault-connect-app

# Get secrets for application
make vault-get-dev > .env
```

### Option 2: Integrated Network (Easier Development)
```bash
# Start Vault integrated with app network
make vault-network-integrated

# Initialize Vault
make vault-setup

# Load environment secrets
make vault-load-dev

# Get secrets for application
make vault-get-dev > .env
```

### Option 3: Production Setup
```bash
# Start Vault in production mode (requires sudo)
sudo make vault-network-production

# Initialize Vault
make vault-setup

# Load environment secrets
make vault-load-production

# Get secrets for application
make vault-get-production > .env
```

### Option 4: External Vault
```bash
# Configure external Vault connection
make vault-network-external -- --vault-url https://vault.company.com --vault-token s.abc123

# Use external Vault
./scripts/use-external-vault.sh ./scripts/get-secrets.sh development
```

## Environment Variables

The following environment variables are managed by Vault:

### Core Application
- `NODE_ENV`, `FLASK_DEBUG`, `ENVIRONMENT`
- `SECRET_KEY`, `JWT_SECRET_KEY`
- `LOG_LEVEL`, `LOG_PATH`

### Database
- `DATABASE_URL`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `POSTGRES_DATA_PATH`, `POSTGRES_BACKUP_PATH`

### API & Frontend
- `REACT_APP_API_URL`, `FRONTEND_URL`
- `FRONTEND_DOMAIN`, `TRAEFIK_DOMAIN`

### OAuth & Authentication
- `REACT_APP_GOOGLE_CLIENT_ID`, `REACT_APP_FACEBOOK_APP_ID`
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`

### Stripe Integration
- `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRICE_*` variables

### Discourse Forum
- `DISCOURSE_URL`, `DISCOURSE_DOMAIN`
- `DISCOURSE_SSO_SECRET`, `DISCOURSE_WEBHOOK_SECRET`
- `DISCOURSE_DB_*` variables

### Analytics & Monitoring
- `REACT_APP_GA_MEASUREMENT_ID`
- `NEW_RELIC_*` variables
- `REACT_APP_CLARITY_*`, `REACT_APP_POSTHOG_*` variables

### Feature Flags
- `REACT_APP_FEATURE_*_ENABLED` variables

## Security Best Practices

1. **Never commit secrets to version control**
2. **Use different secrets for each environment**
3. **Rotate secrets regularly**
4. **Use least-privilege access policies**
5. **Enable audit logging**
6. **Use Vault's transit engine for encryption**

## Network Configurations

### Isolated Network (Default)
- Vault runs in its own Docker network (`plo-solver-vault-network`)
- Applications must be explicitly connected to access Vault
- Best for security and isolation
- Use `make vault-connect-app` to connect applications

### Integrated Network
- Vault runs in both its own network and the main app network
- Applications can access Vault via `http://vault:8200`
- Easier for development but less secure
- Good for local development

### Production Network
- Vault runs with enhanced security settings
- Data stored in `/var/lib/vault/data`
- Uses production-grade security options
- Requires root privileges for setup

### External Vault
- Connect to an existing Vault instance
- Useful for enterprise environments
- Supports remote Vault clusters
- Configure with URL and token

## Environment Management

The Vault setup includes comprehensive environment management for development, staging, and production:

### Quick Environment Setup

```bash
# Development environment
make vault-env-setup development

# Staging environment  
make vault-env-setup staging --network production

# Production environment
make vault-env-setup production --network production
```

### Environment Operations

```bash
# Load secrets for environment
make vault-env-load <environment>

# Deploy with Vault integration
make vault-env-deploy <environment>

# Validate environment configuration
make vault-env-validate <environment>

# Compare environments
make vault-env-compare staging production
```

### Advanced Environment Management

For detailed environment management, see [ENVIRONMENT_MANAGEMENT.md](ENVIRONMENT_MANAGEMENT.md)

## Integration with Application

The application can be configured to use Vault in several ways:

1. **Environment File Generation**: Use `get-secrets.sh` to generate `.env` files
2. **Direct Vault Integration**: Use Vault client libraries in the application
3. **Docker Secrets**: Mount Vault secrets as Docker secrets
4. **Python Integration**: Use the `vault_utils.py` module in the backend
5. **Environment Management**: Use the comprehensive environment management scripts

## Troubleshooting

- Check Vault logs: `docker-compose logs vault`
- Verify Vault status: `vault status`
- Test authentication: `vault login`
- List secrets: `vault kv list secret/plo-solver/`

## Documentation

For detailed information about Vault setup and usage, see the documentation in the `/docs` directory:

- **[Main Documentation](docs/README.md)** - Comprehensive guide to Vault setup and usage
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Essential commands and workflows
- **[Setup Summary](docs/SETUP_SUMMARY.md)** - Overview of completed tasks and features 