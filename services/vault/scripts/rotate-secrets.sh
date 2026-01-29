#!/bin/bash

# PLO Solver Vault Secret Rotation Script
# This script helps rotate secrets and manage secret lifecycle

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
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  generate-secret [length]     Generate a random secret (default: 32 chars)"
    echo "  rotate-key <environment>     Rotate transit key for environment"
    echo "  backup-secrets <environment> Backup secrets to file"
    echo "  restore-secrets <file>       Restore secrets from backup file"
    echo "  list-environments            List all environments"
    echo "  list-secrets <environment>   List secrets for environment"
    echo ""
    echo "Examples:"
    echo "  $0 generate-secret 64"
    echo "  $0 rotate-key development"
    echo "  $0 backup-secrets production"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

# Check if Vault is accessible
if ! curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Vault at ${VAULT_ADDR}${NC}"
    echo -e "${YELLOW}Make sure Vault is running: docker-compose up -d${NC}"
    exit 1
fi

# Get application token
if [ -f "${SCRIPT_DIR}/app-token.txt" ]; then
    export VAULT_TOKEN=$(cat "${SCRIPT_DIR}/app-token.txt")
else
    echo -e "${RED}Error: Application token not found. Run setup-vault.sh first.${NC}"
    exit 1
fi

# Function to generate random secret
generate_secret() {
    local length=${1:-32}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Function to rotate transit key
rotate_key() {
    local environment=$1
    echo -e "${YELLOW}Rotating transit key for ${environment}...${NC}"
    vault write -f "transit/keys/plo-solver-${environment}/rotate"
    echo -e "${GREEN}Transit key rotated successfully${NC}"
}

# Function to backup secrets
backup_secrets() {
    local environment=$1
    local backup_file="backup-${environment}-$(date +%Y%m%d-%H%M%S).json"
    
    echo -e "${YELLOW}Backing up secrets for ${environment}...${NC}"
    vault kv get -format=json "secret/plo-solver/${environment}" > "$backup_file"
    echo -e "${GREEN}Secrets backed up to: $backup_file${NC}"
}

# Function to restore secrets
restore_secrets() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: Backup file not found: $backup_file${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Restoring secrets from: $backup_file${NC}"
    
    # Extract environment from filename or prompt user
    local environment
    if [[ "$backup_file" =~ backup-([^-]+)- ]]; then
        environment="${BASH_REMATCH[1]}"
    else
        read -p "Enter environment name: " environment
    fi
    
    # Restore secrets
    vault kv put "secret/plo-solver/${environment}" @="$backup_file"
    echo -e "${GREEN}Secrets restored successfully for ${environment}${NC}"
}

# Function to list environments
list_environments() {
    echo -e "${YELLOW}Available environments:${NC}"
    vault kv list secret/plo-solver/ | grep -v "Keys" | grep -v "----" | sed 's/^/  /'
}

# Function to list secrets
list_secrets() {
    local environment=$1
    echo -e "${YELLOW}Secrets for ${environment}:${NC}"
    vault kv get "secret/plo-solver/${environment}" | grep -E "^[[:space:]]*[A-Z_]+" | sed 's/^/  /'
}

# Execute command
case "$COMMAND" in
    "generate-secret")
        length=${2:-32}
        secret=$(generate_secret "$length")
        echo -e "${GREEN}Generated secret:${NC}"
        echo "$secret"
        ;;
    "rotate-key")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Environment required for rotate-key command${NC}"
            usage
        fi
        rotate_key "$2"
        ;;
    "backup-secrets")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Environment required for backup-secrets command${NC}"
            usage
        fi
        backup_secrets "$2"
        ;;
    "restore-secrets")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Backup file required for restore-secrets command${NC}"
            usage
        fi
        restore_secrets "$2"
        ;;
    "list-environments")
        list_environments
        ;;
    "list-secrets")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Environment required for list-secrets command${NC}"
            usage
        fi
        list_secrets "$2"
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        usage
        ;;
esac 