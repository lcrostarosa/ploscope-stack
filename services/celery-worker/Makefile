# Celery Worker Makefile
# Celery worker-specific commands for development and deployment

.PHONY: help deps deps-windows dev test build clean lint format scale monitor pre-commit pre-commit-install pre-commit-run pre-commit-run-all pre-commit-fix

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
	@echo "$(BLUE)Celery Worker Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make deps    - Install Python dependencies"
	@echo "  make dev     - Run the celery worker in development mode"
	@echo "  make test    - Run unit tests (no external dependencies)"
	@echo "  make test-integration - Run integration tests (requires Redis, DB, RabbitMQ)"
	@echo "  make scale   - Scale celery workers"
	@echo "  make pre-commit - Install and run pre-commit checks"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Dependencies
deps: ## Install Python dependencies with Poetry
	@echo "$(GREEN)Installing Python dependencies with Poetry...$(NC)"
	@poetry install
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)Dependencies and pre-commit hooks installed!$(NC)"

deps-dev: ## Install Python dependencies including dev dependencies
	@echo "$(GREEN)Installing Python dependencies with dev dependencies...$(NC)"
	@poetry install --with dev
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)Dependencies and pre-commit hooks installed!$(NC)"

deps-windows: ## Install Python dependencies on Windows with Poetry
	@echo "$(GREEN)Installing Python dependencies for Windows with Poetry...$(NC)"
	@poetry install
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)Dependencies and pre-commit hooks installed!$(NC)"

## Development
dev: ## Run the celery worker in development mode
	@echo "$(GREEN)Starting Celery Worker in development mode...$(NC)"
	@set -a && source env.development && set +a && PYTHONPATH=src poetry run python -m celery_worker.main

## Testing
test: test-unit ## Run all celery worker tests (unit tests only)
	@echo "$(GREEN)✅ All celery worker tests completed$(NC)"

test-unit: ## Run celery worker unit tests only (no external dependencies)
	@echo "$(GREEN)Running celery worker unit tests...$(NC)"
	@set -a && source env.test && set +a && poetry run pytest tests/ -m "unit" -v

test-integration: ## Run celery worker integration tests (requires Redis, database, RabbitMQ)
	@echo "$(GREEN)Running celery worker integration tests...$(NC)"
	@echo "$(YELLOW)Note: This requires Redis, database, and RabbitMQ to be running$(NC)"
	@poetry run pytest tests/integration/ -m "integration" -v

test-all: test-unit test-integration ## Run both unit and integration tests
	@echo "$(GREEN)✅ All tests (unit + integration) completed$(NC)"

test-coverage: ## Run celery worker unit tests with coverage
	@echo "$(GREEN)Running celery worker unit tests with coverage...$(NC)"
	@set -a && source env.test && set +a && poetry run pytest --cov=src --cov-report=html --cov-report=term-missing tests/ -m "unit"

## Build
build: ## Build the celery worker with Poetry
	@echo "$(GREEN)Building celery worker with Poetry...$(NC)"
	@poetry build

build-docker: ## Build Docker image for celery worker
	@echo "$(GREEN)Building Docker image for celery worker...$(NC)"
	@docker build -t celery-worker .

build-docker-no-cache: ## Build Docker image without cache
	@echo "$(GREEN)Building Docker image (no cache)...$(NC)"
	@docker build --no-cache -t celery-worker .

build-binary: ## Build Cython binary extensions
	@echo "$(GREEN)Building Cython binary extensions...$(NC)"
	@poetry run python build_poetry.py

## Linting and Formatting
lint: ## Run celery worker linting
	@echo "$(GREEN)Running celery worker linting...$(NC)"
	@poetry run flake8 src/ tests/

lint-fix: ## Auto-fix celery worker lint errors
	@echo "$(GREEN)Auto-fixing celery worker lint errors...$(NC)"
	@poetry run black src/ tests/
	@echo "$(GREEN)✅ Lint auto-fix complete!$(NC)"

format: ## Format celery worker code
	@echo "$(GREEN)Formatting celery worker code...$(NC)"
	@poetry run black src/ tests/

