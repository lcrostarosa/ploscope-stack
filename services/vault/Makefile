# PLO Solver Vault Management Makefile
# Provides easy targets for managing Vault across different environments

.PHONY: help local staging production clean reset setup load get migrate

# Default target
help:
	@echo "PLO Solver Vault Management"
	@echo "=========================="
	@echo ""
	@echo "Environment Targets:"
	@echo "  local       - Start Vault in local development mode"
	@echo "  staging     - Start Vault in staging mode"
	@echo "  production  - Start Vault in production mode"
	@echo ""
	@echo "Workflow Targets:"
	@echo "  dev         - Bootstrap complete development environment"
	@echo "  bootstrap   - Bootstrap development environment from scratch"
	@echo "  stage       - Bootstrap staging environment"
	@echo "  prod        - Bootstrap production environment"
	@echo ""
	@echo "Operation Targets:"
	@echo "  setup       - Initialize Vault for current environment"
	@echo "  load        - Load secrets for current environment"
	@echo "  get         - Get secrets for current environment"
	@echo "  reset       - Reset Vault to development mode"
	@echo "  clean       - Stop and remove Vault containers"
	@echo "  migrate     - Migrate from JSON files to Vault"
	@echo ""
	@echo "Usage Examples:"
	@echo "  make dev            - Bootstrap complete development environment"
	@echo "  make bootstrap      - Bootstrap development from scratch"
	@echo "  make stage          - Bootstrap staging environment"
	@echo "  make prod           - Bootstrap production environment"
	@echo "  make local setup    - Start local Vault and initialize"
	@echo "  make staging load   - Load staging secrets"
	@echo "  make production get - Get production secrets"
	@echo ""

# Environment variables
ENVIRONMENT ?= local
VAULT_ADDR ?= http://localhost:8200

# Local development environment
local:
	@echo "Starting Vault in local development mode..."
	@docker-compose down 2>/dev/null || true
	@docker-compose up -d vault
	@echo "✅ Vault started in development mode"
	@echo "🌐 Vault UI: http://localhost:8200"
	@echo "🔑 Root Token: plo-solver-dev-token"

# Staging environment
staging:
	@echo "Starting Vault in staging mode..."
	@docker-compose -f docker-compose-integrated.yml down 2>/dev/null || true
	@docker-compose -f docker-compose-integrated.yml up -d vault
	@echo "✅ Vault started in staging mode"
	@echo "🌐 Vault UI: http://localhost:8200"

# Production environment
production:
	@echo "Starting Vault in production mode..."
	@echo "🔒 Using secure local data directory"
	@docker-compose -f docker-compose-production.yml down 2>/dev/null || true
	@docker-compose -f docker-compose-production.yml up -d vault
	@echo "✅ Vault started in production mode"
	@echo "🌐 Vault UI: http://localhost:8200"

# Setup Vault for current environment
setup:
	@echo "Setting up Vault for $(ENVIRONMENT) environment..."
	@if [ "$(ENVIRONMENT)" = "local" ]; then \
		./scripts/reset-vault-dev.sh; \
	elif [ "$(ENVIRONMENT)" = "staging" ]; then \
		./scripts/setup-vault.sh; \
	elif [ "$(ENVIRONMENT)" = "production" ]; then \
		./scripts/setup-vault.sh; \
	else \
		echo "❌ Unknown environment: $(ENVIRONMENT)"; \
		exit 1; \
	fi

# Load secrets for current environment
load:
	@echo "Loading secrets for $(ENVIRONMENT) environment..."
	@if [ ! -f "env.$(ENVIRONMENT)" ]; then \
		echo "❌ Environment file env.$(ENVIRONMENT) not found"; \
		echo "💡 Create it from template: cp env.example env.$(ENVIRONMENT)"; \
		exit 1; \
	fi
	@if [ "$(ENVIRONMENT)" = "local" ]; then \
		VAULT_ADDR=$(VAULT_ADDR) ./scripts/load-secrets.sh development env.local; \
	else \
		VAULT_ADDR=$(VAULT_ADDR) ./scripts/load-secrets.sh $(ENVIRONMENT) env.$(ENVIRONMENT); \
	fi
	@echo "✅ Secrets loaded for $(ENVIRONMENT)"

# Get secrets for current environment
get:
	@echo "Getting secrets for $(ENVIRONMENT) environment..."
	@if [ "$(ENVIRONMENT)" = "local" ]; then \
		VAULT_ADDR=$(VAULT_ADDR) ./scripts/get-secrets.sh development; \
	else \
		VAULT_ADDR=$(VAULT_ADDR) ./scripts/get-secrets.sh $(ENVIRONMENT); \
	fi
	@echo "✅ Secrets retrieved for $(ENVIRONMENT)"

# Get secrets and save to .env file
get-env:
	@echo "Getting secrets for $(ENVIRONMENT) environment and saving to .env..."
	@if [ "$(ENVIRONMENT)" = "local" ]; then \
		VAULT_ADDR=$(VAULT_ADDR) ./scripts/get-secrets.sh development .env; \
	else \
		VAULT_ADDR=$(VAULT_ADDR) ./scripts/get-secrets.sh $(ENVIRONMENT) .env; \
	fi
	@echo "✅ Secrets saved to .env"

# Reset Vault to development mode
reset:
	@echo "Resetting Vault to development mode..."
	@./scripts/reset-vault-dev.sh

# Clean up Vault containers and data
clean:
	@echo "Cleaning up Vault containers and data..."
	@docker-compose down 2>/dev/null || true
	@docker-compose -f docker-compose-integrated.yml down 2>/dev/null || true
	@docker-compose -f docker-compose-production.yml down 2>/dev/null || true
	@docker volume rm vault_vault-data 2>/dev/null || true
	@echo "✅ Vault containers and data cleaned up"

