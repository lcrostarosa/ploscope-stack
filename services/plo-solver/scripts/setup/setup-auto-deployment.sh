#!/bin/bash
# Setup script for automated staging deployment
# This script helps configure GitHub Actions secrets and SSH keys

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${GREEN}$1${NC}"
    echo "=================================="
}

# Function to check if running in GitHub Actions
is_github_actions() {
    [ -n "$GITHUB_ACTIONS" ]
}

# Function to check if SSH key exists
check_ssh_key() {
    local key_path="${1:-~/.ssh/id_ed25519}"
    
    if [ -f "$key_path" ]; then
        print_success "SSH key found at $key_path"
        return 0
    else
        print_warning "SSH key not found at $key_path"
        return 1
    fi
}

# Function to generate SSH key
generate_ssh_key() {
    local key_path="${1:-~/.ssh/id_ed25519}"
    
    print_status "Generating new SSH key at $key_path"
    
    if [ -f "$key_path" ]; then
        print_warning "SSH key already exists at $key_path"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "SSH key generation cancelled"
            return 1
        fi
    fi
    
    ssh-keygen -t ed25519 -f "$key_path" -N "" -C "plosolver-staging-deployment"
    print_success "SSH key generated successfully"
}

# Function to display GitHub Actions setup instructions
show_github_actions_setup() {
    print_header "GitHub Actions Setup Instructions"
    
    echo "To enable automated deployments, you need to configure the following secrets in your GitHub repository:"
    echo ""
    echo "1. Go to your GitHub repository: https://github.com/lcrostarosa/plo-solver"
    echo "2. Navigate to Settings > Secrets and variables > Actions"
    echo "3. Add the following repository secrets:"
    echo ""
    
    echo "Required Secrets:"
    echo "  STAGING_HOST: Your staging server hostname (e.g., ploscope.com)"
    echo "  STAGING_USER: SSH user for staging server (e.g., root)"
    echo "  STAGING_PATH: Project path on staging server (e.g., /root/plo-solver)"
    echo "  STAGING_SSH_KEY: Your SSH private key content"
    echo ""
    
    echo "To get your SSH private key content, run:"
    echo "  cat ~/.ssh/id_ed25519"
    echo ""
    
    echo "Optional Secrets (for notifications):"
    echo "  SLACK_WEBHOOK_URL: Slack webhook URL for deployment notifications"
    echo "  DISCORD_WEBHOOK_URL: Discord webhook URL for deployment notifications"
    echo ""
    
    print_warning "Important: Make sure your SSH public key is added to the staging server's authorized_keys"
    echo "To add your public key to the server, run:"
    echo "  ssh-copy-id -i ~/.ssh/id_ed25519.pub root@your-staging-server"
    echo ""
}

# Function to test GitHub Actions configuration
test_github_actions_config() {
    print_header "Testing GitHub Actions Configuration"
    
    if ! is_github_actions; then
        print_warning "This test can only be run in GitHub Actions environment"
        return 1
    fi
    
    # Check if required secrets are set
    local missing_secrets=()
    
    if [ -z "$STAGING_HOST" ]; then
        missing_secrets+=("STAGING_HOST")
    fi
    
    if [ -z "$STAGING_USER" ]; then
        missing_secrets+=("STAGING_USER")
    fi
    
    if [ -z "$STAGING_PATH" ]; then
        missing_secrets+=("STAGING_PATH")
    fi
    
    if [ -z "$STAGING_SSH_KEY" ]; then
        missing_secrets+=("STAGING_SSH_KEY")
    fi
    
    if [ ${#missing_secrets[@]} -gt 0 ]; then
        print_error "Missing required secrets: ${missing_secrets[*]}"
        return 1
    fi
    
    print_success "All required secrets are configured"
    return 0
}

# Function to create deployment configuration file
create_deployment_config() {
    print_header "Creating Deployment Configuration"
    
    local config_file=".deployment-config"
    
    cat > "$config_file" << EOF
# PLOSolver Deployment Configuration
# This file contains deployment settings for your staging environment

# Staging Server Configuration
STAGING_HOST=ploscope.com
STAGING_USER=root
STAGING_PATH=/root/plo-solver

# SSH Configuration
SSH_KEY_PATH=~/.ssh/id_ed25519

# Application Configuration
FRONTEND_DOMAIN=ploscope.com
TRAEFIK_DOMAIN=ploscope.com

# Deployment Settings
DEPLOYMENT_BRANCH=master
HEALTH_CHECK_URL=https://ploscope.com

# Docker Settings
DOCKER_PROFILE=app

# Backup Settings
ENABLE_BACKUP=true
BACKUP_RETENTION_DAYS=7
EOF
    
    print_success "Deployment configuration file created: $config_file"
    print_status "Edit this file to customize your deployment settings"
}

# Function to show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --setup-ssh          Generate SSH key and show setup instructions"
    echo "  --github-actions     Show GitHub Actions setup instructions"
    echo "  --create-config      Create deployment configuration file"
    echo "  --test-config        Test GitHub Actions configuration"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --setup-ssh       # Generate SSH key and show setup"
    echo "  $0 --github-actions  # Show GitHub Actions setup instructions"
    echo "  $0 --create-config   # Create deployment configuration"
}

# Main function
main() {
    case "${1:-}" in
        --setup-ssh)
            print_header "SSH Key Setup"
            if ! check_ssh_key; then
                generate_ssh_key
            fi
            show_github_actions_setup
            ;;
        --github-actions)
            show_github_actions_setup
            ;;
        --create-config)
            create_deployment_config
            ;;
        --test-config)
            test_github_actions_config
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            print_header "PLOSolver Automated Deployment Setup"
            echo "This script helps you set up automated staging deployments."
            echo ""
            echo "Available options:"
            echo "  --setup-ssh          Generate SSH key and show setup instructions"
            echo "  --github-actions     Show GitHub Actions setup instructions"
            echo "  --create-config      Create deployment configuration file"
            echo "  --test-config        Test GitHub Actions configuration"
            echo ""
            echo "Run '$0 --help' for more information"
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 