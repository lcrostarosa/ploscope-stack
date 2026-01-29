# PLOScope Stack Makefile
# Common operations for managing the PLOScope platform

.PHONY: help setup up down restart logs build pull ps status clean reset \
        dev prod monitoring shell exec test lint

# Default target
.DEFAULT_GOAL := help

# Compose file combinations
COMPOSE_BASE := docker compose -f docker-compose.yml
COMPOSE_DEV := $(COMPOSE_BASE) -f docker-compose.dev.yml
COMPOSE_PROD := $(COMPOSE_BASE) -f docker-compose.prod.yml

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

#───────────────────────────────────────────────────────────────────────────────
# HELP
#───────────────────────────────────────────────────────────────────────────────

help: ## Show this help
	@echo ""
	@echo "$(BLUE)PLOScope Stack$(NC) - Orchestration Commands"
	@echo ""
	@echo "$(GREEN)Setup:$(NC)"
	@grep -E '^(setup|clone-repos|init):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Development:$(NC)"
	@grep -E '^(dev|dev-up|dev-down|dev-logs|build):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Production:$(NC)"
	@grep -E '^(prod|up|down|restart|pull):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Monitoring:$(NC)"
	@grep -E '^(logs|ps|status|monitoring):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Utilities:$(NC)"
	@grep -E '^(shell|exec|clean|reset):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

#───────────────────────────────────────────────────────────────────────────────
# SETUP
#───────────────────────────────────────────────────────────────────────────────

setup: ## Run the setup wizard
	@./scripts/setup.sh

clone-repos: ## Clone all PLOScope repositories
	@./scripts/clone-repos.sh

init: .env ## Initialize .env file if not exists
.env:
	@echo "$(YELLOW)Creating .env from .env.example...$(NC)"
	@cp .env.example .env
	@echo "$(GREEN)Created .env - please edit with your values$(NC)"

#───────────────────────────────────────────────────────────────────────────────
# DEVELOPMENT
#───────────────────────────────────────────────────────────────────────────────

dev: dev-up ## Alias for dev-up

dev-up: ## Start development environment (builds from source)
	@echo "$(GREEN)Starting development stack...$(NC)"
	@$(COMPOSE_DEV) up -d
	@echo ""
	@echo "$(GREEN)Services started:$(NC)"
	@echo "  Frontend:  http://localhost:3000"
	@echo "  Backend:   http://localhost:5001"
	@echo "  Grafana:   http://localhost:3001"
	@echo "  RabbitMQ:  http://localhost:15672"

dev-down: ## Stop development environment
	@echo "$(YELLOW)Stopping development stack...$(NC)"
	@$(COMPOSE_DEV) down

dev-logs: ## Follow development logs
	@$(COMPOSE_DEV) logs -f

build: ## Build all development images
	@echo "$(GREEN)Building development images...$(NC)"
	@$(COMPOSE_DEV) build

build-%: ## Build specific service (e.g., make build-backend)
	@echo "$(GREEN)Building $*...$(NC)"
	@$(COMPOSE_DEV) build $*

#───────────────────────────────────────────────────────────────────────────────
# PRODUCTION
#───────────────────────────────────────────────────────────────────────────────

prod: ## Start production environment
	@echo "$(GREEN)Starting production stack...$(NC)"
	@$(COMPOSE_PROD) up -d

up: ## Start stack with base config (pulls images)
	@echo "$(GREEN)Starting PLOScope stack...$(NC)"
	@$(COMPOSE_BASE) up -d

down: ## Stop all services
	@echo "$(YELLOW)Stopping stack...$(NC)"
	@$(COMPOSE_BASE) down

restart: ## Restart all services
	@echo "$(YELLOW)Restarting stack...$(NC)"
	@$(COMPOSE_BASE) restart

restart-%: ## Restart specific service (e.g., make restart-backend)
	@echo "$(YELLOW)Restarting $*...$(NC)"
	@$(COMPOSE_BASE) restart $*

pull: ## Pull latest images
	@echo "$(GREEN)Pulling latest images...$(NC)"
	@$(COMPOSE_BASE) pull

#───────────────────────────────────────────────────────────────────────────────
# MONITORING
#───────────────────────────────────────────────────────────────────────────────

logs: ## Follow logs for all services
	@$(COMPOSE_BASE) logs -f

logs-%: ## Follow logs for specific service (e.g., make logs-backend)
	@$(COMPOSE_BASE) logs -f $*

ps: ## List running containers
	@$(COMPOSE_BASE) ps

status: ## Show detailed status
	@echo "$(BLUE)Service Status:$(NC)"
	@$(COMPOSE_BASE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

monitoring: ## Start monitoring stack (Prometheus, Grafana, Loki)
	@echo "$(GREEN)Starting monitoring services...$(NC)"
	@$(COMPOSE_BASE) --profile monitoring up -d prometheus grafana loki

#───────────────────────────────────────────────────────────────────────────────
# UTILITIES
#───────────────────────────────────────────────────────────────────────────────

shell: ## Open shell in backend container
	@$(COMPOSE_BASE) exec backend /bin/sh -c 'command -v bash >/dev/null && exec bash || exec sh'

shell-%: ## Open shell in specific service (e.g., make shell-frontend)
	@$(COMPOSE_BASE) exec $* /bin/sh -c 'command -v bash >/dev/null && exec bash || exec sh'

exec: ## Execute command in container (usage: make exec SERVICE="backend" CMD="python --version")
	@$(COMPOSE_BASE) exec $(SERVICE) $(CMD)

clean: ## Remove stopped containers and unused images
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker compose down --remove-orphans
	@docker system prune -f

reset: ## Reset everything (removes all data!)
	@echo "$(RED)WARNING: This will destroy all data!$(NC)"
	@read -p "Are you sure? (y/N) " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(COMPOSE_BASE) down -v --remove-orphans
	@docker network rm plo-network-cloud 2>/dev/null || true
	@echo "$(GREEN)Reset complete. Run 'make setup' to start fresh.$(NC)"

#───────────────────────────────────────────────────────────────────────────────
# DATABASE
#───────────────────────────────────────────────────────────────────────────────

db-shell: ## Open PostgreSQL shell
	@$(COMPOSE_BASE) exec db psql -U $${POSTGRES_USER:-postgres} -d $${POSTGRES_DB:-plosolver}

db-backup: ## Backup database
	@mkdir -p ./backups
	@$(COMPOSE_BASE) exec db pg_dump -U $${POSTGRES_USER:-postgres} $${POSTGRES_DB:-plosolver} > ./backups/backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "$(GREEN)Backup created in ./backups/$(NC)"

db-migrate: ## Run database migrations
	@$(COMPOSE_BASE) run --rm db-init

#───────────────────────────────────────────────────────────────────────────────
# CONVENIENCE SHORTCUTS
#───────────────────────────────────────────────────────────────────────────────

backend: logs-backend
frontend: logs-frontend
worker: logs-celery-worker
rabbit: logs-rabbitmq
redis: logs-redis
