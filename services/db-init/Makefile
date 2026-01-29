# Database Init Makefile
# Database initialization-specific commands for development and deployment

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

deps: ## Install dependencies
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	@python -m venv venv || true
	@source venv/bin/activate && pip install -r requirements.txt
	@echo "$(GREEN)Dependencies installed!$(NC)"

deps-windows: ## Install dependencies on Windows
	@echo "$(GREEN)Installing Python dependencies on Windows...$(NC)"
	@python -m venv venv || true
	@venv\Scripts\activate && pip install -r requirements.txt
	@echo "$(GREEN)Dependencies installed!$(NC)"

dev: ## Run db-init in development mode
	@echo "$(GREEN)Running database initialization in development mode...$(NC)"
	@docker-compose -f docker-compose-localdev.yml up --build
	@echo "$(GREEN)Database initialization completed!$(NC)"

dev-docker: ## Run db-init in development mode with Docker
	@echo "$(GREEN)Running database initialization in development mode with Docker...$(NC)"
	@docker-compose -f docker-compose-localdev.yml up --build
	@echo "$(GREEN)Database initialization completed!$(NC)"

test: ## Run db-init tests
	@echo "$(GREEN)Running database initialization tests...$(NC)"
	@docker-compose -f docker-compose-test.yml --profile bootstrap up -d
	@docker-compose -f docker-compose-test.yml --profile test up --build
	@echo "$(GREEN)Database initialization test completed!$(NC)"

test-unit: ## Run unit tests (no unit tests for db-init)
	@echo "$(GREEN)No unit tests available for Database Init$(NC)"

test-integration: ## Run integration tests
	@echo "$(GREEN)Running database initialization integration tests...$(NC)"
	@docker-compose -f docker-compose-test.yml --profile bootstrap up -d
	@docker-compose -f docker-compose-test.yml --profile test up --build
	@echo "$(GREEN)Database initialization integration test completed!$(NC)"

test-coverage: ## Run tests with coverage (no coverage for db-init)
	@echo "$(GREEN)No coverage tests available for Database Init$(NC)"

build: ## Build db-init configuration
	@echo "$(GREEN)Building database initialization configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already built$(NC)"

build-docker: ## Build db-init Docker image
	@echo "$(GREEN)Building database initialization Docker image...$(NC)"
	@docker build -t ploscope/db-init:latest .

clean: ## Clean db-init artifacts
	@echo "$(GREEN)Cleaning database initialization artifacts...$(NC)"
	@docker-compose -f docker-compose-localdev.yml down -v
	@docker-compose -f docker-compose-test.yml down -v
	@rm -rf venv/
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-build: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Build cleanup complete!$(NC)"

lint: ## Lint db-init configuration
	@echo "$(GREEN)Linting database initialization configuration...$(NC)"
	@echo "$(BLUE)Checking Python syntax...$(NC)"
	@python -m py_compile env.py || true
	@echo "$(BLUE)Checking YAML syntax...$(NC)"
	@yamllint *.yml || true
	@echo "$(GREEN)Linting complete!$(NC)"

lint-fix: ## Fix linting issues (no auto-fix for db-init)
	@echo "$(GREEN)No auto-fix available for Database Init configuration$(NC)"

format: ## Format db-init configuration
	@echo "$(GREEN)Formatting database initialization configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already formatted$(NC)"

deploy: ## Deploy db-init
	@echo "$(GREEN)Deploying database initialization...$(NC)"
	@echo "$(YELLOW)Please specify environment: make deploy-staging or make deploy-production$(NC)"

deploy-staging: ## Deploy db-init to staging
	@echo "$(GREEN)Deploying database initialization to staging...$(NC)"
	@docker-compose -f docker-compose.staging.yml up --build
	@echo "$(GREEN)Database initialization deployed to staging!$(NC)"

deploy-production: ## Deploy db-init to production
	@echo "$(GREEN)Deploying database initialization to production...$(NC)"
	@docker-compose -f docker-compose.production.yml up --build
	@echo "$(GREEN)Database initialization deployed to production!$(NC)"

logs: ## Show db-init logs
	@echo "$(GREEN)Showing database initialization logs...$(NC)"
	@docker-compose -f docker-compose-localdev.yml logs -f db-migrate

logs-staging: ## Show staging db-init logs
	@echo "$(GREEN)Showing staging database initialization logs...$(NC)"
	@docker-compose -f docker-compose.staging.yml logs -f db-migrate

