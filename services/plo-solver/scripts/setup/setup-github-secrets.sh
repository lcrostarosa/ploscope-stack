#!/bin/bash

# ===========================================
# GitHub Environment Secrets Setup Script
# ===========================================
# This script sets up GitHub environment secrets for the PLO Solver project
# Supports: development, staging, production environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_status $RED "GitHub CLI (gh) is not installed. Please install it first:"
        echo "  macOS: brew install gh"
        echo "  Ubuntu: sudo apt install gh"
        echo "  Or visit: https://cli.github.com/"
        exit 1
    fi
}

# Function to check if user is authenticated
check_auth() {
    if ! gh auth status &> /dev/null; then
        print_status $RED "You are not authenticated with GitHub CLI."
        print_status $YELLOW "Please run: gh auth login"
        exit 1
    fi
}

# Function to get current repository
get_repo() {
    local repo
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
    
    if [[ -z "$repo" ]]; then
        print_status $RED "Could not determine current repository."
        print_status $YELLOW "Please ensure you're in the correct repository directory."
        exit 1
    fi
    
    echo "$repo"
}

# Function to set a secret for an environment
set_environment_secret() {
    local env_name=$1
    local secret_name=$2
    local secret_value=$3
    
    print_status $BLUE "Setting secret '$secret_name' for environment '$env_name'"
    
    # Set the secret using GitHub CLI
    echo "$secret_value" | gh secret set "$secret_name" --env "$env_name" --body-file -
    
    print_status $GREEN "✅ Secret '$secret_name' set for environment '$env_name'"
}

