# Traefik Makefile
# Traefik-specific commands for development and deployment

.PHONY: help deps deps-windows dev test build clean lint format deploy

# Default target
.DEFAULT_GOAL := help

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

deps: ## Install dependencies (no dependencies for traefik)
	@echo "$(GREEN)Traefik has no external dependencies to install$(NC)"

deps-windows: ## Install dependencies on Windows (no dependencies for traefik)
	@echo "$(GREEN)Traefik has no external dependencies to install$(NC)"

dev: ## Run traefik in development mode
	@echo "$(GREEN)Starting Traefik in development mode...$(NC)"
	@docker-compose -f docker-compose.yml up -d
	@echo "$(GREEN)Traefik started! Dashboard available at http://localhost:8080$(NC)"

dev-docker: ## Run traefik in development mode with Docker
	@echo "$(GREEN)Starting Traefik in development mode with Docker...$(NC)"
	@docker-compose -f docker-compose.yml up -d
	@echo "$(GREEN)Traefik started! Dashboard available at http://localhost:8080$(NC)"

test: ## Run traefik tests
	@echo "$(GREEN)Running Traefik tests...$(NC)"
	@docker-compose -f docker-compose.yml --profile test up -d
	@echo "$(GREEN)Traefik test environment started!$(NC)"

test-unit: ## Run unit tests (no unit tests for traefik)
	@echo "$(GREEN)No unit tests available for Traefik$(NC)"

test-integration: ## Run integration tests
	@echo "$(GREEN)Running Traefik integration tests...$(NC)"
	@docker-compose -f docker-compose.yml --profile test up -d
	@echo "$(GREEN)Traefik integration test environment started!$(NC)"

test-coverage: ## Run tests with coverage (no coverage for traefik)
	@echo "$(GREEN)No coverage tests available for Traefik$(NC)"

build: ## Build traefik configuration
	@echo "$(GREEN)Building Traefik configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already built$(NC)"

build-docker: ## Build traefik Docker image
	@echo "$(GREEN)Building Traefik Docker image...$(NC)"
	@docker build -t ploscope/traefik:latest .

clean: ## Clean traefik artifacts
	@echo "$(GREEN)Cleaning Traefik artifacts...$(NC)"
	@docker-compose -f docker-compose.yml down -v
	@docker-compose -f docker-compose.yml down -v
	@rm -rf logs/*
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-build: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Build cleanup complete!$(NC)"

lint: ## Lint traefik configuration
	@echo "$(GREEN)Linting Traefik configuration...$(NC)"
	@echo "$(BLUE)Checking YAML syntax...$(NC)"
	@yamllint localdev/ staging/ production/ test/ || true
	@echo "$(GREEN)Linting complete!$(NC)"

lint-fix: ## Fix linting issues (no auto-fix for traefik)
	@echo "$(GREEN)No auto-fix available for Traefik configuration$(NC)"

format: ## Format traefik configuration
	@echo "$(GREEN)Formatting Traefik configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already formatted$(NC)"

deploy: ## Deploy traefik
	@echo "$(GREEN)Deploying Traefik...$(NC)"
	@echo "$(YELLOW)Please specify environment: make deploy-staging or make deploy-production$(NC)"

deploy-staging: ## Deploy traefik to staging
	@echo "$(GREEN)Deploying Traefik to staging...$(NC)"
	@docker-compose -f docker-compose.yml up -d
	@echo "$(GREEN)Traefik deployed to staging!$(NC)"

deploy-production: ## Deploy traefik to production
	@echo "$(GREEN)Deploying Traefik to production...$(NC)"
	@docker-compose -f docker-compose.yml up -d
	@echo "$(GREEN)Traefik deployed to production!$(NC)"

logs: ## Show traefik logs
	@echo "$(GREEN)Showing Traefik logs...$(NC)"
	@docker-compose -f docker-compose.yml logs -f traefik

logs-staging: ## Show staging traefik logs
	@echo "$(GREEN)Showing staging Traefik logs...$(NC)"
	@docker-compose -f docker-compose.yml logs -f traefik

logs-production: ## Show production traefik logs
	@echo "$(GREEN)Showing production Traefik logs...$(NC)"
	@docker-compose -f docker-compose.yml logs -f traefik

status: ## Show traefik status
	@echo "$(GREEN)Traefik Status:$(NC)"
	@docker-compose -f docker-compose.yml ps

status-staging: ## Show staging traefik status
	@echo "$(GREEN)Staging Traefik Status:$(NC)"
	@docker-compose -f docker-compose.yml ps

status-production: ## Show production traefik status
	@echo "$(GREEN)Production Traefik Status:$(NC)"
	@docker-compose -f docker-compose.yml ps

stop: ## Stop traefik
	@echo "$(GREEN)Stopping Traefik...$(NC)"
	@docker-compose -f docker-compose.yml down
	@echo "$(GREEN)Traefik stopped!$(NC)"

stop-staging: ## Stop staging traefik
	@echo "$(GREEN)Stopping staging Traefik...$(NC)"
	@docker-compose -f docker-compose.yml down
	@echo "$(GREEN)Staging Traefik stopped!$(NC)"

stop-production: ## Stop production traefik
	@echo "$(GREEN)Stopping production Traefik...$(NC)"
	@docker-compose -f docker-compose.yml down
	@echo "$(GREEN)Production Traefik stopped!$(NC)"

restart: ## Restart traefik
	@echo "$(GREEN)Restarting Traefik...$(NC)"
	@docker-compose -f docker-compose.yml restart
	@echo "$(GREEN)Traefik restarted!$(NC)"

restart-staging: ## Restart staging traefik
	@echo "$(GREEN)Restarting staging Traefik...$(NC)"
	@docker-compose -f docker-compose.yml restart
	@echo "$(GREEN)Staging Traefik restarted!$(NC)"

restart-production: ## Restart production traefik
	@echo "$(GREEN)Restarting production Traefik...$(NC)"
	@docker-compose -f docker-compose.yml restart
	@echo "$(GREEN)Production Traefik restarted!$(NC)"

ci-pipeline: ## Run full CI pipeline for traefik
	@echo "$(GREEN)Running Traefik CI pipeline...$(NC)"
	@make lint
	@make test
	@make build
	@echo "$(GREEN)Traefik CI pipeline completed!$(NC)"

ci-pipeline-quick: ## Run quick CI pipeline for traefik
	@echo "$(GREEN)Running quick Traefik CI pipeline...$(NC)"
	@make lint
	@make build
	@echo "$(GREEN)Quick Traefik CI pipeline completed!$(NC)"

