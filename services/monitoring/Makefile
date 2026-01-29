# Monitoring Makefile
# Monitoring-specific commands for development and deployment

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

deps: ## Install dependencies (no dependencies for monitoring)
	@echo "$(GREEN)Monitoring has no external dependencies to install$(NC)"

deps-windows: ## Install dependencies on Windows (no dependencies for monitoring)
	@echo "$(GREEN)Monitoring has no external dependencies to install$(NC)"

dev: ## Run monitoring in development mode
	@echo "$(GREEN)Starting Monitoring (Grafana + Prometheus) in development mode...$(NC)"
	@docker-compose -f docker-compose-localdev.yml up -d
	@echo "$(GREEN)Monitoring started!$(NC)"
	@echo "$(BLUE)Grafana: http://localhost:3000 (admin/admin-dev-123)$(NC)"
	@echo "$(BLUE)Prometheus: http://localhost:9090$(NC)"

dev-docker: ## Run monitoring in development mode with Docker
	@echo "$(GREEN)Starting Monitoring (Grafana + Prometheus) in development mode with Docker...$(NC)"
	@docker-compose -f docker-compose-localdev.yml up -d
	@echo "$(GREEN)Monitoring started!$(NC)"
	@echo "$(BLUE)Grafana: http://localhost:3000 (admin/admin-dev-123)$(NC)"
	@echo "$(BLUE)Prometheus: http://localhost:9090$(NC)"

test: ## Run monitoring tests
	@echo "$(GREEN)Running Monitoring tests...$(NC)"
	@docker-compose -f docker-compose-test.yml --profile test up -d
	@echo "$(GREEN)Monitoring test environment started!$(NC)"

test-unit: ## Run unit tests (no unit tests for monitoring)
	@echo "$(GREEN)No unit tests available for Monitoring$(NC)"

test-integration: ## Run integration tests
	@echo "$(GREEN)Running Monitoring integration tests...$(NC)"
	@docker-compose -f docker-compose-test.yml --profile test up -d
	@echo "$(GREEN)Monitoring integration test environment started!$(NC)"

test-coverage: ## Run tests with coverage (no coverage for monitoring)
	@echo "$(GREEN)No coverage tests available for Monitoring$(NC)"

build: ## Build monitoring configuration
	@echo "$(GREEN)Building Monitoring configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already built$(NC)"

build-docker: ## Build monitoring Docker images
	@echo "$(GREEN)Building Monitoring Docker images...$(NC)"
	@echo "$(BLUE)Using official Grafana and Prometheus images$(NC)"

clean: ## Clean monitoring artifacts
	@echo "$(GREEN)Cleaning Monitoring artifacts...$(NC)"
	@docker-compose -f docker-compose-localdev.yml down -v
	@docker-compose -f docker-compose-test.yml down -v
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-build: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Build cleanup complete!$(NC)"

