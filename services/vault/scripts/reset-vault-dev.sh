#!/bin/bash

# PLO Solver Vault Reset Script (Development Mode)
# This script resets Vault and initializes it in development mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"http://localhost:8200"}
ROOT_TOKEN="plo-solver-dev-token"

echo -e "${BLUE}PLO Solver Vault Reset (Development Mode)${NC}"
echo -e "${BLUE}==========================================${NC}"

# Confirm action
echo -e "${YELLOW}⚠️  WARNING: This will delete all Vault data and reset to development mode!${NC}"
echo -e "${YELLOW}All existing secrets will be lost.${NC}"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Operation cancelled.${NC}"
    exit 1
fi

# Stop Vault
echo -e "${BLUE}Stopping Vault...${NC}"
docker-compose stop vault

# Remove Vault data
echo -e "${BLUE}Removing Vault data...${NC}"
docker-compose down
docker volume rm vault_vault-data 2>/dev/null || true

# Start Vault in development mode
echo -e "${BLUE}Starting Vault in development mode...${NC}"
docker-compose up -d vault

# Wait for Vault to be ready
echo -e "${YELLOW}Waiting for Vault to be ready...${NC}"
until curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; do
    echo "Waiting for Vault to start..."
    sleep 2
done

echo -e "${GREEN}Vault is ready!${NC}"

# Set environment variables for development mode
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_TOKEN="${ROOT_TOKEN}"

# Verify Vault is in development mode
echo -e "${BLUE}Verifying Vault status...${NC}"
vault status

# Enable KV secrets engine
echo -e "${BLUE}Enabling KV secrets engine...${NC}"
if ! vault secrets list | grep -q "secret/"; then
    vault secrets enable -path=secret kv-v2
    echo -e "${GREEN}KV secrets engine enabled${NC}"
else
    echo -e "${GREEN}KV secrets engine already enabled${NC}"
fi

# Enable transit engine
echo -e "${BLUE}Enabling transit engine...${NC}"
if ! vault secrets list | grep -q "transit/"; then
    vault secrets enable transit
    echo -e "${GREEN}Transit engine enabled${NC}"
else
    echo -e "${GREEN}Transit engine already enabled${NC}"
fi

# Create transit key
echo -e "${BLUE}Creating transit key...${NC}"
vault write -f transit/keys/plo-solver-key
echo -e "${GREEN}Transit key created${NC}"

# Load policies
echo -e "${BLUE}Loading policies...${NC}"
vault policy write plo-solver-policy config/policies/plo-solver-policy.hcl
vault policy write plo-solver-write-policy config/policies/plo-solver-write-policy.hcl
vault policy write admin-policy config/policies/admin-policy.hcl
echo -e "${GREEN}Policies loaded${NC}"

# Create application tokens
echo -e "${BLUE}Creating application tokens...${NC}"
APP_TOKEN=$(vault token create -policy=plo-solver-policy -format=json | jq -r '.auth.client_token')
WRITE_TOKEN=$(vault token create -policy=plo-solver-write-policy -format=json | jq -r '.auth.client_token')

# Save tokens to files
echo -e "${BLUE}Saving tokens...${NC}"
echo "${ROOT_TOKEN}" > scripts/root-token.txt
echo "${APP_TOKEN}" > scripts/app-token.txt
echo "${WRITE_TOKEN}" > scripts/write-token.txt
chmod 600 scripts/root-token.txt scripts/app-token.txt scripts/write-token.txt

# Create secret paths
echo -e "${BLUE}Creating secret paths...${NC}"
vault kv put secret/plo-solver/development placeholder=true
vault kv put secret/plo-solver/staging placeholder=true
vault kv put secret/plo-solver/production placeholder=true

echo -e "${GREEN}Vault reset completed successfully!${NC}"
echo
echo -e "${BLUE}Access Information:${NC}"
echo -e "  Vault UI: ${YELLOW}http://localhost:8200${NC}"
echo -e "  Root Token: ${YELLOW}${ROOT_TOKEN}${NC}"
echo -e "  Root Token File: ${YELLOW}scripts/root-token.txt${NC}"
echo -e "  App Token File: ${YELLOW}scripts/app-token.txt${NC}"
echo
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Access Vault UI at http://localhost:8200"
echo -e "2. Login with the root token: ${ROOT_TOKEN}"
echo -e "3. Load your secrets: ./scripts/load-secrets.sh development"
echo
echo -e "${YELLOW}⚠️  Remember: This is development mode - not suitable for production!${NC}" 