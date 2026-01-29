#!/bin/bash

# ===========================================
# Set CI Environment Variables
# ===========================================
# This script sets CI environment variables from env.development
# Run this AFTER manually creating the CI environment in GitHub

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
    repo=$(git remote get-url origin | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\)\.git/\1/')
    
    if [[ -z "$repo" ]]; then
        print_status $RED "Could not determine current repository."
        print_status $YELLOW "Please ensure you're in the correct repository directory."
        exit 1
    fi
    
    echo "$repo"
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
    print_status $BLUE "Repository: $repo"
    echo
    
    # Read the environment file and set variables
    local count=0
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
        if gh api --method PUT "repos/$repo/environments/ci/variables/$key" \
            --field value="$value" \
            --silent; then
            print_status $GREEN "  ✅ Set $key"
            ((count++))
        else
            print_status $RED "  ❌ Failed to set $key"
        fi
    done < "$env_file"
    
    print_status $GREEN "✅ Set $count CI environment variables successfully"
}

# Function to list required secrets
list_required_secrets() {
    print_status $BLUE "Required secrets for CI environment:"
    echo
    print_status $YELLOW "You need to manually set these secrets in GitHub UI:"
    echo "  https://github.com/$(get_repo)/settings/environments/ci"
    echo
    
    local secrets=(
        "GITHUB_TOKEN (usually auto-provided)"
        "DB_PASSWORD=postgres"
        "SECRET_KEY=dev-secret-key-change-in-production"
        "JWT_SECRET_KEY=your-jwt-secret-key-here"
        "STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here"
        "STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here"
        "STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here"
    )
    
    for secret in "${secrets[@]}"; do
        print_status $YELLOW "  - $secret"
    done
    
    echo
    print_status $GREEN "✅ Secret requirements listed"
}

# Function to validate CI environment
validate_ci_environment() {
    local repo=$(get_repo)
    
    print_status $BLUE "Validating CI environment"
    
    # Check if environment exists
    if ! gh api "repos/$repo/environments/ci" &> /dev/null; then
        print_status $RED "❌ CI environment does not exist"
        print_status $YELLOW "Please create the CI environment manually first:"
        echo "  https://github.com/$repo/settings/environments"
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
    print_status $BLUE "🚀 Setting up CI environment variables"
    echo
    
    # Check prerequisites
    check_gh_cli
    check_auth
    
    # Get repository info
    local repo
    repo=$(get_repo)
    print_status $GREEN "Working with repository: $repo"
    echo
    
    # Validate environment exists
    validate_ci_environment
    echo
    
    # Set variables from env.development
    set_ci_variables
    echo
    
    # List required secrets
    list_required_secrets
    echo
    
    print_status $GREEN "🎉 CI environment variables setup completed!"
    echo
    print_status $BLUE "Next steps:"
    echo "  1. Set required secrets in GitHub UI:"
    echo "     https://github.com/$repo/settings/environments/ci"
    echo "  2. Test the CI pipeline"
    echo "  3. Monitor workflows to ensure they use the correct environment values"
    echo
    print_status $YELLOW "For more information, see: scripts/setup-ci-environment-manual.md"
}

# Run main function
main "$@" 