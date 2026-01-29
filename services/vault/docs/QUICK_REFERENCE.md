# Vault Quick Reference

## Essential Commands

### Bootstrap Development
```bash
make dev                    # Complete development setup
make bootstrap             # Bootstrap from scratch
```

### Environment Management
```bash
make local                 # Start development Vault
make staging               # Start staging Vault
make production            # Start production Vault
```

### Secret Operations
```bash
make ENVIRONMENT=local load    # Load secrets
make ENVIRONMENT=local get     # Get secrets
make ENVIRONMENT=local get-env # Save secrets to .env
```

### Status & Monitoring
```bash
make status                # Check Vault status
make list-secrets          # List secrets in Vault
make logs                  # Show Vault logs
```

### Maintenance
```bash
make clean                 # Stop and clean up
make reset                 # Reset to development mode
make migrate               # Migrate from JSON files
```

## Access Information

### Vault UI
- **URL**: http://localhost:8200
- **Root Token**: `plo-solver-dev-token`

### Token Files
- **Root Token**: `scripts/root-token.txt`
- **Write Token**: `scripts/write-token.txt`
- **App Token**: `scripts/app-token.txt`

## Environment Files

### Development
```bash
cp env.example env.local
nano env.local              # Edit with real secrets
make ENVIRONMENT=local load # Load into Vault
```

### Staging
```bash
cp env.example env.staging
nano env.staging            # Edit with real secrets
make ENVIRONMENT=staging load # Load into Vault
```

### Production
```bash
cp env.example env.production
nano env.production         # Edit with real secrets
make ENVIRONMENT=production load # Load into Vault
```

## Troubleshooting

### Vault Not Running
```bash
make status                # Check status
make local                 # Start Vault
```

### Permission Denied
```bash
ls -la scripts/*.txt       # Check tokens exist
make setup                 # Re-run setup
```

### Secrets Not Found
```bash
make list-secrets          # List secrets
make ENVIRONMENT=local load # Reload secrets
```

## Security Policies

| Policy | Purpose | Token | Permissions |
|--------|---------|-------|-------------|
| `plo-solver-policy` | Application runtime | `app-token.txt` | Read-only |
| `plo-solver-write-policy` | Loading secrets | `write-token.txt` | Read/write |
| `admin-policy` | Admin operations | `root-token.txt` | Full access |

## Common Workflows

### New Developer Setup
```bash
make dev                   # Bootstrap everything
nano env.local             # Add real secrets
make ENVIRONMENT=local load # Load secrets
make ENVIRONMENT=local get-env # Get for application
```

### Secret Rotation
```bash
nano env.local             # Update secrets
make ENVIRONMENT=local load # Reload into Vault
make ENVIRONMENT=local get-env # Update .env file
```

### Environment Switch
```bash
make ENVIRONMENT=staging get-env  # Switch to staging
make ENVIRONMENT=production get-env # Switch to production
```

## File Locations

### Templates (Safe to Commit)
- `secrets/*.template.json`
- `env.example`
- `docs/`

### Secrets (Git Ignored)
- `env.local`
- `env.staging`
- `env.production`
- `scripts/*.txt`
- `secrets/backup-*/`

### Vault Data
- `vault-data/` (Docker volume)
- `secret/plo-solver/*` (in Vault) 