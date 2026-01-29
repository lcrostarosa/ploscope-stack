# Vault Environment Management Guide

This guide explains how to manage different environments (development, staging, production) using HashiCorp Vault for the PLO Solver application.

## Overview

The Vault setup supports multiple environments with different configurations and security levels:

- **Development**: Local development with relaxed security
- **Staging**: Pre-production testing with production-like settings
- **Production**: Live environment with maximum security
- **Test**: Automated testing environment

## Environment Configurations

### Development Environment
- **Purpose**: Local development and testing
- **Security**: Relaxed (dev mode)
- **Network**: Isolated or integrated
- **Data**: Local file storage
- **Features**: All features enabled for testing

### Staging Environment
- **Purpose**: Pre-production testing
- **Security**: Production-like with test credentials
- **Network**: Isolated with production network settings
- **Data**: Separate staging database
- **Features**: Production features with test data

### Production Environment
- **Purpose**: Live application
- **Security**: Maximum security settings
- **Network**: Isolated with enterprise security
- **Data**: Production database with backups
- **Features**: Production features only

## Quick Start Commands

### Using Makefile (Recommended)

```bash
# Set up Vault for development
make vault-env-setup development

# Load development secrets
make vault-env-load development

# Deploy development environment
make vault-env-deploy development

# Set up Vault for staging
make vault-env-setup staging --network production

# Load staging secrets
make vault-env-load staging

# Deploy staging environment
make vault-env-deploy staging

# Set up Vault for production
make vault-env-setup production --network production

# Load production secrets
make vault-env-load production

# Deploy production environment
make vault-env-deploy production
```

### Using Direct Scripts

```bash
# Set up Vault for specific environment
cd server/vault
./scripts/manage-environments.sh setup production --network production

# Load secrets from env file
./scripts/manage-environments.sh load staging

# Get secrets for application
./scripts/manage-environments.sh get production > .env.production

# Deploy with Vault integration
./scripts/manage-environments.sh deploy staging
```

## Environment-Specific Commands

### Development Environment

```bash
# Quick development setup
make vault-network-integrated
make vault-setup
make vault-load-dev
make vault-connect-app
make vault-get-dev > .env

# Or use the comprehensive script
./scripts/manage-environments.sh setup development --network integrated
./scripts/manage-environments.sh deploy development
```

### Staging Environment

```bash
# Staging setup with production-like security
./scripts/manage-environments.sh setup staging --network production
./scripts/manage-environments.sh load staging
./scripts/manage-environments.sh validate staging
./scripts/manage-environments.sh deploy staging
```

### Production Environment

```bash
# Production setup with maximum security
sudo ./scripts/manage-environments.sh setup production --network production
./scripts/manage-environments.sh load production
./scripts/manage-environments.sh validate production
./scripts/manage-environments.sh deploy production
```

## Environment Management Operations

### Setup and Configuration

```bash
# Set up new environment
./scripts/manage-environments.sh setup <environment> [--network <type>]

# Load secrets from env file
./scripts/manage-environments.sh load <environment>

# Validate configuration
./scripts/manage-environments.sh validate <environment>
```

### Deployment

```bash
# Deploy application with Vault secrets
./scripts/manage-environments.sh deploy <environment> [--network <type>]

# Get secrets for manual deployment
./scripts/manage-environments.sh get <environment> --output .env.<environment>
```

### Backup and Recovery

```bash
# Backup environment secrets
./scripts/manage-environments.sh backup <environment>

# Restore from backup
./scripts/manage-environments.sh restore <environment> <backup-file>

# Compare environments
./scripts/manage-environments.sh compare staging production
```

### Maintenance

```bash
# Rotate secrets
./scripts/manage-environments.sh rotate <environment> [--force]

# Check environment status
./scripts/manage-environments.sh status <environment>

# List all environments
./scripts/manage-environments.sh list
```

## Environment Variables by Environment

### Development Variables
- `NODE_ENV=development`
- `FLASK_DEBUG=true`
- `LOG_LEVEL=DEBUG`
- `FRONTEND_DOMAIN=localhost`
- `TRAEFIK_HTTPS_ENABLED=false`
- Test Stripe keys
- Local database

