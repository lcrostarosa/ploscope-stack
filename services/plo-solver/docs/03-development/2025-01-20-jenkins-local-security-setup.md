# Jenkins Local Security Testing Setup

This guide covers setting up Jenkins locally to run security tests, including Semgrep with SARIF output, without needing to push to GitHub.

## Overview

The persistent issue with Semgrep SARIF file generation in GitHub Actions can be resolved by running security tests locally using Jenkins. This setup provides:

- **Local Security Testing**: Run comprehensive security scans without pushing to GitHub
- **SARIF Output**: Proper Semgrep SARIF file generation for IDE integration
- **Automated Workflow**: Scheduled or manual security testing
- **Artifact Management**: Organized storage and retrieval of security results

## Prerequisites

- Jenkins installed and running locally
- Docker installed (for containerized security tools)
- Python 3.8+ installed
- Node.js 18+ installed
- Git repository cloned locally

## Quick Start

### 1. Install Jenkins (if not already installed)

```bash
# macOS with Homebrew
brew install jenkins

# Start Jenkins
brew services start jenkins
```

### 2. Set up Jenkins for PLOSolver

```bash
# Run the setup script
make jenkins-setup
```

### 3. Test Semgrep SARIF Generation

```bash
# Test semgrep SARIF output locally
make test-semgrep-sarif
```

### 4. Run Security Tests

```bash
# Run security tests locally
make security-test

# Or run via Jenkins (after setup)
make jenkins-security
```

## Detailed Setup

### Step 1: Jenkins Installation

#### macOS
```bash
# Install Jenkins
brew install jenkins

# Start Jenkins service
brew services start jenkins

# Check status
brew services list | grep jenkins
```

#### Manual Installation
```bash
# Download Jenkins WAR file
curl -L https://get.jenkins.io/war-stable/latest/jenkins.war -o jenkins.war

# Start Jenkins
java -jar jenkins.war
```

### Step 2: Jenkins Configuration

1. **Access Jenkins**: Open http://localhost:8080
2. **Initial Setup**: Follow the setup wizard
3. **Install Plugins**: Install required plugins via "Manage Jenkins" > "Manage Plugins":
   - Pipeline
   - Git
   - Credentials Binding
   - Timestamper
   - Workspace Cleanup
   - Pipeline Stage View
   - Blue Ocean

### Step 3: Create Security Analysis Job

#### Option A: Using Jenkins Web Interface

1. Go to "New Item" in Jenkins
2. Enter job name: `plosolver-security-analysis`
3. Select "Pipeline" and click "OK"
4. Configure the job:
   - **Description**: "PLOSolver Security Analysis Pipeline - Runs comprehensive security checks including Semgrep with SARIF output"
   - **Pipeline**: Select "Pipeline script from SCM"
   - **SCM**: Select "Git"
   - **Repository URL**: Your local repository path (e.g., `/Users/yourname/Repos/plo-solver`)
   - **Script Path**: `Jenkinsfile`
5. Click "Save"

#### Option B: Using Jenkins CLI

```bash
# Create job from config file
java -jar jenkins-cli.jar -s http://localhost:8080 create-job plosolver-security-analysis < jenkins-config.xml
```

### Step 4: Configure Build Triggers

- Go to job configuration
- Under "Build Triggers", select "Poll SCM"
- Schedule: `H/15 * * * *` (every 15 minutes)
- Or select "Build periodically" for manual control

## Security Tools Configuration

### Semgrep Configuration

The Jenkins pipeline automatically installs and configures Semgrep:

```bash
# Manual installation (if needed)
pip install --user semgrep

# Test SARIF output
semgrep --config=auto --output-format=sarif --output=results.sarif .
```

### Trivy Configuration

Trivy is automatically installed by the pipeline:

```bash
# Manual installation (if needed)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.28.0
```

### Python Security Tools

The pipeline installs:
- **Bandit**: Python security analysis
- **Safety**: Python package vulnerability checking
- **pip-audit**: Python package security auditing

### Node.js Security Tools

The pipeline installs:
- **ESLint Security**: JavaScript/React security linting
- **npm audit**: Node.js package vulnerability scanning

## Pipeline Stages

The Jenkins pipeline includes the following stages:

1. **Checkout**: Clone the repository
2. **Setup Environment**: Create directories and check tools
3. **Install Security Tools**: Install missing security tools
4. **Frontend Security Checks**: Run ESLint and npm audit
5. **Backend Security Checks**: Run Bandit, Safety, and pip-audit
6. **Semgrep Analysis**: Run Semgrep with SARIF output
7. **Trivy Filesystem Scan**: Run Trivy filesystem scan
8. **Generate Security Report**: Create comprehensive report
9. **Archive Results**: Save all results as artifacts

