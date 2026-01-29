# Utilities Scripts

This directory contains utility scripts for maintaining and managing the PLOSolver project.

## Environment File Synchronization

### Overview

The `sync_env_files.py` script synchronizes the order of environment variables across all env files in the project, using `env.example` as the master template.

### Features

- **Reorders variables** to match the master template (`env.example`)
- **Identifies duplicates** within individual files
- **Reports missing variables** that exist in `env.example` but not in other files
- **Reports new variables** that exist in other files but not in `env.example`
- **Preserves comments** and section headers
- **Generates detailed reports** of all changes and issues
- **Supports dry-run mode** to preview changes without making them
- **Creates backups** before making changes

### Usage

#### Via Makefile (Recommended)

```bash
# Dry run - see what would be changed without making changes
make sync-env-files DRY_RUN=1

# Create backups and sync files
make sync-env-files BACKUP=1

# Both dry run and backup
make sync-env-files DRY_RUN=1 BACKUP=1
```

#### Via Shell Script

```bash
# Dry run
./scripts/utilities/sync_env_files.sh --dry-run

# Create backups and sync
./scripts/utilities/sync_env_files.sh --backup

# Both
./scripts/utilities/sync_env_files.sh --dry-run --backup

# Show help
./scripts/utilities/sync_env_files.sh --help
```

#### Via Python Script Directly

```bash
# Dry run
python3 scripts/utilities/sync_env_files.py --dry-run

# Create backups and sync
python3 scripts/utilities/sync_env_files.py --backup

# Both
python3 scripts/utilities/sync_env_files.py --dry-run --backup
```

### How It Works

1. **Parses all env files** in the project root (env.* except env.example)
2. **Uses env.example as master** to determine the correct variable order
3. **Analyzes each file** for:
   - Duplicate variables within the same file
   - Missing variables (in master but not in file)
   - New variables (in file but not in master)
4. **Reorders variables** to match the master template
5. **Preserves new variables** by adding them at the end with a comment
6. **Generates a comprehensive report** of all findings

### Example Output

```
============================================================
ENVIRONMENT FILE SYNCHRONIZATION REPORT
============================================================

❌ DUPLICATE VARIABLES FOUND:
  env.staging: BUILD_ENV, ACME_EMAIL, LOG_LEVEL, ENVIRONMENT, DOCKER_LOG_PATH

⚠️  MISSING VARIABLES (not in env.example):
  env.development: DISCOURSE_DB_NAME, DISCOURSE_DB_USER, ...

🆕 NEW VARIABLES (not in env.example):
  env.development: BACKEND_LOGS, CELERY_ACCEPT_CONTENT, ...

🔄 REORDERED FILES (5):
  ✅ env.development
  ✅ env.ghcr.example
  ✅ env.production
  ✅ env.staging
  ✅ env.test

============================================================
```

### Best Practices

1. **Always run with `--dry-run` first** to see what changes would be made
2. **Use `--backup` when making actual changes** to preserve original files
3. **Review the report carefully** before applying changes
4. **Address duplicates** before syncing (they indicate potential issues)
5. **Consider adding missing variables** to env.example if they should be standard
6. **Review new variables** to see if they should be added to the master template

### File Structure

The script expects the following structure:
```
project-root/
├── env.example          # Master template
├── env.development      # Development environment
├── env.staging         # Staging environment
├── env.production      # Production environment
├── env.test           # Test environment
└── env.ghcr.example   # GitHub Container Registry example
```

### Backup Location

When using the `--backup` option, backup files are created in:
```
project-root/backups/env_files/
├── env.development.backup
├── env.staging.backup
├── env.production.backup
├── env.test.backup
└── env.ghcr.example.backup
```

### Troubleshooting

#### Common Issues

1. **"env.example not found"**: Make sure you're running from the project root
2. **"Python 3 is required"**: Install Python 3 if not available
3. **Permission errors**: Make sure the script is executable (`chmod +x`)

#### Duplicate Variables

If duplicates are found, they usually indicate:
- Copy-paste errors
- Accidental variable redefinition
- Merge conflicts that weren't resolved properly

Fix duplicates by:
1. Identifying which value is correct
2. Removing the duplicate line
3. Running the sync script again

#### Missing Variables

Missing variables indicate that `env.example` has variables that other environments don't need or haven't been configured for. Consider:
- Adding the variable with appropriate default values
- Removing it from `env.example` if it's not needed
- Adding it to the specific environment files that need it

## Other Utilities

### entrypoint-wrapper.sh

A wrapper script for Docker entrypoints that handles certificate monitoring and service health checks.

### ssh-tunnel-all.sh

Script for establishing SSH tunnels to remote services.

### ssh-tunnel-config.sh

Configuration script for SSH tunnel setup. 