### Staging Variables
- `NODE_ENV=staging`
- `FLASK_DEBUG=false`
- `LOG_LEVEL=INFO`
- `FRONTEND_DOMAIN=staging.plosolver.com`
- `TRAEFIK_HTTPS_ENABLED=true`
- Test Stripe keys
- Staging database

### Production Variables
- `NODE_ENV=production`
- `FLASK_DEBUG=false`
- `LOG_LEVEL=WARN`
- `FRONTEND_DOMAIN=plosolver.com`
- `TRAEFIK_HTTPS_ENABLED=true`
- Live Stripe keys
- Production database

## Security Considerations

### Development
- Dev mode enabled
- Local file storage
- Test credentials
- Debug logging enabled

### Staging
- Production-like security
- Separate test credentials
- Audit logging enabled
- HTTPS required

### Production
- Maximum security settings
- Encrypted storage
- Live credentials
- Minimal logging
- Secret rotation required

## Network Configurations

### Isolated Network (Recommended)
```bash
# Applications must be explicitly connected
./scripts/manage-environments.sh setup production --network isolated
./scripts/connect-app-to-vault.sh connect-all
```

### Integrated Network (Development)
```bash
# Applications can access Vault directly
./scripts/manage-environments.sh setup development --network integrated
```

### Production Network (Enterprise)
```bash
# Enhanced security with production settings
sudo ./scripts/manage-environments.sh setup production --network production
```

## Troubleshooting

### Common Issues

1. **Vault not accessible**
   ```bash
   # Check Vault status
   ./scripts/manage-environments.sh status <environment>
   
   # Restart Vault
   make vault-stop
   make vault-start
   ```

2. **Secrets not found**
   ```bash
   # Check if secrets are loaded
   ./scripts/manage-environments.sh validate <environment>
   
   # Reload secrets
   ./scripts/manage-environments.sh load <environment>
   ```

3. **Application can't connect to Vault**
   ```bash
   # Check network connections
   ./scripts/connect-app-to-vault.sh list-connections
   
   # Reconnect applications
   ./scripts/connect-app-to-vault.sh connect-all
   ```

### Validation Commands

```bash
# Validate environment configuration
./scripts/manage-environments.sh validate <environment>

# Check Vault health
curl http://localhost:8200/v1/sys/health

# List all secrets
./scripts/rotate-secrets.sh list-secrets <environment>
```

## Best Practices

1. **Environment Isolation**: Keep environments completely separate
2. **Secret Rotation**: Regularly rotate secrets in production
3. **Backup Strategy**: Backup secrets before major changes
4. **Validation**: Always validate configuration before deployment
5. **Network Security**: Use isolated networks for production
6. **Monitoring**: Monitor Vault health and access logs
7. **Documentation**: Document environment-specific configurations

## CI/CD Integration

### GitHub Actions Example

```yaml
# Load staging secrets for testing
- name: Load Staging Secrets
  run: |
    cd server/vault
    ./scripts/manage-environments.sh load staging
    ./scripts/manage-environments.sh get staging > .env.staging

# Deploy to staging
- name: Deploy to Staging
  run: |
    cd server/vault
    ./scripts/manage-environments.sh deploy staging
```

### Production Deployment

```yaml
# Production deployment with secret validation
- name: Validate Production
  run: |
    cd server/vault
    ./scripts/manage-environments.sh validate production

- name: Deploy to Production
  run: |
    cd server/vault
    ./scripts/manage-environments.sh deploy production
```

## Migration from Environment Files

If you're migrating from traditional `.env` files:

1. **Backup existing secrets**
   ```bash
   cp env.production env.production.backup
   ```

2. **Load into Vault**
   ```bash
   ./scripts/manage-environments.sh load production
   ```

3. **Validate migration**
   ```bash
   ./scripts/manage-environments.sh validate production
   ```

4. **Update deployment scripts**
   ```bash
   # Replace env file usage with Vault
   ./scripts/manage-environments.sh get production > .env
   ```

This comprehensive environment management system provides enterprise-grade secret management with the flexibility to handle different deployment scenarios and security requirements. 