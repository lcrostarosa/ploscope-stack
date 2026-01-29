# Traefik Configuration

This directory contains Traefik reverse proxy configurations for different environments in the PLOScope application stack.

## Overview

Traefik serves as the main reverse proxy and load balancer for the PLOScope application, handling routing between frontend, backend, and other services across different environments. It provides SSL termination, load balancing, and advanced routing capabilities.

**Version**: Traefik v3.0

**Key Features**:
- Automatic SSL certificate management with Let's Encrypt
- WebSocket support for real-time features
- CORS handling for cross-origin requests
- Prometheus metrics integration
- OpenVPN access for secure administrative tasks
- Environment-specific configurations

## Directory Structure

```
traefik/
├── ci/                    # CI/CD environment configuration
├── localdev/             # Local development environment
├── staging/              # Staging environment
├── production/           # Production environment
├── LICENSE.txt           # License file
└── README.md            # This file
```

## Environments

### Local Development (`localdev/`)

**Purpose**: Local development environment with simplified configuration

**Features**:
- HTTP-only (no HTTPS for local development)
- Debug-level logging
- Insecure dashboard access
- WebSocket support for real-time features
- CORS headers for cross-origin requests

**Configuration Files**:
- `traefik.yml` - Main Traefik configuration
- `dynamic.docker.yml` - Routing rules and service definitions
- `traefik-native.yml` - Alternative native configuration

**Routing**:
- `/api/*` → Backend API (port 5001)
- `/socket.io/*` → WebSocket connections
- `/` → Frontend application (port 3001)

### Staging (`staging/`)

**Purpose**: Pre-production testing environment

**Features**:
- HTTPS with Let's Encrypt certificates
- HTTP to HTTPS redirects
- Access logging with filtering
- Large file upload support
- OpenVPN TCP entry point (port 1194)

**Configuration Files**:
- `traefik.yml` - Main Traefik configuration
- `dynamic.docker.yml` - Routing rules and service definitions

**Security**:
- Automatic SSL certificate management
- HTTP to HTTPS redirection
- Access log filtering for security monitoring

### Production (`production/`)

**Purpose**: Live production environment

**Features**:
- Full HTTPS with Let's Encrypt
- Optimized for production workloads
- Comprehensive access logging
- OpenVPN support
- Production-grade security settings

**Configuration Files**:
- `traefik.yml` - Main Traefik configuration
- `dynamic.docker.yml` - Routing rules and service definitions

### CI/CD (`ci/`)

**Purpose**: Continuous Integration testing environment

**Features**:
- Simplified configuration for automated testing
- HTTP-only for CI environment
- Optimized for GitHub Actions
- Integration with Postman/Newman testing
- Direct localhost routing for GitHub Actions runners

**Configuration Files**:
- `traefik.yml` - Main Traefik configuration
- `dynamic.docker.yml` - Routing rules and service definitions
- `README.md` - CI-specific documentation

**Testing Integration**:
- Health checks for Traefik API accessibility
- Backend and frontend routing verification
- Full-stack integration testing via Newman/Postman
- Automated testing in GitHub Actions workflows

## Common Configuration Elements

### Entry Points

All environments support these entry points:
- `web` (port 80) - HTTP traffic
- `websecure` (port 443) - HTTPS traffic (staging/production)
- `metrics` (port 8082) - Prometheus metrics
- `openvpn-tcp` (port 1194) - OpenVPN access (staging/production)

### Services

**Backend API**:
- Routes `/api/*` requests to backend service
- Supports sticky sessions
- WebSocket upgrade handling

**Frontend**:
- Serves React application
- Handles all non-API routes

### Middlewares

**CORS Headers**:
- Allows cross-origin requests
- Supports all HTTP methods
- Configurable origin lists

**WebSocket Support**:
- Proper upgrade headers
- Connection management
- Real-time communication support

### Metrics and Monitoring

**Prometheus Integration**:
- Metrics endpoint on port 8082
- Service and entry point labels
- Custom histogram buckets

**Access Logging**:
- File-based logging
- Status code filtering
- Configurable buffering

## Environment Variables

### Required Variables

```bash
# Let's Encrypt (staging/production)
ACME_EMAIL=admin@ploscope.com

# Service URLs (CI environment)
TRAEFIK_ENABLED=true
TRAEFIK_HOST=localhost
TRAEFIK_PORT=80
TRAEFIK_API_PORT=8082
FRONTEND_URL=http://localhost
REACT_APP_API_URL=http://localhost/api
```

### Optional Variables

```bash
# Logging level
TRAEFIK_LOG_LEVEL=INFO

# Certificate storage
ACME_STORAGE=/etc/certs/acme.json

# Dashboard access
TRAEFIK_DASHBOARD_INSECURE=true
```

## Usage

### Local Development

1. Start the application stack:
```bash
docker-compose up -d
```

2. Access services:
- Frontend: http://localhost
- Backend API: http://localhost/api
- Traefik Dashboard: http://localhost:8082

### Staging/Production

1. Set environment variables:
```bash
export ACME_EMAIL=admin@ploscope.com
```

2. Deploy with Docker Compose:
```bash
docker-compose -f docker-compose.yml up -d
```

3. Access services:
- Frontend: https://your-domain.com
- Backend API: https://your-domain.com/api
- Traefik Dashboard: http://your-domain.com:8082

### CI/CD

The CI environment is automatically configured in GitHub Actions workflows. No manual setup required.

## Security Considerations

### Production Security

- **HTTPS Only**: All production traffic uses HTTPS
- **Certificate Management**: Automatic Let's Encrypt certificate renewal
- **Access Logging**: Comprehensive logging for security monitoring
- **OpenVPN**: Secure VPN access for administrative tasks

### Development Security

- **HTTP Only**: Simplified for local development
- **Insecure Dashboard**: Accessible without authentication
- **CORS**: Permissive CORS settings for development

## Troubleshooting

### Common Issues

1. **Certificate Errors**:
   - Verify ACME_EMAIL is set correctly
   - Check certificate storage permissions
   - Ensure DNS is properly configured

2. **Routing Issues**:
   - Check service health status
   - Verify port mappings
   - Review Traefik logs

3. **WebSocket Problems**:
   - Ensure WebSocket middleware is applied
   - Check upgrade headers
   - Verify backend WebSocket support

### Logs and Debugging

**View Traefik Logs**:
```bash
docker logs traefik
```

**Check Service Health**:
```bash
curl http://localhost:8082/api/http/services
```

**Test Routing**:
```bash
curl -H "Host: localhost" http://localhost/api/health
```

## Monitoring and Metrics

### Prometheus Metrics

Access metrics at `http://localhost:8082/metrics` (or your domain:8082/metrics)

Key metrics:
- Request counts and durations
- Service health status
- Entry point statistics
- Middleware performance

### Dashboard

Access the Traefik dashboard:
- Local: http://localhost:8082
- Production: http://your-domain.com:8082

## Related Documentation

- [CI Environment README](ci/README.md) - Detailed CI configuration
- [Traefik Official Documentation](https://doc.traefik.io/traefik/)
- [Docker Compose Configuration](../docker-compose.yml)
- [GitHub Actions Workflows](../.github/workflows/)

## License

This project is licensed under the terms specified in [LICENSE.txt](LICENSE.txt).


