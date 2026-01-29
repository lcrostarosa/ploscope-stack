# PLOSolver Makefile
# Simple commands for development and deployment

.PHONY: help deps deps-windows dev test build clean deploy docs lint security publish-package publish-tag publish-local-build publish-local-github publish-local-install
 .PHONY: publish-to-nexus publish-nexus

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
	@echo "$(BLUE)PLOSolver Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make deps    - Install all dependencies"
	@echo "  make setup   - Prepare RabbitMQ and Postgres for development"
	@echo "  make dev     - Run the application with hot reloading"
	@echo "  make bootstrap - Bootstrap RabbitMQ queues"
	@echo ""
	@echo "$(GREEN)Individual Services:$(NC)"
	@echo "  make run-backend-only  - Run only backend with Docker infrastructure"
	@echo "  make run-frontend-only - Run only frontend with Docker infrastructure"
	@echo "  make run-celery-only   - Run only celery with Docker infrastructure"
	@echo "  make run-celery-dev    - Run Celery worker natively with hot reloading"
	@echo "  make scale-celery      - Scale Celery workers for better performance"
	@echo "  make monitor-celery    - Monitor Celery worker performance and CPU usage"
	@echo ""
	@echo "$(GREEN)GitHub Container Registry:$(NC)"
	@echo "  make ghcr-setup          - Complete GHCR setup (auth + update compose)"
	@echo "  make ghcr-auth           - Authenticate with GHCR"
	@echo "  make ghcr-build          - Build and push both images to GHCR"
	@echo "  make ghcr-pull           - Pull both images from GHCR"
	@echo ""
	@echo "$(GREEN)CI Pipeline:$(NC)"
	@echo "  make ci-pipeline-docker  - Run full CI pipeline in Docker-in-Docker (isolated)"
	@echo "  make ci-pipeline         - Run full CI pipeline locally"
	@echo "  make ci-pipeline-quick   - Run quick CI pipeline (faster)"
	@echo ""
	@echo "$(GREEN)Package Publishing:$(NC)"
	@echo "  make publish-package     - Publish plosolver-core package via GitHub Actions"
	@echo "  make publish-tag         - Create and push version tag to trigger publishing"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## Dependencies
deps: ## Install all dependencies (Python, Node.js, system)
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@./scripts/setup/setup-dependencies.sh
	@echo "$(GREEN)Dependencies installed!$(NC)"

deps-windows: ## Install all dependencies on Windows (WSL2 + Docker Desktop via PowerShell)
	@echo "$(GREEN)Installing dependencies for Windows (using WSL2 + Docker Desktop)...$(NC)"
	@if command -v pwsh >/dev/null 2>&1; then \
		pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup/setup-dependencies.ps1; \
	elif command -v powershell >/dev/null 2>&1; then \
		powershell -NoProfile -ExecutionPolicy Bypass -File scripts/setup/setup-dependencies.ps1; \
	elif command -v powershell.exe >/dev/null 2>&1; then \
		powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/setup/setup-dependencies.ps1; \
	else \
		echo "$(RED)PowerShell not found. On Windows, run: powershell -ExecutionPolicy Bypass -File scripts/setup/setup-dependencies.ps1$(NC)"; \
		exit 1; \
	fi

deps-python: ## Install Python dependencies only
	@echo "$(GREEN)Installing Python dependencies...$(NC)"
	@./scripts/development/activate_venv.sh
	@cd src/backend && pip install -r requirements.txt
	@cd src/backend && pip install -r requirements-test.txt
	@cd src/celery && pip install -r requirements.txt

deps-node: ## Install Node.js dependencies only
	@echo "$(GREEN)Installing Node.js dependencies...$(NC)"
	@cd src/frontend && npm install

## Development
run: clean-frontend ## Run the application (development mode)
	@echo "$(GREEN)Starting PLOSolver...$(NC)"
	@./scripts/development/run_with_traefik.sh

run-local: clean-frontend ## Run frontend/backend locally with Docker infrastructure (reuses existing services, use ARGS="--recreate" to force recreation)
	@echo "$(GREEN)Starting PLOSolver with local frontend/backend and Docker infrastructure...$(NC)"
	@./scripts/development/run-local-with-docker-infra.sh $(ARGS)

