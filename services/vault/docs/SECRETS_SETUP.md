# Secrets Management with HashiCorp Vault

## Overview

This project uses **HashiCorp Vault** as the primary secrets management solution. **Never commit actual secrets to git!** Instead, use Vault to securely store and manage all sensitive configuration data.

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

### Option 1: Using Makefile (Recommended)

```bash
# Show all available commands
make help

# Complete development setup
make dev

# Complete staging setup
make stage

# Complete production setup
make prod

# Or step by step:
make local setup load    # Start local Vault, setup, and load secrets
make staging load        # Load staging secrets
make production get      # Get production secrets
```

### Option 2: Manual Commands

#### 1. Start Vault
```bash
# Start Vault in isolated network (recommended)
docker-compose up -d vault

# Or start in integrated network (easier for development)
docker-compose -f docker-compose-integrated.yml up -d vault

# Access Vault UI at: http://localhost:8200
```

#### 2. Initialize Vault
```bash
./scripts/setup-vault.sh
```

#### 3. Create Environment Files
```bash
# Copy the example and fill in your actual values
cp env.example env.development
cp env.example env.staging
cp env.example env.production

# Edit the files with your real secrets
nano env.development
```

#### 4. Load Secrets into Vault
```bash
# Load development secrets
./scripts/load-secrets.sh development

# Load staging secrets
./scripts/load-secrets.sh staging

# Load production secrets
./scripts/load-secrets.sh production
```

#### 5. Use Secrets in Your Application
```bash
# Get secrets as environment variables
./scripts/get-secrets.sh development > .env

# Or use directly in your application
source <(./scripts/get-secrets.sh development)
```

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
env.development    # Real development secrets
env.staging        # Real staging secrets
env.production     # Real production secrets
env.example        # Example file (safe to commit)
```

### Vault Storage
```
secret/plo-solver/development  # Development secrets in Vault
secret/plo-solver/staging      # Staging secrets in Vault
secret/plo-solver/production   # Production secrets in Vault
```

## Security Best Practices

### 1. Generate Secure Secrets
```bash
# Generate a secure secret key
openssl rand -hex 32

# Generate a JWT secret
openssl rand -base64 64

# Generate a database password
openssl rand -base64 32
```

### 2. Environment-Specific Secrets
- **Development**: Use test/development API keys
- **Staging**: Use staging/test API keys  
- **Production**: Use live API keys with proper security

### 3. Secret Rotation
```bash
# Rotate secrets for an environment
./scripts/rotate-secrets.sh development

# Update environment file with new secrets
nano env.development

# Reload into Vault
./scripts/load-secrets.sh development
```

### 4. Access Control
- Use different Vault tokens for different environments
- Implement least-privilege access policies
- Regularly rotate Vault tokens

## Environment Management

### Using Makefile (Recommended)

```bash
# Development environment
make dev                    # Complete development setup
make local setup load       # Step by step development setup
make local get-env          # Get secrets and save to .env

# Staging environment
make stage                  # Complete staging setup
make staging setup load     # Step by step staging setup
make staging get-env        # Get secrets and save to .env

# Production environment
make prod                   # Complete production setup
make production setup load  # Step by step production setup
make production get-env     # Get secrets and save to .env

# Environment-specific operations
make ENVIRONMENT=staging load    # Load secrets for specific environment
make ENVIRONMENT=production get  # Get secrets for specific environment
```

### Manual Commands

#### Development Setup
```bash
# Complete development setup
./scripts/manage-environments.sh setup development

# Load development secrets
./scripts/manage-environments.sh load development

# Validate configuration
./scripts/manage-environments.sh validate development
```

#### Staging Setup
```bash
# Setup staging environment
./scripts/manage-environments.sh setup staging

# Load staging secrets
./scripts/manage-environments.sh load staging
```

#### Production Setup
```bash
# Setup production environment (requires extra care)
./scripts/manage-environments.sh setup production

# Load production secrets
./scripts/manage-environments.sh load production
```

## Integration with Applications

### Docker Compose Integration
```yaml
# In your docker-compose.yml
services:
  app:
    environment:
      - VAULT_ADDR=http://vault:8200
    volumes:
      - ./scripts:/scripts
    command: >
      sh -c "
        ./scripts/get-secrets.sh development > .env &&
        source .env &&
        your-app-command
      "
```

### Direct Application Integration
```bash
# In your application startup script
#!/bin/bash
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=$(cat scripts/app-token.txt)

# Load secrets into environment
eval $(./scripts/get-secrets.sh development)

# Start your application
python app.py
```

## Troubleshooting

### Common Issues

#### Vault Connection Failed
```bash
# Check Vault status using Makefile
make status

# Check if Vault is running
docker-compose ps vault

# Check Vault logs
make logs

# Verify Vault address
echo $VAULT_ADDR

# Access Vault UI to verify it's working
# Open http://localhost:8200 in your browser
```

#### Secrets Not Found
```bash
# List secrets using Makefile
make list-secrets

# Check if secrets are loaded
vault kv list secret/plo-solver/

# List secrets for environment
vault kv get secret/plo-solver/development

# Reload secrets if needed
make ENVIRONMENT=development load
```

#### Permission Denied
```bash
# Check if app token exists
ls -la scripts/app-token.txt

# Re-run Vault setup if needed
./scripts/setup-vault.sh
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
# If Vault is corrupted or tokens lost
./scripts/setup-vault.sh --force

# Re-load all secrets
./scripts/load-secrets.sh development
./scripts/load-secrets.sh staging
./scripts/load-secrets.sh production
```

## Advanced Features

### Secret Rotation
```bash
# Rotate specific secrets
./scripts/rotate-secrets.sh development --secrets SECRET_KEY,JWT_SECRET_KEY

# Rotate all secrets
./scripts/rotate-secrets.sh development --all
```

### Environment Comparison
```bash
# Compare environments
./scripts/manage-environments.sh compare staging production
```

### Backup and Restore
```bash
# Backup Vault data
./scripts/manage-environments.sh backup

# Restore Vault data
./scripts/manage-environments.sh restore backup-file
```

## Migration from JSON Files

If you were previously using JSON files directly:

1. **Stop using the JSON files** in `secrets/`
2. **Create environment files** from the templates
3. **Load secrets into Vault** using the scripts
4. **Update your application** to use Vault
5. **Remove the JSON files** from git tracking

```bash
# Remove JSON files from git (but keep them as backup)
git rm --cached secrets/*.json
git commit -m "Remove actual secrets from tracking"

# Create environment files
cp env.example env.development
# Edit env.development with your actual values

# Load into Vault
./scripts/load-secrets.sh development
```

## Important Notes

- ✅ **Never commit** `env.*` files or `secrets/*.json` files
- ✅ **Always use Vault** for production secrets
- ✅ **Use different secrets** for each environment
- ✅ **Regularly rotate** production secrets
- ✅ **Keep backup copies** of secrets in a secure location
- ✅ **Monitor Vault access** and audit logs
- ✅ **Use strong passwords** and API keys
- ✅ **Test your setup** in development before production

## Support

For issues with Vault setup or secrets management:
1. Check the troubleshooting section above
2. Review Vault logs: `docker-compose logs vault`
3. Verify your environment files are properly formatted
4. Ensure Vault is accessible from your application 