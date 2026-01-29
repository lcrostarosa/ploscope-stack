# Docker Compose Usage Guide

This document explains how to use the unified `docker-compose.yml` file for different environments and deployment scenarios.

## Overview

The PLOSolver application uses a single `docker-compose.yml` file that adapts to different environments through runtime configuration. This approach eliminates the need for multiple compose files and provides flexibility for different deployment scenarios.

## Key Features

- **Single compose file**: One file for all environments
- **Runtime configuration**: Environment variables control behavior
- **Registry or local builds**: Can use pre-built images or build locally
- **Environment-aware**: Container names, domains, and SSL based on environment
- **Flexible deployment**: Works for development, staging, and production

## Environment Variables

### Core Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment identifier | `development`, `staging`, `production` |
| `FRONTEND_IMAGE` | Registry image for frontend | `ghcr.io/user/PLOSolver-frontend:staging-frontend` |
| `BACKEND_IMAGE` | Registry image for backend | `ghcr.io/user/PLOSolver-backend:staging-backend` |
| `FRONTEND_DOMAIN` | Domain for frontend routing | `ploscope.com` |
| `TRAEFIK_DOMAIN` | Domain for Traefik configuration | `ploscope.com` |
| `ACME_EMAIL` | Email for Let's Encrypt certificates | `admin@crostamusic.com` |

### Feature Flags

| Variable | Description | Default |
|----------|-------------|---------|
| `REACT_APP_FEATURE_TRAINING_MODE_ENABLED` | Enable training mode | `false` |
| `REACT_APP_FEATURE_SOLVER_MODE_ENABLED` | Enable solver mode | `true` |
| `REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED` | Enable player profiles | `false` |
| `REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED` | Enable hand history analyzer | `false` |
| `REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED` | Enable tournament mode | `true` |
| `REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED` | Enable cash game mode | `false` |
| `REACT_APP_FEATURE_CUSTOM_MODE_ENABLED` | Enable custom mode | `false` |

## Usage Examples

### 1. Development (Local Build)

```bash
# Use local builds (no registry images specified)
docker compose --env-file env.development up -d
```

**env.development:**
```bash
ENVIRONMENT=development
# No FRONTEND_IMAGE or BACKEND_IMAGE specified
# Will build locally using src/frontend/Dockerfile and src/backend/Dockerfile
```

### 2. Staging (Registry Images)

```bash
# Use registry images for staging
docker compose --env-file env.staging up -d
```

**env.staging:**
```bash
ENVIRONMENT=staging
FRONTEND_IMAGE=ghcr.io/your-username/PLOSolver-frontend:staging-frontend
BACKEND_IMAGE=ghcr.io/your-username/PLOSolver-backend:staging-backend
FRONTEND_DOMAIN=ploscope.com
TRAEFIK_DOMAIN=ploscope.com
ACME_EMAIL=admin@crostamusic.com
```

### 3. Production (Registry Images)

```bash
# Use registry images for production
docker compose --env-file env.production up -d
```

**env.production:**
```bash
ENVIRONMENT=production
FRONTEND_IMAGE=ghcr.io/your-username/PLOSolver-frontend:latest-frontend
BACKEND_IMAGE=ghcr.io/your-username/PLOSolver-backend:latest-backend
FRONTEND_DOMAIN=ploscope.com
TRAEFIK_DOMAIN=ploscope.com
ACME_EMAIL=admin@crostamusic.com
```

### 4. Custom Configuration

```bash
# Override specific variables
FRONTEND_IMAGE=ghcr.io/user/PLOSolver-frontend:v1.0.0-frontend \
BACKEND_IMAGE=ghcr.io/user/PLOSolver-backend:v1.0.0-backend \
ENVIRONMENT=production \
docker compose --env-file env.production up -d
```

## Deployment Scenarios

### Scenario 1: Local Development

```bash
# Build and run locally
docker compose up -d

# Or with specific environment file
docker compose --env-file env.development up -d
```

### Scenario 2: Staging Deployment

```bash
# 1. Login to registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# 2. Pull images
docker pull ghcr.io/your-username/PLOSolver-frontend:staging-frontend
docker pull ghcr.io/your-username/PLOSolver-backend:staging-backend

# 3. Deploy
GITHUB_REPOSITORY=your-username/PLOSolver docker compose --env-file env.staging up -d
```