run-backend-only: clean-frontend ## Run only backend locally with Docker infrastructure
	@echo "$(GREEN)Starting PLOSolver Backend Only with Docker infrastructure...$(NC)"
	@./scripts/development/run-backend-only.sh

run-frontend-only: clean-frontend ## Run only frontend locally with Docker infrastructure
	@echo "$(GREEN)Starting PLOSolver Frontend Only with Docker infrastructure...$(NC)"
	@./scripts/development/run-frontend-only.sh

run-celery-only: clean-frontend ## Run only celery locally with Docker infrastructure
	@echo "$(GREEN)Starting PLOSolver Celery Only with Docker infrastructure...$(NC)"
	@./scripts/development/run-celery-only.sh

run-celery-dev: ## Run Celery worker natively with hot reloading (development mode)
	@echo "$(GREEN)Starting Celery Worker in Development Mode (native with hot reloading)...$(NC)"
	@./scripts/development/run-celery-dev.sh

scale-celery: ## Scale Celery workers for better performance
	@echo "$(GREEN)Scaling Celery workers...$(NC)"
	@./scripts/operations/scale-celery-workers.sh $(ENV) $(WORKERS)

monitor-celery: ## Monitor Celery worker performance and CPU usage
	@echo "$(GREEN)Monitoring Celery performance...$(NC)"
	@./scripts/operations/monitor-celery-performance.sh $(ENV) $(DURATION)

test-metrics: ## Test Traefik metrics and Prometheus integration
	@echo "$(GREEN)Testing Traefik metrics and Prometheus integration...$(NC)"
	@./scripts/operations/test-metrics.sh

run-docker: ## Run with Docker
	@echo "$(GREEN)Starting PLOSolver with Docker...$(NC)"
	@./scripts/development/run_with_docker.sh

dev: clean-frontend ## Run the application in local development mode with Docker (hot reloading enabled)
	@echo "$(GREEN)Starting PLOSolver (local development mode with hot reloading)...$(NC)"
	@./scripts/development/dev-hot-reload.sh


## Testing
test: ## Run all tests (frontend + backend)
	@echo "$(GREEN)Running all tests (frontend + backend)...$(NC)"
	@FRONTEND_EXIT=0; BACKEND_EXIT=0; \
	$(MAKE) test-frontend || FRONTEND_EXIT=$$?; \
	$(MAKE) test-backend || BACKEND_EXIT=$$?; \
	echo ""; \
	echo "$(BLUE)📊 Test Results Summary$(NC)"; \
	echo "========================"; \
	if [ $$FRONTEND_EXIT -eq 0 ]; then \
		echo "$(GREEN)Frontend: ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Frontend: ❌ FAILED (exit code: $$FRONTEND_EXIT)$(NC)"; \
	fi; \
	if [ $$BACKEND_EXIT -eq 0 ]; then \
		echo "$(GREEN)Backend: ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Backend: ❌ FAILED (exit code: $$BACKEND_EXIT)$(NC)"; \
	fi; \
	if [ $$FRONTEND_EXIT -eq 0 ] && [ $$BACKEND_EXIT -eq 0 ]; then \
		echo "$(GREEN)✅ All tests completed successfully$(NC)"; \
		exit 0; \
	else \
		echo "$(RED)❌ Some tests failed$(NC)"; \
		exit 1; \
	fi

test-unit: ## Run all unit tests
	@echo "$(GREEN)Running all unit tests (frontend + backend)...$(NC)"
	@FRONTEND_EXIT=0; BACKEND_EXIT=0; \
	$(MAKE) test-frontend-unit || FRONTEND_EXIT=$$?; \
	$(MAKE) test-backend-unit || BACKEND_EXIT=$$?; \
	echo ""; \
	echo "$(BLUE)📊 Unit Test Results Summary$(NC)"; \
	echo "============================="; \
	if [ $$FRONTEND_EXIT -eq 0 ]; then \
		echo "$(GREEN)Frontend Unit Tests: ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Frontend Unit Tests: ❌ FAILED (exit code: $$FRONTEND_EXIT)$(NC)"; \
	fi; \
	if [ $$BACKEND_EXIT -eq 0 ]; then \
		echo "$(GREEN)Backend Unit Tests: ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Backend Unit Tests: ❌ FAILED (exit code: $$BACKEND_EXIT)$(NC)"; \
	fi; \
	if [ $$FRONTEND_EXIT -eq 0 ] && [ $$BACKEND_EXIT -eq 0 ]; then \
		echo "$(GREEN)✅ All unit tests completed successfully$(NC)"; \
		exit 0; \
	else \
		echo "$(RED)❌ Some unit tests failed$(NC)"; \
		exit 1; \
	fi

