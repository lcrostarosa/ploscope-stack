#!/bin/bash

# PLO Solver Vault Setup Script
# This script initializes Vault and sets up the necessary configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"http://localhost:8200"}
ROOT_TOKEN=${VAULT_DEV_ROOT_TOKEN_ID:-"plo-solver-dev-token"}
APP_TOKEN_NAME="plo-solver-app-token"

echo -e "${GREEN}Setting up HashiCorp Vault for PLO Solver...${NC}"

# Wait for Vault to be ready
echo -e "${YELLOW}Waiting for Vault to be ready...${NC}"
until curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; do
    echo "Waiting for Vault to start..."
    sleep 2
done

echo -e "${GREEN}Vault is ready!${NC}"

# Login with root token
echo -e "${YELLOW}Logging in with root token...${NC}"
export VAULT_TOKEN="${ROOT_TOKEN}"

# Check if Vault is already initialized
if vault status | grep -q "Initialized.*true"; then
    echo -e "${GREEN}Vault is already initialized${NC}"
else
    echo -e "${YELLOW}Initializing Vault...${NC}"
    vault operator init -key-shares=1 -key-threshold=1 -format=json > vault-keys.json
    echo -e "${GREEN}Vault initialized successfully${NC}"
    echo -e "${YELLOW}Root token: ${ROOT_TOKEN}${NC}"
    echo -e "${YELLOW}Keys saved to vault-keys.json${NC}"
fi

# Enable KV secrets engine
echo -e "${YELLOW}Enabling KV secrets engine...${NC}"
if ! vault secrets list | grep -q "secret/"; then
    vault secrets enable -path=secret kv-v2
    echo -e "${GREEN}KV secrets engine enabled${NC}"
else
    echo -e "${GREEN}KV secrets engine already enabled${NC}"
fi

# Enable transit engine for encryption
echo -e "${YELLOW}Enabling transit engine...${NC}"
if ! vault secrets list | grep -q "transit/"; then
    vault secrets enable transit
    echo -e "${GREEN}Transit engine enabled${NC}"
else
    echo -e "${GREEN}Transit engine already enabled${NC}"
fi

# Create transit key for PLO Solver
echo -e "${YELLOW}Creating transit key...${NC}"
vault write -f transit/keys/plo-solver-key
echo -e "${GREEN}Transit key created${NC}"

# Load policies
echo -e "${YELLOW}Loading policies...${NC}"
vault policy write plo-solver-policy /vault/config/policies/plo-solver-policy.hcl
vault policy write admin-policy /vault/config/policies/admin-policy.hcl
echo -e "${GREEN}Policies loaded${NC}"

# Create application token
echo -e "${YELLOW}Creating application token...${NC}"
APP_TOKEN=$(vault token create -policy=plo-solver-policy -format=json | jq -r '.auth.client_token')
echo -e "${GREEN}Application token created${NC}"

# Save token to file
echo "${APP_TOKEN}" > /vault/scripts/app-token.txt
chmod 600 /vault/scripts/app-token.txt

# Create environment directories
echo -e "${YELLOW}Creating secret paths...${NC}"
vault kv put secret/plo-solver/development placeholder=true
vault kv put secret/plo-solver/staging placeholder=true
vault kv put secret/plo-solver/production placeholder=true
echo -e "${GREEN}Secret paths created${NC}"

echo -e "${GREEN}Vault setup completed successfully!${NC}"
echo -e "${YELLOW}Vault UI available at: http://localhost:8201${NC}"
echo -e "${YELLOW}Vault API available at: ${VAULT_ADDR}${NC}"
echo -e "${YELLOW}Application token saved to: /vault/scripts/app-token.txt${NC}" 