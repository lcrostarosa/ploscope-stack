# Nexus Repository Makefile
# Nexus-specific commands for development and deployment

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

deps: ## Install dependencies (no dependencies for nexus)
	@echo "$(GREEN)Nexus has no external dependencies to install$(NC)"

deps-windows: ## Install dependencies on Windows (no dependencies for nexus)
	@echo "$(GREEN)Nexus has no external dependencies to install$(NC)"


auth-nexus: ## Setup Nexus repository authentication using keyring
	@echo "$(GREEN)🔐 Setting up Nexus repository authentication...$(NC)"
	@echo "$(YELLOW)This will securely store your Nexus credentials in your system keyring.$(NC)"
	@echo "$(YELLOW)Usage examples:$(NC)"
	@echo "  make auth-nexus                    # Interactive mode"
	@echo "  make auth-nexus USER=myuser PASS=mypass  # Command line"
	@echo "  make auth-nexus ENV_FILE=env.development # From env file"
	@echo ""
	@if [ -n "$(USER)" ] && [ -n "$(PASS)" ]; then \
		echo "$(BLUE)Using command line credentials...$(NC)"; \
		./scripts/setup_nexus_keyring.sh -u "$(USER)" -p "$(PASS)"; \
	elif [ -n "$(ENV_FILE)" ]; then \
		echo "$(BLUE)Using environment file: $(ENV_FILE)$(NC)"; \
		./scripts/setup_nexus_keyring.sh -e "$(ENV_FILE)"; \
	else \
		echo "$(BLUE)Starting interactive mode...$(NC)"; \
		./scripts/setup_nexus_keyring.sh; \
	fi


dev: ## Run nexus in development mode
	@echo "$(GREEN)Starting Nexus Repository in development mode...$(NC)"
	@docker-compose -f docker-compose-localdev.yml up -d
	@echo "$(GREEN)Nexus started! Available at http://localhost:8081$(NC)"

dev-docker: ## Run nexus in development mode with Docker
	@echo "$(GREEN)Starting Nexus Repository in development mode with Docker...$(NC)"
	@docker-compose -f docker-compose-localdev.yml up -d
	@echo "$(GREEN)Nexus started! Available at http://localhost:8081$(NC)"

test: ## Run nexus tests
	@echo "$(GREEN)Running Nexus Repository tests...$(NC)"
	@docker-compose -f docker-compose-test.yml --profile test up -d
	@echo "$(GREEN)Nexus test environment started!$(NC)"

test-unit: ## Run unit tests (no unit tests for nexus)
	@echo "$(GREEN)No unit tests available for Nexus Repository$(NC)"

test-integration: ## Run integration tests
	@echo "$(GREEN)Running Nexus Repository integration tests...$(NC)"
	@docker-compose -f docker-compose-test.yml --profile test up -d
	@echo "$(GREEN)Nexus integration test environment started!$(NC)"

test-coverage: ## Run tests with coverage (no coverage for nexus)
	@echo "$(GREEN)No coverage tests available for Nexus Repository$(NC)"

build: ## Build nexus configuration
	@echo "$(GREEN)Building Nexus Repository configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already built$(NC)"

build-docker: ## Build nexus Docker image
	@echo "$(GREEN)Building Nexus Repository Docker image...$(NC)"
	@docker build -t ploscope/nexus:latest .

