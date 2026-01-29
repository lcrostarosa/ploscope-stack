# PLOSolver Test Environment Setup

This document describes how to set up a headless Ubuntu virtual machine for testing PLOSolver.

## Option 1: Vagrant + VirtualBox (Recommended)

### Prerequisites

1. **Install VirtualBox**
   - Download from: https://www.virtualbox.org/wiki/Downloads
   - Install the latest version for your OS

2. **Install Vagrant**
   - Download from: https://www.vagrantup.com/downloads
   - Install the latest version

### Quick Start

1. **Set up the test environment:**
   ```bash
   ./scripts/vm-test.sh setup
   ```

2. **Start the VM:**
   ```bash
   ./scripts/vm-test.sh start
   ```

3. **SSH into the VM:**
   ```bash
   ./scripts/vm-test.sh ssh
   ```

4. **Run tests:**
   ```bash
   ./scripts/vm-test.sh test
   ```

### VM Management Commands

```bash
# Start the VM
./scripts/vm-test.sh start

# Stop the VM
./scripts/vm-test.sh stop

# Restart the VM
./scripts/vm-test.sh restart

# SSH into the VM
./scripts/vm-test.sh ssh

# Run tests in the VM
./scripts/vm-test.sh test

# Run Docker tests in the VM
./scripts/vm-test.sh docker-test

# Check VM status
./scripts/vm-test.sh status

# Run a custom command in the VM
./scripts/vm-test.sh run "cd /vagrant && make test"

# Show VM logs
./scripts/vm-test.sh logs

# Destroy the VM (completely removes it)
./scripts/vm-test.sh destroy
```

### VM Specifications

- **OS**: Ubuntu 22.04 LTS
- **RAM**: 4GB
- **CPU**: 2 cores
- **Network**: Private network (192.168.56.10)
- **Mode**: Headless (no GUI)

### Installed Software

- Docker & Docker Compose
- Node.js 18.x
- Python 3.11
- PostgreSQL client
- Git, curl, wget, vim, htop
- All necessary development tools

## Option 2: Docker-based Test Environment

If you prefer not to use Vagrant, you can use a Docker-based test environment.

### Quick Start

1. **Set up the test environment:**
   ```bash
   ./scripts/docker-test.sh setup
   ```

2. **Start the environment:**
   ```bash
   ./scripts/docker-test.sh start
   ```

3. **Access the environment:**
   ```bash
   ./scripts/docker-test.sh ssh
   ```

4. **Run tests:**
   ```bash
   ./scripts/docker-test.sh test
   ```

### Docker Environment Management

```bash
# Start the test environment
./scripts/docker-test.sh start

# Stop the test environment
./scripts/docker-test.sh stop

# Restart the test environment
./scripts/docker-test.sh restart

# SSH into the test environment
./scripts/docker-test.sh ssh

# Run tests in the test environment
./scripts/docker-test.sh test

# Run Docker tests in the test environment
./scripts/docker-test.sh docker-test

# Check environment status
./scripts/docker-test.sh status

# Run a custom command in the test environment
./scripts/docker-test.sh run "cd /workspace && make test"

# Show environment logs
./scripts/docker-test.sh logs

# Destroy the test environment (completely removes it)
./scripts/docker-test.sh destroy
```

## Testing Your Application

Once you have the test environment running, you can test your PLOSolver application:

### 1. Basic Tests

```bash
# Run all tests (frontend + backend)
make test

# Run all unit tests (frontend + backend)
make test-unit

# Run all integration tests (frontend + backend)
make test-integration
```

### 2. Docker Tests

```bash
# Run with Docker
make run-docker


```

### 3. CI Pipeline Tests

```bash
# Run full CI pipeline
make ci-pipeline

# Run quick CI pipeline
make ci-pipeline-quick
```

## Troubleshooting

### Vagrant Issues

1. **VM won't start:**
   - Check if VirtualBox is installed and running
   - Ensure virtualization is enabled in BIOS
   - Try: `vagrant reload`

2. **Network issues:**
   - Check if the IP 192.168.56.10 is available
   - Try: `vagrant reload`

3. **Provisioning fails:**
   - Try: `vagrant up --provision`
   - Check internet connection in the VM

### Docker Environment Issues

1. **Container won't start:**
   - Check if Docker is running
   - Try: `docker system prune -f`

2. **Permission issues:**
   - Ensure Docker has proper permissions
   - Try: `sudo chmod 666 /var/run/docker.sock`

### General Issues

1. **Port conflicts:**
   - The test environment uses different ports to avoid conflicts
   - PostgreSQL: 5433 (instead of 5432)
   - Redis: 6380 (instead of 6379)

2. **Resource issues:**
   - Increase VM memory/CPU if needed
   - Edit the Vagrantfile or docker-compose file

## Environment Variables

The test environment uses the following environment variables:

```bash
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=plosolver_test

# Application
NODE_ENV=test
FLASK_ENV=testing
```

## File Structure

```
PLOSolver/
├── Vagrantfile              # Vagrant configuration
├── docker-test-env.yml      # Docker test environment
├── scripts/
│   ├── vm-test.sh          # VM management script
│   └── docker-test.sh      # Docker environment management script
└── TEST_ENVIRONMENT.md     # This file
```

## Next Steps

1. Choose your preferred test environment (Vagrant or Docker)
2. Set up the environment using the provided scripts
3. Run your tests to ensure everything works
4. Use the environment for development and testing

For more information about PLOSolver development, see the main README.md file. 