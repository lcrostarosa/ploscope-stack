# PLO Solver - Docker Setup Guide

## Overview

PLO Solver now uses a **single Docker Compose file** that handles all environments through environment variables and Docker profiles. No more multiple compose files!

## Quick Start

```bash
# Development mode (default)
./scripts/development/run_with_traefik.sh

# Production mode
./scripts/development/run_with_traefik.sh production

# Ngrok mode
./scripts/development/run_with_traefik.sh ngrok
```

## Environment Configurations

### Available Environments

| Environment | Config File | Description |
|-------------|-------------|-------------|
| Development | `env.development` | Local development with hot reload |
| Production | `env.production` | Production-ready with security settings |
| Ngrok | `env.ngrok` | Optimized for ngrok tunneling |

### Environment Variables

Key variables that control the setup:

```bash
# Docker Configuration
FRONTEND_DOCKERFILE=src/frontend/Dockerfile      # or src/frontend/Dockerfile.prod
BACKEND_DOCKERFILE=src/backend/Dockerfile        # or src/backend/Dockerfile.prod
VOLUME_MODE=rw                               # rw for dev, ro for prod
RESTART_POLICY=unless-stopped

# Traefik Configuration
TRAEFIK_DASHBOARD_ENABLED=true               # false in production
TRAEFIK_HTTPS_ENABLED=false                  # true in production
TRAEFIK_LOG_LEVEL=INFO                       # WARN in production

# Service Control
DISCOURSE_ENABLED=true                       # Enable/disable forum
```

## Docker Profiles

Services are organized into profiles:

| Profile | Services | Description |
|---------|----------|-------------|
| `app` | traefik, frontend, backend, database | Core application |
| `forum` | discourse | Forum service (optional) |
| `full` | All services | Complete setup |

### Using Profiles

```bash
# Start only core app
docker compose --profile=app up -d

# Start core app + forum
docker compose --profile=app --profile=forum up -d

# Start everything
docker compose --profile=full up -d
```

## Service Configuration

### Development vs Production

| Service | Development | Production |
|---------|-------------|------------|
| **Frontend** | `src/frontend/Dockerfile` | `src/frontend/Dockerfile.prod` |
| **Backend** | `src/backend/Dockerfile` | `src/backend/Dockerfile.prod` |
| **Volumes** | Read-write mounts | Read-only or no mounts |
| **Traefik** | Dashboard enabled | Dashboard disabled |
| **HTTPS** | Disabled | Enabled with Let's Encrypt |
| **Restart** | Unless stopped | Unless stopped |

### Volume Handling

```yaml
# Development
volumes:
  - ${PWD}/src:/app/src:rw

# Production  
volumes:
  - ${PWD}/src:/app/src:ro  # or no volumes
```

## Commands

### Startup Commands

```bash
# Development (default)
./scripts/development/run_with_traefik.sh

# Production
./scripts/development/run_with_traefik.sh production

# Ngrok-ready
./scripts/development/run_with_traefik.sh ngrok
```

### Direct Docker Compose

```bash
# Development
docker compose --env-file=env.development --profile=app up -d

# Production
docker compose --env-file=env.production --profile=full up -d

# Ngrok
docker compose --env-file=env.ngrok --profile=app up -d
```

### Service Management

```bash
# Stop all services
docker compose down

# Check status
docker compose ps

# View logs
docker compose logs backend
docker compose logs discourse
```

## Environment Customization

### Creating Custom Environments

1. Copy an existing env file:
   ```bash
   cp env.development env.staging
   ```

2. Modify settings as needed:
   ```bash
   # Change domain
   FRONTEND_DOMAIN=staging.yourapp.com
   
   # Enable HTTPS
   TRAEFIK_HTTPS_ENABLED=true
   
   # Use production Dockerfiles
   FRONTEND_DOCKERFILE=src/frontend/Dockerfile.prod
   ```

3. Use with scripts:
   ```bash
   # You'll need to modify the script or use docker compose directly
   docker compose --env-file=env.staging --profile=full up -d
   ```

### Forum Configuration

To enable/disable the forum:

```bash
# In your env file
DISCOURSE_ENABLED=true   # Enable forum
DISCOURSE_ENABLED=false  # Disable forum
```

## Troubleshooting

### Common Issues

**"No such service" errors:**
- Check if service has the correct profile
- Use `--profile=app --profile=forum` for full setup

**Volume mount errors:**
- Check `VOLUME_MODE` setting (rw/ro)
- Verify file permissions

**Traefik routing issues:**
- Check `FRONTEND_DOMAIN` matches your access URL
- Verify environment file is being loaded

### Debug Commands

```bash
# Check what services are defined
docker compose config --services

# Check what would be started with profiles
docker compose --profile=app config

# View computed configuration
docker compose --env-file=env.development config
```

## Migration from Old Setup

If you have old compose files:

1. **Remove old files** (already done):
   - `docker compose.simple.yml`
   - `docker compose.ngrok.yml`
   - `docker compose.prod.yml`

2. **Update scripts** to use new format:
   ```bash
   # Old
   docker compose -f docker-compose.simple.yml up -d
   
   # New
   docker compose --env-file=env.development --profile=app up -d
   ```

3. **Update environment variables** in `.env` or use predefined env files.

## Benefits

✅ **Single source of truth** - One docker compose.yml file
✅ **Environment control** - Easy switching between dev/prod/ngrok
✅ **Service selection** - Use profiles to start only what you need
✅ **Consistent configuration** - No config duplication
✅ **Easier maintenance** - Update one file instead of four 