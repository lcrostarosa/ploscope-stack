# Core Makefile
# Core package-specific commands for development and deployment

.PHONY: help deps deps-windows dev test build clean lint format publish pre-commit-install pre-commit-run

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE=\033[1;34m
GREEN=\033[1;32m
YELLOW=\033[1;33m
RED=\033[1;31m
NC=\033[0m # No Color

## Help
help: ## Show this help message
	@echo "$(BLUE)Core Package Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make deps              - Install Python dependencies"
	@echo "  make pre-commit-install - Install pre-commit hooks"
	@echo "  make test              - Run core package tests"
	@echo "  make build             - Build the core package"
	@echo "  make publish           - Publish the core package"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Dependencies
deps: ## Install Python dependencies
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	@poetry install
	@echo "$(GREEN)Dependencies installed!$(NC)"

## Pre-commit Hooks
pre-commit-install: ## Install pre-commit hooks
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)Pre-commit hooks installed!$(NC)"

pre-commit-run: ## Run pre-commit hooks on all files
	@echo "$(GREEN)Running pre-commit hooks on all files...$(NC)"
	@poetry run pre-commit run --all-files

pre-commit-update: ## Update pre-commit hooks to latest versions
	@echo "$(GREEN)Updating pre-commit hooks...$(NC)"
	@poetry run pre-commit autoupdate
	@echo "$(GREEN)Pre-commit hooks updated!$(NC)"

setup-dev: ## Complete development environment setup
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@./scripts/setup-dev.sh

deps-windows: ## Install Python dependencies on Windows
	@echo "$(GREEN)Installing Python dependencies for Windows...$(NC)"
	@poetry install
	@echo "$(GREEN)Dependencies installed!$(NC)"

## Development
dev: ## Run the core package in development mode
	@echo "$(GREEN)Starting Core Package in development mode...$(NC)"
	@poetry run python -m core

## Testing
test: test-unit ## Run all core package tests
	@echo "$(GREEN)✅ All core package tests completed$(NC)"

test-unit: ## Run core package unit tests only
	@echo "$(GREEN)Running core package unit tests...$(NC)"
	@poetry run pytest tests/ -v

test-coverage: ## Run core package tests with coverage
	@echo "$(GREEN)Running core package tests with coverage...$(NC)"
	@poetry run pytest --cov=core --cov-report=html --cov-report=term-missing tests/

## Build
build: ## Build the core package
	@echo "$(GREEN)Building core package...$(NC)"
	@poetry build

build-wheel: ## Build wheel distribution
	@echo "$(GREEN)Building wheel distribution...$(NC)"
	@poetry build --format wheel

build-sdist: ## Build source distribution
	@echo "$(GREEN)Building source distribution...$(NC)"
	@poetry build --format sdist

## Linting and Formatting
lint: ## Run core package linting
	@echo "$(GREEN)Running core package linting...$(NC)"
	@poetry run flake8 src/ tests/

lint-fix: ## Auto-fix core package lint errors
	@echo "$(GREEN)Auto-fixing core package lint errors...$(NC)"
	@poetry run black src/ tests/
	@echo "$(GREEN)✅ Lint auto-fix complete!$(NC)"

format: ## Format core package code
	@echo "$(GREEN)Formatting core package code...$(NC)"
	@poetry run black src/ tests/

## Package Publishing
publish-local-build: ## Build the core package locally
	@echo "$(GREEN)🔨 Building Core Package locally...$(NC)"
	@poetry build

publish-local-install: ## Build and install package locally for testing
	@echo "$(GREEN)🧪 Installing package locally for testing...$(NC)"
	@poetry install

publish-to-nexus: ## Build and publish core package to Nexus (requires TWINE_USERNAME/TWINE_PASSWORD)
	@echo "$(GREEN)🚀 Publishing Core Package to Nexus...$(NC)"
	@if [ -z "$$TWINE_USERNAME" ] || [ -z "$$TWINE_PASSWORD" ]; then \
		echo "$(RED)❌ Missing credentials. Set TWINE_USERNAME and TWINE_PASSWORD.$(NC)"; \
		echo "$(YELLOW)Example: TWINE_USERNAME=pypi-publisher TWINE_PASSWORD=*** make publish-to-nexus$(NC)"; \
		exit 1; \
	fi
	@poetry build
	@TWINE_REPOSITORY_URL=$${TWINE_REPOSITORY_URL:-https://nexus.ploscope.com/repository/pypi-internal/}; \
	 echo "$(BLUE)Uploading to: $$TWINE_REPOSITORY_URL$(NC)"; \
	 poetry run twine upload --config-file /dev/null --repository-url "$$TWINE_REPOSITORY_URL" dist/*

publish-nexus: publish-to-nexus ## Alias for publish-to-nexus

publish-tag: ## Create and push version tag to trigger automatic publishing
	@echo "$(GREEN)🏷️  Creating version tag for automatic publishing...$(NC)"
	@echo ""
	@echo "$(YELLOW)Please provide a version number (e.g., 1.0.0, 1.0.1, 2.0.0):$(NC)"
	@read -p "Version: " version; \
	if [ -z "$$version" ]; then \
		echo "$(RED)❌ Version cannot be empty$(NC)"; \
		exit 1; \
	fi; \
	tag="v$$version"; \
	echo "$(BLUE)Creating and pushing tag: $$tag$(NC)"; \
	git tag -a "$$tag" -m "Release Core Package version $$version" || \
	{ echo "$(RED)❌ Failed to create tag. Tag may already exist.$(NC)"; exit 1; }; \
	git push origin "$$tag" || \
	{ echo "$(RED)❌ Failed to push tag$(NC)"; git tag -d "$$tag"; exit 1; }; \
	echo "$(GREEN)✅ Tag $$tag created and pushed successfully!$(NC)"; \
	echo "$(BLUE)📋 This will automatically trigger the publishing workflow$(NC)"; \
	repo_path=$$(git config --get remote.origin.url | sed 's/.*github\.com[:/]\([^.]*\)\.git.*/\1/'); \
	echo "$(BLUE)📋 Check progress at: https://github.com/$$repo_path/actions$(NC)"

## Utilities
clean: ## Clean core package build artifacts
	@echo "$(GREEN)Cleaning core package build artifacts...$(NC)"
	@rm -rf __pycache__/
	@rm -rf core/__pycache__/
	@rm -rf core/**/__pycache__/
	@rm -rf tests/__pycache__/
	@rm -rf tests/**/__pycache__/
	@rm -rf .pytest_cache/
	@rm -rf htmlcov/
	@rm -rf .coverage
	@rm -rf coverage.xml
	@rm -rf dist/
	@rm -rf build/
	@rm -rf *.egg-info/

clean-venv: ## Clean virtual environment
	@echo "$(GREEN)Cleaning virtual environment...$(NC)"
	@poetry env remove --all

## Security
security: ## Run security checks
	@echo "$(GREEN)Running security checks...$(NC)"
	@poetry run bandit -r core/

## CI Pipeline
ci-pipeline: ## Run the core package CI pipeline locally
	@echo "$(GREEN)🚀 Running Core Package CI Pipeline locally...$(NC)"
	@echo "$(BLUE)Step 1/4: Installing dependencies...$(NC)"
	@$(MAKE) deps
	@echo "$(BLUE)Step 2/4: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/4: Running tests...$(NC)"
	@$(MAKE) test
	@echo "$(BLUE)Step 4/4: Running security checks...$(NC)"
	@$(MAKE) security
	@echo "$(GREEN)✅ Core Package CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"

ci-pipeline-quick: ## Run quick core package CI pipeline
	@echo "$(GREEN)🚀 Running Quick Core Package CI Pipeline...$(NC)"
	@echo "$(BLUE)Step 1/3: Installing dependencies...$(NC)"
	@$(MAKE) deps
	@echo "$(BLUE)Step 2/3: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/3: Running tests...$(NC)"
	@$(MAKE) test
	@echo "$(GREEN)✅ Quick Core Package CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"