# Function to set secrets from environment file
set_secrets_from_env_file() {
    local env_name=$1
    local env_file=$2
    
    if [[ ! -f "$env_file" ]]; then
        print_status $RED "Environment file not found: $env_file"
        return 1
    fi
    
    print_status $BLUE "Setting secrets from file: $env_file"
    
    # Read the environment file and set secrets
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        if [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Skip if key or value is empty
        if [[ -z "$key" ]] || [[ -z "$value" ]]; then
            continue
        fi
        
        # Set the secret
        set_environment_secret "$env_name" "$key" "$value"
    done < "$env_file"
    
    print_status $GREEN "✅ All secrets from $env_file set for environment '$env_name'"
}

# Function to set secrets interactively
set_secrets_interactively() {
    local env_name=$1
    local secrets=("${@:2}")
    
    print_status $BLUE "Setting secrets interactively for environment: $env_name"
    
    for secret in "${secrets[@]}"; do
        if [[ -n "$secret" ]]; then
            echo -n "Enter value for secret '$secret': "
            read -s secret_value
            echo
            
            if [[ -n "$secret_value" ]]; then
                set_environment_secret "$env_name" "$secret" "$secret_value"
            else
                print_status $YELLOW "Skipping empty secret: $secret"
            fi
        fi
    done
}

# Function to set secrets from command line arguments
set_secrets_from_args() {
    local env_name=$1
    shift
    
    print_status $BLUE "Setting secrets from command line arguments for environment: $env_name"
    
    while [[ $# -gt 0 ]]; do
        local secret_arg=$1
        shift
        
        if [[ "$secret_arg" =~ ^([^=]+)=(.*)$ ]]; then
            local secret_name="${BASH_REMATCH[1]}"
            local secret_value="${BASH_REMATCH[2]}"
            
            set_environment_secret "$env_name" "$secret_name" "$secret_value"
        else
            print_status $RED "Invalid secret format: $secret_arg (expected: NAME=VALUE)"
        fi
    done
}

# Function to list secrets for an environment
list_environment_secrets() {
    local env_name=$1
    
    print_status $BLUE "Listing secrets for environment: $env_name"
    
    local response
    response=$(gh api "repos/$(get_repo)/environments/$env_name/secrets" 2>/dev/null || echo "[]")
    
    local count
    count=$(echo "$response" | jq '.total_count // 0')
    
    if [[ "$count" -eq 0 ]]; then
        print_status $YELLOW "No secrets found for environment '$env_name'"
        return
    fi
    
    echo "$response" | jq -r '.secrets[] | "  - \(.name) (updated: \(.updated_at))"'
}

# Function to delete a secret
delete_environment_secret() {
    local env_name=$1
    local secret_name=$2
    
    print_status $BLUE "Deleting secret '$secret_name' from environment '$env_name'"
    
    gh secret delete "$secret_name" --env "$env_name" --yes
    
    print_status $GREEN "✅ Secret '$secret_name' deleted from environment '$env_name'"
}

# Function to show help
show_help() {
    cat << EOF
GitHub Environment Secrets Setup Script

Usage: $0 [OPTIONS] ENVIRONMENT [SECRETS...]

OPTIONS:
    -h, --help              Show this help message
    -l, --list              List all secrets for the specified environment
    -f, --file FILE         Set secrets from environment file (e.g., env.staging)
    -i, --interactive       Set secrets interactively (prompt for each value)
    -d, --delete SECRET     Delete a specific secret
    -a, --all               Set all common secrets for the environment

ENVIRONMENTS:
    development             Development environment
    staging                 Staging environment  
    production              Production environment

SECRETS:
    NAME=VALUE              Set a specific secret (e.g., DB_PASSWORD=mypass)

EXAMPLES:
    $0 staging --file env.staging                    # Set secrets from file
    $0 production DB_PASSWORD=mypass API_KEY=abc123  # Set specific secrets
    $0 staging --interactive                         # Set secrets interactively
    $0 production --list                             # List all secrets
    $0 staging --delete OLD_SECRET                   # Delete a secret
    $0 production --all                              # Set all common secrets

COMMON SECRETS:
    GITHUB_TOKEN           GitHub personal access token
    DB_PASSWORD            Database password
    API_KEY                API key for external services
    STRIPE_SECRET_KEY      Stripe secret key
    JWT_SECRET_KEY         JWT signing secret
    DEPLOY_KEY             SSH key for deployment

NOTES:
    - Requires GitHub CLI (gh) to be installed and authenticated
    - Secrets are encrypted and stored securely in GitHub
    - Use --interactive for sensitive secrets to avoid them in shell history
    - Environment files should contain KEY=VALUE pairs

EOF
}

# Main function
main() {
    local env_name=""
    local list_only=false
    local env_file=""
    local interactive=false
    local delete_secret=""
    local all_secrets=false
    local secrets=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            -f|--file)
                env_file="$2"
                shift 2
                ;;
            -i|--interactive)
                interactive=true
                shift
                ;;
            -d|--delete)
                delete_secret="$2"
                shift 2
                ;;
            -a|--all)
                all_secrets=true
                shift
                ;;
            development|staging|production)
                if [[ -z "$env_name" ]]; then
                    env_name="$1"
                else
                    print_status $RED "Multiple environments specified. Only one allowed."
                    exit 1
                fi
                shift
                ;;
            *=*)
                secrets+=("$1")
                shift
                ;;
            *)
                print_status $RED "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_gh_cli
    check_auth
    
    # Get repository info
    local repo
    repo=$(get_repo)
    print_status $GREEN "Working with repository: $repo"
    
    # Validate environment
    if [[ -z "$env_name" ]]; then
        print_status $RED "No environment specified."
        show_help
        exit 1
    fi
    
    # Handle list command
    if [[ "$list_only" == "true" ]]; then
        list_environment_secrets "$env_name"
        exit 0
    fi
    
    # Handle delete command
    if [[ -n "$delete_secret" ]]; then
        delete_environment_secret "$env_name" "$delete_secret"
        exit 0
    fi
    
    # Handle file-based secrets
    if [[ -n "$env_file" ]]; then
        set_secrets_from_env_file "$env_name" "$env_file"
    fi
    
    # Handle interactive secrets
    if [[ "$interactive" == "true" ]]; then
        local common_secrets=("GITHUB_TOKEN" "DB_PASSWORD" "API_KEY" "STRIPE_SECRET_KEY" "JWT_SECRET_KEY" "DEPLOY_KEY")
        set_secrets_interactively "$env_name" "${common_secrets[@]}"
    fi
    
    # Handle all secrets
    if [[ "$all_secrets" == "true" ]]; then
        print_status $YELLOW "Setting common secrets for environment: $env_name"
        
        # Define common secrets based on environment
        case "$env_name" in
            development)
                local dev_secrets=("GITHUB_TOKEN" "DB_PASSWORD")
                set_secrets_interactively "$env_name" "${dev_secrets[@]}"
                ;;
            staging)
                local staging_secrets=("GITHUB_TOKEN" "STAGING_DEPLOY_KEY" "STAGING_DB_PASSWORD" "STRIPE_SECRET_KEY")
                set_secrets_interactively "$env_name" "${staging_secrets[@]}"
                ;;
            production)
                local prod_secrets=("GITHUB_TOKEN" "PRODUCTION_DEPLOY_KEY" "PRODUCTION_DB_PASSWORD" "STRIPE_SECRET_KEY" "JWT_SECRET_KEY")
                set_secrets_interactively "$env_name" "${prod_secrets[@]}"
                ;;
        esac
    fi
    
    # Handle command line secrets
    if [[ ${#secrets[@]} -gt 0 ]]; then
        set_secrets_from_args "$env_name" "${secrets[@]}"
    fi
    
    # If no specific action was taken, show help
    if [[ -z "$env_file" ]] && [[ "$interactive" != "true" ]] && [[ "$all_secrets" != "true" ]] && [[ ${#secrets[@]} -eq 0 ]]; then
        print_status $YELLOW "No secrets specified. Use --help for usage information."
        show_help
        exit 1
    fi
    
    print_status $GREEN "🎉 Secrets setup completed successfully!"
}

# Run main function with all arguments
main "$@" 