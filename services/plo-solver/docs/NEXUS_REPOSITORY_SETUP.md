# Nexus Repository Setup for PyPI Packages

This document explains how to set up and use Nexus Repository for hosting PyPI packages, replacing GitHub Packages for the `plosolver-core` package.

## Overview

Nexus Repository provides a robust, enterprise-grade solution for hosting PyPI packages with the following benefits:

- **Reliability**: More stable than GitHub Packages for Python
- **Performance**: Local caching and faster downloads
- **Security**: Enterprise-grade security features
- **Flexibility**: Support for multiple repository types (hosted, proxy, group)
- **Integration**: Easy integration with CI/CD pipelines

## Architecture

The setup includes three repository types:

1. **pypi-internal** (Hosted): Stores our custom packages
2. **pypi-proxy** (Proxy): Caches packages from PyPI.org
3. **pypi-all** (Group): Combines both repositories for easy access

## Quick Start

### 1. Start Nexus Repository

```bash
# Start Nexus using Docker Compose
make nexus-start

# Or manually
docker-compose -f docker-compose-nexus.yml up -d
```

### 2. Set up PyPI repositories

```bash
# Run the setup script
make nexus-setup

# Or manually
./scripts/setup/setup-nexus-pypi.sh
```

### 3. Publish a package

```bash
# Publish to local Nexus
make nexus-publish-local

# Or publish via GitHub Actions (recommended)
make publish-package
```

### 4. Install packages

```bash
# Install from Nexus Repository
make nexus-install

# Or manually configure pip
pip config set global.index-url http://localhost:8081/repository/pypi-all/simple
pip config set global.trusted-host localhost
pip install plosolver-core
```

## Detailed Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.11+
- pip, build, and twine

### Environment Variables

You can customize the setup using environment variables:

```bash
export NEXUS_URL="http://localhost:8081"
export NEXUS_ADMIN_USER="admin"
export NEXUS_ADMIN_PASSWORD="admin123"
export REPOSITORY_NAME="pypi-internal"
export REPOSITORY_GROUP_NAME="pypi-all"
```

### Repository Configuration

#### Hosted Repository (pypi-internal)

- **Purpose**: Stores our custom packages
- **URL**: `http://localhost:8081/repository/pypi-internal/`
- **Access**: Read/Write for authenticated users

#### Proxy Repository (pypi-proxy)

- **Purpose**: Caches packages from PyPI.org
- **Remote URL**: `https://pypi.org/`
- **Access**: Read-only, automatic caching

#### Group Repository (pypi-all)

- **Purpose**: Combines hosted and proxy repositories
- **URL**: `http://localhost:8081/repository/pypi-all/`
- **Access**: Single endpoint for all PyPI packages

### User Management

The setup creates a dedicated user for package publishing:

- **Username**: `pypi-publisher`
- **Password**: `********`
- **Permissions**: Repository admin for PyPI repositories

## Usage Examples

### Publishing Packages

#### Local Publishing

```bash
# Build the package
cd src/plosolver_core
python -m build

# Publish to Nexus
twine upload --repository nexus dist/*
```

#### GitHub Actions Publishing

```bash
# Trigger workflow manually
make publish-package

# Or create a tag
make publish-tag
```

### Installing Packages

#### Configure pip for Nexus

```bash
# Set Nexus as the default index
pip config set global.index-url http://localhost:8081/repository/pypi-all/simple
pip config set global.trusted-host localhost

# Install packages
pip install plosolver-core
```

#### Using pip.conf

Create a `pip.conf` file:

```ini
[global]
index = http://localhost:8081/repository/pypi-all/pypi
index-url = http://localhost:8081/repository/pypi-all/simple
trusted-host = localhost
```

#### Using .pypirc for publishing

Create a `.pypirc` file:

```ini
[distutils]
index-servers =
    nexus

[nexus]
repository: http://localhost:8081/repository/pypi-internal/
username: pypi-publisher
password: ********
```

