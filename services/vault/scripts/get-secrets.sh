#!/bin/bash

# PLO Solver Vault Secret Retrieval Script
# This script retrieves secrets from Vault and outputs them as environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"http://localhost:8200"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0 <environment> [output-file]"
    echo "  environment: development, staging, production, or test"
    echo "  output-file: optional output file (defaults to stdout)"
    echo ""
    echo "Examples:"
    echo "  $0 development"
    echo "  $0 production > .env"
    echo "  $0 staging .env.staging"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

ENVIRONMENT=$1
OUTPUT_FILE=${2:-""}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production|test)$ ]]; then
    echo -e "${RED}Error: Invalid environment. Must be development, staging, production, or test${NC}"
    usage
fi

echo -e "${GREEN}Retrieving secrets for environment: ${ENVIRONMENT}${NC}" >&2

# Check if Vault is accessible
if ! curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Vault at ${VAULT_ADDR}${NC}" >&2
    echo -e "${YELLOW}Make sure Vault is running: docker-compose up -d${NC}" >&2
    exit 1
fi

# Get application token
if [ -f "${SCRIPT_DIR}/app-token.txt" ]; then
    export VAULT_TOKEN=$(cat "${SCRIPT_DIR}/app-token.txt")
else
    echo -e "${RED}Error: Application token not found. Run setup-vault.sh first.${NC}" >&2
    exit 1
fi

# Function to output secrets
output_secrets() {
    # Get secrets from Vault
    SECRETS_JSON=$(vault kv get -format=json "secret/plo-solver/${ENVIRONMENT}" 2>/dev/null | jq -r '.data.data // .data')
    
    if [ "$SECRETS_JSON" = "null" ] || [ -z "$SECRETS_JSON" ]; then
        echo -e "${RED}Error: No secrets found for environment ${ENVIRONMENT}${NC}" >&2
        echo -e "${YELLOW}Run load-secrets.sh first to load secrets into Vault${NC}" >&2
        exit 1
    fi
    
    # Convert JSON to environment variables
    echo "$SECRETS_JSON" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"'
}

# Output secrets
if [ -n "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}Writing secrets to: $OUTPUT_FILE${NC}" >&2
    output_secrets > "$OUTPUT_FILE"
    echo -e "${GREEN}Secrets written to: $OUTPUT_FILE${NC}" >&2
else
    output_secrets
fi 