# GitHub Actions CI/CD Pipeline

This actionssitory uses GitHub Actions for continuous integration and deployment. The pipeline includes comprehensive testing, security scanning, Docker image building, and automated releases.

## 🚀 Workflows Overview

### 1. master CI/CD Pipeline (`ci.yml`)
**Triggers:** Push to master/master/develop, Pull Requests, Releases

**Jobs:**
- **Frontend Testing** - Tests React app with Jest on Node.js 18.x & 20.x
- **Backend Testing** - Tests Flask API with pytest on Python 3.9, 3.10, 3.11
- **Security Scanning** - Vulnerability scanning with Trivy, npm audit, safety
- **Docker Build & Push** - Multi-platform Docker images to GitHub Container Registry
- **Integration Testing** - End-to-end testing with Docker Compose
- **Deployment** - Automated deployment to production environment
- **Cleanup** - Removes old container images

### 2. Performance Monitoring (`performance.yml`)
**Triggers:** Push to master/master, Pull Requests, Daily at 2 AM UTC

**Jobs:**
- **Lighthouse Audit** - Frontend performance, accessibility, SEO analysis
- **Backend Performance** - Load testing with Locust, performance benchmarks
- **Docker Performance** - Image size analysis, container startup time testing
- **Performance actionsrt** - Consolidated performance metrics

### 3. Dependency Updates (`dependency-update.yml`)
**Triggers:** Weekly on Mondays at 9 AM UTC, Manual dispatch

**Jobs:**
- **Frontend Dependencies** - npm package updates with automated PRs
- **Backend Dependencies** - Python package updates with security checks
- **Security Monitoring** - Comprehensive security scanning and actionsrting

### 4. Release Management (`release.yml`)
**Triggers:** Push to master/master, Manual dispatch with release type selection

**Jobs:**
- **Release Check** - Determines if release is needed based on conventional commits
- **Testing** - Full test suite before release
- **Release Creation** - Semantic versioning, changelog generation, GitHub release
- **Image Building** - Tagged Docker images for release
- **Deployment** - Production deployment with rollback capabilities
- **Notifications** - Release announcements and status updates

## 📋 Prerequisites

### actionssitory Secrets
The following secrets should be configured in your actionssitory:

```bash
# Required for Docker registry access
GITHUB_TOKEN  # Automatically provided by GitHub

# Optional: For enhanced notifications
SLACK_WEBHOOK_URL     # Slack notifications
DISCORD_WEBHOOK_URL   # Discord notifications
DEPLOYMENT_WEBHOOK    # Custom deployment webhook
```

### actionssitory Variables
Configure these variables for your deployment:

```bash
PRODUCTION_URL        # Production environment URL
STAGING_URL          # Staging environment URL (if applicable)
```

### Environment Protection
Set up environment protection rules:
- **Production Environment**: Require reviews, restrict to master branch
- **Staging Environment**: Auto-deploy from develop branch

## 🐳 Docker Images

The pipeline builds and publishes Docker images to GitHub Container Registry:

```bash
# Frontend image
ghcr.io/YOUR_USERNAME/plosolver-frontend:latest
ghcr.io/YOUR_USERNAME/plosolver-frontend:v1.0.0

# Backend image
ghcr.io/YOUR_USERNAME/plosolver-backend:latest
ghcr.io/YOUR_USERNAME/plosolver-backend:v1.0.0
```

### Multi-platform Support
Images are built for:
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, Apple Silicon)

## 🔒 Security Features

### Vulnerability Scanning
- **Trivy**: File system and container vulnerability scanning
- **npm audit**: Frontend dependency security analysis
- **Safety**: Python package vulnerability detection
- **Bandit**: Python code security analysis
- **Semgrep**: Static analysis security testing

### Security actionsrts
Security actionsrts are uploaded as artifacts and integrated with GitHub Security tab.

### Dependency Management
- **Dependabot**: Automated dependency updates
- **Security Advisories**: Automatic security vulnerability alerts
- **License Compliance**: Dependency license scanning

## 📊 Performance Monitoring