## Pre-commit
pre-commit: ## Install and run pre-commit checks
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)Running pre-commit checks on all files...$(NC)"
	@poetry run pre-commit run --all-files
	@echo "$(GREEN)✅ Pre-commit checks completed successfully!$(NC)"

pre-commit-install: ## Install pre-commit hooks only
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)✅ Pre-commit hooks installed!$(NC)"

pre-commit-run: ## Run pre-commit checks on staged files
	@echo "$(GREEN)Running pre-commit checks on staged files...$(NC)"
	@poetry run pre-commit run
	@echo "$(GREEN)✅ Pre-commit checks completed!$(NC)"

pre-commit-run-all: ## Run pre-commit checks on all files
	@echo "$(GREEN)Running pre-commit checks on all files...$(NC)"
	@poetry run pre-commit run --all-files
	@echo "$(GREEN)✅ Pre-commit checks completed!$(NC)"

pre-commit-fix: ## Run pre-commit checks with automatic fixes
	@echo "$(GREEN)Running pre-commit checks with automatic fixes...$(NC)"
	@poetry run pre-commit run --all-files --hook-stage manual
	@echo "$(GREEN)✅ Pre-commit checks with fixes completed!$(NC)"

## Scaling and Monitoring
scale: ## Scale celery workers for better performance
	@echo "$(GREEN)Scaling celery workers...$(NC)"
	@if [ -z "$(WORKERS)" ]; then \
		echo "$(YELLOW)Usage: make scale WORKERS=4$(NC)"; \
		exit 1; \
	fi
	@docker-compose up -d --scale celeryworker=$(WORKERS)

monitor: ## Monitor celery worker performance and CPU usage
	@echo "$(GREEN)Monitoring celery worker performance...$(NC)"
	@if [ -z "$(DURATION)" ]; then \
		echo "$(YELLOW)Usage: make monitor DURATION=60$(NC)"; \
		exit 1; \
	fi
	@docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" --no-stream

## Utilities
clean: ## Clean celery worker build artifacts
	@echo "$(GREEN)Cleaning celery worker build artifacts...$(NC)"
	@rm -rf __pycache__/
	@rm -rf src/__pycache__/
	@rm -rf src/**/__pycache__/
	@rm -rf tests/__pycache__/
	@rm -rf tests/**/__pycache__/
	@rm -rf .pytest_cache/
	@rm -rf htmlcov/
	@rm -rf .coverage
	@rm -rf coverage.xml
	@rm -rf dist/
	@rm -rf build/
	@rm -rf *.egg-info/
	@rm -rf *.so
	@rm -rf *.c

clean-venv: ## Clean virtual environment
	@echo "$(GREEN)Cleaning virtual environment...$(NC)"
	@rm -rf venv/

## Docker utilities
docker-logs: ## Show Docker logs for celery worker
	@docker logs -f celery-worker

docker-stop: ## Stop celery worker Docker container
	@docker stop celery-worker || true
	@docker rm celery-worker || true

docker-restart: ## Restart celery worker Docker container
	@docker restart celery-worker

## Security
security: ## Run security checks
	@echo "$(GREEN)Running security checks...$(NC)"
	@poetry run bandit -r src/

## CI Pipeline
ci-pipeline: ## Run the celery worker CI pipeline locally
	@echo "$(GREEN)🚀 Running Celery Worker CI Pipeline locally...$(NC)"
	@echo "$(BLUE)Step 1/4: Installing dependencies...$(NC)"
	@$(MAKE) deps-dev
	@echo "$(BLUE)Step 2/4: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/4: Running tests...$(NC)"
	@$(MAKE) test
	@echo "$(BLUE)Step 4/4: Running security checks...$(NC)"
	@$(MAKE) security
	@echo "$(GREEN)✅ Celery Worker CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"

ci-pipeline-quick: ## Run quick celery worker CI pipeline
	@echo "$(GREEN)🚀 Running Quick Celery Worker CI Pipeline...$(NC)"
	@echo "$(BLUE)Step 1/3: Installing dependencies...$(NC)"
	@$(MAKE) deps-dev
	@echo "$(BLUE)Step 2/3: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/3: Running tests...$(NC)"
	@$(MAKE) test
	@echo "$(GREEN)✅ Quick Celery Worker CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"