### Scenario 3: Production Deployment

```bash
# 1. Login to registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# 2. Pull images
docker pull ghcr.io/your-username/PLOSolver-frontend:latest-frontend
docker pull ghcr.io/your-username/PLOSolver-backend:latest-backend

# 3. Deploy
GITHUB_REPOSITORY=your-username/PLOSolver docker compose --env-file env.production up -d
```

### Scenario 4: Version-Specific Deployment

```bash
# Deploy specific version
FRONTEND_IMAGE=ghcr.io/your-username/PLOSolver-frontend:v1.2.3-frontend \
BACKEND_IMAGE=ghcr.io/your-username/PLOSolver-backend:v1.2.3-backend \
ENVIRONMENT=production \
docker compose --env-file env.production up -d
```

## Container Naming

Containers are automatically named based on the environment:

- **Development**: `plosolver-frontend-development`, `plosolver-backend-development`
- **Staging**: `plosolver-frontend-staging`, `plosolver-backend-staging`
- **Production**: `plosolver-frontend-production`, `plosolver-backend-production`

## SSL Configuration

SSL certificates are automatically configured based on the environment:

- **Development**: No SSL (HTTP only)
- **Staging**: HTTP (for testing)
- **Production**: HTTPS with Let's Encrypt certificates

The SSL configuration is controlled by the `ACME_EMAIL` variable and `FRONTEND_DOMAIN` setting.

## Troubleshooting

### Check Container Status

```bash
# List all containers
docker ps -a | grep plosolver

# Check specific environment
docker ps -a | grep plosolver-${ENVIRONMENT:-development}
```

### View Logs

```bash
# View all logs
docker compose logs

# View specific service logs
docker compose logs frontend
docker compose logs backend

# Follow logs in real-time
docker compose logs -f
```

### Restart Services

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart frontend
```

### Clean Up

```bash
# Stop and remove containers
docker compose down

# Remove volumes (careful - this deletes data)
docker compose down -v

# Remove images
docker compose down --rmi all
```

## Best Practices

### 1. Environment Files

- Keep environment files in version control
- Use `.env.example` for documentation
- Never commit sensitive data (use secrets)

### 2. Registry Images

- Always specify image tags explicitly
- Use semantic versioning for releases
- Keep images up to date

### 3. Configuration

- Use environment variables for all configuration
- Provide sensible defaults
- Document all variables

### 4. Deployment

- Test in staging before production
- Use health checks
- Monitor deployments

## Migration from Multiple Compose Files

If you're migrating from multiple docker-compose files:

1. **Remove old files**: Delete `docker-compose.staging.yml`, `docker-compose.production.yml`
2. **Update environment files**: Add `FRONTEND_IMAGE` and `BACKEND_IMAGE` variables
3. **Update scripts**: Change compose commands to use `--env-file`
4. **Test deployments**: Verify each environment works correctly

## Example Environment Files

### env.development
```bash
ENVIRONMENT=development
NODE_ENV=development
FLASK_DEBUG=true
FRONTEND_DOMAIN=localhost
TRAEFIK_DOMAIN=localhost
# No registry images - will build locally
```

### env.staging
```bash
ENVIRONMENT=staging
NODE_ENV=production
FLASK_DEBUG=false
FRONTEND_DOMAIN=ploscope.com
TRAEFIK_DOMAIN=ploscope.com
ACME_EMAIL=admin@crostamusic.com
FRONTEND_IMAGE=ghcr.io/your-username/PLOSolver-frontend:staging-frontend
BACKEND_IMAGE=ghcr.io/your-username/PLOSolver-backend:staging-backend
```

### env.production
```bash
ENVIRONMENT=production
NODE_ENV=production
FLASK_DEBUG=false
FRONTEND_DOMAIN=ploscope.com
TRAEFIK_DOMAIN=ploscope.com
ACME_EMAIL=admin@crostamusic.com
FRONTEND_IMAGE=ghcr.io/your-username/PLOSolver-frontend:latest-frontend
BACKEND_IMAGE=ghcr.io/your-username/PLOSolver-backend:latest-backend
``` 