test-integration: ## Run all integration tests using Cucumber (containerized CI)
	@echo "$(GREEN)Running all integration tests using Cucumber (containerized CI)...$(NC)"
	@CUCUMBER_EXIT=0; NEWMAN_EXIT=0; \
	$(MAKE) test-cucumber-ci || CUCUMBER_EXIT=$$?; \
	$(MAKE) test-newman || NEWMAN_EXIT=$$?; \
	echo ""; \
	echo "$(BLUE)📊 Integration Test Results Summary$(NC)"; \
	echo "==================================="; \
	if [ $$CUCUMBER_EXIT -eq 0 ]; then \
		echo "$(GREEN)Cucumber Integration Tests (Containerized): ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Cucumber Integration Tests (Containerized): ❌ FAILED (exit code: $$CUCUMBER_EXIT)$(NC)"; \
	fi; \
	if [ $$NEWMAN_EXIT -eq 0 ]; then \
		echo "$(GREEN)API Integration Tests (Newman): ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)API Integration Tests (Newman): ❌ FAILED (exit code: $$NEWMAN_EXIT)$(NC)"; \
	fi; \
	if [ $$CUCUMBER_EXIT -eq 0 ] && [ $$NEWMAN_EXIT -eq 0 ]; then \
		echo "$(GREEN)✅ All integration tests completed successfully$(NC)"; \
		exit 0; \
	else \
		echo "$(RED)❌ Some integration tests failed$(NC)"; \
		exit 1; \
	fi

test-integration-ci: ## Run all integration tests using CI services (no Docker containers)
	@echo "$(GREEN)Running all integration tests using CI services with Cucumber...$(NC)"
	@echo "Pulling prebuilt images for integration tests..."
	@docker compose -f docker-compose-test.yml --profile bootstrap pull frontend backend celeryworker || true
	@CUCUMBER_EXIT=0; \
	$(MAKE) test-cucumber-ci || CUCUMBER_EXIT=$$?; \
	echo ""; \
	echo "$(BLUE)📊 Integration Test Results Summary$(NC)"; \
	echo "==================================="; \
	if [ $$CUCUMBER_EXIT -eq 0 ]; then \
		echo "$(GREEN)Cucumber Integration Tests (Legacy): ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Cucumber Integration Tests (Legacy): ❌ FAILED (exit code: $$CUCUMBER_EXIT)$(NC)"; \
	fi; \
	if [ $$CUCUMBER_EXIT -eq 0 ]; then \
		echo "$(GREEN)✅ All integration tests completed successfully$(NC)"; \
		exit 0; \
	else \
		echo "$(RED)❌ Some integration tests failed$(NC)"; \
		exit 1; \
	fi

test-newman: ## Run Newman API integration tests standalone
	@echo "$(GREEN)Running Newman API integration tests (standalone)...$(NC)"
	@docker compose -f docker-compose-test.yml --profile bootstrap up -d traefik backend rabbitmq db celeryworker >/dev/null
	@NEW_MAN_EXIT=0; \
	docker compose -f docker-compose-test.yml run --rm newman || NEW_MAN_EXIT=$$?; \
	if [ $$NEW_MAN_EXIT -ne 0 ]; then \
	  echo "$(RED)❌ Newman tests failed. Dumping container logs...$(NC)"; \
	  docker compose -f docker-compose-test.yml ps || true; \
	  docker compose -f docker-compose-test.yml logs --tail=200 --timestamps || true; \
	  echo "$(YELLOW)--- Service-specific logs ---$(NC)"; \
	  docker compose -f docker-compose-test.yml logs traefik --tail=200 --timestamps || true; \
	  docker compose -f docker-compose-test.yml logs backend --tail=200 --timestamps || true; \
	  docker compose -f docker-compose-test.yml logs frontend --tail=200 --timestamps || true; \
	  docker compose -f docker-compose-test.yml logs celeryworker --tail=200 --timestamps || true; \
	  docker compose -f docker-compose-test.yml logs rabbitmq --tail=200 --timestamps || true; \
	  docker compose -f docker-compose-test.yml logs db --tail=200 --timestamps || true; \
	fi; \
	docker compose -f docker-compose-test.yml down -v >/dev/null; \
	exit $$NEW_MAN_EXIT