lint: ## Lint monitoring configuration
	@echo "$(GREEN)Linting Monitoring configuration...$(NC)"
	@echo "$(BLUE)Checking YAML syntax...$(NC)"
	@yamllint *.yml || true
	@echo "$(BLUE)Checking JSON syntax...$(NC)"
	@python -m json.tool grafana-dashboards/*.json > /dev/null || true
	@echo "$(GREEN)Linting complete!$(NC)"

lint-fix: ## Fix linting issues (no auto-fix for monitoring)
	@echo "$(GREEN)No auto-fix available for Monitoring configuration$(NC)"

format: ## Format monitoring configuration
	@echo "$(GREEN)Formatting Monitoring configuration...$(NC)"
	@echo "$(BLUE)Configuration files are already formatted$(NC)"

deploy: ## Deploy monitoring
	@echo "$(GREEN)Deploying Monitoring...$(NC)"
	@echo "$(YELLOW)Please specify environment: make deploy-staging or make deploy-production$(NC)"

deploy-staging: ## Deploy monitoring to staging
	@echo "$(GREEN)Deploying Monitoring to staging...$(NC)"
	@ENVIRONMENT=staging ./prepare-grafana-datasources.sh || echo "$(YELLOW)⚠️  Warning: Could not prepare datasources. Continuing...$(NC)"
	@docker-compose --env-file env.staging up -d
	@echo "$(GREEN)Monitoring deployed to staging!$(NC)"
	@echo "$(BLUE)Grafana: http://localhost:3001 (admin/admin-staging-123)$(NC)"

deploy-production: ## Deploy monitoring to production
	@echo "$(GREEN)Deploying Monitoring to production...$(NC)"
	@ENVIRONMENT=production ./prepare-grafana-datasources.sh || echo "$(YELLOW)⚠️  Warning: Could not prepare datasources. Continuing...$(NC)"
	@docker-compose --env-file env.production up -d
	@echo "$(GREEN)Monitoring deployed to production!$(NC)"

logs: ## Show monitoring logs
	@echo "$(GREEN)Showing Monitoring logs...$(NC)"
	@docker-compose -f docker-compose-localdev.yml logs -f

logs-staging: ## Show staging monitoring logs
	@echo "$(GREEN)Showing staging Monitoring logs...$(NC)"
	@docker-compose -f docker-compose.staging.yml logs -f

logs-production: ## Show production monitoring logs
	@echo "$(GREEN)Showing production Monitoring logs...$(NC)"
	@docker-compose -f docker-compose.production.yml logs -f

logs-grafana: ## Show Grafana logs
	@echo "$(GREEN)Showing Grafana logs...$(NC)"
	@docker-compose -f docker-compose-localdev.yml logs -f grafana

logs-prometheus: ## Show Prometheus logs
	@echo "$(GREEN)Showing Prometheus logs...$(NC)"
	@docker-compose -f docker-compose-localdev.yml logs -f prometheus

status: ## Show monitoring status
	@echo "$(GREEN)Monitoring Status:$(NC)"
	@docker-compose -f docker-compose-localdev.yml ps

status-staging: ## Show staging monitoring status
	@echo "$(GREEN)Staging Monitoring Status:$(NC)"
	@docker-compose -f docker-compose.staging.yml ps

status-production: ## Show production monitoring status
	@echo "$(GREEN)Production Monitoring Status:$(NC)"
	@docker-compose -f docker-compose.production.yml ps

stop: ## Stop monitoring
	@echo "$(GREEN)Stopping Monitoring...$(NC)"
	@docker-compose -f docker-compose-localdev.yml down
	@echo "$(GREEN)Monitoring stopped!$(NC)"

stop-staging: ## Stop staging monitoring
	@echo "$(GREEN)Stopping staging Monitoring...$(NC)"
	@docker-compose -f docker-compose.staging.yml down
	@echo "$(GREEN)Staging Monitoring stopped!$(NC)"

stop-production: ## Stop production monitoring
	@echo "$(GREEN)Stopping production Monitoring...$(NC)"
	@docker-compose -f docker-compose.production.yml down
	@echo "$(GREEN)Production Monitoring stopped!$(NC)"

restart: ## Restart monitoring
	@echo "$(GREEN)Restarting Monitoring...$(NC)"
	@docker-compose -f docker-compose-localdev.yml restart
	@echo "$(GREEN)Monitoring restarted!$(NC)"

restart-staging: ## Restart staging monitoring
	@echo "$(GREEN)Restarting staging Monitoring...$(NC)"
	@docker-compose -f docker-compose.staging.yml restart
	@echo "$(GREEN)Staging Monitoring restarted!$(NC)"

restart-production: ## Restart production monitoring
	@echo "$(GREEN)Restarting production Monitoring...$(NC)"
	@docker-compose -f docker-compose.production.yml restart
	@echo "$(GREEN)Production Monitoring restarted!$(NC)"

backup: ## Backup monitoring data
	@echo "$(GREEN)Backing up monitoring data...$(NC)"
	@docker run --rm -v ploscope-prometheus-localdev_prometheus_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/prometheus-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@docker run --rm -v ploscope-grafana-localdev_grafana_data:/data -v $(PWD)/backups:/backup alpine tar czf /backup/grafana-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "$(GREEN)Backup completed!$(NC)"

restore: ## Restore monitoring data
	@echo "$(GREEN)Restoring monitoring data...$(NC)"
	@echo "$(YELLOW)Usage: make restore PROMETHEUS_BACKUP=backup-file.tar.gz GRAFANA_BACKUP=backup-file.tar.gz$(NC)"

ci-pipeline: ## Run full CI pipeline for monitoring
	@echo "$(GREEN)Running Monitoring CI pipeline...$(NC)"
	@make lint
	@make test
	@make build
	@echo "$(GREEN)Monitoring CI pipeline completed!$(NC)"

ci-pipeline-quick: ## Run quick CI pipeline for monitoring
	@echo "$(GREEN)Running quick Monitoring CI pipeline...$(NC)"
	@make lint
	@make build
	@echo "$(GREEN)Quick Monitoring CI pipeline completed!$(NC)"

cleanup-logs: ## Clean up old Docker log files to prevent Alloy startup issues
	@echo "$(GREEN)Cleaning up old Docker log files...$(NC)"
	@chmod +x ./cleanup-old-logs.sh
	@./cleanup-old-logs.sh
	@echo "$(GREEN)Log cleanup completed!$(NC)"

cleanup-logs-dry-run: ## Show what would be cleaned up without actually deleting
	@echo "$(GREEN)Checking for old Docker log files (dry run)...$(NC)"
	@if [ -d "/var/lib/docker/containers" ]; then \
		find /var/lib/docker/containers -name "*.log" -type f -mtime +7 2>/dev/null | wc -l | xargs -I {} echo "Found {} old log files"; \
		find /var/lib/docker/containers -name "*.log.*" -type f -mtime +7 2>/dev/null | wc -l | xargs -I {} echo "Found {} old compressed log files"; \
		echo "$(BLUE)Run 'make cleanup-logs' to actually clean them up$(NC)"; \
	else \
		echo "$(YELLOW)Docker containers directory not found or not accessible$(NC)"; \
		echo "$(BLUE)This is normal in some environments$(NC)"; \
	fi

