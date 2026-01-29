#!/bin/bash

# ===========================================
# GitHub Environment Setup Script
# ===========================================
# This script sets up GitHub environments for the PLO Solver project
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
REPO_NAME="PLOSolver"

# Environment configurations
declare -A ENVIRONMENTS=(
    ["development"]="Development environment for local testing and development"
    ["staging"]="Staging environment for pre-production testing"
    ["production"]="Production environment for live deployment"
)

# Required secrets for each environment
declare -A REQUIRED_SECRETS=(
    ["development"]="GITHUB_TOKEN"
    ["staging"]="GITHUB_TOKEN,STAGING_DEPLOY_KEY,STAGING_DB_PASSWORD"
    ["production"]="GITHUB_TOKEN,PRODUCTION_DEPLOY_KEY,PRODUCTION_DB_PASSWORD,STRIPE_SECRET_KEY"
)

# Required variables for each environment
declare -A REQUIRED_VARIABLES=(
    ["development"]="ENVIRONMENT=development,FRONTEND_URL=http://localhost:3000"
    ["staging"]="ENVIRONMENT=staging,FRONTEND_URL=https://staging.plosolver.com"
    ["production"]="ENVIRONMENT=production,FRONTEND_URL=https://plosolver.com"
)

# Protection rules
declare -A PROTECTION_RULES=(
    ["development"]="false"
    ["staging"]="true"
    ["production"]="true"
)

# Required reviewers for protected environments
declare -A REQUIRED_REVIEWERS=(
    ["development"]=""
    ["staging"]="lucascrostarosa"
    ["production"]="lucascrostarosa"
)

# Wait timer for protected environments (in minutes)
declare -A WAIT_TIMERS=(
    ["development"]="0"
    ["staging"]="5"
    ["production"]="10"
)

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

# Function to create environment
create_environment() {
    local env_name=$1
    local description=$2
    local protection=$3
    local wait_timer=$4
    local reviewers=$5
    
    print_status $BLUE "Creating environment: $env_name"
    
    # Create the environment
    if gh api "repos/$(get_repo)/environments/$env_name" &> /dev/null; then
        print_status $YELLOW "Environment '$env_name' already exists. Updating..."
        
        # Update environment
        gh api --method PATCH "repos/$(get_repo)/environments/$env_name" \
            --field name="$env_name" \
            --field protection_rules="[{\"id\":1,\"node_id\":\"MDQ6RW52aXJvbm1lbnRQcm90ZWN0aW9uUnVsZTE=\",\"type\":\"wait_timer\",\"wait_timer\":$wait_timer},{\"id\":2,\"node_id\":\"MDQ6RW52aXJvbm1lbnRQcm90ZWN0aW9uUnVsZTI=\",\"type\":\"required_reviewers\",\"reviewers\":[{\"type\":\"User\",\"reviewer\":{\"login\":\"$reviewers\"}}]}]" \
            --silent
    else
        print_status $GREEN "Creating new environment: $env_name"
        
        # Create environment with protection rules
        gh api --method POST "repos/$(get_repo)/environments" \
            --field name="$env_name" \
            --field protection_rules="[{\"type\":\"wait_timer\",\"wait_timer\":$wait_timer},{\"type\":\"required_reviewers\",\"reviewers\":[{\"type\":\"User\",\"reviewer\":{\"login\":\"$reviewers\"}}]}]" \
            --silent
    fi
    
    print_status $GREEN "✅ Environment '$env_name' configured successfully"
}

# Function to set environment variables
set_environment_variables() {
    local env_name=$1
    local variables=$2
    
    print_status $BLUE "Setting variables for environment: $env_name"
    
    # Split variables string and set each one
    IFS=',' read -ra VAR_ARRAY <<< "$variables"
    for var in "${VAR_ARRAY[@]}"; do
        if [[ -n "$var" ]]; then
            local key="${var%%=*}"
            local value="${var#*=}"
            
            print_status $YELLOW "Setting variable: $key"
            gh api --method PUT "repos/$(get_repo)/environments/$env_name/variables/$key" \
                --field value="$value" \
                --silent
        fi
    done
    
    print_status $GREEN "✅ Variables set for environment '$env_name'"
}

# Function to set environment secrets
set_environment_secrets() {
    local env_name=$1
    local secrets=$2
    
    print_status $BLUE "Setting secrets for environment: $env_name"
    print_status $YELLOW "Note: You will need to manually set these secrets in the GitHub UI or via gh secret set"
    
    # Split secrets string and list each one
    IFS=',' read -ra SECRET_ARRAY <<< "$secrets"
    for secret in "${SECRET_ARRAY[@]}"; do
        if [[ -n "$secret" ]]; then
            print_status $YELLOW "Required secret: $secret"
        fi
    done
    
    print_status $GREEN "✅ Secret requirements listed for environment '$env_name'"
}

# Function to create deployment protection rules
create_deployment_protection_rules() {
    local env_name=$1
    local protection=$2
    
    if [[ "$protection" == "true" ]]; then
        print_status $BLUE "Setting up deployment protection rules for: $env_name"
        
        # Create deployment branch policy
        gh api --method PUT "repos/$(get_repo)/environments/$env_name/deployment-branch-policies" \
            --field name_pattern="main" \
            --silent
        
        print_status $GREEN "✅ Deployment protection rules configured for '$env_name'"
    else
        print_status $YELLOW "Skipping deployment protection for '$env_name' (not required)"
    fi
}

