# ===========================================
# RabbitMQ Makefile for Local Development
# ===========================================

.PHONY: help build up down restart logs clean test test-up test-down init migrate pre-commit install-hooks

# Default target
help:
	@echo "Available commands:"
	@echo "  build         - Build RabbitMQ containers"
	@echo "  up            - Start RabbitMQ services"
	@echo "  down          - Stop RabbitMQ services"
	@echo "  restart       - Restart RabbitMQ services"
	@echo "  logs          - Show RabbitMQ logs"
	@echo "  clean         - Clean up containers and volumes"
	@echo "  test          - Run tests with test RabbitMQ"
	@echo "  test-up       - Start test RabbitMQ services"
	@echo "  test-down     - Stop test RabbitMQ services"
	@echo "  test-full     - Run full test setup"
	@echo "  init          - Initialize RabbitMQ queues"
	@echo "  rabbitmq-up   - Start RabbitMQ only"
	@echo "  rabbitmq-down - Stop RabbitMQ only"
	@echo "  rabbitmq-reset - Reset RabbitMQ and initialize queues"
	@echo "  dev           - Full development setup"
	@echo "  dev-full      - Development setup with queue initialization"
	@echo "  network       - Create Docker network if it doesn't exist"
	@echo "  pre-commit    - Run pre-commit hooks"
	@echo "  install-hooks - Install pre-commit hooks"

# Build containers
build: network
	@echo "🔧 Loading environment variables..."
	@if [ -f env.local ]; then \
		export $$(grep -v '^#' env.local | xargs) && docker compose build; \
	else \
		echo "⚠️  env.local file not found, using system environment variables"; \
		docker compose build; \
	fi

# Create Docker network if it doesn't exist
network:
	@echo "🔗 Checking Docker network plo-network-cloud..."
	@if ! docker network inspect plo-network-cloud >/dev/null 2>&1; then \
		echo "🔗 Creating Docker network plo-network-cloud with subnet 172.30.1.0/24..."; \
		docker network create --subnet=172.30.1.0/24 plo-network-cloud; \
	else \
		echo "🔗 Docker network plo-network-cloud already exists."; \
	fi

# Start services
up: network
	@echo "🔧 Loading environment variables..."
	@if [ -f env.local ]; then \
		export $$(grep -v '^#' env.local | xargs) && docker compose up -d; \
	else \
		echo "⚠️  env.local file not found, using system environment variables"; \
		docker compose up -d; \
	fi

# Stop services
down:
	docker compose down

# Restart services
restart: down up

# Show logs
logs:
	@if [ -f env.local ]; then \
		export $$(grep -v '^#' env.local | xargs) && docker compose logs -f; \
	else \
		docker compose logs -f; \
	fi

# Clean up
clean:
	docker compose down -v --remove-orphans
	docker system prune -f

# Pre-commit hooks
pre-commit:
	@echo "Running pre-commit hooks..."
	poetry run pre-commit run --all-files

install-hooks:
	@echo "Installing pre-commit hooks..."
	@echo "Installing poetry dependencies..."
	poetry install
	@echo "Installing pre-commit hooks..."
	@echo "Note: Temporarily using public PyPI for pre-commit dependencies..."
	PIP_INDEX_URL=https://pypi.org/simple/ poetry run pre-commit install

# Health check
health:
	@echo "Checking RabbitMQ health..."
	docker compose exec rabbitmq rabbitmq-diagnostics ping || echo "RabbitMQ is not healthy"

# Show environment info
env-info:
	@echo "Environment Information:"
	@echo "RABBITMQ_HOST: $(RABBITMQ_HOST)"
	@echo "RABBITMQ_PORT: $(RABBITMQ_PORT)"
	@echo "RABBITMQ_USERNAME: $(RABBITMQ_USERNAME)"
	@echo "RABBITMQ_VHOST: $(RABBITMQ_VHOST)"
	@echo "ENVIRONMENT: $(ENVIRONMENT)"
	@echo "BUILD_ENV: $(BUILD_ENV)"
