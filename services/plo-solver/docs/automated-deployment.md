# Automated Staging Deployment

This document describes the automated deployment system for PLOSolver's staging environment. The system provides both GitHub Actions-based automated deployments and local deployment scripts for manual control.

## Overview

The automated deployment system eliminates the need for manual SSH access and deployment steps. It provides:

- **GitHub Actions**: Automatic deployment on push to `master` branch
- **Local Scripts**: Manual deployment with full control
- **Health Checks**: Automatic verification of deployment success
- **Rollback Capability**: Easy rollback to previous versions
- **Cost-Effective**: Uses GitHub Actions (free for public repos, reasonable pricing for private)

## Quick Start

### 1. Setup SSH Keys

First, ensure you have SSH access to your staging server:

```bash
# Generate SSH key if you don't have one
./scripts/setup/setup-auto-deployment.sh --setup-ssh

# Add your public key to the staging server
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@ploscope.com
```

### 2. Configure GitHub Actions (Recommended)

For automatic deployments on every push to master:

```bash
# Show setup instructions
./scripts/setup/setup-auto-deployment.sh --github-actions
```

Then add the required secrets to your GitHub repository:
- Go to Settings > Secrets and variables > Actions
- Add the following secrets:
  - `STAGING_HOST`: `ploscope.com`
  - `STAGING_USER`: `root`
  - `STAGING_PATH`: `/root/plo-solver`
  - `STAGING_SSH_KEY`: Your SSH private key content

### 3. Manual Deployment (Alternative)

For manual deployments with full control:

```bash
# Deploy to staging
make deploy-staging-auto

# Or use the script directly
./scripts/deployment/deploy-staging.sh
```

## Deployment Methods

### Method 1: GitHub Actions (Automated)

**Trigger**: Push to `master` branch  
**Cost**: Free for public repos, ~$0.008/minute for private repos

**Features**:
- Automatic testing before deployment
- Health checks after deployment
- Deployment notifications
- Rollback capability

**Setup**:
1. Configure GitHub secrets (see Quick Start)
2. Push to `master` branch
3. Monitor deployment in GitHub Actions tab

### Method 2: Local Script (Manual)

**Trigger**: Manual execution  
**Cost**: No additional cost

**Features**:
- Full control over deployment process
- Interactive confirmation
- Detailed logging
- SSH key password handling

**Usage**:
```bash
# Basic deployment
./scripts/deployment/deploy-staging.sh

# Check deployment status
./scripts/deployment/deploy-staging.sh --status

# Health check only
./scripts/deployment/deploy-staging.sh --health

# Show help
./scripts/deployment/deploy-staging.sh --help
```

## Configuration

### Environment Variables

You can customize deployment behavior using environment variables:

```bash
# Server configuration
export STAGING_HOST="ploscope.com"
export STAGING_USER="root"
export STAGING_PATH="/root/plo-solver"
export SSH_KEY_PATH="~/.ssh/id_ed25519"

# Application configuration
export FRONTEND_DOMAIN="ploscope.com"
export TRAEFIK_DOMAIN="ploscope.com"

# Deployment settings
export DEPLOYMENT_BRANCH="master"
export HEALTH_CHECK_URL="https://ploscope.com"
export HEALTH_CHECK_TIMEOUT="10"
export HEALTH_CHECK_RETRIES="10"
```

### Configuration File

Create a `.deployment-config` file for persistent settings:

```bash
./scripts/setup/setup-auto-deployment.sh --create-config
```

Then edit the generated file to customize your settings.

## Deployment Process

### Automated Deployment (GitHub Actions)

1. **Trigger**: Push to `master` branch
2. **Testing**: Run frontend and backend tests
3. **Build**: Build frontend application
4. **Deploy**: SSH to server and execute deployment
5. **Health Check**: Verify application is responding
6. **Notification**: Report deployment status

### Manual Deployment (Local Script)

1. **Prerequisites**: Check SSH key and connection
2. **Confirmation**: Interactive confirmation prompt
3. **Deployment**: SSH to server and execute deployment
4. **Health Check**: Verify application is responding
5. **Status Report**: Show deployment summary

## Monitoring and Troubleshooting

### Check Deployment Status

```bash
# Check container status
./scripts/deployment/deploy-staging.sh --status

# Health check
./scripts/deployment/deploy-staging.sh --health

# View logs
ssh root@ploscope.com "cd /root/plo-solver && docker compose logs"
```

### Common Issues

#### SSH Connection Failed
```bash
# Test SSH connection
ssh -i ~/.ssh/id_ed25519 root@ploscope.com

# Check SSH key permissions
chmod 600 ~/.ssh/id_ed25519
```

