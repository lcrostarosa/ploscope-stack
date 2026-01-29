# Nexus Repository Staging Environment Setup

This document explains how to set up and deploy Nexus Repository in the staging environment using Docker.

## Overview

The staging environment Nexus Repository provides a production-like environment for testing PyPI package hosting before deploying to production. It includes:

- **HTTPS Support**: SSL/TLS termination via Traefik
- **Domain Routing**: Accessible via `nexus.staging.ploscope.com`
- **Automated Setup**: Scripts for deployment and configuration
- **Monitoring**: Health checks and logging
- **Security**: Staging-specific credentials and access controls

## Architecture

### Network Architecture

```
Internet → Traefik (SSL/TLS) → Nexus Repository (8081)
                              ↓
                         Docker Network: staging-network
```

### Repository Structure

- **pypi-internal** (Hosted): Staging-specific packages
- **pypi-proxy** (Proxy): Caches from PyPI.org
- **pypi-all** (Group): Combined access point

## Prerequisites

### System Requirements

- Docker and Docker Compose
- Access to staging environment
- DNS configuration for `nexus.staging.ploscope.com`
- Traefik reverse proxy running

### Network Requirements

- Port 8081 available for Nexus
- Staging network accessible
- SSL certificate for domain

## Quick Start

### 1. Deploy Nexus Repository

```bash
# Deploy to staging environment
make nexus-staging-deploy

# Or manually
./scripts/deployment/deploy-nexus-staging.sh
```

### 2. Set up repositories

```bash
# Configure PyPI repositories
make nexus-staging-setup

# Or manually
./scripts/setup/setup-nexus-staging.sh
```

### 3. Verify deployment

```bash
# Check deployment status
make nexus-staging-status

# Verify connectivity
make nexus-staging-verify
```

### 4. Access Nexus Repository

- **Web Interface**: https://nexus.staging.ploscope.com
- **API Endpoint**: https://nexus.staging.ploscope.com/service/rest/v1
- **Admin Credentials**: admin / admin-staging-123

## Detailed Setup

### Environment Configuration

The staging environment uses the following configuration:

```bash
# Load environment variables
source nexus-staging.env

# Or set manually
export NEXUS_URL=https://nexus.staging.ploscope.com
export NEXUS_ADMIN_PASSWORD=admin-staging-123
export NEXUS_PYPI_PASSWORD=********
```

### Docker Compose Configuration

The staging deployment uses `docker-compose-staging-nexus.yml`:

```yaml
version: '3.8'

services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: plosolver-staging-nexus
    restart: unless-stopped
    environment:
      - NEXUS_SECURITY_RANDOMPASSWORD=false
      - NEXUS_CONTEXT=/
    volumes:
      - nexus-staging-data:/nexus-data
      - ./server/nexus/staging/logs:/opt/sonatype/nexus/logs
    networks:
      - staging-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nexus.rule=Host(`nexus.staging.ploscope.com`)"
      - "traefik.http.routers.nexus.entrypoints=websecure"
      - "traefik.http.routers.nexus.tls.certresolver=letsencrypt"
      - "traefik.http.routers.nexus.middlewares=cors-headers"
      - "traefik.http.services.nexus.loadbalancer.server.port=8081"
      - "traefik.docker.network=staging-network"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/service/rest/v1/status"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s
```

### Traefik Integration

Nexus Repository is integrated with Traefik for SSL termination and routing:

```yaml
# Traefik router configuration
nexus-https:
  rule: "Host(`nexus.staging.ploscope.com`)"
  priority: 1
  service: nexus
  entrypoints:
    - websecure
  middlewares:
    - cors-headers
  tls:
    certResolver: letsencrypt

# Traefik service configuration
nexus:
  loadBalancer:
    servers:
      - url: "http://nexus:8081"
```

## Usage

### Publishing Packages

#### Using twine

```bash
# Configure twine for staging
export TWINE_REPOSITORY_URL=https://nexus.staging.ploscope.com/repository/pypi-internal/
export TWINE_USERNAME=pypi-publisher
export TWINE_PASSWORD=********

# Publish package
twine upload dist/*
```

#### Using .pypirc

Create `.pypirc.staging`:

```ini
[distutils]
index-servers =
    nexus-staging

[nexus-staging]
repository: https://nexus.staging.ploscope.com/repository/pypi-internal/
username: pypi-publisher
password: ********
```

Then publish:

```bash
twine upload --repository nexus-staging dist/*
```

### Installing Packages

#### Configure pip

```bash
# Set Nexus as the default index
pip config set global.index-url https://nexus.staging.ploscope.com/repository/pypi-all/simple
pip config set global.trusted-host nexus.staging.ploscope.com

# Install packages
pip install plosolver-core
```

#### Using pip.conf

Create `pip.conf.staging`:

```ini
[global]
index = https://nexus.staging.ploscope.com/repository/pypi-all/pypi
index-url = https://nexus.staging.ploscope.com/repository/pypi-all/simple
trusted-host = nexus.staging.ploscope.com
```

### Docker Integration

#### Dockerfile Configuration

```dockerfile
# Configure pip for staging Nexus Repository
RUN pip config set global.index-url https://nexus.staging.ploscope.com/repository/pypi-all/simple && \
    pip config set global.trusted-host nexus.staging.ploscope.com

# Install packages
RUN pip install plosolver-core
```