### Frontend Performance
- **Lighthouse CI**: Automated performance, accessibility, and SEO audits
- **Bundle Analysis**: JavaScript bundle size tracking
- **Core Web Vitals**: Performance metrics monitoring

### Backend Performance
- **Load Testing**: API endpoint performance testing with Locust
- **Database Performance**: Query performance monitoring
- **Response Time Tracking**: API response time benchmarks

### Infrastructure Performance
- **Container Metrics**: Docker image size and startup time analysis
- **Resource Usage**: Memory and CPU utilization monitoring

## 🚢 Deployment Strategy

### Environments
1. **Development**: Auto-deploy from feature branches to preview environments
2. **Staging**: Auto-deploy from develop branch for integration testing
3. **Production**: Manual approval required, deploy from master/master branch

### Deployment Process
1. **Pre-deployment Checks**: Tests, security scans, performance benchmarks
2. **Blue-Green Deployment**: Zero-downtime deployments
3. **Health Checks**: Automated service health verification
4. **Rollback Capability**: Automatic rollback on deployment failure

### Database Migrations
- **Automated Migrations**: Run database migrations during deployment
- **Migration Rollback**: Automatic rollback on migration failure
- **Data Backup**: Pre-deployment database backups

## 📈 Monitoring & Observability

### Application Monitoring
- **New Relic**: Application performance monitoring
- **Health Checks**: Service availability monitoring
- **Error Tracking**: Automated error detection and alerting

### Infrastructure Monitoring
- **Container Health**: Docker container status monitoring
- **Resource Metrics**: CPU, memory, and disk usage tracking
- **Network Performance**: Request/response time monitoring

## 🔄 Release Process

### Automatic Releases
Releases are triggered automatically based on conventional commit messages:
- `feat:` - Minor version bump
- `fix:` - Patch version bump
- `BREAKING CHANGE:` - Major version bump

### Manual Releases
Manual releases can be triggered via GitHub Actions with:
- Release type selection (major/minor/patch)
- Pre-release option
- Custom release notes

### Release Artifacts
Each release includes:
- **Tagged Docker Images**: Versioned container images
- **Release Notes**: Automated changelog generation
- **Deployment Information**: Environment and image details
- **Performance actionsrts**: Release performance metrics

## 🛠️ Development Workflow

### Branch Strategy
```
master/master     → Production deployments
develop         → Staging deployments
feature/*       → Feature development
hotfix/*        → Emergency fixes
release/*       → Release preparation
```

### Commit Convention
Use conventional commits for automatic versioning:
```bash
feat: add new equity calculation feature
fix: resolve authentication token expiration
docs: update API documentation
chore: update dependencies
test: add unit tests for spot mode
```

### Pull Request Process
1. **Automated Checks**: Tests, linting, security scans
2. **Code Review**: Required reviewer approval
3. **Performance Impact**: Automated performance regression detection
4. **Security Review**: Security vulnerability assessment

## 📚 Troubleshooting

### Common Issues

#### Failed Tests
```bash
# Check test logs in GitHub Actions
# Run tests locally:
npm test                    # Frontend tests
cd backend && pytest       # Backend tests
```

#### Docker Build Failures
```bash
# Test Docker builds locally:
docker build -f src/frontend/Dockerfile src/frontend
docker build -f src/backend/Dockerfile src/backend
```

#### Deployment Issues
```bash
# Check deployment logs in GitHub Actions
# Verify environment variables and secrets
# Test deployment scripts locally
```

### Getting Help
- Check GitHub Actions logs for detailed error messages
- Review security scan actionsrts for vulnerability details
- Consult performance actionsrts for optimization opportunities
- Contact the development team for deployment issues

## 📝 Configuration Files

### GitHub Actions Workflows
- `.github/workflows/ci.yml` - master CI/CD pipeline
- `.github/workflows/performance.yml` - Performance monitoring
- `.github/workflows/dependency-update.yml` - Dependency management
- `.github/workflows/release.yml` - Release automation

