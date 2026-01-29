# Jenkins Security CI/CD Setup

This directory contains the Jenkins configuration for PLOSolver's security-focused Continuous Integration and Continuous Deployment pipeline. The setup includes comprehensive security scanning tools and automated testing capabilities.

## Overview

The Jenkins setup provides:
- **Security Analysis Pipeline**: Automated security scanning with Semgrep, Trivy, Bandit, and other tools
- **Docker-based CI Environment**: Isolated testing environment with all necessary tools
- **SARIF Output**: Standardized security results format for integration with other tools
- **Multi-language Support**: Security scanning for Python, JavaScript/TypeScript, and Docker containers

## Directory Structure

```
jenkins/
├── docker-compose-jenkins.yml    # Main Jenkins service configuration
├── Dockerfile.jenkins            # Jenkins master with security tools
├── Dockerfile.ci                 # CI environment for running tests
├── jenkins-config.xml           # Jenkins job configuration
├── LICENSE.txt                  # License information
└── README.md                    # This file
```

## Prerequisites

- Docker and Docker Compose
- Git
- At least 4GB RAM available for Jenkins
- Ports 8080 and 50001 available

## Quick Start

### 1. Start Jenkins Security Environment

```bash
cd jenkins
docker-compose -f docker-compose-jenkins.yml up -d
```

### 2. Access Jenkins

- **URL**: http://localhost:8080
- **Initial Setup**: The setup wizard is disabled by default
- **Default Job**: `plosolver-security-analysis` is pre-configured

### 3. Run Security Analysis

The security analysis pipeline will automatically:
- Check out the latest code
- Install security tools
- Run frontend security checks (ESLint, npm audit)
- Run backend security checks (Bandit, Safety, pip-audit)
- Perform container scanning with Trivy
- Generate SARIF reports

## Security Tools Included

### Python Security Tools
- **Semgrep**: Static analysis for security vulnerabilities
- **Bandit**: Security linter for Python code
- **Safety**: Checks for known security vulnerabilities in dependencies
- **pip-audit**: Audits Python packages for known vulnerabilities
- **Flake8**: Code quality and style checking
- **Black**: Code formatting
- **isort**: Import sorting

### JavaScript/Node.js Security Tools
- **ESLint**: Code linting with security plugins
- **eslint-plugin-security**: Security-focused ESLint rules
- **eslint-plugin-react-hooks**: React hooks linting
- **npm audit**: Dependency vulnerability scanning

### Container Security
- **Trivy**: Container and filesystem vulnerability scanner
- **Docker-in-Docker**: For building and scanning containers

## Configuration Files

### docker-compose-jenkins.yml

Main service configuration that sets up:
- Jenkins master container with security tools
- Optional security-tools container for additional scanning
- Volume mounts for persistent data and workspace access
- Network configuration for inter-container communication

### Dockerfile.jenkins

Custom Jenkins image that includes:
- Jenkins LTS with JDK 17
- All security tools pre-installed
- Docker-in-Docker capabilities
- Pre-configured Jenkins plugins
- Security scripts and configurations

### Dockerfile.ci

CI environment for running tests that includes:
- Ubuntu 22.04 base
- Python 3.11 and Node.js 24
- Docker CLI
- Pre-installed dependencies
- Automated CI pipeline script

### jenkins-config.xml

Jenkins job configuration that defines:
- Security analysis pipeline stages
- Tool installation and execution
- SARIF report generation
- Build retention policies
- SCM triggers (every 15 minutes)

## Security Pipeline Stages

