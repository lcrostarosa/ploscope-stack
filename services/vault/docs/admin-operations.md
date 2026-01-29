# Vault Admin Operations Guide

## Overview
This guide covers how to perform admin operations in Vault for managing PLO Solver secrets.

## Admin Access Methods

### Method 1: Root Token (Development)
```bash
export VAULT_TOKEN="plo-solver-dev-token"
export VAULT_ADDR="http://localhost:8200"
```

### Method 2: Admin Policy Token (Recommended)
```bash
# Get admin token
ADMIN_TOKEN=$(docker exec plo-solver-vault cat /vault/scripts/admin-token.txt)
export VAULT_TOKEN="$ADMIN_TOKEN"
export VAULT_ADDR="http://localhost:8200"
```

## Common Admin Operations

### 1. Create/Update Secrets
```bash
# Create a new secret
vault kv put secret/plo-solver/database-password password="newpassword123"

# Update an existing secret
vault kv put secret/plo-solver/api-key key="updated-api-key-456"

# Create a complex secret with multiple values
vault kv put secret/plo-solver/database-config \
  host="db.example.com" \
  port="5432" \
  database="plosolver" \
  username="app_user"
```

### 2. Read Secrets
```bash
# Read a secret
vault kv get secret/plo-solver/database-password

# Read specific field
vault kv get -field=password secret/plo-solver/database-password

# Read with metadata
vault kv get -format=json secret/plo-solver/database-password
```

### 3. List Secrets
```bash
# List all secrets under plo-solver
vault kv list secret/plo-solver/

# List with metadata
vault kv list -format=json secret/plo-solver/
```

### 4. Delete Secrets
```bash
# Delete a secret
vault kv delete secret/plo-solver/old-api-key

# Delete and destroy (permanent)
vault kv destroy -versions=1 secret/plo-solver/old-api-key
```

### 5. Manage Policies
```bash
# List all policies
vault policy list

# Read a specific policy
vault policy read container-readonly

# Update a policy
vault policy write container-readonly /vault/policies/read-only-policy.hcl
```

### 6. Manage Tokens
```bash
# List tokens
vault token list

# Lookup token info
vault token lookup <token>

# Create new token
vault token create -policy=container-readonly -ttl=24h

# Revoke token
vault token revoke <token>
```

## Setup Scripts

### Initial Setup
```bash
# Start Vault
docker-compose up -d

# Setup read-only policy for containers
docker exec plo-solver-vault /vault/scripts/setup-readonly-policy.sh

# Setup admin policy
docker exec plo-solver-vault /vault/scripts/setup-admin-policy.sh
```

### Quick Admin Setup
```bash
# Run admin setup script
./scripts/admin-setup.sh
```

## Security Best Practices

### 1. Token Management
- Use admin tokens only when needed
- Set appropriate TTL for tokens
- Revoke tokens when no longer needed
- Store tokens securely

### 2. Secret Management
- Use descriptive secret names
- Include version information in secrets
- Rotate secrets regularly
- Use complex, unique values

### 3. Access Control
- Follow principle of least privilege
- Use specific policies for different roles
- Audit access regularly
- Monitor for suspicious activity

## Example Workflows

### Adding a New Service
```bash
# 1. Create secrets for the new service
vault kv put secret/plo-solver/new-service/api-key key="new-service-key"
vault kv put secret/plo-solver/new-service/database-url url="postgresql://user:pass@host:5432/db"

# 2. Verify secrets are accessible
vault kv get secret/plo-solver/new-service/api-key

# 3. Update container configuration to use new secrets
```

### Rotating Secrets
```bash
# 1. Create new secret version
vault kv put secret/plo-solver/database-password password="new-password-2024"

# 2. Update application to use new secret
# 3. Verify application works with new secret
# 4. Delete old secret version (optional)
vault kv destroy -versions=1 secret/plo-solver/database-password
```

### Emergency Access
```bash
# If you need full admin access
export VAULT_TOKEN="plo-solver-dev-token"
export VAULT_ADDR="http://localhost:8200"

# List all secrets
vault kv list secret/

# Access any secret
vault kv get secret/any-secret
```

## Troubleshooting

### Common Issues
1. **Permission Denied**: Check token permissions
2. **Token Expired**: Create new token
3. **Connection Refused**: Check Vault is running
4. **Policy Not Found**: Run setup scripts

### Debug Commands
```bash
# Check Vault status
vault status

# Check token capabilities
vault token lookup

# List all mounts
vault secrets list

# Check audit logs
docker exec plo-solver-vault tail -f /vault/logs/audit.log
```

## Integration with Applications

### Environment Variables for Admin Operations
```bash
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="your-admin-token"
export VAULT_NAMESPACE="plo-solver"
```

### Python Admin Script Example
```python
import hvac
import os

client = hvac.Client(
    url=os.environ['VAULT_ADDR'],
    token=os.environ['VAULT_TOKEN']
)

# Create a secret
client.secrets.kv.v2.create_or_update_secret(
    path='plo-solver/new-secret',
    secret=dict(password='new-password')
)

# Read a secret
secret = client.secrets.kv.v2.read_secret_version(
    path='plo-solver/database-password'
)
print(secret['data']['data']['password'])
``` 