#!/bin/bash

# PLO Solver Vault Environment Management Script
# This script helps manage different environments (dev, staging, production) with Vault

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

# Function to display usage
usage() {
    echo "Usage: $0 <command> [environment] [options]"
    echo ""
    echo "Commands:"
    echo "  setup <env>           - Set up Vault for specific environment"
    echo "  load <env>            - Load secrets for environment"
    echo "  get <env>             - Get secrets for environment"
    echo "  deploy <env>          - Deploy application with Vault secrets"
    echo "  backup <env>          - Backup environment secrets"
    echo "  restore <env> <file>  - Restore environment secrets from backup"
    echo "  compare <env1> <env2> - Compare secrets between environments"
    echo "  validate <env>        - Validate environment configuration"
    echo "  rotate <env>          - Rotate secrets for environment"
    echo "  list                  - List all environments"
    echo "  status <env>          - Show environment status"
    echo ""
    echo "Environments:"
    echo "  development (dev)     - Development environment"
    echo "  staging (stage)       - Staging environment"
    echo "  production (prod)     - Production environment"
    echo "  test                  - Test environment"
    echo ""
    echo "Options:"
    echo "  --network <type>      - Network type: isolated, integrated, production"
    echo "  --force               - Force operations without confirmation"
    echo "  --dry-run             - Show what would be done without executing"
    echo ""
    echo "Examples:"
    echo "  $0 setup production"
    echo "  $0 load staging"
    echo "  $0 deploy production --network production"
    echo "  $0 compare staging production"
    exit 1
}

# Function to validate environment
validate_environment() {
    local env=$1
    case "$env" in
        "development"|"dev"|"staging"|"stage"|"production"|"prod"|"test")
            return 0
            ;;
        *)
            echo -e "${RED}Error: Invalid environment '$env'${NC}"
            return 1
            ;;
    esac
}

# Function to normalize environment name
normalize_environment() {
    local env=$1
    case "$env" in
        "dev") echo "development" ;;
        "stage") echo "staging" ;;
        "prod") echo "production" ;;
        *) echo "$env" ;;
    esac
}

# Function to setup environment
setup_environment() {
    local env=$1
    local network_type=${NETWORK_TYPE:-"isolated"}
    
    echo -e "${GREEN}Setting up Vault for environment: $env${NC}"
    
    # Start Vault with appropriate network configuration
    case "$network_type" in
        "isolated")
            echo -e "${YELLOW}Starting Vault in isolated mode...${NC}"
            cd "$VAULT_DIR" && ./scripts/vault-network-setup.sh isolated
            ;;
        "integrated")
            echo -e "${YELLOW}Starting Vault in integrated mode...${NC}"
            cd "$VAULT_DIR" && ./scripts/vault-network-setup.sh integrated
            ;;
        "production")
            echo -e "${YELLOW}Starting Vault in production mode...${NC}"
            cd "$VAULT_DIR" && ./scripts/vault-network-setup.sh production
            ;;
        *)
            echo -e "${RED}Error: Invalid network type '$network_type'${NC}"
            return 1
            ;;
    esac
    
    # Initialize Vault
    echo -e "${YELLOW}Initializing Vault...${NC}"
    cd "$VAULT_DIR" && ./scripts/setup-vault.sh
    
    # Load environment secrets
    echo -e "${YELLOW}Loading secrets for $env...${NC}"
    cd "$VAULT_DIR" && ./scripts/load-secrets.sh "$env"
    
    echo -e "${GREEN}Environment $env setup complete!${NC}"
}

# Function to load environment secrets
load_environment() {
    local env=$1
    
    echo -e "${GREEN}Loading secrets for environment: $env${NC}"
    
    # Check if env file exists
    local env_file="$PROJECT_ROOT/env.$env"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: Environment file not found: $env_file${NC}"
        echo -e "${YELLOW}Available environment files:${NC}"
        ls -la "$PROJECT_ROOT"/env.* 2>/dev/null || echo "No environment files found"
        return 1
    fi
    
    cd "$VAULT_DIR" && ./scripts/load-secrets.sh "$env" "$env_file"
    echo -e "${GREEN}Secrets loaded for $env!${NC}"
}

