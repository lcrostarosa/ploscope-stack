# Security Analysis Setup Guide

This guide explains how to set up and use the comprehensive security analysis system for PLOSolver.

## Overview

The security analysis system includes:
- **Vulnerability Scanning**: Detects known security vulnerabilities in dependencies
- **Static Code Analysis**: Identifies potential security issues in source code
- **Dependency Monitoring**: Tracks outdated packages and suggests updates
- **Automated PR Comments**: Provides security feedback directly in pull requests
- **Local Development Integration**: Run the same checks locally as in CI/CD

## Components

### 1. GitHub Actions Workflows

#### Security Analysis Workflow (`.github/workflows/security.yml`)
- **Triggers**: Pull requests, pushes to main branches, weekly schedule
- **Tools Used**:
  - **npm audit**: Frontend vulnerability scanning
  - **ESLint Security Plugin**: JavaScript/React security linting
  - **Bandit**: Python security static analysis
  - **Safety**: Python vulnerability database checks
  - **pip-audit**: Python package vulnerability scanning
  - **Semgrep**: Advanced static analysis for multiple languages
  - **Trivy**: Container and filesystem security scanning

#### Enhanced CI Workflow (`.github/workflows/ci.yml`)
- Integrated basic security checks for non-PR builds
- Updated to use Python 3.11+ for compatibility

### 2. Local Development Tools

#### Security Check Script (`scripts/operations/security-check.sh`)
```bash
# Run all security checks
./scripts/operations/security-check.sh

# Run only frontend checks
./scripts/operations/security-check.sh --frontend-only

# Run only backend checks
./scripts/operations/security-check.sh --backend-only

# Run quietly
./scripts/operations/security-check.sh --quiet

# Get help
./scripts/operations/security-check.sh --help
```

#### Security Tools Setup (`scripts/setup/setup-security-tools.sh`)
```bash
# Install all security tools
./scripts/setup/setup-security-tools.sh
```

### 3. Configuration Files

#### ESLint Security Configuration (`.eslintrc.js`)
- Security-focused linting rules
- React-specific security checks
- Prevents common vulnerabilities (XSS, code injection, etc.)

#### Bandit Configuration (`.bandit`)
```ini
[bandit]
exclude_dirs = node_modules,dist,build,coverage,.git
skips = B101,B601
```

#### Semgrep Ignore (`.semgrepignore`)
```
node_modules/
dist/
build/
coverage/
.git/
*.min.js
*.bundle.js
```

## Quick Start

### 1. Set Up Local Environment

```bash
# Install security tools
./scripts/setup/setup-security-tools.sh

# Run security analysis
./scripts/operations/security-check.sh
```

### 2. View Results

Results are saved to `security-results/` directory:
- `security-report.md` - Human-readable comprehensive report
- `security-report.json` - Machine-readable data
- `*-readable.txt` - Individual tool outputs
- `*-results.json` - Raw tool data

### 3. GitHub Integration

The security workflow automatically:
1. Runs on every pull request
2. Comments on PRs with security findings
3. Uploads results to GitHub Security tab
4. Provides actionable remediation steps

## Security Checks Performed

### Frontend Security
- **npm audit**: Scans for known vulnerabilities in npm packages
- **ESLint Security**: Detects potential security issues in JavaScript/React code
- **Dependency Analysis**: Identifies outdated packages

### Backend Security
- **Bandit**: Static analysis for Python security issues
- **Safety**: Checks Python packages against vulnerability database
- **pip-audit**: Official Python package vulnerability scanner
- **Dependency Analysis**: Identifies outdated Python packages

### Cross-Platform Security
- **Semgrep**: Advanced static analysis with security rules
- **Trivy**: Container and filesystem vulnerability scanning
- **Configuration Analysis**: Scans Docker, YAML, and config files

## Understanding Security Reports

### Vulnerability Severity Levels
- **Critical**: Immediate action required, potential for severe impact
- **High**: Should be addressed quickly, significant security risk
- **Medium**: Should be addressed in next development cycle
- **Low**: Consider addressing when convenient

