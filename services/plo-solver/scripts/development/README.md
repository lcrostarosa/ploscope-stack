# CI Debugging Scripts

This directory contains scripts for debugging CI issues locally by recreating the GitHub Actions environment.

## Available Scripts

### 1. `debug-ci-locally.sh` - Basic CI Environment
Creates a basic interactive environment with all CI services running locally.

**Features:**
- PostgreSQL, RabbitMQ, and Traefik containers
- Interactive shell with all dependencies installed
- Automatic cleanup on exit
- Colored output for better visibility

**Usage:**
```bash
./scripts/development/debug-ci-locally.sh
```

### 2. `debug-ci-runner.sh` - GitHub Actions Runner Environment
Creates a more accurate GitHub Actions runner environment for precise debugging.

**Features:**
- Same services as above but with GitHub Actions environment variables
- Mirrors the actual runner setup more closely
- Includes runner-specific environment variables
- Better for debugging CI-specific issues

**Usage:**
```bash
./scripts/development/debug-ci-runner.sh
```

## What Gets Set Up

Both scripts create the following environment:

### 🐳 Docker Containers
- **PostgreSQL**: `postgres:15` on port 5432
- **RabbitMQ**: `rabbitmq:3.13-management` on ports 5672, 15672
- **Traefik**: `traefik:v3.0` on ports 80, 8082

### 🌐 Network
- Custom Docker network: `ci-debug-network`
- All containers can communicate with each other
- Services accessible via container names

### 🔧 Environment Variables
All CI environment variables are set:
- Database configuration
- RabbitMQ configuration
- Traefik configuration
- Application URLs and ports

### 📦 Dependencies
- Python 3.11 with virtual environment
- Node.js with npm
- All project dependencies installed
- PostgreSQL client tools

## Debugging Workflow

1. **Start the debugging environment:**
   ```bash
   ./scripts/development/debug-ci-runner.sh
   ```

2. **Wait for setup to complete** - The script will:
   - Start all containers
   - Install dependencies
   - Verify service connectivity
   - Drop you into an interactive shell

3. **Run CI commands manually:**
   ```bash
   # Test database connectivity
   pg_isready -h postgres-ci-debug -p 5432 -U testuser -d testdb
   
   # Test RabbitMQ
   curl -u plosolver:dev_password_2024 http://rabbitmq-ci-debug:15672/api/overview
   
   # Test Traefik
   curl http://traefik-ci-debug:8082/api/rawdata
   
   # Start backend server
   cd /workspace/src/backend
   source venv/bin/activate
   python -m flask run --host=0.0.0.0 --port=5001
   
   # Start frontend server
   cd /workspace/src/frontend
   npm start
   
   # Run tests
   cd /workspace/src/backend
   source venv/bin/activate
   python -m pytest tests/unit/ -v
   ```

4. **Debug issues in real-time:**
   - Check logs: `docker logs <container-name>`
   - Inspect containers: `docker exec -it <container-name> bash`
   - Test API endpoints: `curl http://localhost/api/health`

5. **Exit and cleanup:**
   ```bash
   exit
   ```
   The script will automatically clean up all containers and networks.

## Troubleshooting

### Common Issues

**Docker not running:**
```bash
# Start Docker Desktop or Docker daemon
sudo systemctl start docker  # Linux
# Or start Docker Desktop on macOS/Windows
```

**Port conflicts:**
If ports 5432, 5672, 15672, 80, or 8082 are already in use:
```bash
# Stop existing services
sudo systemctl stop postgresql  # If running locally
# Or change ports in the script
```

**Permission issues:**
```bash
# Make scripts executable
chmod +x scripts/development/*.sh
```

**Network issues:**
```bash
# Clean up existing networks
docker network prune
```

### Debugging Tips

1. **Check container status:**
   ```bash
   docker ps
   docker logs <container-name>
   ```

2. **Inspect network connectivity:**
   ```bash
   docker network inspect ci-debug-network
   ```

3. **Test service connectivity from host:**
   ```bash
   # PostgreSQL
   pg_isready -h localhost -p 5432
   
   # RabbitMQ
   curl http://localhost:15672/api/overview
   
   # Traefik
   curl http://localhost:8082/api/rawdata
   ```

4. **Access container shell:**
   ```bash
   docker exec -it postgres-ci-debug bash
   docker exec -it rabbitmq-ci-debug bash
   docker exec -it traefik-ci-debug sh
   ```

## Environment Comparison

| Aspect | GitHub Actions | Local Debug |
|--------|---------------|-------------|
| OS | Ubuntu 22.04 | Ubuntu 22.04 |
| Python | 3.11 | 3.11 |
| Node.js | Latest | Latest |
| Services | Containerized | Containerized |
| Network | Host networking | Docker network |
| Environment | CI variables | Same CI variables |

## Next Steps

After debugging locally:
1. Fix the issue in your code
2. Test the fix in the local environment
3. Commit and push changes
4. Verify the fix in GitHub Actions

This approach allows you to iterate quickly and catch issues before they reach the CI pipeline. 