# Function to get environment secrets
get_environment() {
    local env=$1
    local output_file=${OUTPUT_FILE:-""}
    
    echo -e "${GREEN}Retrieving secrets for environment: $env${NC}"
    
    if [ -n "$output_file" ]; then
        cd "$VAULT_DIR" && ./scripts/get-secrets.sh "$env" "$output_file"
    else
        cd "$VAULT_DIR" && ./scripts/get-secrets.sh "$env"
    fi
}

# Function to deploy application with Vault
deploy_application() {
    local env=$1
    local network_type=${NETWORK_TYPE:-"isolated"}
    
    echo -e "${GREEN}Deploying application for environment: $env${NC}"
    
    # Get secrets and create .env file
    local env_file="$PROJECT_ROOT/.env.$env"
    cd "$VAULT_DIR" && ./scripts/get-secrets.sh "$env" "$env_file"
    
    # Connect application containers to Vault
    if [ "$network_type" = "isolated" ]; then
        echo -e "${YELLOW}Connecting application containers to Vault...${NC}"
        cd "$VAULT_DIR" && ./scripts/connect-app-to-vault.sh connect-all
    fi
    
    # Deploy using appropriate method
    case "$env" in
        "development"|"dev")
            echo -e "${YELLOW}Deploying development environment...${NC}"
            cd "$PROJECT_ROOT" && make dev
            ;;
        "staging"|"stage")
            echo -e "${YELLOW}Deploying staging environment...${NC}"
            cd "$PROJECT_ROOT" && make staging-deploy
            ;;
        "production"|"prod")
            echo -e "${YELLOW}Deploying production environment...${NC}"
            cd "$PROJECT_ROOT" && make production-deploy
            ;;
        *)
            echo -e "${YELLOW}Deploying $env environment...${NC}"
            cd "$PROJECT_ROOT" && docker-compose --env-file "$env_file" up -d
            ;;
    esac
    
    echo -e "${GREEN}Application deployed for $env!${NC}"
}

# Function to backup environment
backup_environment() {
    local env=$1
    
    echo -e "${GREEN}Backing up secrets for environment: $env${NC}"
    cd "$VAULT_DIR" && ./scripts/rotate-secrets.sh backup-secrets "$env"
}

# Function to restore environment
restore_environment() {
    local env=$1
    local backup_file=$2
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}Error: Backup file required for restore${NC}"
        usage
    fi
    
    echo -e "${GREEN}Restoring secrets for environment: $env from $backup_file${NC}"
    cd "$VAULT_DIR" && ./scripts/rotate-secrets.sh restore-secrets "$backup_file"
}

# Function to compare environments
compare_environments() {
    local env1=$1
    local env2=$2
    
    if [ -z "$env2" ]; then
        echo -e "${RED}Error: Two environments required for comparison${NC}"
        usage
    fi
    
    echo -e "${GREEN}Comparing secrets between $env1 and $env2${NC}"
    
    # Get secrets for both environments
    local temp1=$(mktemp)
    local temp2=$(mktemp)
    
    cd "$VAULT_DIR" && ./scripts/get-secrets.sh "$env1" > "$temp1"
    cd "$VAULT_DIR" && ./scripts/get-secrets.sh "$env2" > "$temp2"
    
    # Compare and show differences
    echo -e "${YELLOW}Differences between $env1 and $env2:${NC}"
    diff "$temp1" "$temp2" || echo "No differences found"
    
    # Clean up
    rm "$temp1" "$temp2"
}

