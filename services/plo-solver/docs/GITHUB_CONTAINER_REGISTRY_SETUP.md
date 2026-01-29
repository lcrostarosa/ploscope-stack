# GitHub Container Registry Setup for PLOSolver

This document explains how to set up and use GitHub Container Registry (GHCR) for deploying the PLOSolver application across different environments.

## Overview

The PLOSolver application uses GitHub Container Registry to store and distribute Docker images for both frontend and backend services. This setup provides:

- **Consistent deployments**: Same images across all environments
- **Version control**: Tagged images for different releases
- **Security**: Private registry with GitHub authentication
- **Automation**: CI/CD workflows for building and deploying

## Architecture

### Image Structure

```
ghcr.io/{username}/PLOSolver-frontend:{tag}
ghcr.io/{username}/PLOSolver-backend:{tag}
```

### Tagging Strategy

- **Staging**: `staging-frontend`, `staging-backend`
- **Production**: `latest-frontend`, `latest-backend`
- **Releases**: `v1.0.0-frontend`, `v1.0.0-backend`
- **Branches**: `master-frontend`, `develop-backend`

## Prerequisites

### 1. GitHub Repository Setup

Ensure your repository has the following:

- **Packages permissions**: Enable "Read and write permissions" for packages
- **GitHub Actions**: Enable GitHub Actions for the repository
- **Secrets**: Configure required secrets (see below)

### 2. Required GitHub Secrets

Add these secrets to your repository (`Settings > Secrets and variables > Actions`):

#### For Staging Deployment
```
STAGING_HOST=your-staging-server-ip
STAGING_USER=your-staging-username
STAGING_PATH=/path/to/plosolver/on/staging
STAGING_SSH_KEY=your-staging-ssh-private-key
```

#### For Production Deployment
```
PRODUCTION_HOST=your-production-server-ip
PRODUCTION_USER=your-production-username
PRODUCTION_PATH=/path/to/plosolver/on/production
PRODUCTION_SSH_KEY=your-production-ssh-private-key
```

### 3. Server Requirements

Each deployment server needs:

- **Docker**: Latest version installed
- **Docker Compose**: v2.0+ installed
- **SSH access**: Configured with the provided SSH keys
- **Network access**: To pull images from GHCR

## Setup Instructions

### 1. Initial Setup

#### Option A: Using the Setup Script

```bash
# Make the script executable
chmod +x scripts/setup/setup-registry.sh

# Set environment variables
export GITHUB_TOKEN=your_github_token
export GITHUB_ACTOR=your_github_username
export GITHUB_REPOSITORY=your_username/PLOSolver

# Complete setup for staging
./scripts/setup/setup-registry.sh setup --environment staging

# Complete setup for production
./scripts/setup/setup-registry.sh setup --environment production
```

#### Option B: Manual Setup

```bash
# 1. Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# 2. Build and push images
docker build -f src/frontend/Dockerfile -t ghcr.io/your_username/PLOSolver-frontend:staging-frontend src/frontend
docker build -f src/backend/Dockerfile -t ghcr.io/your_username/PLOSolver-backend:staging-backend src/backend
docker push ghcr.io/your_username/PLOSolver-frontend:staging-frontend
docker push ghcr.io/your_username/PLOSolver-backend:staging-backend

# 3. Deploy
GITHUB_REPOSITORY=your_username/PLOSolver docker compose -f docker-compose.staging.yml --env-file env.staging up -d
```

### 2. GitHub Actions Workflows

The repository includes several GitHub Actions workflows:

#### Docker Build Workflow (`.github/workflows/docker-build.yml`)

**Triggers:**
- Push to `master` or `develop` branches
- Push of version tags (`v*`)
- Manual workflow dispatch

**Actions:**
- Builds frontend and backend images
- Pushes to GHCR with appropriate tags
- Supports multi-platform builds (amd64, arm64)

#### Staging Deployment (`.github/workflows/staging-deploy.yml`)

**Triggers:**
- Push to `master` branch
- Manual workflow dispatch

**Actions:**
- Runs tests
- Deploys to staging server
- Pulls images from GHCR
- Performs health checks

#### Production Deployment (`.github/workflows/production-deploy.yml`)

**Triggers:**
- Push of version tags (`v*`)
- Manual workflow dispatch

**Actions:**
- Runs comprehensive tests
- Deploys to production server
- Uses versioned images from GHCR
- Performs extended health checks

## Usage

### 1. Development Workflow

#### Building Images Locally

```bash
# Build for staging
make build-docker-staging

# Build for production
make build-docker
```

#### Testing Images

```bash
# Run integration tests
make test-integration

# Test with Docker containers
make test-integration
```

### 2. Deployment Workflow

#### Automated Deployment (Recommended)

1. **Push to master**: Automatically triggers staging deployment
2. **Create release tag**: Automatically triggers production deployment
3. **Manual deployment**: Use GitHub Actions UI for manual deployments

#### Manual Deployment

```bash
# Deploy to staging using registry images
make staging-deploy-registry

# Deploy to production using registry images
make production-deploy-registry

# Deploy to staging with local build
make staging-deploy
```