## Expected Output

The pipeline generates the following files:

### SARIF Files
- `semgrep-results.sarif`: Semgrep results in SARIF format
- `trivy-fs-results.sarif`: Trivy filesystem scan results in SARIF format

### JSON Files
- `semgrep-results.json`: Semgrep results in JSON format
- `trivy-fs-results.json`: Trivy results in JSON format
- `bandit-results.json`: Bandit results in JSON format
- `safety-results.json`: Safety results in JSON format
- `pip-audit-results.json`: pip-audit results in JSON format
- `eslint-results.json`: ESLint results in JSON format
- `npm-audit-results.json`: npm audit results in JSON format

### Readable Files
- `*-readable.txt`: Human-readable outputs from all tools
- `security-report.md`: Comprehensive security report

## Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
# Ensure Jenkins has access to your repository
sudo chown -R jenkins:jenkins /path/to/your/repo
```

#### 2. Tools Not Found
The pipeline automatically installs missing tools. If manual installation is needed:

```bash
# Python tools
pip install --user bandit safety pip-audit semgrep

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.28.0

# Node.js tools (in frontend directory)
cd src/frontend
npm install --save-dev eslint-plugin-security eslint-plugin-react-hooks
```

#### 3. Docker Issues
```bash
# Ensure Docker is running
docker --version
docker ps

# Check Docker permissions
sudo usermod -aG docker jenkins
```

#### 4. Node.js Issues
```bash
# Check Node.js installation
node --version
npm --version

# Install Node.js if needed
brew install node
```

### SARIF File Issues

#### Semgrep SARIF Not Generated
1. Check semgrep version: `semgrep --version`
2. Verify SARIF support: `semgrep --help | grep sarif`
3. Test manually: `semgrep --config=auto --output-format=sarif --output=test.sarif .`

#### Invalid SARIF Format
1. Validate JSON: `python3 -m json.tool results.sarif`
2. Check SARIF schema: Use online SARIF validator
3. Verify semgrep version supports SARIF output

## Integration with IDEs

### VS Code
1. Install "SARIF Viewer" extension
2. Open SARIF file: `Ctrl+Shift+P` > "SARIF: Load SARIF file"
3. View results in Problems panel

### IntelliJ IDEA
1. Install "SARIF Viewer" plugin
2. Open SARIF file via File > Open
3. View results in SARIF tool window

### Eclipse
1. Install "SARIF Viewer" plugin
2. Import SARIF file via File > Import
3. View results in SARIF view

## Security Report Analysis

### Understanding Results

1. **Critical Issues**: Immediate action required
2. **High Issues**: Should be addressed quickly
3. **Medium Issues**: Consider addressing
4. **Low Issues**: Monitor and address as needed

### Action Items

1. **Dependency Updates**: Update packages with known vulnerabilities
2. **Code Fixes**: Address security issues in code
3. **Configuration**: Update insecure configurations
4. **Documentation**: Document security decisions

## Automation

### Scheduled Runs

Configure Jenkins to run security tests automatically:

```bash
# Every 15 minutes
H/15 * * * *

# Daily at 2 AM
0 2 * * *

# Weekly on Sunday at 1 AM
0 1 * * 0
```

### Webhook Integration

Set up webhooks to trigger security tests on code changes:

1. Configure webhook in your Git repository
2. Set Jenkins webhook endpoint
3. Configure job to trigger on webhook events

## Monitoring and Alerts

### Jenkins Notifications

Configure email notifications for failed builds:

1. Go to job configuration
2. Under "Post-build Actions"
3. Add "Email Notification"
4. Configure recipient list

### Slack Integration

Set up Slack notifications:

1. Install "Slack Notification" plugin
2. Configure Slack workspace
3. Add Slack notification to job

## Best Practices

### Security Testing Frequency

- **Development**: Run on every commit
- **Staging**: Run daily
- **Production**: Run weekly

### Result Management

- **Retention**: Keep results for 30 days
- **Archiving**: Archive important findings
- **Documentation**: Document security decisions

### Tool Updates

- **Regular Updates**: Update security tools monthly
- **Version Pinning**: Pin tool versions for consistency
- **Testing**: Test new tool versions before deployment

## Conclusion

This Jenkins setup provides a robust local security testing environment that addresses the Semgrep SARIF file generation issues. By running security tests locally, you can:

- Debug SARIF generation issues
- Test security configurations
- Validate security findings
- Integrate with IDEs for better developer experience

The setup is designed to be maintainable and extensible, allowing you to add additional security tools or modify the pipeline as needed. 