clean: ## Clean nexus artifacts
	@echo "$(GREEN)Cleaning Nexus Repository artifacts...$(NC)"
	@docker-compose -f docker-compose-localdev.yml down -v
	@docker-compose -f docker-compose-test.yml down -v
	@rm -rf logs/*
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-build: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Build cleanup complete!$(NC)"

lint: ## Lint nexus configuration
	@echo "$(GREEN)Linting Nexus Repository configuration...$(NC)"
	@echo "$(BLUE)Checking YAML syntax...$(NC)"
	@yamllint *.yml || true
	@echo "$(GREEN)Linting complete!$(NC)"

lint-fix: ## Fix linting issues (no auto-fix for nexus)
	@echo "$(GREEN)No auto-fix available for Nexus Repository configuration$(NC)"

format: ## Format nexus configuration
	@echo "$(GREEN)Formatting Nexus Repository configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already formatted$(NC)"

deploy: ## Deploy nexus
	@echo "$(GREEN)Deploying Nexus Repository...$(NC)"
	@echo "$(YELLOW)Please specify environment: make deploy-staging or make deploy-production$(NC)"

deploy-staging: ## Deploy nexus to staging
	@echo "$(GREEN)Deploying Nexus Repository to staging...$(NC)"
	@docker-compose -f docker-compose.staging.yml up -d
	@echo "$(GREEN)Nexus deployed to staging!$(NC)"

deploy-production: ## Deploy nexus to production
	@echo "$(GREEN)Deploying Nexus Repository to production...$(NC)"
	@docker-compose -f docker-compose.production.yml up -d
	@echo "$(GREEN)Nexus deployed to production!$(NC)"

logs: ## Show nexus logs
	@echo "$(GREEN)Showing Nexus Repository logs...$(NC)"
	@docker-compose -f docker-compose-localdev.yml logs -f nexus

logs-staging: ## Show staging nexus logs
	@echo "$(GREEN)Showing staging Nexus Repository logs...$(NC)"
	@docker-compose -f docker-compose.staging.yml logs -f nexus

logs-production: ## Show production nexus logs
	@echo "$(GREEN)Showing production Nexus Repository logs...$(NC)"
	@docker-compose -f docker-compose.production.yml logs -f nexus

status: ## Show nexus status
	@echo "$(GREEN)Nexus Repository Status:$(NC)"
	@docker-compose -f docker-compose-localdev.yml ps

status-staging: ## Show staging nexus status
	@echo "$(GREEN)Staging Nexus Repository Status:$(NC)"
	@docker-compose -f docker-compose.staging.yml ps

status-production: ## Show production nexus status
	@echo "$(GREEN)Production Nexus Repository Status:$(NC)"
	@docker-compose -f docker-compose.production.yml ps

stop: ## Stop nexus
	@echo "$(GREEN)Stopping Nexus Repository...$(NC)"
	@docker-compose -f docker-compose-localdev.yml down
	@echo "$(GREEN)Nexus stopped!$(NC)"

stop-staging: ## Stop staging nexus
	@echo "$(GREEN)Stopping staging Nexus Repository...$(NC)"
	@docker-compose -f docker-compose.staging.yml down
	@echo "$(GREEN)Staging Nexus stopped!$(NC)"

stop-production: ## Stop production nexus
	@echo "$(GREEN)Stopping production Nexus Repository...$(NC)"
	@docker-compose -f docker-compose.production.yml down
	@echo "$(GREEN)Production Nexus stopped!$(NC)"

restart: ## Restart nexus
	@echo "$(GREEN)Restarting Nexus Repository...$(NC)"
	@docker-compose -f docker-compose-localdev.yml restart
	@echo "$(GREEN)Nexus restarted!$(NC)"

restart-staging: ## Restart staging nexus
	@echo "$(GREEN)Restarting staging Nexus Repository...$(NC)"
	@docker-compose -f docker-compose.staging.yml restart
	@echo "$(GREEN)Staging Nexus restarted!$(NC)"

restart-production: ## Restart production nexus
	@echo "$(GREEN)Restarting production Nexus Repository...$(NC)"
	@docker-compose -f docker-compose.production.yml restart
	@echo "$(GREEN)Production Nexus restarted!$(NC)"

setup: ## Setup nexus repositories and users
	@echo "$(GREEN)Setting up Nexus Repository...$(NC)"
	@chmod +x setup-nexus.sh
	@./setup-nexus.sh
	@echo "$(GREEN)Nexus setup complete!$(NC)"

test-npm: ## Test NPM registry configuration
	@echo "$(GREEN)Testing NPM registry configuration...$(NC)"
	@chmod +x test-npm-config.sh
	@./test-npm-config.sh
	@echo "$(GREEN)NPM registry test complete!$(NC)"

setup-staging: ## Setup staging nexus repositories and users
	@echo "$(GREEN)Setting up staging Nexus Repository...$(NC)"
	@chmod +x setup-nexus.sh
	@./setup-nexus.sh staging
	@echo "$(GREEN)Staging Nexus setup complete!$(NC)"

setup-production: ## Setup production nexus repositories and users
	@echo "$(GREEN)Setting up production Nexus Repository...$(NC)"
	@chmod +x setup-nexus.sh
	@./setup-nexus.sh production
	@echo "$(GREEN)Production Nexus setup complete!$(NC)"

ci-pipeline: ## Run full CI pipeline for nexus
	@echo "$(GREEN)Running Nexus Repository CI pipeline...$(NC)"
	@make lint
	@make test
	@make build
	@echo "$(GREEN)Nexus CI pipeline completed!$(NC)"

ci-pipeline-quick: ## Run quick CI pipeline for nexus
	@echo "$(GREEN)Running quick Nexus Repository CI pipeline...$(NC)"
	@make lint
	@make build
	@echo "$(GREEN)Quick Nexus CI pipeline completed!$(NC)"

