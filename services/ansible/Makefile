# Colors for output
BLUE=\033[1;34m
GREEN=\033[1;32m
YELLOW=\033[1;33m
RED=\033[1;31m
NC=\033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

hetzner-initial-setup: ## Initial Hetzner server setup (ONE-TIME ONLY - removes root access)
	@echo "$(RED)⚠️  CRITICAL: This will remove root SSH access permanently! ⚠️$(NC)"
	@echo "$(YELLOW)This is a ONE-TIME setup. After this, you can only connect as 'appuser'.$(NC)"
	@read -p "Type 'yes' to continue with initial setup: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "$(RED)Setup aborted.$(NC)"; \
		exit 1; \
	fi
	@cd ansible-playbook -i inventories/inventory.yml --extra-vars "@variables/vars.yml" 00_root-setup.yml

hetzner-appuser: ## Configure the appuser account on the Hetzner server
	@cd ansible-playbook -i inventories/inventory.yml --extra-vars "@variables/vars.yml" 01_appuser.yml

hetzner-deploy: ## Deploy staging application to Hetzner server
	@cd ansible-playbook -i inventories/inventory.yml --extra-vars "@variables/vars.yml" 02_deploy.yml