test-frontend: test-frontend-unit ## Run all frontend tests
	@echo "$(GREEN)✅ All frontend tests completed$(NC)"

test-frontend-unit: ## Run frontend unit tests only
	@echo "$(GREEN)Running frontend unit tests...$(NC)"
	@cd src/frontend && if [ ! -d node_modules ]; then echo "Installing frontend dependencies..." && npm ci --silent --no-progress; fi && npm run test:unit

test-cucumber: ## Run Cucumber integration tests (containerized)
	@echo "$(GREEN)Running Cucumber integration tests (containerized)...$(NC)"
	@./scripts/testing/run-cucumber-tests-docker.sh

test-cucumber-legacy: ## Run Cucumber integration tests (legacy script)
	@echo "$(GREEN)Running Cucumber integration tests (legacy script)...$(NC)"
	@./scripts/testing/run-cucumber-tests.sh --containerized

test-cucumber-local: ## Run Cucumber integration tests against local development environment
	@echo "$(GREEN)Running Cucumber integration tests against local development environment...$(NC)"
	@./scripts/testing/run-cucumber-tests.sh --local

test-cucumber-ci: ## Run Cucumber integration tests using CI services in Docker containers
	@echo "$(GREEN)Running Cucumber integration tests using CI services in Docker containers...$(NC)"
	@./scripts/testing/run-cucumber-tests-docker.sh

test-backend: test-backend-unit ## Run all backend tests
	@echo "$(GREEN)✅ All backend tests completed$(NC)"

test-backend-unit: ## Run backend unit tests only
	@echo "$(GREEN)Running backend unit tests...$(NC)"
	@./scripts/testing/run_tests.sh backend unit

test-coverage: ## Run unit tests (frontend + backend) with coverage reports
	@echo "$(GREEN)Running unit tests with coverage (frontend + backend)...$(NC)"
	@./scripts/testing/run_tests.sh --frontend-only --coverage && ./scripts/testing/run_unit_tests.sh --coverage



## Build
build: clean-frontend ## Build the application
	@echo "$(GREEN)Building application...$(NC)"
	@cd src/frontend && npm run build

build-docker: ## Build Docker images
	@echo "$(GREEN)Building Docker images...$(NC)"
	@COMPOSE_PROFILES=app docker compose build

build-docker-staging: ## Build Docker images for staging
	@echo "$(GREEN)Building Docker images for staging...$(NC)"
	@set -a; . ./env.staging; set +a; COMPOSE_PROFILES=app docker compose build

build-docker-no-cache: ## Build Docker images without cache
	@echo "$(GREEN)Building Docker images (no cache)...$(NC)"
	@COMPOSE_PROFILES=app docker compose build --no-cache

build-docker-pull: ## Build Docker images with latest base images
	@echo "$(GREEN)Building Docker images (pulling latest base images)...$(NC)"
	@COMPOSE_PROFILES=app docker compose build --pull

## Database
db-migrate: ## Run database migrations using containerized db-init (development local stack)
	@echo "$(GREEN)Running database migrations using containers...$(NC)"
	@docker compose -f docker-compose-localdev.yml --profile migrate up db-migrate --build --abort-on-container-exit --remove-orphans

db-stamp: ## Stamp the database with the latest migration using containerized db-init
	@echo "$(GREEN)Stamping database with latest Alembic migration (containers)...$(NC)"
	@docker compose -f docker-compose-localdev.yml run --rm db-migrate alembic -c /app/migrations/alembic.ini stamp head

# Assumes environment variables: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, DATABASE_URL
# Loads from env.development if present