### 3. Registry Management

#### Using the Setup Script

```bash
# Login to registry
./scripts/setup/setup-registry.sh login

# Build and push images
./scripts/setup/setup-registry.sh build --environment staging

# Pull images
./scripts/setup/setup-registry.sh pull --environment production

# Deploy to staging
./scripts/setup/setup-registry.sh deploy-staging

# Deploy to production
./scripts/setup/setup-registry.sh deploy-production

# List available images
./scripts/setup/setup-registry.sh list

# Clean up unused images
./scripts/setup/setup-registry.sh cleanup
```

#### Direct Docker Commands

```bash
# Pull specific images
docker pull ghcr.io/your_username/PLOSolver-frontend:staging-frontend
docker pull ghcr.io/your_username/PLOSolver-backend:staging-backend

# List local images
docker images | grep PLOSolver

# Remove unused images
docker image prune -f
```

## Environment Configuration

### Unified Docker Compose Configuration

**File:** `docker-compose.yml`

The application uses a single docker-compose file with environment-aware configuration:

- **Registry Images**: Uses `FRONTEND_IMAGE` and `BACKEND_IMAGE` environment variables
- **Local Builds**: Falls back to local builds when registry images aren't specified
- **Environment-Specific**: Container names, domains, and SSL configuration based on environment
- **Runtime Configuration**: All settings controlled via environment variables

### Environment Variables

Both environments use environment-specific `.env` files:

- `env.staging`: Staging configuration
- `env.production`: Production configuration

Key variables:
```bash
# Environment identification
ENVIRONMENT=staging|production|development

# Registry images (for registry-based deployments)
FRONTEND_IMAGE=ghcr.io/your_username/PLOSolver-frontend:staging-frontend
BACKEND_IMAGE=ghcr.io/your_username/PLOSolver-backend:staging-backend

# Domain configuration
FRONTEND_DOMAIN=ploscope.com
TRAEFIK_DOMAIN=ploscope.com

# SSL configuration
ACME_EMAIL=admin@crostamusic.com

# GitHub repository
GITHUB_REPOSITORY=your_username/PLOSolver
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors

**Problem:** `unauthorized: authentication required`

**Solution:**
```bash
# Re-login to registry
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin
```

#### 2. Image Pull Errors

**Problem:** `manifest not found`

**Solution:**
```bash
# Check if image exists
docker pull ghcr.io/your_username/PLOSolver-frontend:staging-frontend

# Rebuild and push if missing
./scripts/setup/setup-registry.sh build --environment staging
```

#### 3. Permission Denied

**Problem:** `permission denied` when pushing

**Solution:**
- Ensure GitHub token has `write:packages` permission
- Check repository package permissions
- Verify token is not expired

#### 4. Deployment Failures

**Problem:** Containers fail to start

**Solution:**
```bash
# Check container logs
docker compose -f docker-compose.staging.yml logs

# Check health status
docker compose -f docker-compose.staging.yml ps

# Restart services
docker compose -f docker-compose.staging.yml restart
```

### Debugging Commands

```bash
# Check registry connectivity
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://ghcr.io/v2/

# List local images
docker images | grep PLOSolver

# Check container status
docker ps -a | grep plosolver

# View container logs
docker logs plosolver-frontend-staging
docker logs plosolver-backend-staging

# Check network connectivity
docker network ls
docker network inspect plosolver_plo-network
```

## Security Considerations

### 1. Token Management

- Use GitHub Personal Access Tokens with minimal required permissions
- Rotate tokens regularly
- Store tokens securely in GitHub Secrets

### 2. Image Security

- Regularly update base images
- Scan images for vulnerabilities
- Use multi-stage builds to reduce attack surface

### 3. Network Security

- Use private networks for inter-container communication
- Restrict external access to necessary ports only
- Use HTTPS in production

## Best Practices

### 1. Image Management

- Always tag images with meaningful versions
- Use semantic versioning for releases
- Keep images up to date with security patches

### 2. Deployment Strategy

- Test in staging before production
- Use blue-green deployments for zero-downtime updates
- Monitor deployments with health checks

### 3. Monitoring

- Set up logging aggregation
- Monitor container resource usage
- Implement alerting for failures

### 4. Backup Strategy

- Regular database backups
- Configuration backups
- Image registry backups (if needed)

## Advanced Configuration

### 1. Multi-Environment Setup

For multiple environments, use environment-specific `.env` files:

```bash
env.development
env.staging
env.production
```

The same `docker-compose.yml` file works for all environments by changing the environment file:

```bash
# Development
docker compose --env-file env.development up -d

# Staging
docker compose --env-file env.staging up -d

# Production
docker compose --env-file env.production up -d
```

### 2. Custom Image Tags

Modify the build workflow to support custom tags:

```yaml
- name: Build with custom tag
  run: |
    docker build -t ghcr.io/${{ github.repository }}-frontend:${{ github.sha }}-frontend .
```

### 3. Image Caching

Enable Docker layer caching in GitHub Actions:

```yaml
- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Check container logs on deployment servers
4. Consult the main project documentation

## References

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Traefik Documentation](https://doc.traefik.io/traefik/)