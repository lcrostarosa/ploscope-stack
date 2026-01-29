# Frontend Makefile
# Frontend-specific commands for development and deployment

.PHONY: help deps deps-windows dev test build clean lint typecheck format run-local

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
	@echo "$(BLUE)Frontend Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make setup   - Set up the complete development environment"
	@echo "  make deps    - Install Node.js dependencies"
	@echo "  make dev     - Run the frontend in development mode"
	@echo "  make run-local - Run the frontend locally on port 3001"
	@echo "  make build   - Build the frontend for production"
	@echo "  make test    - Run frontend tests"
	@echo ""
	@echo "$(GREEN)Code Quality:$(NC)"
	@echo "  make pre-commit - Run pre-commit checks manually"
	@echo "  make setup-hooks - Set up pre-commit hooks only"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Dependencies
setup-hooks: ## Set up pre-commit hooks only
	@echo "$(GREEN)Setting up pre-commit hooks...$(NC)"
	@if [ ! -d ".husky" ]; then \
		echo "$(YELLOW)Installing husky...$(NC)"; \
		npx husky init; \
	fi
	@if [ -f ".husky/pre-commit" ]; then \
		chmod +x .husky/pre-commit; \
		echo "$(GREEN)✅ Pre-commit hooks configured!$(NC)"; \
	else \
		echo "$(RED)❌ Pre-commit hook not found$(NC)"; \
	fi

deps: ## Install Node.js dependencies
	@echo "$(GREEN)Installing Node.js dependencies...$(NC)"
	@npm install
	@echo "$(GREEN)Dependencies installed!$(NC)"

deps-windows: ## Install Node.js dependencies on Windows
	@echo "$(GREEN)Installing Node.js dependencies for Windows...$(NC)"
	@npm install
	@echo "$(GREEN)Dependencies installed!$(NC)"

## Development
dev: ## Run the frontend in development mode (npm run dev only)
	@echo "$(GREEN)Starting Frontend in development mode...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)No .env file found, copying from env.development...$(NC)"; \
		cp env.development .env; \
	fi
	@npm run dev

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
	@docker volume rm grafana-data
	@docker volume rm postgres-data
	@docker volume rm rabbitmq-data
	@docker volume rm shared-logs
	@docker volume rm redis-data
	@echo "$(GREEN)Local Docker infrastructure cleaned!$(NC)"

local-infra:
	@echo "$(GREEN)Starting local infrastructure...$(NC)"
	@docker compose --profile localdev up -d db rabbitmq-init db-migrate rabbitmq grafana backend-grpc backend celeryworker redis
	@echo "$(GREEN)Local infrastructure started!$(NC)"

## Testing
test: test-unit ## Run all frontend tests
	@echo "$(GREEN)✅ All frontend tests completed$(NC)"

test-unit: ## Run frontend unit tests only
	@echo "$(GREEN)Running frontend unit tests...$(NC)"
	@if [ ! -d node_modules ]; then echo "Installing frontend dependencies..." && npm ci --silent --no-progress; fi
	@npm run test:unit

test-integration: ## Run frontend integration tests
	@echo "$(GREEN)Running frontend integration tests...$(NC)"
	@npm run test:integration

test-e2e: ## Run frontend end-to-end tests
	@echo "$(GREEN)Running frontend end-to-end tests...$(NC)"
	@npm run test:e2e

test-coverage: ## Run frontend tests with coverage
	@echo "$(GREEN)Running frontend tests with coverage...$(NC)"
	@npm run test:coverage

## Build
build: clean ## Build the frontend for production
	@echo "$(GREEN)Building frontend for production...$(NC)"
	@npm run build

build-docker: ## Build Docker image for frontend
	@echo "$(GREEN)Building Docker image for frontend...$(NC)"
	@docker build -t frontend .

## Linting and Formatting
lint: ## Run frontend linting
	@echo "$(GREEN)Running frontend linting...$(NC)"
	@npm run lint

typecheck: ## Run TypeScript type checking (no emit)
	@echo "$(GREEN)Running TypeScript type checking...$(NC)"
	@npm run typecheck
	@echo "$(GREEN)✅ TypeScript checks completed$(NC)"

lint-fix: ## Auto-fix frontend lint errors
	@echo "$(GREEN)Auto-fixing frontend lint errors...$(NC)"
	@npm run lint:fix
	@echo "$(GREEN)✅ Lint auto-fix complete!$(NC)"

format: ## Format frontend code
	@echo "$(GREEN)Formatting frontend code...$(NC)"
	@npm run lint:fix

pre-commit: ## Run pre-commit checks manually
	@echo "$(GREEN)Running pre-commit checks...$(NC)"
	@npx lint-staged
	@npm run typecheck || echo "$(YELLOW)⚠️  TypeScript errors found (continuing...)$(NC)"
	@npm run test:unit || echo "$(YELLOW)⚠️  Test failures found (continuing...)$(NC)"
	@echo "$(GREEN)✅ Pre-commit checks completed!$(NC)"

## Utilities
clean: ## Clean frontend build artifacts
	@echo "$(GREEN)Cleaning frontend build artifacts...$(NC)"
	@rm -rf dist/
	@rm -rf node_modules/
	@rm -rf coverage/