### Docker Integration

#### Dockerfile Configuration

```dockerfile
# Configure pip for Nexus Repository
RUN pip config set global.index-url http://nexus:8081/repository/pypi-all/simple && \
    pip config set global.trusted-host nexus

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
      - PIP_INDEX_URL=http://nexus:8081/repository/pypi-all/simple
      - PIP_TRUSTED_HOST=nexus
```

## CI/CD Integration

### GitHub Actions Secrets

Configure these secrets in your GitHub repository:

- `NEXUS_URL`: Nexus Repository URL
- `NEXUS_USERNAME`: Username for publishing
- `NEXUS_PASSWORD`: Password for publishing

### Workflow Configuration

The GitHub Actions workflow automatically:

1. Builds the package
2. Updates version numbers
3. Publishes to Nexus Repository
4. Creates a GitHub release

## Monitoring and Management

### Web Interface

Access the Nexus web interface at `http://localhost:8081`:

- **Username**: `admin`
- **Password**: `admin123`

### Repository Management

- Browse packages: Navigate to Repositories → pypi-internal
- View logs: System → Logging
- Monitor health: System → Health Check

### Backup and Restore

```bash
# Backup Nexus data
docker run --rm -v plosolver-nexus_nexus-data:/data -v $(pwd):/backup alpine tar czf /backup/nexus-backup.tar.gz -C /data .

# Restore Nexus data
docker run --rm -v plosolver-nexus_nexus-data:/data -v $(pwd):/backup alpine tar xzf /backup/nexus-backup.tar.gz -C /data
```

## Troubleshooting

### Common Issues

#### Nexus not starting

```bash
# Check Docker logs
docker-compose -f docker-compose-nexus.yml logs nexus

# Check if port 8081 is available
netstat -tulpn | grep 8081
```

#### Package upload failures

```bash
# Check authentication
curl -u pypi-publisher:${NEXUS_PYPI_PASSWORD} http://localhost:8081/service/rest/v1/status

# Verify repository exists
curl -u admin:admin123 http://localhost:8081/service/rest/v1/repositories
```

#### Package installation failures

```bash
# Check pip configuration
pip config list

# Test repository access
curl http://localhost:8081/repository/pypi-all/simple/
```

### Logs and Debugging

```bash
# View Nexus logs
docker-compose -f docker-compose-nexus.yml logs -f nexus

# Check repository health
curl http://localhost:8081/service/rest/v1/status
```

## Security Considerations

### Authentication

- Use strong passwords for admin and publisher users
- Consider using LDAP integration for enterprise environments
- Regularly rotate credentials

### Network Security

- Use HTTPS in production
- Configure firewall rules appropriately
- Consider VPN access for remote teams

### Package Security

- Enable content validation
- Use cleanup policies to remove old packages
- Monitor for security vulnerabilities

## Migration from GitHub Packages

### Step 1: Set up Nexus Repository

```bash
make nexus-start
make nexus-setup
```

### Step 2: Update configuration files

- Update `requirements.txt` files
- Configure CI/CD pipelines
- Update documentation

### Step 3: Publish packages to Nexus

```bash
make nexus-publish-local
```

### Step 4: Test installation

```bash
make nexus-install
```

### Step 5: Update GitHub Actions

- Add Nexus secrets
- Update workflow files
- Test automated publishing

## Best Practices

### Package Management

- Use semantic versioning
- Include comprehensive metadata
- Test packages before publishing

### Repository Management

- Regular backups
- Monitor disk usage
- Clean up old packages

### CI/CD Integration

- Use automated testing
- Implement version validation
- Monitor build success rates

## References

- [Nexus Repository Documentation](https://help.sonatype.com/repomanager3/)
- [PyPI Repository Configuration](https://help.sonatype.com/en/pypi-repositories.html)
- [Twine Documentation](https://twine.readthedocs.io/)
- [Pip Configuration](https://pip.pypa.io/en/stable/topics/configuration/)
