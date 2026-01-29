# Backend Makefile
# Backend-specific commands for development and deployment

.PHONY: help install-poetry deps deps-prod deps-windows dev test build clean lint format db-migrate db-reset poetry-install poetry-update poetry-lock gen

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
	@echo "$(BLUE)Backend Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make setup   - Complete development setup (deps + pre-commit hooks)"
	@echo "  make install-poetry - Install Poetry if not already installed"
	@echo "  make deps    - Install Python dependencies"
	@echo "  make dev     - Run the backend in development mode"
	@echo "  make test    - Run backend tests"
	@echo "  make db-migrate - Run database migrations"
	@echo "  make pre-commit-install - Install pre-commit hooks"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Dependencies
install-poetry: ## Install Poetry if not already installed
	@echo "$(GREEN)Checking if Poetry is installed...$(NC)"
	@if command -v poetry >/dev/null 2>&1; then \
		echo "$(GREEN)Poetry is already installed: $$(poetry --version)$(NC)"; \
	else \
		echo "$(YELLOW)Poetry not found. Installing Poetry...$(NC)"; \
		curl -sSL https://install.python-poetry.org | python3 - || \
		(echo "$(YELLOW)Official installer failed, trying pip...$(NC)" && pip install poetry); \
		echo "$(GREEN)Poetry installed successfully!$(NC)"; \
		echo "$(YELLOW)Note: You may need to restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc'$(NC)"; \
	fi

deps: install-poetry ## Install Python dependencies with Poetry
	@echo "$(GREEN)Installing Python dependencies with Poetry...$(NC)"
	@poetry install --with dev,build
	@echo "$(GREEN)Dependencies installed!$(NC)"

setup: deps pre-commit-install ## Complete development setup (deps + pre-commit hooks)
	@echo "$(GREEN)🎉 Development environment setup complete!$(NC)"
	@echo "$(YELLOW)You can now start developing with: make dev$(NC)"

deps-prod: ## Install production dependencies only
	@echo "$(GREEN)Installing production dependencies only...$(NC)"
	@poetry install --only main
	@echo "$(GREEN)Production dependencies installed!$(NC)"

deps-windows: ## Install Python dependencies on Windows with Poetry
	@echo "$(GREEN)Installing Python dependencies for Windows with Poetry...$(NC)"
	@poetry install --with dev,build
	@echo "$(GREEN)Dependencies installed!$(NC)"

## Development
dev: ## Run the unified backend (REST API + gRPC server)
	@echo "$(GREEN)Starting unified Backend (REST + gRPC) in development mode...$(NC)"
	@poetry run python src/backend/main.py

dev-docker: ## Run the backend in Docker development mode
	@echo "$(GREEN)Starting Backend in Docker development mode...$(NC)"
	@docker build -f Dockerfile.dev -t backend-dev .
	@docker run -p 5001:5001 -v $(PWD):/app backend-dev

## Testing
test: test-unit ## Run all backend tests
	@echo "$(GREEN)✅ All backend tests completed$(NC)"

test-unit: ## Run backend unit tests only
	@echo "$(GREEN)Running backend unit tests...$(NC)"
	@poetry run pytest tests/unit/ -v

test-integration: ## Run backend integration tests
	@echo "$(GREEN)Running backend integration tests...$(NC)"
	@poetry run pytest tests/integration/ -v

test-coverage: ## Run backend tests with coverage
	@echo "$(GREEN)Running backend tests with coverage...$(NC)"
	@poetry run pytest --cov=src --cov-report=html --cov-report=term-missing tests/

## Build
build: ## Build the backend with Poetry
	@echo "$(GREEN)Building backend with Poetry...$(NC)"
	@poetry build

build-docker: ## Build Docker image for backend
	@echo "$(GREEN)Building Docker image for backend...$(NC)"
	@docker build -t backend .

build-docker-no-cache: ## Build Docker image without cache
	@echo "$(GREEN)Building Docker image (no cache)...$(NC)"
	@docker build --no-cache -t backend .

## Linting and Formatting
lint: ## Run backend linting
	@echo "$(GREEN)Running backend linting...$(NC)"
	@poetry run flake8 src/backend/ tests/ --exclude=src/backend/protos/

lint-fix: ## Auto-fix backend lint errors
	@echo "$(GREEN)Auto-fixing backend lint errors...$(NC)"
	@poetry run black src/ tests/
	@echo "$(GREEN)✅ Lint auto-fix complete!$(NC)"

format: ## Format backend code
	@echo "$(GREEN)Formatting backend code...$(NC)"
	@poetry run black src/ tests/


## Poetry Management
poetry-install: ## Install Poetry dependencies
	@echo "$(GREEN)Installing Poetry dependencies...$(NC)"
	@poetry install --with dev,build

poetry-update: ## Update Poetry dependencies
	@echo "$(GREEN)Updating Poetry dependencies...$(NC)"
	@poetry update

poetry-lock: ## Lock Poetry dependencies
	@echo "$(GREEN)Locking Poetry dependencies...$(NC)"
	@poetry lock

poetry-add: ## Add a new dependency
	@echo "$(GREEN)Adding new dependency...$(NC)"
	@read -p "Enter package name: " package; \
	poetry add "$$package"

poetry-add-dev: ## Add a new development dependency
	@echo "$(GREEN)Adding new development dependency...$(NC)"
	@read -p "Enter package name: " package; \
	poetry add --group dev "$$package"

## Utilities
gen: ## Generate protobuf files from .proto definitions
	@echo "$(GREEN)Generating protobuf files from .proto definitions...$(NC)"
	@poetry run python scripts/generate_protos.py
	@echo "$(GREEN)✅ Protobuf generation completed!$(NC)"

clean: ## Clean backend build artifacts
	@echo "$(GREEN)Cleaning backend build artifacts...$(NC)"
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

