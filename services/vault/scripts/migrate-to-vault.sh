#!/bin/bash

# PLO Solver Migration Script: JSON Files to Vault
# This script helps migrate from JSON secret files to HashiCorp Vault

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --backup-json    Create backup of current JSON files"
    echo "  --create-env     Create environment files from JSON"
    echo "  --load-vault     Load secrets into Vault"
    echo "  --remove-json    Remove JSON files from git tracking"
    echo "  --all            Run complete migration"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Complete migration"
    echo "  $0 --backup-json            # Just backup JSON files"
    echo "  $0 --create-env --load-vault # Create env files and load to Vault"
    exit 1
}

# Function to backup JSON files
backup_json_files() {
    echo -e "${BLUE}Creating backup of JSON secret files...${NC}"
    
    BACKUP_DIR="${PROJECT_ROOT}/secrets/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "${PROJECT_ROOT}/secrets/development.json" ]; then
        cp "${PROJECT_ROOT}/secrets/development.json" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ Backed up development.json${NC}"
    fi
    
    if [ -f "${PROJECT_ROOT}/secrets/staging.json" ]; then
        cp "${PROJECT_ROOT}/secrets/staging.json" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ Backed up staging.json${NC}"
    fi
    
    if [ -f "${PROJECT_ROOT}/secrets/production.json" ]; then
        cp "${PROJECT_ROOT}/secrets/production.json" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ Backed up production.json${NC}"
    fi
    
    echo -e "${GREEN}Backup created at: $BACKUP_DIR${NC}"
    echo -e "${YELLOW}⚠️  Keep this backup secure! It contains real secrets.${NC}"
}

# Function to create environment files from JSON
create_env_files() {
    echo -e "${BLUE}Creating environment files from JSON...${NC}"
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo -e "${YELLOW}Install jq: brew install jq (macOS) or apt-get install jq (Ubuntu)${NC}"
        exit 1
    fi
    
    # Create development environment file
    if [ -f "${PROJECT_ROOT}/secrets/development.json" ]; then
        echo -e "${BLUE}Creating env.development...${NC}"
        jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "${PROJECT_ROOT}/secrets/development.json" > "${PROJECT_ROOT}/env.development"
        echo -e "${GREEN}✓ Created env.development${NC}"
    else
        echo -e "${YELLOW}⚠️  development.json not found, skipping${NC}"
    fi
    
    # Create staging environment file
    if [ -f "${PROJECT_ROOT}/secrets/staging.json" ]; then
        echo -e "${BLUE}Creating env.staging...${NC}"
        jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "${PROJECT_ROOT}/secrets/staging.json" > "${PROJECT_ROOT}/env.staging"
        echo -e "${GREEN}✓ Created env.staging${NC}"
    else
        echo -e "${YELLOW}⚠️  staging.json not found, skipping${NC}"
    fi
    
    # Create production environment file
    if [ -f "${PROJECT_ROOT}/secrets/production.json" ]; then
        echo -e "${BLUE}Creating env.production...${NC}"
        jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "${PROJECT_ROOT}/secrets/production.json" > "${PROJECT_ROOT}/env.production"
        echo -e "${GREEN}✓ Created env.production${NC}"
    else
        echo -e "${YELLOW}⚠️  production.json not found, skipping${NC}"
    fi
    
    echo -e "${GREEN}Environment files created successfully!${NC}"
    echo -e "${YELLOW}⚠️  Review and edit these files if needed before loading to Vault.${NC}"
}

# Function to load secrets into Vault
load_vault() {
    echo -e "${BLUE}Loading secrets into Vault...${NC}"
    
    # Check if Vault is accessible
    if ! curl -s -f "${VAULT_ADDR:-http://localhost:8200}/v1/sys/health" > /dev/null 2>&1; then
        echo -e "${RED}Error: Cannot connect to Vault. Make sure Vault is running.${NC}"
        echo -e "${YELLOW}Start Vault: docker-compose up -d vault${NC}"
        exit 1
    fi
    
    # Check if Vault is initialized
    if [ ! -f "${SCRIPT_DIR}/app-token.txt" ]; then
        echo -e "${RED}Error: Vault not initialized. Run setup-vault.sh first.${NC}"
        exit 1
    fi
    
    # Load development secrets
    if [ -f "${PROJECT_ROOT}/env.development" ]; then
        echo -e "${BLUE}Loading development secrets...${NC}"
        VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200} ./scripts/load-secrets.sh development env.development
    fi
    
    # Load staging secrets
    if [ -f "${PROJECT_ROOT}/env.staging" ]; then
        echo -e "${BLUE}Loading staging secrets...${NC}"
        VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200} ./scripts/load-secrets.sh staging env.staging
    fi
    
    # Load production secrets
    if [ -f "${PROJECT_ROOT}/env.production" ]; then
        echo -e "${BLUE}Loading production secrets...${NC}"
        VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200} ./scripts/load-secrets.sh production env.production
    fi
    
    echo -e "${GREEN}Secrets loaded into Vault successfully!${NC}"
}

