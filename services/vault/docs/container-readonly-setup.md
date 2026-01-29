# Container Read-Only Vault Access Setup

## Overview
This document describes how to configure containers to have read-only access to Vault secrets.

## Security Model

### Vault Policy
- **Policy Name**: `container-readonly`
- **Access**: Read-only access to `secret/data/plo-solver/*`
- **Denied Operations**: Create, update, delete, list, sudo
- **Token TTL**: 1 year (8760h)

### Network Access
- **VPN Required**: All external access requires VPN connection
- **Container Network**: Accessible via `plo-solver-network`
- **Service Name**: `plo-solver-vault:8200`

## Container Configuration

### Environment Variables
```yaml
environment:
  - VAULT_ADDR=http://plo-solver-vault:8200
  - VAULT_TOKEN=${VAULT_READONLY_TOKEN}  # Set from container-readonly-token.txt
  - VAULT_NAMESPACE=plo-solver
```

### Docker Compose Example
```yaml
services:
  your-app:
    image: your-app:latest
    environment:
      - VAULT_ADDR=http://plo-solver-vault:8200
      - VAULT_TOKEN=${VAULT_READONLY_TOKEN}
    networks:
      - plo-solver-network
    # ... other configuration
```

## Usage in Applications

### Python Example
```python
import hvac

client = hvac.Client(
    url=os.environ['VAULT_ADDR'],
    token=os.environ['VAULT_TOKEN']
)

# Read a secret (allowed)
secret = client.secrets.kv.v2.read_secret_version(
    path='plo-solver/database-password'
)

# This would be denied by policy
# client.secrets.kv.v2.create_or_update_secret(
#     path='plo-solver/new-secret',
#     secret=dict(password='new-password')
# )
```

### Node.js Example
```javascript
const vault = require('node-vault')({
  apiVersion: 'v1',
  endpoint: process.env.VAULT_ADDR,
  token: process.env.VAULT_TOKEN
});

// Read a secret (allowed)
vault.read('secret/data/plo-solver/database-password')
  .then((result) => console.log(result.data.data));

// This would be denied by policy
// vault.write('secret/data/plo-solver/new-secret', { password: 'new-password' });
```

## Setup Instructions

1. **Start Vault**:
   ```bash
   cd /path/to/vault
   docker-compose up -d
   ```

2. **Setup Read-Only Policy**:
   ```bash
   docker exec plo-solver-vault /vault/scripts/setup-readonly-policy.sh
   ```

3. **Get Read-Only Token**:
   ```bash
   docker exec plo-solver-vault cat /vault/scripts/container-readonly-token.txt
   ```

4. **Configure Your Container**:
   - Set `VAULT_READONLY_TOKEN` environment variable
   - Ensure container is on `plo-solver-network`
   - Use `plo-solver-vault:8200` as Vault address

## Security Considerations

- **Token Rotation**: Read-only tokens expire after 1 year
- **Secret Path**: Only secrets under `plo-solver/` are accessible
- **Network Isolation**: VPN required for external access
- **Audit Logging**: All access is logged to `/vault/logs/audit.log`

## Troubleshooting

### Common Issues
1. **Permission Denied**: Check if secret path starts with `plo-solver/`
2. **Connection Refused**: Ensure container is on `plo-solver-network`
3. **Token Expired**: Regenerate token using setup script

### Debug Commands
```bash
# Check Vault status
docker exec plo-solver-vault vault status

# List policies
docker exec plo-solver-vault vault policy list

# Check token capabilities
docker exec plo-solver-vault vault token lookup <token>
``` 