db-reset: ## Drop, recreate, and migrate the database using Alembic only
	@echo "$(YELLOW)Resetting database (full drop and recreate)...$(NC)"
	@if [ -f env.development ]; then set -a && source env.development && set +a; fi; \
	if [ -z "$$POSTGRES_DB" ] || [ -z "$$POSTGRES_USER" ] || [ -z "$$POSTGRES_HOST" ] || [ -z "$$DATABASE_URL" ]; then \
		echo "$(RED)Missing required environment variables: POSTGRES_DB, POSTGRES_USER, POSTGRES_HOST, or DATABASE_URL$(NC)"; \
		exit 1; \
	fi; \
	echo "Dropping database $$POSTGRES_DB..."; \
	PGPASSWORD=$$POSTGRES_PASSWORD dropdb -h $$POSTGRES_HOST -U $$POSTGRES_USER --if-exists $$POSTGRES_DB; \
	echo "Creating database $$POSTGRES_DB..."; \
	PGPASSWORD=$$POSTGRES_PASSWORD createdb -h $$POSTGRES_HOST -U $$POSTGRES_USER $$POSTGRES_DB; \
	cd src/backend && alembic -c migrations/alembic.ini upgrade head

db-bootstrap: ## Bootstrap database with proper initialization and migrations (ENV=production|staging|development)
	@echo "$(GREEN)Bootstrapping database with proper initialization...$(NC)"
	@./scripts/setup/bootstrap-database.sh

db-migrate-staging: ## Run database migrations for staging environment
	@echo "$(GREEN)Running database migrations for staging...$(NC)"
	@docker compose -f docker-compose.staging.yml --env-file env.staging --profile migrate up db-migrate --build --abort-on-container-exit --remove-orphans

db-migrate-production: ## Run database migrations for production environment
	@echo "$(GREEN)Running database migrations for production...$(NC)"
	@docker compose -f docker-compose.production.yml --env-file env.production --profile migrate up db-migrate --build --abort-on-container-exit --remove-orphans

db-bootstrap-test: ## Test database bootstrap functionality (ENV=production|staging|development)
	@echo "$(GREEN)Testing database bootstrap functionality...$(NC)"
	@./scripts/setup/test-database-bootstrap.sh

## Security
security: ## Run security checks
	@echo "$(GREEN)Running security checks...$(NC)"
	@./scripts/operations/security-check.sh

security-setup: ## Set up security tools
	@echo "$(GREEN)Setting up security tools...$(NC)"
	@./scripts/setup/setup-security-tools.sh

## Deployment
staging-deploy: ## Deploy to staging environment
	@echo "$(GREEN)Deploying to staging...$(NC)"
	@DOCKER_BUILDKIT=1 docker compose -f docker-compose.staging.yml --env-file env.staging up -d --build --scale celeryworker=1 backend frontend celeryworker rabbitmq db

production-deploy: ## Deploy to production environment
	@echo "$(GREEN)Deploying to production...$(NC)"
	@DOCKER_BUILDKIT=1 docker compose -f docker-compose.production.yml --env-file env.production up -d --build --scale celeryworker=1 backend frontend celeryworker rabbitmq db

hetzner-initial-setup: ## Initial Hetzner server setup (ONE-TIME ONLY - removes root access)
	@echo "$(RED)⚠️  CRITICAL: This will remove root SSH access permanently! ⚠️$(NC)"
	@echo "$(YELLOW)This is a ONE-TIME setup. After this, you can only connect as 'appuser'.$(NC)"
	@read -p "Type 'yes' to continue with initial setup: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "$(RED)Setup aborted.$(NC)"; \
		exit 1; \
	fi
	@cd server/ansible && ansible-playbook -i inventories/inventory.yml --extra-vars "@variables/vars.yml" 00_root-setup.yml

hetzner-appuser: ## Configure the appuser account on the Hetzner server
	@cd server/ansible && ansible-playbook -i inventories/inventory.yml --extra-vars "@variables/vars.yml" 01_appuser.yml

hetzner-deploy: ## Deploy staging application to Hetzner server
	@cd server/ansible && ansible-playbook -i inventories/inventory.yml --extra-vars "@variables/vars.yml" 02_deploy.yml


## Documentation
docs: ## Generate documentation
	@echo "$(GREEN)Generating documentation...$(NC)"
	@./scripts/docs/generate_docs.py

docs-serve: ## Serve documentation locally
	@echo "$(GREEN)Serving documentation...$(NC)"
	@./scripts/docs/serve-docs.sh &
	@echo "\nSwagger UI available at: http://localhost:8000/docs/swagger-ui/\n"