#### Docker Compose

```yaml
services:
  app:
    build: .
    depends_on:
      - nexus
    environment:
      - PIP_INDEX_URL=https://nexus.staging.ploscope.com/repository/pypi-all/simple
      - PIP_TRUSTED_HOST=nexus.staging.ploscope.com
```

## Management Commands

### Deployment Commands

```bash
# Deploy Nexus Repository
make nexus-staging-deploy

# Set up repositories
make nexus-staging-setup

# Check status
make nexus-staging-status

# View logs
make nexus-staging-logs

# Verify deployment
make nexus-staging-verify

# Rollback deployment
make nexus-staging-rollback
```

### Manual Commands

```bash
# Start Nexus Repository
docker-compose -f docker-compose-staging-nexus.yml up -d

# Stop Nexus Repository
docker-compose -f docker-compose-staging-nexus.yml down

# View logs
docker-compose -f docker-compose-staging-nexus.yml logs -f nexus

# Access container
docker exec -it plosolver-staging-nexus bash
```

## Monitoring and Logging

### Health Checks

Nexus Repository includes health checks:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8081/service/rest/v1/status"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 120s
```

### Logging

Logs are available at:

- **Container logs**: `docker-compose -f docker-compose-staging-nexus.yml logs nexus`
- **File logs**: `./server/nexus/staging/logs/nexus.log`

### Monitoring

Monitor Nexus Repository via:

- **Web Interface**: https://nexus.staging.ploscope.com
- **API Status**: https://nexus.staging.ploscope.com/service/rest/v1/status
- **Health Check**: Docker health check status

## Security

### Authentication

- **Admin User**: admin / admin-staging-123
- **PyPI Publisher**: pypi-publisher / pypi-publisher-staging-123

### Network Security

- HTTPS enforced via Traefik
- SSL certificates managed by Let's Encrypt
- CORS headers configured
- Internal network isolation

### Access Control

- Repository-specific permissions
- User role-based access
- Audit logging enabled

## Troubleshooting

### Common Issues

#### Nexus not starting

```bash
# Check Docker logs
docker-compose -f docker-compose-staging-nexus.yml logs nexus

# Check if port 8081 is available
netstat -tulpn | grep 8081

# Check network connectivity
docker network ls | grep staging-network
```

#### SSL/TLS Issues

```bash
# Check Traefik configuration
docker-compose -f docker-compose-staging-nexus.yml logs traefik

# Verify SSL certificate
curl -I https://nexus.staging.ploscope.com

# Check DNS resolution
nslookup nexus.staging.ploscope.com
```

#### Package Upload Failures

```bash
# Check authentication
curl -u pypi-publisher:${NEXUS_PYPI_PASSWORD} \
  https://nexus.staging.ploscope.com/service/rest/v1/status

# Verify repository exists
curl https://nexus.staging.ploscope.com/service/rest/v1/repositories
```

#### Package Installation Failures

```bash
# Check pip configuration
pip config list

# Test repository access
curl https://nexus.staging.ploscope.com/repository/pypi-all/simple/

# Verify SSL certificate
openssl s_client -connect nexus.staging.ploscope.com:443
```

### Debugging Commands

```bash
# Check container status
docker ps | grep nexus

# View real-time logs
docker-compose -f docker-compose-staging-nexus.yml logs -f nexus

# Access Nexus container
docker exec -it plosolver-staging-nexus bash

# Check Nexus configuration
docker exec -it plosolver-staging-nexus cat /opt/sonatype/nexus/etc/nexus.properties
```

## Backup and Recovery

### Backup

```bash
# Backup Nexus data
docker run --rm -v plosolver-staging-nexus_nexus-staging-data:/data \
  -v $(pwd):/backup alpine tar czf /backup/nexus-staging-backup.tar.gz -C /data .
```

### Recovery

```bash
# Restore Nexus data
docker run --rm -v plosolver-staging-nexus_nexus-staging-data:/data \
  -v $(pwd):/backup alpine tar xzf /backup/nexus-staging-backup.tar.gz -C /data
```

## CI/CD Integration

### GitHub Actions

Add these secrets to your GitHub repository:

```yaml
NEXUS_STAGING_URL: https://nexus.staging.ploscope.com
NEXUS_STAGING_USERNAME: pypi-publisher
NEXUS_STAGING_PASSWORD: pypi-publisher-staging-123
```

### Workflow Configuration

```yaml
- name: Publish to Staging Nexus
  run: |
    twine upload --repository-url ${{ secrets.NEXUS_STAGING_URL }}/repository/pypi-internal/ \
      --username ${{ secrets.NEXUS_STAGING_USERNAME }} \
      --password ${{ secrets.NEXUS_STAGING_PASSWORD }} \
      dist/*
```

## Best Practices

### Security

- Use strong passwords for staging environment
- Regularly rotate credentials
- Monitor access logs
- Enable audit logging

### Performance

- Monitor disk usage
- Configure cleanup policies
- Use appropriate cache settings
- Monitor network performance

### Maintenance

- Regular backups
- Monitor log files
- Update Nexus version
- Clean up old packages

## References

- [Nexus Repository Documentation](https://help.sonatype.com/repomanager3/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PyPI Repository Configuration](https://help.sonatype.com/en/pypi-repositories.html)