#### Deployment Failed
```bash
# Check server logs
ssh root@ploscope.com "cd /root/plo-solver && docker compose logs --tail=50"

# Check container status
ssh root@ploscope.com "cd /root/plo-solver && docker compose ps"
```

#### Health Check Failed
```bash
# Check if application is running
curl -I https://ploscope.com

# Check Traefik dashboard
curl -I https://ploscope.com:8080
```

## Rollback

### Automatic Rollback

If deployment fails, the system will automatically rollback to the previous version.

### Manual Rollback

```bash
# SSH to server and rollback
ssh root@ploscope.com << 'EOF'
cd /root/plo-solver
git log --oneline -5
git reset --hard HEAD~1
make staging-deploy
EOF
```

## Security Considerations

### SSH Key Security

- Use dedicated SSH keys for deployment
- Set proper permissions: `chmod 600 ~/.ssh/id_ed25519`
- Rotate keys regularly
- Use key-based authentication only

### GitHub Secrets

- Never commit secrets to the repository
- Use GitHub's encrypted secrets
- Rotate secrets regularly
- Limit access to repository settings

### Server Security

- Use non-root user when possible
- Restrict SSH access to specific IPs
- Monitor server logs
- Keep system updated

## Cost Analysis

### GitHub Actions Pricing

- **Public repositories**: 2,000 minutes/month free
- **Private repositories**: $0.008 per minute
- **Typical deployment**: ~5-10 minutes
- **Monthly cost for private repo**: ~$2-5 (assuming 10 deployments/month)

### Alternative Solutions

| Solution | Cost | Pros | Cons |
|----------|------|------|------|
| GitHub Actions | $2-5/month | Easy setup, integrated | Limited free minutes |
| Self-hosted runner | $0 | Unlimited deployments | Requires server |
| Jenkins | $0 | Full control | Complex setup |
| GitLab CI | $0 | Free private repos | Migration required |

## Best Practices

### Development Workflow

1. **Feature branches**: Develop features in separate branches
2. **Pull requests**: Use PRs for code review
3. **Testing**: Ensure all tests pass before merging
4. **Deployment**: Automatic deployment on merge to master

### Deployment Strategy

1. **Blue-green deployment**: Zero-downtime deployments
2. **Health checks**: Verify deployment success
3. **Rollback plan**: Quick rollback capability
4. **Monitoring**: Monitor application health

### Security

1. **Secrets management**: Use encrypted secrets
2. **Access control**: Limit deployment access
3. **Audit logging**: Track all deployments
4. **Regular updates**: Keep dependencies updated

## Troubleshooting Guide

### GitHub Actions Issues

#### Workflow Not Triggering
- Check branch name (should be `master`)
- Verify workflow file is in `.github/workflows/`
- Check GitHub Actions permissions

#### SSH Connection Failed
- Verify `STAGING_SSH_KEY` secret is correct
- Check `STAGING_HOST` and `STAGING_USER` secrets
- Ensure public key is in server's `authorized_keys`

#### Deployment Failed
- Check server logs: `docker compose logs`
- Verify environment variables in `env.staging`
- Check disk space and memory on server

### Local Script Issues

#### Permission Denied
```bash
chmod +x scripts/deployment/deploy-staging.sh
chmod 600 ~/.ssh/id_ed25519
```

#### SSH Key Password Prompt
```bash
# Add key to ssh-agent
ssh-add ~/.ssh/id_ed25519
```

#### Connection Timeout
- Check server accessibility
- Verify firewall settings
- Test with: `ssh -v root@ploscope.com`

## Support

For issues with the deployment system:

1. Check the troubleshooting guide above
2. Review server logs and GitHub Actions logs
3. Test SSH connection manually
4. Verify configuration settings

## Future Enhancements

- [ ] Slack/Discord notifications
- [ ] Email notifications
- [ ] Deployment metrics dashboard
- [ ] Blue-green deployment
- [ ] Database migration handling
- [ ] Backup before deployment
- [ ] Performance monitoring
- [ ] Cost optimization
- [ ] Cost optimization

## Documentation Navigation

Our documentation is organized for easy navigation:

- **[🚀 Getting Started](docs/01-getting-started/)** - User guides and tutorials
- **[⚙️ Setup](docs/02-setup/)** - Installation and configuration
- **[💻 Development](docs/03-development/)** - Contributing and development
- **[📋 Deployment Guide](docs/03-development/deployment-guide.md)** - GitHub Actions deployment workflows and PR deployments
- **[🏗️ Architecture](docs/05-architecture/)** - System design and technical details
- **[🧪 Testing](docs/06-testing/)** - Testing guides and best practices
- **[🔌 Integrations](docs/07-integrations/)** - Third-party integrations