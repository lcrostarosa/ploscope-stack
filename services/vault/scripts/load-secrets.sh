#!/bin/bash

# PLO Solver Vault Secret Loading Script
# This script loads environment variables from env files into Vault

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"http://localhost:8200"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

# Function to display usage
usage() {
    echo "Usage: $0 <environment> [env-file-path]"
    echo "  environment: development, staging, production, or test"
    echo "  env-file-path: optional path to env file (defaults to env.<environment>)"
    echo ""
    echo "Examples:"
    echo "  $0 development"
    echo "  $0 production /path/to/custom.env"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

ENVIRONMENT=$1
ENV_FILE=${2:-"${PROJECT_ROOT}/env.${ENVIRONMENT}"}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production|test)$ ]]; then
    echo -e "${RED}Error: Invalid environment. Must be development, staging, production, or test${NC}"
    usage
fi

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: Environment file not found: $ENV_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Loading secrets for environment: ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}Source file: $ENV_FILE${NC}"

# Check if Vault is accessible
if ! curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Vault at ${VAULT_ADDR}${NC}"
    echo -e "${YELLOW}Make sure Vault is running: docker-compose up -d${NC}"
    exit 1
fi

# Get write token for loading secrets
if [ -f "${SCRIPT_DIR}/write-token.txt" ]; then
    export VAULT_TOKEN=$(cat "${SCRIPT_DIR}/write-token.txt")
elif [ -f "${SCRIPT_DIR}/app-token.txt" ]; then
    export VAULT_TOKEN=$(cat "${SCRIPT_DIR}/app-token.txt")
else
    echo -e "${RED}Error: No token found. Run setup-vault.sh first.${NC}"
    exit 1
fi

# Parse env file and create JSON for Vault
echo -e "${YELLOW}Parsing environment file...${NC}"

# Create temporary JSON file
TEMP_JSON=$(mktemp)

# Initialize JSON object
echo "{" > "$TEMP_JSON"

# Read env file line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Parse key=value pairs
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Remove quotes from value if present
        value=$(echo "$value" | sed 's/^"//;s/"$//;s/^'"'"'//;s/'"'"'$//')
        
        # Escape quotes in value for JSON
        value=$(echo "$value" | sed 's/"/\\"/g')
        
        # Add to JSON (check if it's the first entry)
        if [ "$(wc -l < "$TEMP_JSON")" -eq 1 ]; then
            echo "  \"$key\": \"$value\"" >> "$TEMP_JSON"
        else
            echo "  ,\"$key\": \"$value\"" >> "$TEMP_JSON"
        fi
    fi
done < "$ENV_FILE"

# Close JSON object
echo "}" >> "$TEMP_JSON"

# Load secrets into Vault
echo -e "${YELLOW}Loading secrets into Vault...${NC}"
vault kv put "secret/plo-solver/${ENVIRONMENT}" @="$TEMP_JSON"

# Clean up temporary file
rm "$TEMP_JSON"

echo -e "${GREEN}Successfully loaded secrets for ${ENVIRONMENT} environment${NC}"
echo -e "${YELLOW}Secrets stored at: secret/plo-solver/${ENVIRONMENT}${NC}"

# List the secrets (without values)
echo -e "${YELLOW}Loaded secrets:${NC}"
vault kv get "secret/plo-solver/${ENVIRONMENT}" | grep -E "^[[:space:]]*[A-Z_]+" | head -20 