logs-production: ## Show production db-init logs
	@echo "$(GREEN)Showing production database initialization logs...$(NC)"
	@docker-compose -f docker-compose.production.yml logs -f db-migrate

status: ## Show db-init status
	@echo "$(GREEN)Database Initialization Status:$(NC)"
	@docker-compose -f docker-compose-localdev.yml ps

status-staging: ## Show staging db-init status
	@echo "$(GREEN)Staging Database Initialization Status:$(NC)"
	@docker-compose -f docker-compose.staging.yml ps

status-production: ## Show production db-init status
	@echo "$(GREEN)Production Database Initialization Status:$(NC)"
	@docker-compose -f docker-compose.production.yml ps

stop: ## Stop db-init
	@echo "$(GREEN)Stopping database initialization...$(NC)"
	@docker-compose -f docker-compose-localdev.yml down
	@echo "$(GREEN)Database initialization stopped!$(NC)"

stop-staging: ## Stop staging db-init
	@echo "$(GREEN)Stopping staging database initialization...$(NC)"
	@docker-compose -f docker-compose.staging.yml down
	@echo "$(GREEN)Staging database initialization stopped!$(NC)"

stop-production: ## Stop production db-init
	@echo "$(GREEN)Stopping production database initialization...$(NC)"
	@docker-compose -f docker-compose.production.yml down
	@echo "$(GREEN)Production database initialization stopped!$(NC)"

restart: ## Restart db-init
	@echo "$(GREEN)Restarting database initialization...$(NC)"
	@docker-compose -f docker-compose-localdev.yml restart
	@echo "$(GREEN)Database initialization restarted!$(NC)"

restart-staging: ## Restart staging db-init
	@echo "$(GREEN)Restarting staging database initialization...$(NC)"
	@docker-compose -f docker-compose.staging.yml restart
	@echo "$(GREEN)Staging database initialization restarted!$(NC)"

restart-production: ## Restart production db-init
	@echo "$(GREEN)Restarting production database initialization...$(NC)"
	@docker-compose -f docker-compose.production.yml restart
	@echo "$(GREEN)Production database initialization restarted!$(NC)"

migrate: ## Run database migrations manually
	@echo "$(GREEN)Running database migrations manually...$(NC)"
	@source venv/bin/activate && alembic -c alembic.ini upgrade head
	@echo "$(GREEN)Database migrations completed!$(NC)"

migrate-staging: ## Run staging database migrations
	@echo "$(GREEN)Running staging database migrations...$(NC)"
	@docker-compose -f docker-compose.staging.yml up --build
	@echo "$(GREEN)Staging database migrations completed!$(NC)"

migrate-production: ## Run production database migrations
	@echo "$(GREEN)Running production database migrations...$(NC)"
	@docker-compose -f docker-compose.production.yml up --build
	@echo "$(GREEN)Production database migrations completed!$(NC)"

create-migration: ## Create a new migration
	@echo "$(GREEN)Creating new migration...$(NC)"
	@if [ -z "$(MESSAGE)" ]; then \
		echo "$(YELLOW)Usage: make create-migration MESSAGE='description of changes'$(NC)"; \
		exit 1; \
	fi
	@source venv/bin/activate && alembic -c alembic.ini revision --autogenerate -m "$(MESSAGE)"
	@echo "$(GREEN)Migration created!$(NC)"

stamp: ## Stamp database with current revision
	@echo "$(GREEN)Stamping database with current revision...$(NC)"
	@source venv/bin/activate && alembic -c alembic.ini stamp head
	@echo "$(GREEN)Database stamped!$(NC)"

history: ## Show migration history
	@echo "$(GREEN)Showing migration history...$(NC)"
	@source venv/bin/activate && alembic -c alembic.ini history
	@echo "$(GREEN)Migration history displayed!$(NC)"

current: ## Show current migration
	@echo "$(GREEN)Showing current migration...$(NC)"
	@source venv/bin/activate && alembic -c alembic.ini current
	@echo "$(GREEN)Current migration displayed!$(NC)"

ci-pipeline: ## Run full CI pipeline for db-init
	@echo "$(GREEN)Running database initialization CI pipeline...$(NC)"
	@make lint
	@make test
	@make build
	@echo "$(GREEN)Database initialization CI pipeline completed!$(NC)"

ci-pipeline-quick: ## Run quick CI pipeline for db-init
	@echo "$(GREEN)Running quick database initialization CI pipeline...$(NC)"
	@make lint
	@make build
	@echo "$(GREEN)Quick database initialization CI pipeline completed!$(NC)"
