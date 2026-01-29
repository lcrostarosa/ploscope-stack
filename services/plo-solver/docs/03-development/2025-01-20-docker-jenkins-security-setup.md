# Docker Jenkins Security Testing Setup

This guide covers setting up Jenkins in Docker for local security testing, including Semgrep with SARIF output, without needing to push to GitHub.

## Overview

The Docker Jenkins setup provides a complete containerized environment for running security tests locally. This includes:

- **Containerized Jenkins**: Pre-configured Jenkins with all security tools
- **Pre-installed Security Tools**: Semgrep, Bandit, Safety, Trivy, ESLint, npm-audit
- **SARIF Output**: Proper Semgrep SARIF file generation for IDE integration
- **Docker-in-Docker**: Full Docker support for container scanning
- **Persistent Storage**: Security results and Jenkins data persistence

## Prerequisites

- Docker installed and running
- Docker Compose installed
- At least 4GB RAM available for Jenkins
- Port 8080 available on localhost
- Port 50001 available for Jenkins agent (avoiding conflict with backend on 5001)

## Quick Start

### 1. Automated Setup

```bash
# Run the automated setup script
make jenkins-docker-setup
```

This will:
- Build the Jenkins Docker image with security tools
- Start Jenkins container
- Wait for Jenkins to be ready
- Display access information
- Generate setup summary

### 2. Manual Setup

```bash
# Build the Jenkins image
make jenkins-docker-build

# Start Jenkins
make jenkins-docker-up

# Check logs
make jenkins-docker-logs
```

## Docker Configuration

### Main Docker Compose Integration

Jenkins is integrated into the main `docker-compose.yml`:

```yaml
jenkins:
  build:
    context: .
    dockerfile: Dockerfile.jenkins
  container_name: plosolver-jenkins-${ENVIRONMENT:-development}
  ports:
    - "8080:8080"
    - "50001:50000"
  volumes:
    - jenkins_data:/var/jenkins_home
    - /var/run/docker.sock:/var/run/docker.sock
    - ${PWD}:/workspace:ro
  environment:
    - WORKSPACE=/workspace
    - SECURITY_RESULTS_DIR=/workspace/security-results
```

### Dedicated Jenkins Compose File

For standalone Jenkins security testing, use `docker-compose-jenkins.yml`:

```bash
# Start standalone Jenkins
docker-compose -f docker-compose-jenkins.yml up -d

# Stop standalone Jenkins
docker-compose -f docker-compose-jenkins.yml down
```

## Custom Dockerfile

The `Dockerfile.jenkins` includes:

### Pre-installed Security Tools

```dockerfile
# Python security tools
RUN pip3 install --user \
    semgrep \
    bandit \
    safety \
    pip-audit \
    flake8 \
    black \
    isort

# Node.js security tools
RUN npm install -g \
    npm-audit \
    eslint \
    eslint-plugin-security \
    eslint-plugin-react-hooks

# Container scanning
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.28.0
```

### Jenkins Configuration

```dockerfile
# Pre-installed Jenkins plugins
RUN mkdir -p /var/jenkins_home/plugins && \
    cd /var/jenkins_home/plugins && \
    wget -O workflow-aggregator.hpi https://updates.jenkins.io/latest/workflow-aggregator.hpi && \
    wget -O git.hpi https://updates.jenkins.io/latest/git.hpi && \
    wget -O credentials-binding.hpi https://updates.jenkins.io/latest/credentials-binding.hpi
```

## Available Commands

### Makefile Targets

```bash
# Setup and management
make jenkins-docker-setup      # Complete automated setup
make jenkins-docker-build      # Build Jenkins image
make jenkins-docker-up         # Start Jenkins
make jenkins-docker-down       # Stop Jenkins
make jenkins-docker-logs       # View logs
make jenkins-docker-shell      # Access container shell

# Security testing
make jenkins-docker-test       # Run security tests in container
make security-test             # Run security tests locally
make test-semgrep-sarif        # Test SARIF generation
```

### Docker Compose Commands

```bash
# Standalone Jenkins
docker-compose -f docker-compose-jenkins.yml up -d
docker-compose -f docker-compose-jenkins.yml down
docker-compose -f docker-compose-jenkins.yml logs -f

# Integrated with main services
docker-compose up jenkins -d
docker-compose down
```

## Security Tools Configuration

### Semgrep Configuration

The container includes Semgrep with SARIF support:

