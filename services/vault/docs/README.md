# PLO Solver Vault Documentation

## Overview

This project uses **HashiCorp Vault** as the primary secrets management solution for the PLO Solver application. Vault provides secure storage, encryption, and access control for all sensitive configuration data across development, staging, and production environments.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Template      │    │   Environment   │    │   HashiCorp     │
│   Files         │    │   Files         │    │   Vault         │
│                 │    │                 │    │                 │
│ ✅ Git tracked  │    │ ❌ Git ignored  │    │ 🔐 Secure       │
│ ✅ Safe to      │    │ ✅ Real secrets │    │ ✅ Encrypted    │
│    commit       │    │ ✅ Loaded into  │    │ ✅ Access       │
│                 │    │    Vault        │    │    controlled   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### Bootstrap Development Environment

```bash
# Complete development setup
make dev

# Or step by step
make local
make setup
make create-env
```

### Load and Use Secrets

```bash
# Edit environment files with your secrets
nano env.local

# Load secrets into Vault
make ENVIRONMENT=local load

# Get secrets for your application
make ENVIRONMENT=local get-env
```

## Makefile Commands

### Environment Targets

| Command | Description |
|---------|-------------|
| `make local` | Start Vault in development mode |
| `make staging` | Start Vault in staging mode |
| `make production` | Start Vault in production mode |

### Workflow Targets

| Command | Description |
|---------|-------------|
| `make dev` | Bootstrap complete development environment |
| `make bootstrap` | Bootstrap development from scratch |
| `make stage` | Bootstrap staging environment |
| `make prod` | Bootstrap production environment |

### Operation Targets

| Command | Description |
|---------|-------------|
| `make setup` | Initialize Vault for current environment |
| `make load` | Load secrets for current environment |
| `make get` | Get secrets for current environment |
| `make get-env` | Get secrets and save to .env file |
| `make reset` | Reset Vault to development mode |
| `make clean` | Stop and remove Vault containers |
| `make migrate` | Migrate from JSON files to Vault |

### Utility Targets

| Command | Description |
|---------|-------------|
| `make status` | Check Vault status |
| `make list-secrets` | List secrets in Vault |
| `make logs` | Show Vault logs |
| `make validate` | Validate environment configuration |
| `make create-env` | Create environment files from templates |

## File Structure

### Template Files (Safe to Commit)
```
secrets/
├── development.template.json  # Development configuration template
├── staging.template.json      # Staging configuration template
└── production.template.json   # Production configuration template
```

### Environment Files (Git Ignored)
```
env.local        # Real development secrets
env.staging      # Real staging secrets
env.production   # Real production secrets
env.example      # Example file (safe to commit)
```

### Vault Storage
```
secret/plo-solver/development  # Development secrets in Vault
secret/plo-solver/staging      # Staging secrets in Vault
secret/plo-solver/production   # Production secrets in Vault
```

## Security Model

### Access Policies

#### Read-Only Policy (`plo-solver-policy`)
- **Purpose**: Application runtime access
- **Capabilities**: Read secrets, use transit encryption
- **Token**: `scripts/app-token.txt`

#### Write Policy (`plo-solver-write-policy`)
- **Purpose**: Loading and updating secrets
- **Capabilities**: Read/write secrets, use transit encryption
- **Token**: `scripts/write-token.txt`

#### Admin Policy (`admin-policy`)
- **Purpose**: Administrative operations
- **Capabilities**: Full access to Vault
- **Token**: `scripts/root-token.txt` (development only)

### Token Management

| Token Type | File | Usage | Permissions |
|------------|------|-------|-------------|
| Root Token | `scripts/root-token.txt` | Admin operations | Full access |
| Write Token | `scripts/write-token.txt` | Loading secrets | Read/write secrets |
| App Token | `scripts/app-token.txt` | Application runtime | Read-only |

## Environment Setup

### Development Environment

```bash
# Complete setup
make dev

# Access Vault UI
# URL: http://localhost:8200
# Token: plo-solver-dev-token
```

### Staging Environment

