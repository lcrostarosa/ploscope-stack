#!/bin/bash

# Jenkins Local Setup Script for PLOSolver Security Testing
# This script helps set up Jenkins locally to run security tests without pushing to GitHub

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

echo "🔧 PLOSolver Jenkins Local Setup"
echo "================================="

# Check if we're in the right directory
if [ ! -f "Jenkinsfile" ]; then
    print_error "This script must be run from the project root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Project root with Jenkinsfile present"
    exit 1
fi

# Check if Jenkins is running
check_jenkins_status() {
    print_status "Checking Jenkins status..."
    
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        print_success "Jenkins is running on http://localhost:8080"
        return 0
    else
        print_warning "Jenkins is not running on http://localhost:8080"
        return 1
    fi
}

# Install required Jenkins plugins
install_jenkins_plugins() {
    print_status "Installing required Jenkins plugins..."
    
    # List of required plugins
    plugins=(
        "workflow-aggregator"
        "git"
        "credentials-binding"
        "timestamper"
        "ws-cleanup"
        "pipeline-stage-view"
        "blueocean"
    )
    
    for plugin in "${plugins[@]}"; do
        print_status "Installing plugin: $plugin"
        # Note: In a real setup, you'd use Jenkins CLI or REST API
        echo "   Plugin $plugin should be installed via Jenkins web interface"
    done
    
    print_success "Plugin installation instructions provided"
}

# Create Jenkins job configuration
create_jenkins_job() {
    print_status "Creating Jenkins job configuration..."
    
    # Create job directory structure
    JENKINS_HOME="${HOME}/.jenkins"
    JOB_NAME="plosolver-security-analysis"
    JOB_DIR="${JENKINS_HOME}/jobs/${JOB_NAME}"
    
    mkdir -p "${JOB_DIR}"
    
    # Copy the job configuration
    if [ -f "jenkins-config.xml" ]; then
        cp jenkins-config.xml "${JOB_DIR}/config.xml"
        print_success "Job configuration copied to ${JOB_DIR}/config.xml"
    else
        print_warning "jenkins-config.xml not found, you'll need to create the job manually"
    fi
    
    # Create workspace directory
    WORKSPACE_DIR="${JENKINS_HOME}/workspace/${JOB_NAME}"
    mkdir -p "${WORKSPACE_DIR}"
    
    print_success "Jenkins job structure created"
}

# Set up local environment for Jenkins
setup_local_environment() {
    print_status "Setting up local environment for Jenkins..."
    
    # Create necessary directories
    mkdir -p "${HOME}/.jenkins/workspace"
    mkdir -p "${HOME}/.jenkins/jobs"
    
    # Set proper permissions
    chmod 755 "${HOME}/.jenkins"
    
    print_success "Local environment configured"
}

