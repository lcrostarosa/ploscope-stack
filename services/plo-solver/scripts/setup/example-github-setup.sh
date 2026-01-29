#!/bin/bash

# ===========================================
# Example GitHub Environment Setup Workflow
# ===========================================
# This script demonstrates a typical workflow for setting up GitHub environments
# for the PLO Solver project.

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

# Function to check if GitHub CLI is installed and authenticated
check_prerequisites() {
    print_status $BLUE "Checking prerequisites..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        print_status $RED "GitHub CLI (gh) is not installed."
        print_status $YELLOW "Please install it first:"
        echo "  macOS: brew install gh"
        echo "  Ubuntu: sudo apt install gh"
        echo "  Or visit: https://cli.github.com/"
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        print_status $RED "You are not authenticated with GitHub CLI."
        print_status $YELLOW "Please run: gh auth login"
        exit 1
    fi
    
    print_status $GREEN "✅ Prerequisites check passed"
}

# Function to get user confirmation
confirm_action() {
    local message=$1
    echo -n "$message (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to set up environments
setup_environments() {
    print_status $BLUE "Setting up GitHub environments..."
    
    # Create all environments
    ./scripts/setup-github-environments.sh --all
    
    print_status $GREEN "✅ Environments created successfully"
}

# Function to set up secrets for staging
setup_staging_secrets() {
    print_status $BLUE "Setting up secrets for staging environment..."
    
    if [[ -f "env.staging" ]]; then
        print_status $YELLOW "Found env.staging file. Use it to set secrets? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            ./scripts/setup-github-secrets.sh staging --file env.staging
        else
            ./scripts/setup-github-secrets.sh staging --interactive
        fi
    else
        print_status $YELLOW "No env.staging file found. Setting secrets interactively..."
        ./scripts/setup-github-secrets.sh staging --interactive
    fi
    
    print_status $GREEN "✅ Staging secrets configured"
}

# Function to set up secrets for production
setup_production_secrets() {
    print_status $BLUE "Setting up secrets for production environment..."
    
    if [[ -f "env.production" ]]; then
        print_status $YELLOW "Found env.production file. Use it to set secrets? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            ./scripts/setup-github-secrets.sh production --file env.production
        else
            ./scripts/setup-github-secrets.sh production --interactive
        fi
    else
        print_status $YELLOW "No env.production file found. Setting secrets interactively..."
        ./scripts/setup-github-secrets.sh production --interactive
    fi
    
    print_status $GREEN "✅ Production secrets configured"
}

# Function to validate setup
validate_setup() {
    print_status $BLUE "Validating environment setup..."
    
    # List all environments
    ./scripts/setup-github-environments.sh --list
    
    # Validate each environment
    for env in development staging production; do
        print_status $BLUE "Validating $env environment..."
        ./scripts/setup-github-environments.sh --validate "$env"
    done
    
    print_status $GREEN "✅ Environment validation completed"
}

# Function to show next steps
show_next_steps() {
    print_status $GREEN "🎉 GitHub environment setup completed successfully!"
    echo
    print_status $BLUE "Next steps:"
    echo "  1. Review the environments in GitHub UI:"
    echo "     https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/settings/environments"
    echo
    echo "  2. Update your GitHub Actions workflows to use these environments:"
    echo "     - Add 'environment: staging' to staging deployment jobs"
    echo "     - Add 'environment: production' to production deployment jobs"
    echo
    echo "  3. Test the deployment process:"
    echo "     - Push to main branch to trigger staging deployment"
    echo "     - Approve staging deployment to trigger production"
    echo
    echo "  4. Monitor deployments and adjust protection rules as needed"
    echo
    print_status $YELLOW "For more information, see: docs/05-architecture/2025-01-20-github-environments-setup.md"
}

# Main workflow
main() {
    print_status $BLUE "🚀 GitHub Environment Setup Workflow"
    echo
    
    # Check prerequisites
    check_prerequisites
    echo
    
    # Confirm setup
    if ! confirm_action "Do you want to set up GitHub environments for this repository?"; then
        print_status $YELLOW "Setup cancelled"
        exit 0
    fi
    echo
    
    # Set up environments
    setup_environments
    echo
    
    # Set up staging secrets
    if confirm_action "Do you want to set up secrets for the staging environment?"; then
        setup_staging_secrets
        echo
    fi
    
    # Set up production secrets
    if confirm_action "Do you want to set up secrets for the production environment?"; then
        setup_production_secrets
        echo
    fi
    
    # Validate setup
    if confirm_action "Do you want to validate the environment setup?"; then
        validate_setup
        echo
    fi
    
    # Show next steps
    show_next_steps
}

# Run main workflow
main "$@" 