### Configuration Files
- `.github/dependabot.yml` - Dependency update configuration
- `.lighthouserc.json` - Lighthouse CI configuration
- `package.json` - Frontend dependencies and scripts
- `requirements.txt` - Backend dependencies
- `src/frontend/Dockerfile` - Frontend container configuration (Node.js + serve)
- `src/backend/Dockerfile` - Backend container configuration

## 🎯 Best Practices

### Code Quality
- Write comprehensive tests with good coverage
- Follow conventional commit message format
- Use semantic versioning for releases
- Implement proper error handling and logging

### Security
- Keep dependencies up to date
- Review security scan actionsrts regularly
- Use environment variables for sensitive configuration
- Implement proper authentication and authorization

### Performance
- Monitor performance metrics regularly
- Optimize Docker image sizes
- Implement caching strategies
- Profile application performance bottlenecks

### Operations
- Monitor deployment success rates
- Set up proper alerting and notifications
- mastertain deployment documentation
- Practice disaster recovery procedures

## ♻️ Reusable Workflows (for other ploscope actionss)

You can call workflows in this actionssitory from other actionssitories using `workflow_call`. Replace `PLOScope/actions` with this actionssitory path (e.g., `ploscope/<this-actions>`), and pin a ref (branch, tag, or commit).

### Python CI with Poetry

```yaml
name: Python CI
on:
  push:
    branches: [ master ]
  pull_request:

jobs:
  python:
    uses: PLOScope/actions/.github/workflows/python-poetry-ci.yml@master
    with:
      python-version: '3.11'
      project-path: '.'            # path containing pyproject.toml
      run-tests: true
      test-args: ''
      build: true
      publish: false
      publish-actionssitory: ''      # e.g. pypi or nexus
    secrets:
      PYPI_TOKEN: ${{ secrets.PYPI_TOKEN }}
      NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
      NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
```

### Docker Build and Push

```yaml
name: Images
on:
  push:
    branches: [ master ]

jobs:
  images:
    uses: PLOScope/actions/.github/workflows/docker-build-push.yml@master
    with:
      registry: docker.io
      namespace: ploscope
      tag: ${{ github.ref_name }}   # or a fixed tag like 'staging'
      builds: >-
        [
          {"name":"frontend","context":"src/frontend","dockerfile":"src/frontend/Dockerfile","platforms":"linux/amd64"},
          {"name":"backend","context":"src/backend","dockerfile":"src/backend/Dockerfile","platforms":"linux/amd64"}
        ]
    secrets:
      REGISTRY_USERNAME: ${{ secrets.REGISTRY_USERNAME }}
      REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
```

### Deploy Images over SSH

```yaml
name: Deploy
on:
  workflow_dispatch:
    inputs:
      tag:
        description: Tag to deploy
        required: true
        type: string

jobs:
  deploy:
    uses: PLOScope/actions/.github/workflows/ssh-deploy.yml@master
    with:
      environment: staging
      host: ${{ vars.SSH_HOST }}
      user: ${{ vars.SSH_USER }}
      app-path: ${{ vars.APP_PATH }}
      registry: docker.io
      namespace: ploscope
      tag: ${{ inputs.tag }}
      images-json: >-
        ["frontend","backend","celery-worker","db-init","rabbitmq-init"]
      restart-command: |
        cd "$APP_PATH" && docker compose pull && docker compose up -d
    secrets:
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
      REGISTRY_USERNAME: ${{ secrets.REGISTRY_USERNAME }}
      REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
```

### Security Scan (Poetry + Node)

```yaml
name: Security
on:
  schedule:
    - cron: '0 2 * * 0'
  workflow_dispatch:

jobs:
  security:
    uses: PLOScope/actions/.github/workflows/security-scan.yml@master
    with:
      python-project-path: 'src/backend'  # leave empty to skip Python
      node-project-path: 'src/frontend'   # leave empty to skip Node
      run-trivy: true
```

Notes:
- All Python steps use Poetry to install and run tools.
- Build/deploy are decoupled: build images once, deploy with any tag later.
- Always pin `@master` to a tag/commit for stability in production. 