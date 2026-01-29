#!/bin/bash
# Deployment Configuration for PLOSolver
# This file contains all deployment-related configuration

# Staging Environment Configuration
export STAGING_HOST="${STAGING_HOST:-ploscope.com}"
export STAGING_USER="${STAGING_USER:-root}"
export STAGING_PATH="${STAGING_PATH:-/root/plo-solver}"
export SSH_KEY_PATH="${SSH_KEY_PATH:-~/.ssh/id_ed25519}"

# Application Configuration
export FRONTEND_DOMAIN="${FRONTEND_DOMAIN:-ploscope.com}"
export TRAEFIK_DOMAIN="${TRAEFIK_DOMAIN:-ploscope.com}"

# Deployment Settings
export DEPLOYMENT_BRANCH="${DEPLOYMENT_BRANCH:-master}"
export HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-https://ploscope.com}"
export HEALTH_CHECK_TIMEOUT="${HEALTH_CHECK_TIMEOUT:-10}"
export HEALTH_CHECK_RETRIES="${HEALTH_CHECK_RETRIES:-10}"

# Docker Settings
export DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
export DOCKER_PROFILE="${DOCKER_PROFILE:-app}"

# Notification Settings (for future use)
export SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
export DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
export EMAIL_NOTIFICATIONS="${EMAIL_NOTIFICATIONS:-false}"

# Logging Settings
export DEPLOYMENT_LOG_LEVEL="${DEPLOYMENT_LOG_LEVEL:-info}"
export DEPLOYMENT_LOG_FILE="${DEPLOYMENT_LOG_FILE:-/tmp/plosolver-deployment.log}"

# Backup Settings
export ENABLE_BACKUP="${ENABLE_BACKUP:-true}"
export BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Performance Settings
export DOCKER_BUILD_PARALLEL="${DOCKER_BUILD_PARALLEL:-true}"
export DOCKER_BUILD_CACHE="${DOCKER_BUILD_CACHE:-true}"

# Security Settings
export SSH_STRICT_HOST_KEY_CHECKING="${SSH_STRICT_HOST_KEY_CHECKING:-no}"
export SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-30}"
export SSH_BATCH_MODE="${SSH_BATCH_MODE:-yes}"

# Function to load environment-specific configuration
load_environment_config() {
    local env_file="env.${1:-staging}"
    
    if [ -f "$env_file" ]; then
        print_status "Loading environment configuration from $env_file"
        set -a
        source "$env_file"
        set +a
    else
        print_warning "Environment file $env_file not found, using defaults"
    fi
}

# Function to validate configuration
validate_config() {
    local errors=0
    
    # Check required variables
    if [ -z "$STAGING_HOST" ]; then
        print_error "STAGING_HOST is not set"
        ((errors++))
    fi
    
    if [ -z "$STAGING_USER" ]; then
        print_error "STAGING_USER is not set"
        ((errors++))
    fi
    
    if [ -z "$STAGING_PATH" ]; then
        print_error "STAGING_PATH is not set"
        ((errors++))
    fi
    
    if [ -z "$SSH_KEY_PATH" ]; then
        print_error "SSH_KEY_PATH is not set"
        ((errors++))
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_error "SSH key not found at $SSH_KEY_PATH"
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "Configuration validation failed with $errors error(s)"
        return 1
    fi
    
    print_success "Configuration validation passed"
    return 0
}

# Function to print configuration summary
print_config_summary() {
    echo "=== Deployment Configuration Summary ==="
    echo "Staging Host: $STAGING_HOST"
    echo "Staging User: $STAGING_USER"
    echo "Project Path: $STAGING_PATH"
    echo "SSH Key: $SSH_KEY_PATH"
    echo "Frontend Domain: $FRONTEND_DOMAIN"
    echo "Deployment Branch: $DEPLOYMENT_BRANCH"
    echo "Health Check URL: $HEALTH_CHECK_URL"
    echo "Docker Profile: $DOCKER_PROFILE"
    echo "Backup Enabled: $ENABLE_BACKUP"
    echo "========================================"
}

# Load default configuration when sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly
    echo "This script should be sourced, not executed directly."
    echo "Usage: source scripts/deploy-config.sh"
    exit 1
else
    # Script is being sourced
    print_status "Deployment configuration loaded"
fi 