#!/bin/bash

# ===========================================
# Setup CI Environment for GitHub
# ===========================================
# This script sets up a CI environment in GitHub using env.development values

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to create CI environment
create_ci_environment() {
    local repo=$(get_repo)
    
    print_status $BLUE "Creating CI environment for repository: $repo"
    
    # Create the CI environment
    if gh api "repos/$repo/environments/ci" &> /dev/null; then
        print_status $YELLOW "CI environment already exists. Updating..."
        
        # Update environment
        gh api --method PATCH "repos/$repo/environments/ci" \
            --field name="ci" \
            --silent
    else
        print_status $GREEN "Creating new CI environment..."
        
        # Create environment without protection rules
        gh api --method POST "repos/$repo/environments" \
            --field name="ci" \
            --silent
    fi
    
    print_status $GREEN "✅ CI environment created successfully"
}

# Function to set CI environment variables from env.development
set_ci_variables() {
    local repo=$(get_repo)
    local env_file="env.development"
    
    if [[ ! -f "$env_file" ]]; then
        print_status $RED "Environment file not found: $env_file"
        exit 1
    fi
    
    print_status $BLUE "Setting CI environment variables from $env_file"
    
    # Read the environment file and set variables
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
        
        # Set the variable
        print_status $YELLOW "Setting variable: $key"
        gh api --method PUT "repos/$repo/environments/ci/variables/$key" \
            --field value="$value" \
            --silent
    done < "$env_file"
    
    print_status $GREEN "✅ CI environment variables set successfully"
}

# Function to set CI environment secrets
set_ci_secrets() {
    local repo=$(get_repo)
    
    print_status $BLUE "Setting up CI environment secrets"
    print_status $YELLOW "Note: You will need to manually set these secrets in the GitHub UI or via gh secret set"
    
    # List required secrets for CI environment
    local secrets=(
        "GITHUB_TOKEN"
        "DB_PASSWORD"
        "SECRET_KEY"
        "JWT_SECRET_KEY"
        "STRIPE_SECRET_KEY"
        "STRIPE_PUBLISHABLE_KEY"
        "STRIPE_WEBHOOK_SECRET"
    )
    
    for secret in "${secrets[@]}"; do
        print_status $YELLOW "Required secret: $secret"
    done
    
    print_status $GREEN "✅ CI environment secrets listed"
}

# Function to validate CI environment
validate_ci_environment() {
    local repo=$(get_repo)
    
    print_status $BLUE "Validating CI environment"
    
    # Check if environment exists
    if ! gh api "repos/$repo/environments/ci" &> /dev/null; then
        print_status $RED "❌ CI environment does not exist"
        return 1
    fi
    
    # Check environment variables
    local vars_response
    vars_response=$(gh api "repos/$repo/environments/ci/variables" 2>/dev/null || echo "[]")
    
    # Check secrets
    local secrets_response
    secrets_response=$(gh api "repos/$repo/environments/ci/secrets" 2>/dev/null || echo "[]")
    
    print_status $GREEN "✅ CI environment validation completed"
    print_status $BLUE "  Variables: $(echo "$vars_response" | jq '.total_count // 0')"
    print_status $BLUE "  Secrets: $(echo "$secrets_response" | jq '.total_count // 0')"
}

# Main function
main() {
    print_status $BLUE "🚀 Setting up CI environment for GitHub"
    echo
    
    # Check prerequisites
    check_gh_cli
    check_auth
    
    # Get repository info
    local repo
    repo=$(get_repo)
    print_status $GREEN "Working with repository: $repo"
    echo
    
    # Create CI environment
    create_ci_environment
    echo
    
    # Set variables from env.development
    set_ci_variables
    echo
    
    # Set up secrets
    set_ci_secrets
    echo
    
    # Validate setup
    validate_ci_environment
    echo
    
    print_status $GREEN "🎉 CI environment setup completed successfully!"
    echo
    print_status $BLUE "Next steps:"
    echo "  1. Set required secrets in GitHub UI:"
    echo "     https://github.com/$repo/settings/environments/ci"
    echo "  2. Update your workflows to use 'environment: ci'"
    echo "  3. Test the CI pipeline"
    echo
    print_status $YELLOW "For more information, see: docs/05-architecture/2025-01-20-ci-environment-integration.md"
}

# Run main function
main "$@" 