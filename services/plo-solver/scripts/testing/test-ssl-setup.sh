#!/bin/bash

# PLO Solver - SSL Setup Test Script
# This script tests the SSL certificate setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running"
        return 1
    fi
    print_success "Docker is running"
    return 0
}

# Function to check if Traefik is running
check_traefik() {
    if docker compose ps traefik | grep -q "Up"; then
        print_success "Traefik is running"
        return 0
    else
        print_error "Traefik is not running"
        return 1
    fi
}

# Function to check environment variables
check_environment() {
    local env_file=${1:-.env}
    
    if [ ! -f "$env_file" ]; then
        print_error "Environment file $env_file not found"
        return 1
    fi
    
    # Source the environment file
    source "$env_file"
    
    if [ -z "$FRONTEND_DOMAIN" ]; then
        print_error "FRONTEND_DOMAIN is not set"
        return 1
    fi
    
    if [ -z "$ACME_EMAIL" ]; then
        print_warning "ACME_EMAIL is not set (SSL will be disabled)"
        return 0
    fi
    
    print_success "Environment variables are configured"
    print_status "Domain: $FRONTEND_DOMAIN"
    print_status "Email: $ACME_EMAIL"
    return 0
}

# Function to test HTTP access
test_http() {
    local domain=$1
    print_status "Testing HTTP access to $domain..."
    
    if curl -s -I "http://$domain" >/dev/null 2>&1; then
        print_success "HTTP access works"
        return 0
    else
        print_error "HTTP access failed"
        return 1
    fi
}

# Function to test HTTPS access
test_https() {
    local domain=$1
    print_status "Testing HTTPS access to $domain..."
    
    if curl -s -I "https://$domain" >/dev/null 2>&1; then
        print_success "HTTPS access works"
        return 0
    else
        print_warning "HTTPS access failed (certificate may still be generating)"
        return 1
    fi
}

# Function to check certificate file
check_certificate_file() {
    print_status "Checking certificate file..."
    
    if docker compose exec traefik test -f /etc/certs/acme.json 2>/dev/null; then
        local cert_size=$(docker compose exec traefik stat -c%s /etc/certs/acme.json 2>/dev/null || echo "0")
        if [ "$cert_size" -gt 100 ]; then
            print_success "Certificate file exists and has content ($cert_size bytes)"
            return 0
        else
            print_warning "Certificate file exists but is small ($cert_size bytes)"
            return 1
        fi
    else
        print_warning "Certificate file does not exist yet"
        return 1
    fi
}

# Function to check Traefik logs for SSL activity
check_ssl_logs() {
    print_status "Checking Traefik logs for SSL activity..."
    
    local ssl_logs=$(docker compose logs traefik 2>/dev/null | grep -i "acme\|certificate\|letsencrypt" | tail -5)
    
    if [ -n "$ssl_logs" ]; then
        print_success "SSL activity found in logs:"
        echo "$ssl_logs"
        return 0
    else
        print_warning "No SSL activity found in recent logs"
        return 1
    fi
}

# Function to test certificate details
test_certificate_details() {
    local domain=$1
    print_status "Testing certificate details for $domain..."
    
    if command -v openssl >/dev/null 2>&1; then
        local cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null || echo "")
        
        if [ -n "$cert_info" ]; then
            print_success "Certificate details:"
            echo "$cert_info"
            return 0
        else
            print_warning "Could not retrieve certificate details"
            return 1
        fi
    else
        print_warning "openssl not available, skipping certificate details"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    local env_file=${1:-.env}
    local domain=${2:-}
    
    print_status "Running SSL setup tests..."
    echo "=================================="
    
    # Check Docker
    if ! check_docker; then
        print_error "Docker is required for SSL tests"
        return 1
    fi
    
    # Check environment
    if ! check_environment "$env_file"; then
        print_error "Environment configuration failed"
        return 1
    fi
    
    # Get domain from environment if not provided
    if [ -z "$domain" ]; then
        source "$env_file"
        domain="$FRONTEND_DOMAIN"
    fi
    
    # Check Traefik
    if ! check_traefik; then
        print_error "Traefik is required for SSL tests"
        return 1
    fi
    
    # Test HTTP access
    test_http "$domain"
    
    # Test HTTPS access
    test_https "$domain"
    
    # Check certificate file
    check_certificate_file
    
    # Check SSL logs
    check_ssl_logs
    
    # Test certificate details
    test_certificate_details "$domain"
    
    echo "=================================="
    print_status "SSL setup tests completed"
}

# Function to show usage
show_usage() {
    echo "PLO Solver - SSL Setup Test Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --env-file FILE    Environment file to use (default: .env)"
    echo "  -d, --domain DOMAIN    Domain to test (default: from env file)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Test with default .env file"
    echo "  $0 -e env.production  # Test with production env file"
    echo "  $0 -d plosolver.com   # Test specific domain"
    echo ""
}

# Parse command line arguments
ENV_FILE=".env"
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run tests
run_all_tests "$ENV_FILE" "$DOMAIN" 