1. **Checkout**: Clone the latest code
2. **Setup Environment**: Create directories and verify tools
3. **Install Security Tools**: Ensure all tools are available
4. **Frontend Security Checks**: ESLint and npm audit
5. **Backend Security Checks**: Bandit, Safety, pip-audit
6. **Container Scanning**: Trivy vulnerability scanning
7. **SARIF Generation**: Create standardized security reports
8. **Results Collection**: Archive and store results

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WORKSPACE` | Jenkins workspace directory | `/workspace` |
| `SECURITY_RESULTS_DIR` | Directory for security results | `/workspace/security-results` |
| `SEMGREP_RESULTS` | Semgrep SARIF output file | `/workspace/semgrep-results.sarif` |
| `TRIVY_RESULTS` | Trivy SARIF output file | `/workspace/trivy-fs-results.sarif` |
| `JENKINS_OPTS` | Jenkins startup options | `--httpPort=8080` |
| `JAVA_OPTS` | JVM options | `-Djenkins.install.runSetupWizard=false` |

## Usage Examples

### Run Security Analysis Manually

```bash
# Access Jenkins and trigger the security analysis job
curl -X POST http://localhost:8080/job/plosolver-security-analysis/build
```

### View Security Results

```bash
# Check security results directory
docker exec plosolver-jenkins-security ls -la /workspace/security-results/

# View Semgrep results
docker exec plosolver-jenkins-security cat /workspace/semgrep-results.sarif
```

### Run Individual Security Tools

```bash
# Run Semgrep scan
docker exec plosolver-jenkins-security semgrep scan --config=auto --json --output=/workspace/semgrep-results.json

# Run Bandit scan
docker exec plosolver-jenkins-security bandit -r /workspace/src/backend -f json -o /workspace/bandit-results.json

# Run Trivy filesystem scan
docker exec plosolver-jenkins-security trivy fs --format sarif --output /workspace/trivy-fs-results.sarif /workspace
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check if ports are in use
   lsof -i :8080
   lsof -i :50001
   ```

2. **Docker Permission Issues**
   ```bash
   # Ensure Docker socket permissions
   sudo chmod 666 /var/run/docker.sock
   ```

3. **Jenkins Not Starting**
   ```bash
   # Check Jenkins logs
   docker logs plosolver-jenkins-security
   ```

4. **Security Tools Not Found**
   ```bash
   # Reinstall tools in Jenkins container
   docker exec plosolver-jenkins-security pip install --user semgrep bandit safety pip-audit
   ```

### Health Checks

The Jenkins container includes health checks:
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 5 attempts
- **Start Period**: 120 seconds

### Logs and Monitoring

```bash
# View Jenkins logs
docker logs -f plosolver-jenkins-security

# View security tools logs
docker logs -f plosolver-security-tools

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## Integration with CI/CD

This Jenkins setup integrates with:
- **GitHub Actions**: For automated triggers
- **Docker Registry**: For container image scanning
- **SARIF Viewers**: For security result visualization
- **Security Dashboards**: For vulnerability tracking

## Security Considerations

- Jenkins runs as root for Docker access (required for Docker-in-Docker)
- All security tools are run in isolated containers
- Results are stored in persistent volumes
- Network access is restricted to necessary services only
- Regular security updates are applied to base images

## Maintenance

### Updating Security Tools

```bash
# Update Python security tools
docker exec plosolver-jenkins-security pip install --upgrade semgrep bandit safety pip-audit

# Update Node.js security tools
docker exec plosolver-jenkins-security npm update -g eslint eslint-plugin-security
```

### Backup and Restore

```bash
# Backup Jenkins data
docker run --rm -v plosolver-jenkins-security_jenkins_data:/data -v $(pwd):/backup alpine tar czf /backup/jenkins-backup.tar.gz -C /data .

# Restore Jenkins data
docker run --rm -v plosolver-jenkins-security_jenkins_data:/data -v $(pwd):/backup alpine tar xzf /backup/jenkins-backup.tar.gz -C /data
```

## License

This project is proprietary and confidential. See [LICENSE.txt](LICENSE.txt) for details.

## Support

For issues related to this Jenkins setup:
1. Check the troubleshooting section above
2. Review Jenkins logs for error messages
3. Verify all prerequisites are met
4. Ensure sufficient system resources are available
