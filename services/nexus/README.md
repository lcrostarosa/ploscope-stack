# Nexus Repository Manager

This directory contains the Nexus Repository Manager configuration for the PLOSolver project.

## Overview

Nexus Repository Manager is used to host private PyPI and NPM packages and other artifacts for the PLOSolver project. It's now deployed as a separate service that connects to the main staging environment via an external Docker network.

## Architecture

The Nexus service is deployed independently from the main PLOSolver staging environment but connects to it via an external Docker network (`plo-network-staging`). This allows:

- Independent deployment and management of Nexus
- Access to the same Traefik reverse proxy for SSL termination
- Communication with other services in the staging environment
- Separate scaling and maintenance cycles

## Authenticating with Nexus
If you do not need to run or manage nexus need ot authenticate, use this
```bash
./setup_nexus_keyring.sh -u username -p password

#or 

 make auth-nexus USER=myuser PASS=mypass
```

## Deployment

### Automated Deployment (Recommended)

The Nexus repository is automatically deployed using GitHub Actions when changes are pushed to the `main` or `develop` branches.

#### Prerequisites

1. **GitHub Secrets**: Configure the following secrets in your GitHub repository:
   - `HOST`: Server hostname/IP
   - `SSH_USER`: SSH username for server
   - `SSH_KEY`: SSH private key for server
   - `DOCKERHUB_USERNAME`: Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub access token

2. **Server Prerequisites**: The target server must have:
   - Docker and Docker Compose installed
   - Git installed
   - SSH access configured

#### Repository Handling

The deployment workflow automatically handles repository setup:
- **First deployment**: Clones the repository if it doesn't exist
- **Subsequent deployments**: Pulls latest changes from the main branch
- **Branch management**: Uses `main` branch for deployment

#### Configuration Application

The deployment workflow automatically applies Nexus configuration:
- **Configuration parsing**: Reads `nexus.yml` and applies settings via REST API
- **Repository setup**: Creates/updates PyPI and NPM repositories (hosted, proxy, group)
- **User management**: Creates/updates users and permissions
- **Environment variables**: Supports variable substitution from environment files

#### Manual Deployment

For manual deployment or initial setup:

```bash
# Initialize deployment environment (first time only)
./scripts/init-deployment.sh

# Deploy manually
./scripts/deploy-nexus.sh

# Apply configuration manually (if needed)
./scripts/apply-nexus-config.sh
```

### Manual Deployment (Legacy)

#### Prerequisites

1. The main PLOSolver staging environment must be running first
2. The external network `plosolver_plo-network-staging` must exist

#### Starting Nexus

```bash
# Navigate to the nexus directory
cd server/nexus

# Start Nexus with external network
docker-compose -f docker-compose-nexus.yml up -d
```

### Stopping Nexus

```bash
# Stop Nexus
docker-compose -f docker-compose-nexus.yml down

# To also remove volumes (WARNING: This will delete all Nexus data)
docker-compose -f docker-compose-nexus.yml down -v
```

## Configuration

### Nexus Configuration File

The Nexus configuration is defined in `nexus.yml` and includes:
- **Repository definitions**: PyPI and NPM hosted, proxy, and group repositories
- **User management**: User accounts and permissions
- **Security settings**: Authentication and authorization
- **Storage configuration**: Blob stores and cleanup policies

### Environment Variables

The Nexus service uses the environment file (`env.development`). Key variables include:

- `NEXUS_PYPI_PASSWORD`: Password for PyPI repository access
- `NEXUS_NPM_PASSWORD`: Password for NPM repository access
- `NEXUS_ADMIN_PASSWORD`: Admin password for Nexus
- `NEXUS_HOST`: Hostname for Nexus (typically `nexus.ploscope.com`)

### Network Configuration

Nexus connects to the main staging environment via the external network `plosolver_plo-network-staging`. This network is created by the main staging docker-compose file.

### Traefik Integration

Nexus is configured to work with Traefik for:
- SSL termination via Let's Encrypt
- Host-based routing (`nexus.ploscope.com`)
- Automatic certificate management

## Access

- **Web UI**: https://nexus.ploscope.com
- **PyPI Repository**: https://nexus.ploscope.com/repository/pypi-internal/
- **NPM Repository**: https://nexus.ploscope.com/repository/npm-internal/
- **Admin Username**: `admin`
- **Admin Password**: Set via `NEXUS_ADMIN_PASSWORD` environment variable

## PyPI Package Management

### Uploading Packages

```bash
# Configure pip to use Nexus
pip config set global.index-url https://nexus.ploscope.com/repository/pypi-internal/simple/
pip config set global.trusted-host nexus.ploscope.com

# Upload a package
python setup.py sdist bdist_wheel
twine upload --repository-url https://nexus.ploscope.com/repository/pypi-internal/ dist/*
```

### Installing Packages

```bash
# Install from Nexus
pip install --index-url https://nexus.ploscope.com/repository/pypi-internal/simple/ your-package-name
```

## NPM Package Management

### Uploading Packages

```bash
# Configure npm to use Nexus
npm config set registry https://nexus.ploscope.com/repository/npm-internal/
npm config set //nexus.ploscope.com/repository/npm-internal/:_authToken YOUR_NPM_TOKEN

# Publish a package
npm publish
```

### Installing Packages

```bash
# Install from Nexus
npm install --registry https://nexus.ploscope.com/repository/npm-all/ your-package-name
```

### NPM Configuration

The setup script generates an `.npmrc` file with the following configuration:

```ini
registry=https://nexus.ploscope.com/repository/npm-all/
//nexus.ploscope.com/repository/npm-internal/:_authToken=${NPM_TOKEN}
//nexus.ploscope.com/repository/npm-all/:_authToken=${NPM_TOKEN}
always-auth=true
```

To use the NPM registry, set the `NPM_TOKEN` environment variable with your authentication token.

## Troubleshooting

### Network Issues

If Nexus can't connect to the staging environment:

1. Verify the external network exists:
   ```bash
   docker network ls | grep plo-network-staging
   ```

2. If the network doesn't exist, start the main staging environment first:
   ```bash
   docker-compose -f docker-compose.staging.yml up -d
   ```

### Traefik Issues

If Nexus is not accessible via HTTPS:

1. Check Traefik logs:
   ```bash
   docker logs plosolver-traefik-staging
   ```

2. Verify DNS resolution for `nexus.ploscope.com`

3. Check certificate status in Traefik dashboard

### Data Persistence

Nexus data is stored in a Docker volume (`nexus_data`). To backup or restore:

```bash
# Backup
docker run --rm -v plosolver_nexus_data:/data -v $(pwd):/backup alpine tar czf /backup/nexus-backup.tar.gz -C /data .

# Restore
docker run --rm -v plosolver_nexus_data:/data -v $(pwd):/backup alpine tar xzf /backup/nexus-backup.tar.gz -C /data
```

## Security Considerations

- Nexus admin password should be strong and unique
- Access to Nexus should be restricted to authorized users
- Regular backups of Nexus data are recommended
- Monitor Nexus logs for security events

## Monitoring

Nexus includes health checks and can be monitored via:
- Docker health check: `docker inspect plosolver-nexus-staging`
- Nexus API: `curl https://nexus.ploscope.com/service/rest/v1/status`
- Traefik metrics (if configured)

## Migration from Integrated Deployment

If migrating from the previous integrated deployment:

1. Stop the main staging environment
2. Start the main staging environment (this creates the external network)
3. Start Nexus using the new docker-compose file
4. Verify Nexus is accessible and functional
5. Update any CI/CD pipelines to use the new deployment method