## Utilities
lint: ## Run linting
	@echo "$(GREEN)Running linting...$(NC)"
	@echo "$(BLUE)Frontend linting...$(NC)"; \
	(cd src/frontend && npm run lint > /tmp/frontend_lint_output.txt 2>&1); echo $$? > /tmp/frontend_exit_code; cat /tmp/frontend_lint_output.txt; \
	echo "$(BLUE)Backend linting...$(NC)"; \
	(cd src/backend && ( [ -x venv/bin/flake8 ] && venv/bin/flake8 . || flake8 . )); echo $$? > /tmp/backend_exit_code; \
	echo "$(BLUE)Celery worker linting...$(NC)"; \
	(cd src/celery && ( [ -x ../backend/venv/bin/flake8 ] && ../backend/venv/bin/flake8 . || flake8 . )); echo $$? > /tmp/celery_exit_code; \
	echo ""; \
	FRONTEND_EXIT=$$(cat /tmp/frontend_exit_code 2>/dev/null || echo 0); \
	BACKEND_EXIT=$$(cat /tmp/backend_exit_code 2>/dev/null || echo 0); \
	CELERY_EXIT=$$(cat /tmp/celery_exit_code 2>/dev/null || echo 0); \
	echo "$(BLUE)📊 Linting Results Summary$(NC)"; \
	echo "========================="; \
	if grep -q "^.*[0-9]+:[0-9]+.*error" /tmp/frontend_lint_output.txt; then \
		echo "$(RED)Frontend Linting: ❌ FAILED (errors found - run 'make lint-fix' to auto-fix)$(NC)"; \
	elif grep -q "warning" /tmp/frontend_lint_output.txt; then \
		echo "$(YELLOW)Frontend Linting: ⚠️ WARNINGS ONLY (no errors)$(NC)"; \
		FRONTEND_EXIT=0; \
	else \
		echo "$(GREEN)Frontend Linting: ✅ PASSED$(NC)"; \
	fi; \
	if [ "$$BACKEND_EXIT" -eq 0 ]; then \
		echo "$(GREEN)Backend Linting: ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Backend Linting: ❌ FAILED$(NC)"; \
	fi; \
	if [ "$$CELERY_EXIT" -eq 0 ]; then \
		echo "$(GREEN)Celery Linting: ✅ PASSED$(NC)"; \
	else \
		echo "$(RED)Celery Linting: ❌ FAILED$(NC)"; \
	fi; \
	if [ "$$FRONTEND_EXIT" -eq 0 ] && [ "$$BACKEND_EXIT" -eq 0 ] && [ "$$CELERY_EXIT" -eq 0 ]; then \
		echo "$(GREEN)✅ All linting checks passed!$(NC)"; \
		rm -f /tmp/frontend_lint_output.txt /tmp/*_exit_code; \
		exit 0; \
	else \
		echo "$(RED)❌ Some linting checks failed$(NC)"; \
		rm -f /tmp/frontend_lint_output.txt /tmp/*_exit_code; \
		exit 1; \
	fi

typecheck: ## Run TypeScript type checking for the frontend (no emit)
	@echo "$(GREEN)Running TypeScript type checking (frontend)...$(NC)"
	@cd src/frontend && npm run typecheck
	@echo "$(GREEN)✅ TypeScript checks completed$(NC)"

lint-fix: ## Auto-fix lint errors (frontend, backend, and celery)
	@echo "$(GREEN)Auto-fixing frontend lint errors...$(NC)"
	@(cd src/frontend && npm run lint:fix) || true
	@echo "$(GREEN)Auto-fixing backend lint errors...$(NC)"
	@(cd src/backend && (if [ -f "venv/bin/activate" ]; then . venv/bin/activate; elif [ -f "venv/Scripts/activate" ]; then . venv/Scripts/activate; else echo "No virtual environment found, using system Python"; fi) && black .) || true
	@echo "$(GREEN)Auto-fixing celery worker lint errors...$(NC)"
	@(cd src/celery && (if [ -f "../backend/venv/bin/activate" ]; then . ../backend/venv/bin/activate; elif [ -f "../backend/venv/Scripts/activate" ]; then . ../backend/venv/Scripts/activate; else echo "No virtual environment found, using system Python"; fi) && black .) || true
	@echo "$(GREEN)✅ Lint auto-fix complete!$(NC)"

sync-env-files: ## Synchronize environment variable order across all env files
	@echo "$(GREEN)Synchronizing environment files...$(NC)"
	@./scripts/utilities/sync_env_files.sh $(if $(DRY_RUN),--dry-run) $(if $(BACKUP),--backup)

format: ## Format code
	@echo "$(GREEN)Formatting code...$(NC)"
	@cd src/frontend && npm run lint:fix
	@cd src/backend && black .
	@cd src/celery && black .

clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@rm -rf src/frontend/dist/
	@rm -rf src/frontend/node_modules/
	@rm -rf src/backend/__pycache__/
	@rm -rf src/backend/**/__pycache__/
	@rm -rf .pytest_cache/
	@docker system prune -f