# Function to remove JSON files from git tracking
remove_json_from_git() {
    echo -e "${BLUE}Removing JSON files from git tracking...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Remove from git tracking (but keep files locally)
    if [ -f "secrets/development.json" ]; then
        git rm --cached secrets/development.json 2>/dev/null || true
        echo -e "${GREEN}✓ Removed development.json from git tracking${NC}"
    fi
    
    if [ -f "secrets/staging.json" ]; then
        git rm --cached secrets/staging.json 2>/dev/null || true
        echo -e "${GREEN}✓ Removed staging.json from git tracking${NC}"
    fi
    
    if [ -f "secrets/production.json" ]; then
        git rm --cached secrets/production.json 2>/dev/null || true
        echo -e "${GREEN}✓ Removed production.json from git tracking${NC}"
    fi
    
    echo -e "${GREEN}JSON files removed from git tracking!${NC}"
    echo -e "${YELLOW}⚠️  Commit these changes: git commit -m 'Remove actual secrets from tracking'${NC}"
}

# Function to validate setup
validate_setup() {
    echo -e "${BLUE}Validating Vault setup...${NC}"
    
    # Check if Vault is running
    if curl -s -f "${VAULT_ADDR:-http://localhost:8200}/v1/sys/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Vault is running${NC}"
    else
        echo -e "${RED}✗ Vault is not running${NC}"
        return 1
    fi
    
    # Check if app token exists
    if [ -f "${SCRIPT_DIR}/app-token.txt" ]; then
        echo -e "${GREEN}✓ Vault is initialized${NC}"
    else
        echo -e "${RED}✗ Vault is not initialized${NC}"
        return 1
    fi
    
    # Check if secrets are loaded
    export VAULT_TOKEN=$(cat "${SCRIPT_DIR}/app-token.txt" 2>/dev/null || echo "")
    if [ -n "$VAULT_TOKEN" ]; then
        if vault kv list secret/plo-solver/ 2>/dev/null | grep -q "development\|staging\|production"; then
            echo -e "${GREEN}✓ Secrets are loaded in Vault${NC}"
        else
            echo -e "${YELLOW}⚠️  No secrets found in Vault${NC}"
        fi
    fi
    
    echo -e "${GREEN}Validation complete!${NC}"
}

# Main script logic
if [ $# -eq 0 ]; then
    usage
fi

# Parse arguments
BACKUP_JSON=false
CREATE_ENV=false
LOAD_VAULT=false
REMOVE_JSON=false
RUN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-json)
            BACKUP_JSON=true
            shift
            ;;
        --create-env)
            CREATE_ENV=true
            shift
            ;;
        --load-vault)
            LOAD_VAULT=true
            shift
            ;;
        --remove-json)
            REMOVE_JSON=true
            shift
            ;;
        --all)
            RUN_ALL=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Run all steps if --all is specified
if [ "$RUN_ALL" = true ]; then
    BACKUP_JSON=true
    CREATE_ENV=true
    LOAD_VAULT=true
    REMOVE_JSON=true
fi

echo -e "${BLUE}PLO Solver Migration: JSON Files to Vault${NC}"
echo -e "${BLUE}===========================================${NC}"

# Execute requested steps
if [ "$BACKUP_JSON" = true ]; then
    backup_json_files
    echo
fi

if [ "$CREATE_ENV" = true ]; then
    create_env_files
    echo
fi

if [ "$LOAD_VAULT" = true ]; then
    load_vault
    echo
fi

if [ "$REMOVE_JSON" = true ]; then
    remove_json_from_git
    echo
fi

# Validate setup
validate_setup

echo
echo -e "${GREEN}Migration completed successfully!${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Review the created environment files"
echo -e "2. Test your application with Vault secrets"
echo -e "3. Commit the git changes (removal of JSON files)"
echo -e "4. Update your deployment scripts to use Vault"
echo
echo -e "${YELLOW}For more information, see: SECRETS_SETUP.md${NC}" 