# PLOSolver Ansible Deployment

This directory contains Ansible playbooks for deploying PLOSolver to Hetzner servers. The deployment system is designed to be secure, repeatable, and follows infrastructure-as-code best practices.

## Overview

The deployment system consists of three main playbooks:

1. **Initial Setup** (`00_root-setup.yml`) - One-time server configuration
2. **Appuser Configuration** (`01_appuser.yml`) - User and service setup
3. **Application Deployment** (`02_deploy.yml`) - Application deployment - TODO - broken

## Prerequisites

- Ansible installed locally
- SSH access to the target server
- Docker Hub credentials
- GitHub personal access token (optional, for automatic SSH key setup)
- GitHub Actions runner token

## Quick Start

### 1. Initial Server Setup (ONE-TIME ONLY)

⚠️ **CRITICAL**: This playbook will remove root SSH access permanently!

```bash
# Run the initial setup
make hetzner-initial-setup
```

This will:
- Install Docker and required packages
- Create the `appuser` account
- Configure SSH keys
- Remove root SSH access
- Set up basic system configuration

### 2. Configure Appuser Account

```bash
# Configure the appuser account and services
make hetzner-appuser
```

This will:
- Install and configure Docker
- Set up GitHub SSH access
- Create SSL certificate directories
- Clone the PLOSolver repository
- Configure GitHub Actions runner

### 3. Deploy Application

```bash
# Deploy the application
make hetzner-deploy
```

This will:
- Pull latest code from Git
- Copy environment files
- Pull Docker images
- Deploy the application stack

## Configuration

### Variables File

Copy the example variables file and update it with your values:

```bash
cp variables/vars.example.yml variables/vars.yml
```

Edit `variables/vars.yml` with your specific configuration:

### Inventory Configuration

The inventory file (`inventories/inventory.yml`) contains server definitions:

```yaml
all:
  children:
    root_servers:
      hosts:
        staging-root:
          ansible_host: "5.78.113.169"
          ansible_user: root
          ansible_ssh_private_key_file: "~/.ssh/plo-scope-staging"
    
    appuser_servers:
      hosts:
        staging-appuser:
          ansible_host: "5.78.113.169"
          ansible_user: appuser
          ansible_ssh_private_key_file: "~/.ssh/plo-scope-staging"
```

## Playbook Details

### 00_root-setup.yml

**Purpose**: Initial server setup (one-time only)

**Tasks**:
- Update system packages
- Create `appuser` account
- Configure SSH keys
- Disable root SSH access
- Set up basic system configuration

**Warning**: This playbook permanently removes root SSH access!

### 01_appuser.yml

**Purpose**: Configure the appuser account and services

**Tasks**:
- Install Docker and Docker Compose
- Configure Docker daemon
- Set up GitHub SSH access
- Create SSL certificate directories
- Clone PLOSolver repository
- Configure GitHub Actions runner

### 02_deploy.yml

**Purpose**: Deploy the PLOSolver application

**Tasks**:
- Pull latest code from Git
- Copy environment configuration
- Pull Docker images
- Stop existing services
- Start application stack

## Security Features

- **Root Access Removal**: After initial setup, root SSH access is permanently disabled
- **Appuser Isolation**: All operations run under the `appuser` account
- **SSH Key Authentication**: Uses SSH keys for secure authentication
- **Docker Group Permissions**: Proper Docker socket permissions for appuser
- **SSL Certificate Management**: Secure SSL certificate handling

## Monitoring Setup

The deployment includes monitoring infrastructure:

- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **Proper Permissions**: Monitoring services run with correct user/group permissions

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key is in `~/.ssh/`
   - Check key permissions (should be 600)
   - Ensure key is added to SSH agent

2. **Docker Permission Denied**
   - Verify appuser is in docker group
   - Check Docker socket permissions
   - Restart Docker service if needed

3. **GitHub SSH Access Failed**
   - Add SSH public key to GitHub account
   - Verify SSH config file exists
   - Test with `ssh -T git@github.com`

4. **Docker Compose Failed**
   - Check environment variables
   - Verify Docker Hub credentials
   - Check available disk space

### Validation Commands

```bash
# Test SSH connection
ssh appuser@your-server-ip

# Test Docker access
docker ps

# Test GitHub SSH
ssh -T git@github.com

# Check service status
docker compose -f docker-compose.staging.yml ps
```

### Logs

Application logs are available in the project directory:

```bash
# View application logs
docker compose -f docker-compose.staging.yml logs

# View specific service logs
docker compose -f docker-compose.staging.yml logs backend
docker compose -f docker-compose.staging.yml logs frontend
```

## File Structure

```
ansible/
├── 00_root-setup.yml          # Initial server setup
├── 01_appuser.yml             # Appuser configuration
├── 02_deploy.yml              # Application deployment
├── Makefile                   # Convenience commands
├── inventories/
│   └── inventory.yml          # Server definitions
├── playbooks/
│   ├── 01_root/              # Root-level tasks
│   ├── 02_appuser/           # Appuser tasks
│   └── 03_deploy/            # Deployment tasks
└── variables/
    ├── vars.example.yml       # Example configuration
    └── vars.yml              # Actual configuration (gitignored)
```

## Best Practices

1. **Never commit sensitive data**: The `vars.yml` file is gitignored
2. **Use SSH keys**: Avoid password authentication
3. **Test in staging**: Always test changes in staging before production
4. **Monitor deployments**: Check logs and metrics after deployment
5. **Backup configuration**: Keep backups of your `vars.yml` file

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Ansible logs for detailed error messages
3. Verify all prerequisites are met
4. Check server resources (disk space, memory, etc.)

## License

This project is proprietary and confidential. See `LICENSE.txt` for details.