```bash
# Test SARIF generation
docker-compose -f docker-compose-jenkins.yml exec jenkins semgrep scan --config=auto --sarif --sarif-output=/workspace/semgrep-results.sarif /workspace
```

### Jenkins Pipeline

The `Jenkinsfile` is configured for Docker environment:

```groovy
environment {
    WORKSPACE_DIR = "/workspace"
    SECURITY_RESULTS_DIR = "/workspace/security-results"
    SEMGREP_RESULTS = "/workspace/semgrep-results.sarif"
}
```

## Volume Mounts

### Workspace Mount

```yaml
volumes:
  - ${PWD}:/workspace:ro  # Read-only mount of current directory
```

### Security Results

```yaml
volumes:
  - security_results:/workspace/security-results  # Persistent results storage
```

### Jenkins Data

```yaml
volumes:
  - jenkins_data:/var/jenkins_home  # Persistent Jenkins configuration
```

## Environment Variables

### Container Environment

```bash
WORKSPACE=/workspace
SECURITY_RESULTS_DIR=/workspace/security-results
SEMGREP_RESULTS=/workspace/semgrep-results.sarif
TRIVY_RESULTS=/workspace/trivy-fs-results.sarif
PYTHONPATH=/workspace/src
```

### Docker Host Access

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock  # Docker-in-Docker support
environment:
  - DOCKER_HOST=unix:///var/run/docker.sock
```

## Security Testing Workflow

### 1. Start Jenkins

```bash
make jenkins-docker-setup
```

### 2. Access Jenkins

- Open http://localhost:8080
- Use initial admin password from setup output
- Complete Jenkins initial configuration

### 3. Create Security Job

- Create new Pipeline job
- Configure to use `/workspace/Jenkinsfile`
- Set up SCM to use local workspace

### 4. Run Security Scan

```bash
# Via Jenkins web interface
# Or via command line
make jenkins-docker-test
```

### 5. Review Results

- Check `/workspace/security-results/` for output files
- Review SARIF files for IDE integration
- Address security findings

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using port 8080
   lsof -i :8080
   
   # Stop conflicting service or change port in docker-compose-jenkins.yml
   ```

2. **Docker Permission Issues**
   ```bash
   # Add user to docker group
   sudo usermod -a -G docker $USER
   
   # Restart Docker service
   sudo systemctl restart docker
   ```

3. **Jenkins Not Starting**
   ```bash
   # Check logs
   make jenkins-docker-logs
   
   # Rebuild image
   make jenkins-docker-build
   ```

4. **Security Tools Not Found**
   ```bash
   # Access container and check installation
   make jenkins-docker-shell
   
   # Inside container
   semgrep --version
   bandit --version
   trivy --version
   ```

### Performance Optimization

1. **Increase Memory**
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx2g -Xms1g
   ```

2. **Use Volume Caching**
   ```yaml
   volumes:
     - jenkins_cache:/var/jenkins_home/.cache
   ```

3. **Parallel Security Scans**
   ```groovy
   parallel {
     stage('Semgrep') { ... }
     stage('Bandit') { ... }
     stage('Trivy') { ... }
   }
   ```

## Integration with CI/CD

### GitHub Actions Integration

```yaml
- name: Run Security Tests in Docker Jenkins
  run: |
    make jenkins-docker-setup
    make jenkins-docker-test
    # Upload SARIF results
    - uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: security-results/semgrep-results.sarif
```

### Local Development

```bash
# Development workflow
make jenkins-docker-up
# Make code changes
make jenkins-docker-test
# Review security results
make jenkins-docker-down
```

## Security Best Practices

1. **Container Security**
   - Use non-root user where possible
   - Scan base images regularly
   - Keep security tools updated

2. **Data Protection**
   - Mount sensitive directories as read-only
   - Use Docker secrets for credentials
   - Encrypt persistent volumes

3. **Network Security**
   - Use internal networks for service communication
   - Expose only necessary ports
   - Implement proper firewall rules

## Monitoring and Logging

### Health Checks

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/login"]
  interval: 30s
  timeout: 10s
  retries: 5
```

### Log Management

```bash
# View real-time logs
make jenkins-docker-logs

# Export logs
docker-compose -f docker-compose-jenkins.yml logs jenkins > jenkins.log
```

## Conclusion

The Docker Jenkins setup provides a robust, containerized environment for local security testing. It eliminates the need to push to GitHub for security scans while maintaining all the benefits of proper SARIF output and comprehensive security tool integration.

For additional support or questions, refer to the main security testing documentation or check the troubleshooting section above. 