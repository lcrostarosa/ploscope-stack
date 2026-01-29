# GitHub Container Registry (GHCR) Setup

This document explains how to set up and use GitHub Container Registry (GHCR) for the PLOSolver project.

## Overview

GitHub Container Registry allows you to store and manage Docker images directly in your GitHub repository. This setup provides:

- Automated image building and pushing via GitHub Actions
- Version control for Docker images
- Easy deployment across different environments
- Reduced build times in production deployments

## Prerequisites

1. **GitHub Personal Access Token**: Create a token with `write:packages` and `read:packages` permissions
2. **Docker**: Ensure Docker is installed and running locally
3. **GitHub Repository**: Your repository should be connected to GitHub

## Setup Instructions

### 1. Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate a new token with the following permissions:
   - `write:packages`
   - `read:packages`
   - `repo` (for private repositories)
3. Copy the token and keep it secure

### 2. Configure Environment Variables

Set the following environment variables:

```bash
export GITHUB_USERNAME="your-github-username"
export GITHUB_TOKEN="your-personal-access-token"
export GITHUB_REPOSITORY="your-username/PLOSolver"
export ENVIRONMENT="development"  # or staging, production
```

### 3. Authenticate with GHCR

Run the setup script to authenticate:

```bash
./scripts/development/ghcr-setup.sh auth
```

### 4. Build and Push Images

#### Option A: Using GitHub Actions (Recommended)

The GitHub Actions workflow will automatically build and push images when you:

- Push to `main` or `master` branch
- Create a tag starting with `v*` (e.g., `v1.0.0`)
- Create a pull request

#### Option B: Manual Build and Push

Build and push images locally:

```bash
# Build and push frontend
./scripts/development/ghcr-setup.sh build frontend latest

# Build and push backend
./scripts/development/ghcr-setup.sh build backend latest

# Build with specific environment
ENVIRONMENT=production ./scripts/development/ghcr-setup.sh build frontend production
```

### 5. Update Docker Compose

Update your `docker-compose.yml` to use GHCR images:

```bash
./scripts/development/ghcr-setup.sh update-compose
```

Or run the complete setup:

```bash
./scripts/development/ghcr-setup.sh setup
```

## Image Naming Convention

Images are named using the following pattern:
```
ghcr.io/{repository}-{service}:{environment}
```

Examples:
- `ghcr.io/your-username/PLOSolver-frontend:development`
- `ghcr.io/your-username/PLOSolver-backend:production`
- `ghcr.io/your-username/PLOSolver-frontend:v1.0.0`

## Available Script Commands

The `ghcr-setup.sh` script provides the following commands:

| Command | Description |
|---------|-------------|
| `auth` | Authenticate with GHCR |
| `build [frontend\|backend] [tag]` | Build and push image locally |
| `pull [frontend\|backend] [tag]` | Pull image from GHCR |
| `list [frontend\|backend]` | List available images |
| `update-compose` | Update docker-compose.yml to use GHCR images |
| `setup` | Complete setup (auth + update-compose) |
| `help` | Show help message |

## GitHub Actions Workflow

The workflow file `.github/workflows/build-and-push-images.yml` automatically:

1. **Builds images** for both frontend and backend
2. **Pushes to GHCR** with appropriate tags
3. **Supports multiple environments** (development, staging, production)
4. **Uses Docker layer caching** for faster builds
5. **Builds for multiple architectures** (amd64, arm64)

### Workflow Triggers

- **Push to main/master**: Builds and pushes with branch name tag
- **Tag push (v*)**: Builds and pushes with version tag
- **Pull request**: Builds but doesn't push (for testing)

### Environment-Specific Builds

When pushing to main/master or creating tags, the workflow also builds environment-specific images:

- `ghcr.io/repo-frontend:development`
- `ghcr.io/repo-frontend:staging`
- `ghcr.io/repo-frontend:production`

## Usage in Docker Compose

After setup, your `docker-compose.yml` will use GHCR images:

```yaml
frontend:
  image: ghcr.io/your-username/PLOSolver-frontend:development
  # ... other configuration

backend:
  image: ghcr.io/your-username/PLOSolver-backend:development
  # ... other configuration
```

## Environment Variables

The following environment variables control the GHCR setup:

| Variable | Description | Default |
|----------|-------------|---------|
| `GITHUB_USERNAME` | Your GitHub username | - |
| `GITHUB_TOKEN` | GitHub Personal Access Token | - |
| `GITHUB_REPOSITORY` | Repository name (auto-detected) | - |
| `ENVIRONMENT` | Environment tag | `development` |

## Troubleshooting

### Authentication Issues

1. **Invalid token**: Ensure your GitHub token has the correct permissions
2. **Repository access**: For private repositories, ensure the token has `repo` access
3. **Token expiration**: GitHub tokens can expire; create a new one if needed

### Image Pull Issues

1. **Image not found**: Ensure the image was built and pushed successfully
2. **Permission denied**: Check that your Docker is authenticated with GHCR
3. **Network issues**: Verify internet connectivity and GitHub availability

### Build Issues

1. **Docker not running**: Ensure Docker Desktop is started
2. **Insufficient resources**: Increase Docker memory/CPU allocation
3. **Build context**: Ensure you're running commands from the project root

## Security Considerations

1. **Token security**: Never commit GitHub tokens to version control
2. **Image scanning**: Consider enabling GitHub's security scanning for container images
3. **Access control**: Use repository permissions to control who can push images
4. **Image signing**: Consider implementing image signing for production deployments

## Best Practices

1. **Use semantic versioning** for production releases
2. **Tag images appropriately** for different environments
3. **Regular cleanup** of old images to save storage
4. **Monitor image sizes** and optimize Dockerfiles
5. **Use multi-stage builds** to reduce final image size
6. **Implement health checks** in your Dockerfiles

## Migration from Local Builds

If you're migrating from local builds to GHCR:

1. **Backup your current setup**: The script creates backups automatically
2. **Test the new images**: Pull and test images before switching
3. **Update CI/CD pipelines**: Ensure they use GHCR images
4. **Update documentation**: Update deployment guides and runbooks

## Support

For issues with GHCR setup:

1. Check the GitHub Actions logs for build errors
2. Verify your GitHub token permissions
3. Ensure your repository has the correct settings
4. Review the Docker build logs for image-specific issues 