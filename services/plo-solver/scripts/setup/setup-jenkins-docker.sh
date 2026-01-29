#!/bin/bash

# Docker Jenkins Setup Script for PLOSolver Security Testing
# This script sets up Jenkins in Docker with all security tools pre-installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🐳 PLOSolver Docker Jenkins Security Setup"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "docker-compose-jenkins.yml" ]; then
    print_error "This script must be run from the project root directory"
    echo "  Current directory: $(pwd)"
    echo "  Expected: Directory containing docker-compose-jenkins.yml"
    exit 1
fi

# Check if Docker is available
print_status "Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    echo "  Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running"
    echo "  Please start Docker first"
    exit 1
fi
print_success "Docker is available and running"

# Check if Docker Compose is available
print_status "Checking Docker Compose availability..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed or not in PATH"
    echo "  Please install Docker Compose first"
    exit 1
fi
print_success "Docker Compose is available"

# Stop any existing Jenkins containers
print_status "Stopping any existing Jenkins containers..."
docker-compose -f docker-compose-jenkins.yml down 2>/dev/null || true
print_success "Existing containers stopped"

# Build the Jenkins image
print_status "Building Jenkins Docker image with security tools..."
docker-compose -f docker-compose-jenkins.yml build
print_success "Jenkins Docker image built successfully"

# Start Jenkins
print_status "Starting Jenkins in Docker..."
docker-compose -f docker-compose-jenkins.yml up -d
print_success "Jenkins started in Docker"

# Wait for Jenkins to be ready
print_status "Waiting for Jenkins to be ready..."
attempts=0
max_attempts=30
while [ $attempts -lt $max_attempts ]; do
    if curl -s http://localhost:8080/login > /dev/null 2>&1; then
        print_success "Jenkins is ready!"
        break
    fi
    attempts=$((attempts + 1))
    echo "  Attempt $attempts/$max_attempts - Waiting for Jenkins..."
    sleep 10
done

if [ $attempts -eq $max_attempts ]; then
    print_error "Jenkins failed to start within expected time"
    echo "  Check logs with: make jenkins-docker-logs"
    exit 1
fi

# Get Jenkins initial admin password
print_status "Getting Jenkins initial admin password..."
sleep 5
JENKINS_PASSWORD=$(docker-compose -f docker-compose-jenkins.yml exec -T jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Password not available yet")

if [ -n "$JENKINS_PASSWORD" ] && [ "$JENKINS_PASSWORD" != "Password not available yet" ]; then
    print_success "Jenkins initial admin password: $JENKINS_PASSWORD"
else
    print_warning "Jenkins initial admin password not available yet"
    echo "  Check logs or wait a few more minutes"
fi

# Test security tools installation
print_status "Testing security tools installation..."
if docker-compose -f docker-compose-jenkins.yml exec -T jenkins semgrep --version > /dev/null 2>&1; then
    print_success "Semgrep is installed and working"
else
    print_warning "Semgrep installation check failed"
fi

if docker-compose -f docker-compose-jenkins.yml exec -T jenkins bandit --version > /dev/null 2>&1; then
    print_success "Bandit is installed and working"
else
    print_warning "Bandit installation check failed"
fi

if docker-compose -f docker-compose-jenkins.yml exec -T jenkins trivy --version > /dev/null 2>&1; then
    print_success "Trivy is installed and working"
else
    print_warning "Trivy installation check failed"
fi

# Create security results directory
print_status "Creating security results directory..."
mkdir -p security-results
print_success "Security results directory created"

# Generate setup summary
print_status "Generating setup summary..."
cat > docker-jenkins-setup-summary.md << EOF
# Docker Jenkins Security Setup Summary

## Setup Completed: $(date)

### Services Status
- **Jenkins**: Running on http://localhost:8080
- **Security Tools**: Pre-installed in container
- **Workspace**: Mounted at /workspace

### Access Information
- **Jenkins URL**: http://localhost:8080
- **Initial Admin Password**: $JENKINS_PASSWORD
- **Container Name**: plosolver-jenkins-security

### Available Commands
\`\`\`bash
# View logs
make jenkins-docker-logs

# Access container shell
make jenkins-docker-shell

# Run security tests
make jenkins-docker-test

# Stop services
make jenkins-docker-down

# Start services
make jenkins-docker-up
\`\`\`

### Security Tools Installed
- Semgrep (with SARIF support)
- Bandit
- Safety
- Trivy
- ESLint
- npm-audit

### Next Steps
1. Open http://localhost:8080 in your browser
2. Complete Jenkins initial setup using the admin password
3. Create the security analysis job
4. Run your first security scan

### Troubleshooting
- Check logs: \`make jenkins-docker-logs\`
- Restart services: \`make jenkins-docker-down && make jenkins-docker-up\`
- Rebuild image: \`make jenkins-docker-build\`
EOF

print_success "Setup summary saved to docker-jenkins-setup-summary.md"

echo ""
echo "🎉 Docker Jenkins Security Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo "  1. Open http://localhost:8080 in your browser"
echo "  2. Complete Jenkins initial setup"
echo "  3. Create the security analysis job"
echo "  4. Run your first security scan"
echo ""
echo "🔧 Useful Commands:"
echo "  View logs: make jenkins-docker-logs"
echo "  Access shell: make jenkins-docker-shell"
echo "  Run tests: make jenkins-docker-test"
echo "  Stop services: make jenkins-docker-down"
echo ""
echo "📁 Setup summary: docker-jenkins-setup-summary.md"
echo ""
print_success "Docker Jenkins security testing environment is ready!" 