```bash
# Setup staging
make stage

# Requires external network: plo-solver-network
# Create network: docker network create plo-solver-network
```

### Production Environment

```bash
# Setup production (requires sudo)
make prod

# Requires:
# - sudo privileges
# - /var/lib/vault/data directory
# - Proper security configuration
```

## Secret Management

### Loading Secrets

```bash
# Edit environment file
nano env.local

# Load into Vault
make ENVIRONMENT=local load
```

### Retrieving Secrets

```bash
# Get secrets as environment variables
make ENVIRONMENT=local get

# Save to .env file
make ENVIRONMENT=local get-env
```

### Secret Rotation

```bash
# Rotate secrets for environment
make ENVIRONMENT=local rotate

# Update environment file
nano env.local

# Reload into Vault
make ENVIRONMENT=local load
```

## Troubleshooting

### Common Issues

#### Vault Connection Failed
```bash
# Check Vault status
make status

# Check if Vault is running
docker-compose ps vault

# Check Vault logs
make logs
```

#### Permission Denied
```bash
# Check if tokens exist
ls -la scripts/*.txt

# Re-run setup
make setup
```

#### Secrets Not Found
```bash
# List secrets in Vault
make list-secrets

# Check if secrets are loaded
vault kv list secret/plo-solver/

# Reload secrets
make ENVIRONMENT=local load
```

### Emergency Procedures

#### If Secrets Are Compromised
1. **Immediately rotate all exposed secrets**
2. **Update environment files with new secrets**
3. **Reload secrets into Vault**
4. **Restart affected services**
5. **Monitor for unauthorized access**

#### Vault Recovery
```bash
# Reset Vault to development mode
make reset

# Re-load all secrets
make ENVIRONMENT=local load
make ENVIRONMENT=staging load
make ENVIRONMENT=production load
```

## Best Practices

### Security
- ✅ **Never commit** `env.*` files or `secrets/*.json` files
- ✅ **Use different secrets** for each environment
- ✅ **Regularly rotate** production secrets
- ✅ **Use least-privilege** access policies
- ✅ **Monitor Vault access** and audit logs

### Development
- ✅ **Use development mode** for local development
- ✅ **Test secrets loading** before production
- ✅ **Validate environment** configuration
- ✅ **Keep backup copies** of secrets in secure location

### Production
- ✅ **Use production-grade** Vault configuration
- ✅ **Enable audit logging**
- ✅ **Use proper storage** backend
- ✅ **Implement backup** and recovery procedures
- ✅ **Use TLS** for all communications

## API Reference

### Vault CLI Commands

```bash
# Check Vault status
vault status

# List secrets
vault kv list secret/plo-solver/

# Get secrets
vault kv get secret/plo-solver/development

# Put secrets
vault kv put secret/plo-solver/development key=value

# List policies
vault policy list

# Create token
vault token create -policy=plo-solver-policy
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VAULT_ADDR` | Vault server address | `http://localhost:8200` |
| `VAULT_TOKEN` | Vault authentication token | From token files |
| `ENVIRONMENT` | Current environment | `local` |

## Migration Guide

### From JSON Files

If you were previously using JSON files directly:

```bash
# Run migration script
make migrate

# This will:
# 1. Backup existing JSON files
# 2. Create environment files from JSON
# 3. Load secrets into Vault
# 4. Remove JSON files from git tracking
```

### From Other Secret Managers

1. **Export secrets** from your current system
2. **Create environment files** with the exported secrets
3. **Load secrets** into Vault using the load commands
4. **Update your application** to use Vault

## Support

For issues with Vault setup or secrets management:

1. Check the troubleshooting section above
2. Review Vault logs: `make logs`
3. Verify your environment files are properly formatted
4. Ensure Vault is accessible from your application
5. Check the [HashiCorp Vault documentation](https://www.vaultproject.io/docs)

## Contributing

When contributing to this Vault setup:

1. **Test all changes** in development first
2. **Update documentation** for any new features
3. **Follow security best practices**
4. **Add tests** for new functionality
5. **Update policies** if needed 