clean-frontend: ## Clean frontend build artifacts only
	@echo "$(GREEN)Cleaning frontend build artifacts...$(NC)"
	@rm -rf src/frontend/dist/

## Docker utilities
docker-logs: ## Show Docker logs
	@docker compose logs -f

docker-stop: ## Stop Docker containers
	@docker compose down

localdev-stop: ## Stop local development environment
	@echo "$(GREEN)Stopping local development environment...$(NC)"
	@docker compose -f docker-compose-localdev.yml down
	@echo "$(GREEN)Local development environment stopped!$(NC)"

local-services-stop: ## Stop local Docker infrastructure services
	@echo "$(GREEN)Stopping local Docker infrastructure services...$(NC)"
	@./scripts/development/stop-local-services.sh

docker-restart: ## Restart Docker containers
	@./scripts/operations/restart-docker.sh

## Setup
setup-discourse: ## Set up Discourse forum
	@echo "$(GREEN)Setting up Discourse...$(NC)"
	@./scripts/setup/setup-discourse.sh

setup-solver: ## Set up solver engine
	@echo "$(GREEN)Setting up solver engine...$(NC)"
	@python scripts/setup/setup_solver.py

setup-pre-commit: ## Set up pre-commit hook for CI pipeline
	@echo "$(GREEN)Setting up pre-commit hook...$(NC)"
	@./scripts/setup/setup-pre-commit.sh

setup: ## Prepare RabbitMQ and Postgres for development
	@echo "$(GREEN)Starting RabbitMQ and Postgres containers...$(NC)"
	docker-compose -f docker-compose-localdev.yml up -d db rabbitmq
	@echo "$(GREEN)Waiting for Postgres to be healthy...$(NC)"
	until docker-compose -f docker-compose-localdev.yml exec db pg_isready -U postgres; do sleep 2; done
	@echo "$(GREEN)Waiting for RabbitMQ to be healthy...$(NC)"
	until docker-compose -f docker-compose-localdev.yml exec rabbitmq rabbitmq-diagnostics ping | grep -q 'Ping succeeded'; do sleep 2; done
	@echo "$(GREEN)Bootstrapping RabbitMQ queues...$(NC)"
	./scripts/setup/bootstrap-rabbitmq.sh
	@echo "$(GREEN)Resetting and initializing the database...$(NC)"
	docker-compose -f docker-compose-localdev.yml up -d backend
	sleep 10
	docker-compose -f docker-compose-localdev.yml exec backend python scripts/reset_db.py reset
	@echo "$(GREEN)Setup complete!$(NC)"

bootstrap-rabbitmq: ## Bootstrap RabbitMQ queues
	@echo "$(GREEN)Bootstrapping RabbitMQ queues...$(NC)"
	@./scripts/setup/bootstrap-rabbitmq.sh

bootstrap: setup bootstrap-rabbitmq ## Bootstrap all required services
	@echo "$(GREEN)All services bootstrapped!$(NC)"

## Health checks
health: ## Check application health
	@echo "$(GREEN)Checking application health...$(NC)"
	@./scripts/operations/health-check.sh

check-docker: ## Check Docker setup
	@echo "$(GREEN)Checking Docker setup...$(NC)"
	@./scripts/operations/check-docker.sh

## Package Publishing

publish-local-build: ## Build the plosolver-core package locally
	@echo "$(GREEN)🔨 Building PLOSolver Core Package locally...$(NC)"
	@./scripts/utilities/publish-package-local.sh build

publish-local-install: ## Build and install package locally for testing
	@echo "$(GREEN)🧪 Installing package locally for testing...$(NC)"
	@./scripts/utilities/publish-package-local.sh install