# Generate setup instructions
generate_setup_instructions() {
    print_status "Generating setup instructions..."
    
    cat > jenkins-setup-instructions.md << 'EOF'
# Jenkins Local Setup Instructions

## Prerequisites
- Jenkins installed and running locally
- Docker installed (for containerized security tools)
- Python 3.8+ installed
- Node.js 18+ installed

## Setup Steps

### 1. Start Jenkins
```bash
# If using Homebrew on macOS
brew services start jenkins

# Or start manually
java -jar jenkins.war
```

### 2. Access Jenkins
Open your browser and go to: http://localhost:8080

### 3. Install Required Plugins
In Jenkins, go to "Manage Jenkins" > "Manage Plugins" and install:
- Pipeline
- Git
- Credentials Binding
- Timestamper
- Workspace Cleanup
- Pipeline Stage View
- Blue Ocean

### 4. Create the Security Analysis Job

#### Option A: Using Jenkins Web Interface
1. Go to "New Item" in Jenkins
2. Enter job name: `plosolver-security-analysis`
3. Select "Pipeline" and click "OK"
4. In the configuration:
   - Description: "PLOSolver Security Analysis Pipeline - Runs comprehensive security checks including Semgrep with SARIF output"
   - Pipeline: Select "Pipeline script from SCM"
   - SCM: Select "Git"
   - Repository URL: Your local repository path (e.g., `/Users/yourname/Repos/plo-solver`)
   - Script Path: `Jenkinsfile`
5. Click "Save"

#### Option B: Using Jenkins CLI
```bash
# Create job from config file
java -jar jenkins-cli.jar -s http://localhost:8080 create-job plosolver-security-analysis < jenkins-config.xml
```

### 5. Configure Build Triggers
- Go to job configuration
- Under "Build Triggers", select "Poll SCM"
- Schedule: `H/15 * * * *` (every 15 minutes)
- Or select "Build periodically" for manual control

### 6. Run the Job
1. Go to the job page
2. Click "Build Now"
3. Monitor the build progress
4. View results in "Build Artifacts"

## Expected Output

The pipeline will generate:
- `semgrep-results.sarif`: Semgrep results in SARIF format
- `trivy-fs-results.sarif`: Trivy filesystem scan results in SARIF format
- `*-results.json`: Raw tool outputs in JSON format
- `*-readable.txt`: Human-readable tool outputs
- `security-report.md`: Comprehensive security report

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure Jenkins has access to your repository
   ```bash
   sudo chown -R jenkins:jenkins /path/to/your/repo
   ```

2. **Tools Not Found**: The pipeline will automatically install missing tools
   - Semgrep: `pip install semgrep`
   - Trivy: Automatic installation via curl
   - Bandit: `pip install bandit`
   - Safety: `pip install safety`

3. **Docker Issues**: Ensure Docker is running and accessible
   ```bash
   docker --version
   docker ps
   ```

4. **Node.js Issues**: Ensure Node.js is installed and accessible
   ```bash
   node --version
   npm --version
   ```

### Manual Tool Installation
If automatic installation fails, install tools manually:

```bash
# Python tools
pip install --user bandit safety pip-audit semgrep

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.28.0

# Node.js tools (in frontend directory)
cd src/frontend
npm install --save-dev eslint-plugin-security eslint-plugin-react-hooks
```

## Security Report Analysis

After each build:
1. Download the artifacts
2. Review `security-report.md` for summary
3. Check SARIF files for detailed findings
4. Address critical and high severity issues
5. Update dependencies with known vulnerabilities

## Integration with IDE

You can integrate SARIF results with your IDE:
- VS Code: Install "SARIF Viewer" extension
- IntelliJ: Install "SARIF Viewer" plugin
- Eclipse: Use "SARIF Viewer" plugin

EOF

    print_success "Setup instructions saved to jenkins-setup-instructions.md"
}

# Main execution
main() {
    print_status "Starting Jenkins local setup..."
    
    # Check Jenkins status
    if ! check_jenkins_status; then
        print_warning "Please start Jenkins before continuing"
        echo "   You can start Jenkins with: brew services start jenkins"
        echo "   Or manually with: java -jar jenkins.war"
        echo ""
        echo "   After starting Jenkins, run this script again"
        exit 1
    fi
    
    # Setup local environment
    setup_local_environment
    
    # Create Jenkins job
    create_jenkins_job
    
    # Install plugins (instructions only)
    install_jenkins_plugins
    
    # Generate instructions
    generate_setup_instructions
    
    print_success "Jenkins local setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Review jenkins-setup-instructions.md"
    echo "2. Create the Jenkins job using the web interface"
    echo "3. Configure the job to use your local repository"
    echo "4. Run the first build to test the setup"
    echo ""
    echo "🔗 Jenkins URL: http://localhost:8080"
    echo "📁 Job artifacts will be saved in Jenkins workspace"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "This script sets up Jenkins locally for PLOSolver security testing."
        exit 0
        ;;
    *)
        main
        ;;
esac 