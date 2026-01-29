#!/bin/bash

# Test script for the health check functionality
# This script can be used to test the health check in different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test 1: Check if health check script exists and is executable
test_script_exists() {
    log "Testing if health check script exists and is executable..."

    if [ -f "src/scripts/health_check.sh" ]; then
        if [ -x "src/scripts/health_check.sh" ]; then
            success "Health check script exists and is executable"
            return 0
        else
            error "Health check script exists but is not executable"
            return 1
        fi
    else
        error "Health check script does not exist"
        return 1
    fi
}

# Test 2: Check script syntax
test_script_syntax() {
    log "Testing health check script syntax..."

    if bash -n src/scripts/health_check.sh; then
        success "Health check script has valid syntax"
        return 0
    else
        error "Health check script has syntax errors"
        return 1
    fi
}

# Test 3: Test individual functions (mock environment)
test_individual_functions() {
    log "Testing individual health check functions..."

    # Test that the script has the expected functions
    if grep -q "check_celery_process()" src/scripts/health_check.sh; then
        success "Script contains celery process check function"
    else
        error "Script missing celery process check function"
        return 1
    fi

    if grep -q "check_rabbitmq_connectivity()" src/scripts/health_check.sh; then
        success "Script contains RabbitMQ connectivity check function"
    else
        error "Script missing RabbitMQ connectivity check function"
        return 1
    fi

    if grep -q "check_redis_connectivity()" src/scripts/health_check.sh; then
        success "Script contains Redis connectivity check function"
    else
        error "Script missing Redis connectivity check function"
        return 1
    fi

    if grep -q "main()" src/scripts/health_check.sh; then
        success "Script contains main function"
    else
        error "Script missing main function"
        return 1
    fi

    return 0
}

# Test 4: Test Docker health check configuration
test_docker_healthcheck() {
    log "Testing Docker health check configuration..."

    # Check if Dockerfile has the correct health check
    if grep -q "HEALTHCHECK" Dockerfile && grep -q "health_check.sh" Dockerfile; then
        success "Dockerfile has correct health check configuration"
    else
        error "Dockerfile missing health check configuration"
        return 1
    fi

    # Check if docker-compose files have health check
    if grep -q "health_check.sh" docker-compose.cloud.yml; then
        success "Cloud Docker Compose has health check configuration"
    else
        error "Cloud Docker Compose missing health check configuration"
        return 1
    fi

    if grep -q "health_check.sh" docker-compose.localdev.yml; then
        success "Local dev Docker Compose has health check configuration"
    else
        error "Local dev Docker Compose missing health check configuration"
        return 1
    fi

    return 0
}

# Test 5: Test deployment workflow health check
test_deployment_healthcheck() {
    log "Testing deployment workflow health check..."

    if grep -q "Waiting for celery container to become healthy" .github/workflows/deploy.yml; then
        success "Deployment workflow has health check waiting logic"
    else
        error "Deployment workflow missing health check waiting logic"
        return 1
    fi

    return 0
}

# Main test function
main() {
    log "Starting health check tests..."

    local exit_code=0

    # Run all tests
    test_script_exists || exit_code=1
    test_script_syntax || exit_code=1
    test_individual_functions || exit_code=1
    test_docker_healthcheck || exit_code=1
    test_deployment_healthcheck || exit_code=1

    if [ $exit_code -eq 0 ]; then
        success "🎉 All health check tests passed!"
    else
        error "💥 Some health check tests failed!"
    fi

    exit $exit_code
}

# Run the main function
main "$@"
