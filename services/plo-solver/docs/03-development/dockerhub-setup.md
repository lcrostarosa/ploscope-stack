# DockerHub Setup Guide

This guide explains how to set up DockerHub integration for the PLOSolver project, including creating access tokens and configuring GitHub Actions.

## Overview

The project has been migrated from GitHub Container Registry (GHCR) to DockerHub for image storage. The new image naming convention is:

- **Frontend**: `ploscope/frontend`
- **Backend**: `ploscope/backend` 
- **Celery Worker**: `ploscope/celery-worker`

## Prerequisites

1. A DockerHub account
2. Access to the `ploscope` organization on DockerHub
3. GitHub repository access for setting up secrets

## Step 1: Create DockerHub Access Token

### 1.1 Log into DockerHub
1. Go to [hub.docker.com](https://hub.docker.com)
2. Sign in with your DockerHub account

### 1.2 Create Access Token
1. Click on your username in the top-right corner
2. Select **Account Settings**
3. Navigate to **Security** in the left sidebar
4. Click **New Access Token**
5. Fill in the details:
   - **Token name**: `PLOSolver-GitHub-Actions` (or any descriptive name)
   - **Access permissions**: Select **Read & Write**
6. Click **Generate**
7. **Important**: Copy the token immediately - you won't be able to see it again!

### 1.3 Token Permissions
The token should have the following permissions:
- **Read & Write** access to repositories
- Ability to push to the `ploscope` organization

## Step 2: Configure GitHub Repository Secrets

### 2.1 Add DockerHub Credentials to GitHub
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | Your DockerHub username |
| `DOCKERHUB_TOKEN` | The access token you created in Step 1 |

### 2.2 Verify Secrets
You should now have these secrets available in your GitHub Actions workflows:
- `${{ secrets.DOCKERHUB_USERNAME }}`
- `${{ secrets.DOCKERHUB_TOKEN }}`

## Step 3: Local Development Setup

### 3.1 Environment Variables
Create a `env.dockerhub` file in your project root (optional):

```bash
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-token
DOCKERHUB_REPOSITORY=ploscope
ENVIRONMENT=development
```

### 3.2 Using the DockerHub Setup Script
The project includes a setup script for local development:

```bash
# Make the script executable (if not already done)
chmod +x scripts/development/dockerhub-setup.sh

# Authenticate with DockerHub
./scripts/development/dockerhub-setup.sh auth

# Build and push an image locally
./scripts/development/dockerhub-setup.sh build frontend latest
./scripts/development/dockerhub-setup.sh build backend production
./scripts/development/dockerhub-setup.sh build celery-worker staging

# Pull images from DockerHub
./scripts/development/dockerhub-setup.sh pull frontend development

# Update docker-compose files to use DockerHub images
./scripts/development/dockerhub-setup.sh update-compose

# Complete setup (auth + update-compose)
./scripts/development/dockerhub-setup.sh setup
```

## Step 4: Docker Compose Configuration

### 4.1 Updated Image References
All docker-compose files have been updated to use the new DockerHub images:

```yaml
# Main docker-compose.yml
frontend:
  image: ploscope/frontend:${ENVIRONMENT:-development}

backend:
  image: ploscope/backend:${ENVIRONMENT:-development}

celeryworker:
  image: ploscope/celery-worker:${ENVIRONMENT:-development}
```

### 4.2 Environment-Specific Files
- `docker-compose.staging.yml` - Uses `ploscope/frontend:staging`, etc.
- `docker-compose.production.yml` - Uses `ploscope/frontend:production`, etc.

## Step 5: GitHub Actions Workflow

### 5.1 Updated Workflows
The GitHub Actions workflows have been updated to:

1. **Build and Push Images** (`.github/workflows/build-and-push-images.yml`):
   - Uses DockerHub registry (`docker.io`)
   - Pushes to `ploscope` organization
   - Supports multiple environments (development, staging, production)

2. **CI/CD Pipeline** (`.github/workflows/ci.yml`):
   - Updated image references
   - Uses DockerHub secrets

### 5.2 Workflow Triggers
Images are automatically built and pushed when:
- Code is pushed to `main` or `master` branches
- Tags are created (e.g., `v1.0.0`)
- Manual workflow dispatch

## Step 6: Testing the Setup

### 6.1 Verify GitHub Actions
1. Push a change to the main branch
2. Check the GitHub Actions tab
3. Verify that images are being built and pushed to DockerHub

### 6.2 Test Local Deployment
```bash
# Pull the latest images
docker pull ploscope/frontend:development
docker pull ploscope/backend:development
docker pull ploscope/celery-worker:development

# Run the application
docker-compose up -d
```

### 6.3 Verify Image Availability
Check that images are available on DockerHub:
- [ploscope/frontend](https://hub.docker.com/r/ploscope/frontend)
- [ploscope/backend](https://hub.docker.com/r/ploscope/backend)
- [ploscope/celery-worker](https://hub.docker.com/r/ploscope/celery-worker)

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
**Problem**: `unauthorized: authentication required`
**Solution**: 
- Verify your DockerHub username and token
- Ensure the token has the correct permissions
- Check that secrets are properly set in GitHub

#### 2. Push Permission Denied
**Problem**: `denied: requested access to the resource is denied`
**Solution**:
- Verify you have write access to the `ploscope` organization
- Check that your access token has "Read & Write" permissions
- Ensure you're a member of the DockerHub organization

#### 3. Image Not Found
**Problem**: `manifest for ploscope/frontend:latest not found`
**Solution**:
- Verify the image exists on DockerHub
- Check the correct tag name
- Ensure the image was successfully pushed

#### 4. GitHub Actions Failures
**Problem**: Workflow fails with authentication errors
**Solution**:
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are set
- Check that the secrets are not empty
- Ensure the token hasn't expired

### Debugging Commands

```bash
# Test DockerHub authentication locally
docker login -u your-username

# Check available images
docker search ploscope

# Verify image tags
docker pull ploscope/frontend:development

# Check GitHub Actions logs
# Go to Actions tab in GitHub repository
```

## Security Considerations

### 1. Token Security
- Never commit tokens to version control
- Use GitHub secrets for sensitive data
- Rotate tokens regularly
- Use minimal required permissions

### 2. Organization Access
- Only grant necessary permissions to team members
- Use organization-level access tokens when possible
- Monitor token usage and access logs

### 3. Image Security
- Scan images for vulnerabilities
- Use specific version tags instead of `latest`
- Implement image signing for production deployments

## Migration Notes

### From GHCR to DockerHub
The migration involved:
1. Updating all image references from `ghcr.io/username/PLOSolver-*` to `ploscope/*`
2. Changing authentication from GitHub tokens to DockerHub tokens
3. Updating GitHub Actions workflows
4. Modifying docker-compose files to use pre-built images

### Rollback Plan
If issues arise, you can:
1. Revert to the previous GHCR configuration
2. Update secrets back to GitHub tokens
3. Revert docker-compose files to use build contexts

## Support

For issues related to:
- **DockerHub setup**: Check this guide and DockerHub documentation
- **GitHub Actions**: Review workflow logs and GitHub Actions documentation
- **Docker Compose**: Check docker-compose documentation and logs

## Additional Resources

- [DockerHub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [DockerHub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/) 