# Function to validate environment
validate_environment_config() {
    local env=$1
    
    echo -e "${GREEN}Validating configuration for environment: $env${NC}"
    
    # Check if Vault is accessible
    if ! curl -s -f "http://localhost:8200/v1/sys/health" > /dev/null 2>&1; then
        echo -e "${RED}✗ Vault is not accessible${NC}"
        return 1
    fi
    
    # Check if secrets exist
    cd "$VAULT_DIR"
    if ./scripts/get-secrets.sh "$env" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Secrets found for $env${NC}"
    else
        echo -e "${RED}✗ No secrets found for $env${NC}"
        return 1
    fi
    
    # Check required environment variables
    local required_vars=("DATABASE_URL" "SECRET_KEY" "JWT_SECRET_KEY")
    local secrets=$(./scripts/get-secrets.sh "$env")
    
    for var in "${required_vars[@]}"; do
        if echo "$secrets" | grep -q "^$var="; then
            echo -e "${GREEN}✓ $var is configured${NC}"
        else
            echo -e "${RED}✗ $var is missing${NC}"
        fi
    done
    
    echo -e "${GREEN}Environment $env validation complete!${NC}"
}

# Function to rotate secrets
rotate_environment_secrets() {
    local env=$1
    
    echo -e "${GREEN}Rotating secrets for environment: $env${NC}"
    
    if [ "$FORCE" != "true" ]; then
        echo -e "${YELLOW}This will rotate all secrets for $env. Continue? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Secret rotation cancelled${NC}"
            return 0
        fi
    fi
    
    cd "$VAULT_DIR" && ./scripts/rotate-secrets.sh rotate-key "$env"
    echo -e "${GREEN}Secrets rotated for $env!${NC}"
}

# Function to list environments
list_environments() {
    echo -e "${GREEN}Available environments:${NC}"
    cd "$VAULT_DIR" && ./scripts/rotate-secrets.sh list-environments
}

# Function to show environment status
show_environment_status() {
    local env=$1
    
    echo -e "${GREEN}Status for environment: $env${NC}"
    
    # Check Vault status
    if curl -s -f "http://localhost:8200/v1/sys/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Vault is running${NC}"
    else
        echo -e "${RED}✗ Vault is not running${NC}"
        return 1
    fi
    
    # Check if secrets exist
    cd "$VAULT_DIR"
    if ./scripts/get-secrets.sh "$env" > /dev/null 2>&1; then
        local secret_count=$(./scripts/get-secrets.sh "$env" | wc -l)
        echo -e "${GREEN}✓ $secret_count secrets found for $env${NC}"
    else
        echo -e "${RED}✗ No secrets found for $env${NC}"
    fi
    
    # Show last modified
    echo -e "${YELLOW}Last modified: $(date)${NC}"
}

# Parse command line arguments
COMMAND=""
ENVIRONMENT=""
NETWORK_TYPE=""
FORCE="false"
DRY_RUN="false"
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --network)
            NETWORK_TYPE="$2"
            shift 2
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
        *)
            if [ -z "$COMMAND" ]; then
                COMMAND="$1"
            elif [ -z "$ENVIRONMENT" ]; then
                ENVIRONMENT="$1"
            else
                echo -e "${RED}Error: Too many arguments${NC}"
                usage
            fi
            shift
            ;;
    esac
done

# Check required arguments
if [ -z "$COMMAND" ]; then
    usage
fi

# Execute command
case "$COMMAND" in
    "setup")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for setup command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && setup_environment "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "load")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for load command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && load_environment "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "get")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for get command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && get_environment "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "deploy")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for deploy command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && deploy_application "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "backup")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for backup command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && backup_environment "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "restore")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment and backup file required for restore command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && restore_environment "$(normalize_environment "$ENVIRONMENT")" "$2"
        ;;
    "compare")
        if [ -z "$ENVIRONMENT" ] || [ -z "$2" ]; then
            echo -e "${RED}Error: Two environments required for compare command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && validate_environment "$2" && compare_environments "$(normalize_environment "$ENVIRONMENT")" "$(normalize_environment "$2")"
        ;;
    "validate")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for validate command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && validate_environment_config "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "rotate")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for rotate command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && rotate_environment_secrets "$(normalize_environment "$ENVIRONMENT")"
        ;;
    "list")
        list_environments
        ;;
    "status")
        if [ -z "$ENVIRONMENT" ]; then
            echo -e "${RED}Error: Environment required for status command${NC}"
            usage
        fi
        validate_environment "$ENVIRONMENT" && show_environment_status "$(normalize_environment "$ENVIRONMENT")"
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        usage
        ;;
esac 