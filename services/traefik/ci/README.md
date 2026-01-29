# CI Environment Traefik Configuration

This directory contains the Traefik configuration for the CI (Continuous Integration) environment.

## Overview

The CI Traefik setup provides a reverse proxy for testing the complete application stack in GitHub Actions. It routes traffic between the frontend, backend, and other services during integration testing.

**Version**: Traefik v3.0

## Configuration Files

- `traefik.yml` - Main Traefik configuration file
- `dynamic.docker.yml` - Dynamic configuration for routing rules and services
- `README.md` - This documentation file

## Architecture

The CI Traefik setup includes:

- **Entry Points**: HTTP (port 80) and metrics (port 8082)
- **Services**: Backend API (port 5001) and Frontend (port 3001)
- **Routers**: API routes, frontend routes, and WebSocket support
- **Middlewares**: CORS headers and WebSocket upgrade handling

## Routing Rules

- `/api/*` → Backend API (port 5001)
- `/socket.io/*` → Backend WebSocket support
- `/` → Frontend application (port 3001)

## Environment Variables

The CI environment sets the following Traefik-related variables:

```bash
TRAEFIK_ENABLED=true
TRAEFIK_HOST=localhost
TRAEFIK_PORT=80
TRAEFIK_API_PORT=8082
FRONTEND_URL=http://localhost
REACT_APP_API_URL=http://localhost/api
```

## Testing

The CI workflow includes several tests for Traefik functionality:

1. **Health Check**: Verifies Traefik API is accessible
2. **Backend Routing**: Tests API endpoint routing
3. **Frontend Routing**: Tests frontend application routing
4. **Integration Tests**: Full-stack testing via Newman/Postman

## Differences from Local Development

- Simplified configuration for CI environment
- No HTTPS (HTTP only for testing)
- Direct localhost routing instead of Docker networking
- Optimized for GitHub Actions runner environment
- Uses Traefik v3.0 configuration format

## Troubleshooting

If Traefik tests fail in CI:

1. Check that all services (PostgreSQL, RabbitMQ, Backend, Frontend) are running
2. Verify Traefik container health status
3. Check Traefik logs for routing errors
4. Ensure proper port mappings and service discovery

## Related Files

- `.github/workflows/ci.yml` - CI workflow configuration
- `postman/PLOSolver-CI-Environment.postman_environment.json` - Postman test environment
- `env.test` - Test environment variables 