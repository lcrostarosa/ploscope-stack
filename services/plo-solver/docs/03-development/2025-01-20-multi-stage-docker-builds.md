# Multi-Stage Docker Builds

This document explains the multi-stage Docker build optimizations implemented for the PLO Solver application to reduce image sizes and improve build efficiency.

## Overview

All Docker images (Frontend, Backend, and Celery) have been converted to use multi-stage builds, which significantly reduce the final image size by separating build dependencies from runtime dependencies.

## Architecture

### Build Stage
- Contains all build tools and dependencies
- Compiles/transpiles the application
- Creates optimized artifacts

### Production Stage
- Contains only runtime dependencies
- Copies artifacts from build stage
- Minimal image size for deployment

## Frontend Multi-Stage Build

### Build Stage
```dockerfile
FROM node:24-alpine AS builder
# Install all dependencies (including dev dependencies)
# Build the React application
# Create optimized static files in /app/dist
```

### Production Stage
```dockerfile
FROM node:24-alpine AS production
# Install only 'serve' for static file serving
# Copy built application from builder stage
# Run as non-root user
```

**Benefits:**
- Removes all Node.js dev dependencies after build
- Eliminates build tools and source code from final image
- Reduces image size by ~60-80%

## Backend Multi-Stage Build

### Build Stage
```dockerfile
FROM python:3.11-slim AS builder
# Install build dependencies (gcc, g++)
# Create virtual environment
# Install all Python dependencies
```

### Production Stage
```dockerfile
FROM python:3.11-slim AS production
# Install only runtime system dependencies
# Copy virtual environment from builder
# Copy application code
# Run as non-root user
```

**Benefits:**
- Removes build tools (gcc, g++) from final image
- Uses virtual environment for clean dependency isolation
- Reduces image size by ~40-60%

## Celery Multi-Stage Build

### Build Stage
```dockerfile
FROM python:3.11-slim AS builder
# Install build dependencies
# Create virtual environment
# Install Python dependencies
```

### Production Stage
```dockerfile
FROM python:3.11-slim AS production
# Install only runtime dependencies
# Copy virtual environment from builder
# Copy application code
# Run as non-root user
```

**Benefits:**
- Consistent with backend optimization strategy
- Reduces image size by ~40-60%

## Testing Multi-Stage Builds

Use the provided test script to build and measure image sizes:

```bash
./scripts/development/test-multi-stage-builds.sh
```

This script will:
1. Build all three services with multi-stage builds
2. Display the final image sizes
3. Provide cleanup commands

## CI/CD Integration

The GitHub Actions workflow (`build-and-push-images.yml`) automatically uses the multi-stage builds:

- **Frontend**: `src/frontend/Dockerfile`
- **Backend**: `src/backend/Dockerfile`
- **Celery**: `src/celery/Dockerfile`

All images are built for both `linux/amd64` and `linux/arm64` platforms.

## Build Arguments

### Frontend
- `NODE_ENV`: Environment (production, development, staging)
- `REACT_APP_*`: Various React environment variables
- `REACT_APP_FEATURE_*`: Feature flags

### Backend
- `BUILD_ENV`: Build environment (production, test, development)

### Celery
- Inherits backend build arguments
- Uses same virtual environment strategy

## Security Benefits

1. **Non-root users**: All production stages run as non-root users
2. **Minimal attack surface**: Reduced number of packages in final images
3. **No build tools**: Build dependencies are not present in production images
4. **Virtual environments**: Clean Python dependency isolation

## Performance Benefits

1. **Smaller images**: Faster deployment and reduced storage costs
2. **Better caching**: Build dependencies are cached separately
3. **Faster pulls**: Smaller images download faster
4. **Reduced memory footprint**: Less unused software in containers

## Best Practices

1. **Layer optimization**: Dependencies are installed before copying source code
2. **Cache utilization**: Build stages leverage Docker layer caching
3. **Security**: Production stages run as non-root users
4. **Health checks**: All images include appropriate health checks
5. **Multi-platform**: Images support both AMD64 and ARM64 architectures

## Troubleshooting

### Build Issues
- Ensure all required files are copied in the correct order
- Check that build arguments are properly passed
- Verify virtual environment paths are correct

### Runtime Issues
- Confirm all runtime dependencies are installed in production stage
- Check that non-root user has proper permissions
- Verify health check endpoints are accessible

### Size Optimization
- Use `.dockerignore` files to exclude unnecessary files
- Consider using Alpine Linux for even smaller base images
- Remove package manager caches in the same RUN command 