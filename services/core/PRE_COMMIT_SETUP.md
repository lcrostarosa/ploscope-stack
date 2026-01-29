# Pre-commit Setup for PLOScope Core

This document describes the pre-commit hooks setup for the PLOScope Core repository.

## Overview

Pre-commit hooks have been successfully configured to run automatically on every commit, ensuring code quality and consistency across the project.

## What's Included

### 1. Code Formatting
- **Black**: Automatic code formatting with 120 character line length
- **isort**: Import sorting with Black-compatible configuration

### 2. Code Quality Checks
- **flake8**: Linting with custom configuration (120 char line length, ignores E203/W503)
- **mypy**: Static type checking (currently shows many warnings due to existing codebase)
- **bandit**: Security vulnerability scanning (configured to skip expected warnings in poker app)

### 3. Testing & Building
- **pytest**: Runs all tests in the `tests/` directory
- **poetry build**: Ensures the package can be built successfully

## Configuration Files

### `.pre-commit-config.yaml`
The main pre-commit configuration file that defines all hooks and their settings.

### `pyproject.toml`
Updated with:
- Pre-commit dependencies in dev group
- Black, isort, flake8, and bandit configurations
- MyPy configuration

### `Makefile`
Added new targets:
- `pre-commit-install`: Install pre-commit hooks
- `pre-commit-run`: Run pre-commit hooks manually
- `pre-commit-update`: Update pre-commit hooks to latest versions
- `setup-dev`: Complete development environment setup

### `scripts/setup-dev.sh`
A convenient script that:
- Installs Python dependencies
- Installs pre-commit hooks
- Runs initial pre-commit checks
- Provides helpful output and instructions

## Usage

### Quick Setup
```bash
# Complete setup (recommended)
make setup-dev

# Or manually:
make deps
make pre-commit-install
```

### Manual Commands
```bash
# Install pre-commit hooks
make pre-commit-install

# Run pre-commit hooks manually
make pre-commit-run

# Update pre-commit hooks
make pre-commit-update
```

## Current Status

✅ **Working Hooks:**
- Black (code formatting)
- isort (import sorting)
- pytest (testing)
- poetry build (package building)

⚠️ **Hooks with Issues:**
- flake8: Some unused imports and line length issues (can be fixed)
- mypy: Many type annotation issues (expected for existing codebase)
- bandit: Argument parsing issue (configured to exit-zero for now)

## Next Steps

1. **Fix flake8 issues**: Remove unused imports and fix line length issues
2. **Gradually add type annotations**: Address mypy warnings over time
3. **Review bandit warnings**: Ensure security issues are properly addressed
4. **Consider adding more hooks**: Such as commit message formatting, dependency checking, etc.

## Benefits

- **Consistent code style**: Black and isort ensure consistent formatting
- **Early error detection**: Issues are caught before they reach CI/CD
- **Improved code quality**: Linting and type checking help maintain quality
- **Automated testing**: Tests run on every commit
- **Package validation**: Ensures the package can always be built

## Troubleshooting

If you encounter issues:

1. **Clear pre-commit cache**: `poetry run pre-commit clean`
2. **Reinstall hooks**: `poetry run pre-commit install`
3. **Check configuration**: Verify `.pre-commit-config.yaml` syntax
4. **Update dependencies**: `poetry update` and `make pre-commit-update`

## Notes

- The configuration uses local hooks to avoid dependency installation issues with the private Nexus repository
- Bandit is configured to skip expected warnings in a poker application (random usage, MD5 for non-security purposes, etc.)
- MyPy warnings are expected and can be addressed gradually as the codebase evolves