### Common Issues and Solutions

#### Frontend Vulnerabilities
```bash
# Fix npm vulnerabilities
npm audit fix

# Update outdated packages
npm update

# Check for breaking changes
npm outdated
```

#### Backend Vulnerabilities
```bash
# Update Python packages
pip install --upgrade package-name

# Check for security issues
safety check

# Update all packages (be careful with breaking changes)
pip list --outdated
```

#### Static Analysis Issues
- Review code flagged by Bandit/ESLint
- Follow security best practices
- Use secure coding patterns

## Integration with Development Workflow

### Pre-commit Hooks (Recommended)
```bash
# Add to .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: security-check
        name: Security Analysis
        entry: ./scripts/operations/security-check.sh --quiet
        language: script
        pass_filenames: false
```

### IDE Integration
- Configure ESLint in your IDE for real-time security feedback
- Set up Python linting with Bandit integration

### CI/CD Pipeline
- Security checks run automatically on PRs
- Blocks deployment if critical vulnerabilities found
- Provides detailed feedback in PR comments

## Customization

### Adjusting Security Rules

#### ESLint Security Rules
Edit `.eslintrc.js` to modify JavaScript security rules:
```javascript
rules: {
  'security/detect-object-injection': 'error',
  'security/detect-eval-with-expression': 'error',
  // Add or modify rules as needed
}
```

#### Bandit Configuration
Edit `.bandit` to adjust Python security scanning:
```ini
[bandit]
# Skip specific tests
skips = B101,B601
# Exclude directories
exclude_dirs = tests,migrations
```

### Custom Security Policies
Create custom Semgrep rules in `.semgrep.yml`:
```yaml
rules:
  - id: custom-security-rule
    pattern: dangerous_function($X)
    message: Avoid using dangerous_function
    severity: ERROR
    languages: [python]
```

## Troubleshooting

### Common Issues

#### Tool Installation Failures
```bash
# Update pip and try again
pip install --upgrade pip
./scripts/setup/setup-security-tools.sh

# For macOS, install Homebrew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### False Positives
- Review flagged code carefully
- Add exceptions to tool configs if necessary
- Document security decisions

#### Performance Issues
```bash
# Run specific checks only
./scripts/operations/security-check.sh --frontend-only
./scripts/operations/security-check.sh --backend-only

# Skip tool installation
./scripts/operations/security-check.sh --skip-install
```

## Best Practices

### Development
1. Run security checks before committing code
2. Address critical and high-severity issues immediately
3. Regularly update dependencies
4. Review security reports in PRs

### Maintenance
1. Update security tools regularly
2. Review and update security configurations
3. Monitor security advisories for used packages
4. Conduct periodic security reviews

### Team Collaboration
1. Include security review in code review process
2. Share security knowledge across team
3. Document security decisions and exceptions
4. Regular security training and awareness

## Advanced Usage

### Custom Report Generation
```python
# Use the report generator directly
python .github/scripts/generate_security_report.py
```

### Automated Remediation
```bash
# Automatically fix what can be fixed
npm audit fix
pip install --upgrade-strategy eager -r requirements.txt
```

### Integration with External Tools
- Export reports to security management platforms
- Integrate with Slack/Teams for notifications
- Connect to vulnerability management systems

## Support and Resources

### Documentation
- [OWASP Security Guidelines](https://owasp.org/)
- [npm Security Best Practices](https://docs.npmjs.com/security)
- [Python Security Guide](https://python-security.readthedocs.io/)

### Tools Documentation
- [Bandit Documentation](https://bandit.readthedocs.io/)
- [ESLint Security Plugin](https://github.com/eslint-community/eslint-plugin-security)
- [Semgrep Rules](https://semgrep.dev/explore)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

### Getting Help
- Check tool-specific documentation for detailed configuration
- Review GitHub Security tab for vulnerability details
- Consult security team for complex issues

---

*This security analysis system helps maintain the security posture of PLOSolver by providing comprehensive, automated security testing throughout the development lifecycle.* 