clean-venv: ## Clean virtual environment
	@echo "$(GREEN)Cleaning virtual environment...$(NC)"
	@rm -rf venv/

## Docker utilities
local-docker-bootstrap:
	@echo "$(GREEN)Bootstrapping local Docker infrastructure...$(NC)"
	@docker network create plo-network-cloud
	@docker volume create grafana-data
	@docker volume create postgres-data
	@docker volume create rabbitmq-data
	@docker volume create shared-logs
	@docker volume create redis-data
	@echo "$(GREEN)Local Docker infrastructure bootstrapped!$(NC)"

local-docker-clean:
	@echo "$(GREEN)Cleaning local Docker infrastructure...$(NC)"
	@docker network rm plo-network-cloud
	@docker volume rm grafana-data
	@docker volume rm postgres-data
	@docker volume rm rabbitmq-data
	@docker volume rm shared-logs
	@docker volume rm redis-data
	@echo "$(GREEN)Local Docker infrastructure cleaned!$(NC)"

local-infra:
	@echo "$(GREEN)Starting local infrastructure...$(NC)"
	@env $$(grep -v '^#' env.development | xargs) docker compose --profile localdev up -d db rabbitmq-init db-migrate rabbitmq redis
	@echo "$(GREEN)Local infrastructure started!$(NC)"

docker-logs: ## Show Docker logs for backend
	@env $$(grep -v '^#' env.development | xargs) docker compose --profile localdev logs -f db rabbitmq-init db-migrate rabbitmq redis

docker-stop: ## Stop backend Docker container
	@env $$(grep -v '^#' env.development | xargs) docker compose --profile localdev down db rabbitmq-init db-migrate rabbitmq redis || true

docker-restart: ## Restart backend Docker container
	@env $$(grep -v '^#' env.development | xargs) docker compose --profile localdev restart -d db rabbitmq-init db-migrate rabbitmq redis || true

## Security
security: ## Run security checks
	@echo "$(GREEN)Running security checks...$(NC)"
	@poetry run bandit -r src/

## CI Pipeline
ci-pipeline: ## Run the backend CI pipeline locally
	@echo "$(GREEN)🚀 Running Backend CI Pipeline locally...$(NC)"
	@echo "$(BLUE)Step 1/4: Installing dependencies...$(NC)"
	@$(MAKE) deps
	@echo "$(BLUE)Step 2/4: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/4: Running tests...$(NC)"
	@$(MAKE) test
	@echo "$(BLUE)Step 4/4: Running security checks...$(NC)"
	@$(MAKE) security
	@echo "$(GREEN)✅ Backend CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"

ci-pipeline-quick: ## Run quick backend CI pipeline
	@echo "$(GREEN)🚀 Running Quick Backend CI Pipeline...$(NC)"
	@echo "$(BLUE)Step 1/3: Installing dependencies...$(NC)"
	@$(MAKE) deps
	@echo "$(BLUE)Step 2/3: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/3: Running tests...$(NC)"
	@$(MAKE) test
	@echo "$(GREEN)✅ Quick Backend CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"

pre-commit-install: ## Install pre-commit hooks
	@echo "$(GREEN)Installing pre-commit hooks...$(NC)"
	@poetry run pre-commit install
	@echo "$(GREEN)✅ Pre-commit hooks installed and enabled!$(NC)"
	@echo "$(YELLOW)Note: Pre-commit hooks will now run on every commit$(NC)"
	@echo "$(YELLOW)To skip: git commit --no-verify$(NC)"

pre-commit-uninstall: ## Uninstall pre-commit hooks
	@echo "$(YELLOW)Uninstalling pre-commit hooks...$(NC)"
	@poetry run pre-commit uninstall
	@echo "$(GREEN)✅ Pre-commit hooks uninstalled!$(NC)"

pre-commit-update: ## Update pre-commit hooks to latest versions
	@echo "$(GREEN)Updating pre-commit hooks...$(NC)"
	@poetry run pre-commit autoupdate
	@echo "$(GREEN)✅ Pre-commit hooks updated!$(NC)"

pre-commit-run: ## Run pre-commit hooks on all files
	@echo "$(GREEN)Running pre-commit hooks on all files...$(NC)"
	@poetry run pre-commit run --all-files
	@echo "$(GREEN)✅ Pre-commit checks completed!$(NC)"

pre-commit-run-changed: ## Run pre-commit hooks on changed files only
	@echo "$(GREEN)Running pre-commit hooks on changed files...$(NC)"
	@poetry run pre-commit run
	@echo "$(GREEN)✅ Pre-commit checks completed!$(NC)"

## Protobuf Package Building
build-protos: ## Build both Python and Node.js protobuf packages
	@echo "$(GREEN)Building protobuf packages for Python and Node.js...$(NC)"
	python scripts/build_protos.py

build-protos-python: ## Build only Python protobuf package
	@echo "$(GREEN)Building Python protobuf package...$(NC)"
	python scripts/build_protos.py --python-only

build-protos-nodejs: ## Build only Node.js protobuf package
	@echo "$(GREEN)Building Node.js protobuf package...$(NC)"
	python scripts/build_protos.py --nodejs-only

publish-protos: ## Publish both Python and Node.js protobuf packages
	@echo "$(GREEN)Publishing protobuf packages...$(NC)"
	python scripts/build_protos.py --publish

publish-protos-python: ## Publish only Python protobuf package
	@echo "$(GREEN)Publishing Python protobuf package...$(NC)"
	python scripts/build_protos.py --python-only --publish

publish-protos-nodejs: ## Publish only Node.js protobuf package
	@echo "$(GREEN)Publishing Node.js protobuf package...$(NC)"
	python scripts/build_protos.py --nodejs-only --publish