publish-to-nexus: ## Build and publish plosolver-core to Nexus (requires TWINE_USERNAME/TWINE_PASSWORD)
	@echo "$(GREEN)🚀 Publishing PLOSolver Core to Nexus...$(NC)"
	@if [ -z "$$TWINE_USERNAME" ] || [ -z "$$TWINE_PASSWORD" ]; then \
		echo "$(RED)❌ Missing credentials. Set TWINE_USERNAME and TWINE_PASSWORD.$(NC)"; \
		echo "$(YELLOW)Example: TWINE_USERNAME=pypi-publisher TWINE_PASSWORD=*** make publish-to-nexus$(NC)"; \
		exit 1; \
	fi
	@python -m pip install --upgrade pip build twine >/dev/null 2>&1 || true
	@cd src/plosolver_core && rm -rf dist build *.egg-info && PIP_INDEX_URL=https://pypi.org/simple python -m build
	@TWINE_REPOSITORY_URL=$${TWINE_REPOSITORY_URL:-https://nexus.ploscope.com/repository/pypi-internal/}; \
	 echo "$(BLUE)Uploading to: $$TWINE_REPOSITORY_URL$(NC)"; \
	 python -m twine upload --config-file /dev/null --repository-url "$$TWINE_REPOSITORY_URL" src/plosolver_core/dist/*

publish-nexus: publish-to-nexus ## Alias for publish-to-nexus

test-nexus: ## Test Nexus Repository connectivity and package installation
	@echo "$(GREEN)🔍 Testing Nexus Repository setup...$(NC)"
	@./scripts/testing/test-nexus-install.sh

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
	git tag -a "$$tag" -m "Release PLOSolver Core version $$version" || \
	{ echo "$(RED)❌ Failed to create tag. Tag may already exist.$(NC)"; exit 1; }; \
	git push origin "$$tag" || \
	{ echo "$(RED)❌ Failed to push tag$(NC)"; git tag -d "$$tag"; exit 1; }; \
	echo "$(GREEN)✅ Tag $$tag created and pushed successfully!$(NC)"; \
	echo "$(BLUE)📋 This will automatically trigger the publishing workflow$(NC)"; \
	repo_path=$$(git config --get remote.origin.url | sed 's/.*github\.com[:/]\([^.]*\)\.git.*/\1/'); \
	echo "$(BLUE)📋 Check progress at: https://github.com/$$repo_path/actions$(NC)"

## CI Pipeline
ci-pipeline: ## Run the full CI pipeline locally (pre-commit hook)
	@echo "$(GREEN)🚀 Running CI Pipeline locally...$(NC)"
	@echo "$(BLUE)Step 1/5: Installing dependencies...$(NC)"
	@$(MAKE) deps-python
	@$(MAKE) deps-node
	@echo "$(BLUE)Step 2/5: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/5: Running unit tests...$(NC)"
	@$(MAKE) test-unit
	@echo "$(BLUE)Step 4/5: Building Docker images...$(NC)"
	@$(MAKE) build-docker
	@echo "$(BLUE)Step 5/5: Running integration tests...$(NC)"
	@$(MAKE) test-integration
	@echo "$(GREEN)✅ CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"

ci-pipeline-docker: ## Run the full CI pipeline in isolated Docker container (Docker-in-Docker)
	@echo "$(GREEN)🚀 Running CI Pipeline in Docker-in-Docker...$(NC)"
	@echo "$(BLUE)📦 Complete isolation from local environment$(NC)"
	@echo "$(BLUE)🔒 No conflicts with local services (RabbitMQ, PostgreSQL, etc.)$(NC)"
	@./scripts/ci/run-ci-pipeline-docker.sh

ci-pipeline-quick: ## Run quick CI pipeline (faster version)
	@echo "$(GREEN)🚀 Running Quick CI Pipeline locally...$(NC)"
	@echo "$(BLUE)Step 1/4: Installing dependencies...$(NC)"
	@$(MAKE) deps-python
	@$(MAKE) deps-node
	@echo "$(BLUE)Step 2/4: Running linting...$(NC)"
	@$(MAKE) lint
	@echo "$(BLUE)Step 3/4: Running unit tests...$(NC)"
	@$(MAKE) test-unit
	@echo "$(BLUE)Step 4/4: Building frontend...$(NC)"
	@$(MAKE) build
	@echo "$(GREEN)✅ Quick CI Pipeline completed successfully!$(NC)"
	@echo "$(GREEN)🎉 All checks passed - ready to commit!$(NC)"
