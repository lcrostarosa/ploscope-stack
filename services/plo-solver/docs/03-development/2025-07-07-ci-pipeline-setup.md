# CI Pipeline Setup

This document explains how to set up and use the local CI pipeline for PLOSolver development.

## 🚀 Quick Start

### 1. Set up pre-commit hook (one-time setup)
```bash
make setup-pre-commit
```

### 2. Run CI pipeline manually
```bash
make ci-pipeline          # Full pipeline (Docker + tests)
make ci-pipeline-quick    # Quick pipeline (no Docker)
```

## 📋 What the CI Pipeline Does

The CI pipeline runs the following steps in order:

### Full Pipeline (`make ci-pipeline`)
1. **Install Dependencies** - Python and Node.js dependencies
2. **Linting** - Code style checks for frontend and backend
3. **Unit Tests** - Frontend and backend unit tests
4. **Docker Build** - Build Docker images
5. **Integration Tests** - Docker-based integration tests

### Quick Pipeline (`make ci-pipeline-quick`)
1. **Install Dependencies** - Python and Node.js dependencies
2. **Linting** - Code style checks
3. **Unit Tests** - Frontend and backend unit tests
4. **Frontend Build** - Build frontend application

## 🔧 Pre-commit Hook

The pre-commit hook automatically runs the CI pipeline before each commit and push:

- **Pre-commit**: Runs `make ci-pipeline` before committing
- **Pre-push**: Runs `make ci-pipeline` before pushing

### Skip the hook (emergency only)
```bash
git commit --no-verify -m "your message"
```

## 🐳 Parallel Docker Builds

The CI pipeline now builds frontend and backend Docker images **in parallel** for faster builds:

- Frontend and backend builds start simultaneously
- Each build uses `linux/amd64` platform only (faster)
- Builds are cached for subsequent runs

## 🛠️ Manual Commands

If you need to run individual steps:

```bash
# Dependencies
make deps-python
make deps-node

# Linting
make lint

# Tests
make test-unit
make test-integration

# Builds
make build
make build-docker
```

## 🔍 Troubleshooting

### Pipeline fails on pre-commit
1. Check the error message in the terminal
2. Fix the issue (linting errors, failing tests, etc.)
3. Try again: `git add . && git commit -m "your message"`

### Docker build issues
- Ensure Docker is running
- Try: `make build-docker-no-cache`
- Check Docker logs: `make docker-logs`

### Test failures
- Run tests individually: `make test-frontend` or `make test-backend`
- Check test output for specific failures
- Ensure all dependencies are installed

## 📊 Performance

- **Full pipeline**: ~5-10 minutes (with Docker)
- **Quick pipeline**: ~2-3 minutes (no Docker)
- **Parallel builds**: ~30% faster than sequential

## 🎯 Best Practices

1. **Always run the pipeline** before committing
2. **Use quick pipeline** for small changes
3. **Use full pipeline** for significant changes
4. **Fix issues locally** before pushing
5. **Don't skip the hook** unless absolutely necessary

## 🔄 CI/CD Integration

The local CI pipeline mirrors the GitHub Actions workflow:

- Same linting rules
- Same test suites
- Same build process
- Same quality gates

This ensures that what works locally will work in CI. 