# Function to validate environment configuration
validate_environment() {
    local env_name=$1
    
    print_status $BLUE "Validating environment: $env_name"
    
    # Check if environment exists
    if ! gh api "repos/$(get_repo)/environments/$env_name" &> /dev/null; then
        print_status $RED "❌ Environment '$env_name' does not exist"
        return 1
    fi
    
    # Check environment variables
    local vars_response
    vars_response=$(gh api "repos/$(get_repo)/environments/$env_name/variables" 2>/dev/null || echo "[]")
    
    # Check secrets
    local secrets_response
    secrets_response=$(gh api "repos/$(get_repo)/environments/$env_name/secrets" 2>/dev/null || echo "[]")
    
    print_status $GREEN "✅ Environment '$env_name' validation completed"
    print_status $BLUE "  Variables: $(echo "$vars_response" | jq '.total_count // 0')"
    print_status $BLUE "  Secrets: $(echo "$secrets_response" | jq '.total_count // 0')"
}

# Function to list all environments
list_environments() {
    print_status $BLUE "Listing all environments for repository: $(get_repo)"
    
    local response
    response=$(gh api "repos/$(get_repo)/environments" 2>/dev/null || echo "[]")
    
    local count
    count=$(echo "$response" | jq '.total_count // 0')
    
    if [[ "$count" -eq 0 ]]; then
        print_status $YELLOW "No environments found"
        return
    fi
    
    echo "$response" | jq -r '.environments[] | "  - \(.name) (\(.protection_rules | length) protection rules)"'
}

# Function to show help
show_help() {
    cat << EOF
GitHub Environment Setup Script

Usage: $0 [OPTIONS] [ENVIRONMENT...]

OPTIONS:
    -h, --help              Show this help message
    -l, --list              List all existing environments
    -v, --validate          Validate existing environments
    -a, --all               Set up all environments (development, staging, production)
    -c, --create-only       Only create environments, skip variables and secrets
    -f, --force             Force recreation of existing environments

ENVIRONMENTS:
    development             Set up development environment
    staging                 Set up staging environment  
    production              Set up production environment

EXAMPLES:
    $0 --all                    # Set up all environments
    $0 staging production       # Set up staging and production only
    $0 --list                   # List existing environments
    $0 --validate staging       # Validate staging environment
    $0 --create-only --all      # Create environments without setting variables

NOTES:
    - Requires GitHub CLI (gh) to be installed and authenticated
    - Secrets must be set manually in GitHub UI or via 'gh secret set'
    - Protected environments require approval from specified reviewers
    - Wait timers are applied to protected environments

EOF
}

# Main function
main() {
    local environments=()
    local list_only=false
    local validate_only=false
    local create_only=false
    local force=false
    local all_environments=false
    
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
            -v|--validate)
                validate_only=true
                shift
                ;;
            -a|--all)
                all_environments=true
                shift
                ;;
            -c|--create-only)
                create_only=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            development|staging|production)
                environments+=("$1")
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
    
    # Handle list command
    if [[ "$list_only" == "true" ]]; then
        list_environments
        exit 0
    fi
    
    # Determine which environments to process
    if [[ "$all_environments" == "true" ]]; then
        environments=("development" "staging" "production")
    elif [[ ${#environments[@]} -eq 0 ]]; then
        print_status $RED "No environments specified. Use --all or specify individual environments."
        show_help
        exit 1
    fi
    
    # Process each environment
    for env in "${environments[@]}"; do
        if [[ ! -v ENVIRONMENTS[$env] ]]; then
            print_status $RED "Unknown environment: $env"
            continue
        fi
        
        print_status $BLUE "Processing environment: $env"
        
        if [[ "$validate_only" == "true" ]]; then
            validate_environment "$env"
        else
            # Create environment
            create_environment "$env" \
                "${ENVIRONMENTS[$env]}" \
                "${PROTECTION_RULES[$env]}" \
                "${WAIT_TIMERS[$env]}" \
                "${REQUIRED_REVIEWERS[$env]}"
            
            # Set up deployment protection
            create_deployment_protection_rules "$env" "${PROTECTION_RULES[$env]}"
            
            # Set variables and secrets (unless create-only)
            if [[ "$create_only" != "true" ]]; then
                set_environment_variables "$env" "${REQUIRED_VARIABLES[$env]}"
                set_environment_secrets "$env" "${REQUIRED_SECRETS[$env]}"
            fi
            
            # Validate the environment
            validate_environment "$env"
        fi
        
        echo
    done
    
    print_status $GREEN "🎉 Environment setup completed successfully!"
    
    if [[ "$create_only" != "true" ]]; then
        echo
        print_status $YELLOW "Next steps:"
        echo "  1. Set required secrets in GitHub UI or via 'gh secret set'"
        echo "  2. Configure deployment workflows to use these environments"
        echo "  3. Test deployments to each environment"
    fi
}

# Run main function with all arguments
main "$@" 