# Migrate from JSON files to Vault
migrate:
	@echo "Migrating from JSON files to Vault..."
	@./scripts/migrate-to-vault.sh --all

# Status check
status:
	@echo "Checking Vault status for $(ENVIRONMENT) environment..."
	@if curl -s -f "$(VAULT_ADDR)/v1/sys/health" > /dev/null 2>&1; then \
		echo "✅ Vault is running at $(VAULT_ADDR)"; \
		export VAULT_ADDR=$(VAULT_ADDR); \
		if [ -f "scripts/root-token.txt" ]; then \
			export VAULT_TOKEN=$$(cat scripts/root-token.txt); \
			vault status 2>/dev/null || echo "⚠️  Vault is running but token may be invalid"; \
		else \
			echo "⚠️  No root token file found"; \
		fi; \
	else \
		echo "❌ Vault is not running at $(VAULT_ADDR)"; \
		echo "💡 Start Vault with: make $(ENVIRONMENT)"; \
	fi

# List secrets in Vault
list-secrets:
	@echo "Listing secrets in Vault..."
	@if [ -f "scripts/app-token.txt" ]; then \
		export VAULT_ADDR=$(VAULT_ADDR); \
		export VAULT_TOKEN=$$(cat scripts/app-token.txt); \
		vault kv list secret/plo-solver/ 2>/dev/null || echo "❌ No secrets found or token invalid"; \
	else \
		echo "❌ No app token found. Run setup first: make setup"; \
	fi

# Create environment files from templates
create-env:
	@echo "Creating environment files from templates..."
	@cp env.example env.local 2>/dev/null || echo "⚠️  env.local already exists"
	@cp env.example env.staging 2>/dev/null || echo "⚠️  env.staging already exists"
	@cp env.example env.production 2>/dev/null || echo "⚠️  env.production already exists"
	@echo "✅ Environment files created"
	@echo "💡 Edit these files with your actual secrets:"
	@echo "   - env.local for development"
	@echo "   - env.staging for staging"
	@echo "   - env.production for production"

# Validate environment configuration
validate:
	@echo "Validating $(ENVIRONMENT) environment configuration..."
	@if [ ! -f "env.$(ENVIRONMENT)" ]; then \
		echo "❌ Environment file env.$(ENVIRONMENT) not found"; \
		exit 1; \
	fi
	@if [ ! -f "scripts/app-token.txt" ]; then \
		echo "❌ Vault not initialized. Run setup first: make setup"; \
		exit 1; \
	fi
	@echo "✅ Environment configuration is valid"

# Complete environment setup (without loading secrets)
setup-env: create-env $(ENVIRONMENT) setup
	@echo "✅ Complete setup for $(ENVIRONMENT) environment completed!"

# Bootstrap development environment from scratch
bootstrap: clean local setup create-env
	@echo "✅ Development environment bootstrapped!"
	@echo "🌐 Vault UI: http://localhost:8200"
	@echo "🔑 Root Token: plo-solver-dev-token"
	@echo ""
	@echo "📝 Next steps:"
	@echo "1. Edit env.local with your actual secrets"
	@echo "2. Load secrets: make ENVIRONMENT=local load"
	@echo "3. Get secrets: make ENVIRONMENT=local get-env"

# Development workflow - bootstrap everything
dev: bootstrap

# Staging workflow
stage: clean staging setup create-env
	@echo "✅ Staging environment ready!"
	@echo "🌐 Vault UI: http://localhost:8200"
	@echo ""
	@echo "📝 Next steps:"
	@echo "1. Edit env.staging with your actual secrets"
	@echo "2. Load secrets: make ENVIRONMENT=staging load"
	@echo "3. Get secrets: make ENVIRONMENT=staging get-env"

# Production workflow
prod: clean production setup create-env
	@echo "✅ Production environment ready!"
	@echo "🌐 Vault UI: http://localhost:8200"
	@echo ""
	@echo "📝 Next steps:"
	@echo "1. Edit env.production with your actual secrets"
	@echo "2. Load secrets: make ENVIRONMENT=production load"
	@echo "3. Get secrets: make ENVIRONMENT=production get-env"

# Rotate secrets for current environment
rotate:
	@echo "Rotating secrets for $(ENVIRONMENT) environment..."
	@./scripts/rotate-secrets.sh $(ENVIRONMENT)
	@echo "✅ Secrets rotated for $(ENVIRONMENT)"

# Backup Vault data
backup:
	@echo "Creating Vault backup..."
	@mkdir -p backups
	@docker exec plo-solver-vault vault operator raft snapshot save /tmp/backup.snap 2>/dev/null || \
		echo "⚠️  Raft snapshot not available, creating manual backup"
	@docker cp plo-solver-vault:/tmp/backup.snap backups/vault-backup-$$(date +%Y%m%d-%H%M%S).snap 2>/dev/null || \
		echo "✅ Manual backup created in backups/ directory"

# Restore Vault data
restore:
	@echo "Restoring Vault data..."
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "❌ Please specify backup file: make restore BACKUP_FILE=backups/vault-backup-YYYYMMDD-HHMMSS.snap"; \
		exit 1; \
	fi
	@docker cp $(BACKUP_FILE) plo-solver-vault:/tmp/restore.snap
	@docker exec plo-solver-vault vault operator raft snapshot restore /tmp/restore.snap
	@echo "✅ Vault data restored from $(BACKUP_FILE)"

# Show logs
logs:
	@echo "Showing Vault logs..."
	@docker-compose logs -f vault

# Show logs for specific environment
logs-staging:
	@docker-compose -f docker-compose-integrated.yml logs -f vault

logs-production:
	@docker-compose -f docker-compose-production.yml logs -f vault 