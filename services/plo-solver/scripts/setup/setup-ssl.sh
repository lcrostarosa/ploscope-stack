#!/bin/bash

# PLO Solver - SSL Setup Script
# This script helps configure automatic SSL certificate generation with Let's Encrypt and Traefik

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check domain DNS
check_domain_dns() {
    local domain=$1
    print_status "Checking DNS for domain: $domain"
    
    # Get the IP address of the domain
    local domain_ip=$(dig +short $domain | head -1)
    
    if [ -z "$domain_ip" ]; then
        print_error "Could not resolve DNS for $domain"
        print_warning "Make sure your domain points to this server's IP address"
        return 1
    fi
    
    # Get the server's public IP
    local server_ip=$(curl -s ifconfig.me)
    
    if [ "$domain_ip" = "$server_ip" ]; then
        print_success "DNS is correctly configured for $domain"
        return 0
    else
        print_warning "DNS mismatch: $domain resolves to $domain_ip, but server IP is $server_ip"
        print_warning "Make sure your domain points to this server's IP address"
        return 1
    fi
}

# Function to create SSL directory structure
setup_ssl_directories() {
    print_status "Setting up SSL directories..."
    
    # Create SSL directory if it doesn't exist
    mkdir -p ssl
    
    # Set proper permissions
    chmod 700 ssl
    
    print_success "SSL directories created"
}

# Function to check environment configuration
check_environment() {
    local env_file=${1:-.env}
    
    if [ ! -f "$env_file" ]; then
        print_error "Environment file $env_file not found"
        print_status "Please copy env.example to $env_file and configure it"
        exit 1
    fi
    
    # Source the environment file
    source "$env_file"
    
    # Check required variables
    if [ -z "$FRONTEND_DOMAIN" ]; then
        print_error "FRONTEND_DOMAIN is not set in $env_file"
        exit 1
    fi
    
    if [ -z "$ACME_EMAIL" ]; then
        print_error "ACME_EMAIL is not set in $env_file"
        print_status "This is required for Let's Encrypt certificate generation"
        exit 1
    fi
    
    print_success "Environment configuration looks good"
    print_status "Domain: $FRONTEND_DOMAIN"
    print_status "Email: $ACME_EMAIL"
}

# Function to test SSL certificate
test_ssl_certificate() {
    local domain=$1
    print_status "Testing SSL certificate for $domain..."
    
    # Wait a bit for certificate generation
    sleep 10
    
    # Test HTTPS connection
    if curl -s -I "https://$domain" >/dev/null 2>&1; then
        print_success "SSL certificate is working for $domain"
        return 0
    else
        print_warning "SSL certificate test failed for $domain"
        print_status "This might be normal if the certificate is still being generated"
        return 1
    fi
}

# Function to show certificate information
show_certificate_info() {
    local domain=$1
    print_status "Certificate information for $domain:"
    
    if command_exists openssl; then
        echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | \
            openssl x509 -noout -dates -subject -issuer
    else
        print_warning "openssl not available, cannot show certificate details"
    fi
}

# Function to restart Traefik
restart_traefik() {
    print_status "Restarting Traefik to apply SSL configuration..."
    
    docker compose restart traefik
    
    # Wait for Traefik to start
    sleep 10
    
    print_success "Traefik restarted"
}

# Function to check Traefik logs for certificate issues
check_traefik_logs() {
    print_status "Checking Traefik logs for certificate generation..."
    
    docker compose logs traefik | grep -i "acme\|certificate\|letsencrypt" | tail -10
}

# Function to force certificate renewal
force_certificate_renewal() {
    local domain=$1
    print_status "Forcing certificate renewal for $domain..."
    
    # Remove existing certificate
    docker compose exec traefik rm -f /etc/certs/acme.json
    
    # Restart Traefik to trigger new certificate generation
    restart_traefik
    
    print_success "Certificate renewal triggered"
}

# Function to show SSL status
show_ssl_status() {
    local domain=$1
    print_status "SSL Status for $domain:"
    
    echo "----------------------------------------"
    echo "Domain: $domain"
    echo "Email: $ACME_EMAIL"
    echo "Certificate Storage: /etc/certs/acme.json"
    echo "----------------------------------------"
    
    # Check if certificate file exists
    if docker compose exec traefik test -f /etc/certs/acme.json; then
        print_success "Certificate file exists"
        local cert_size=$(docker compose exec traefik stat -c%s /etc/certs/acme.json)
        echo "Certificate file size: $cert_size bytes"
    else
        print_warning "Certificate file does not exist yet"
    fi
    
    # Test HTTPS
    if test_ssl_certificate "$domain"; then
        show_certificate_info "$domain"
    fi
}

# Function to show usage
show_usage() {
    echo "PLO Solver - SSL Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup [ENV_FILE]     - Set up SSL configuration"
    echo "  test [DOMAIN]        - Test SSL certificate"
    echo "  status [DOMAIN]      - Show SSL status"
    echo "  renew [DOMAIN]       - Force certificate renewal"
    echo "  logs                  - Show Traefik SSL logs"
    echo "  help                  - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup .env"
    echo "  $0 test plosolver.com"
    echo "  $0 status plosolver.com"
    echo "  $0 renew plosolver.com"
    echo ""
}

# Main script logic
main() {
    local command=${1:-help}
    local env_file=${2:-.env}
    local domain=${2:-$FRONTEND_DOMAIN}
    
    case "$command" in
        setup)
            print_status "Setting up SSL configuration..."
            check_docker
            check_environment "$env_file"
            setup_ssl_directories
            
            if [ "$FRONTEND_DOMAIN" != "localhost" ]; then
                if check_domain_dns "$FRONTEND_DOMAIN"; then
                    print_success "DNS is properly configured"
                else
                    print_warning "DNS configuration issues detected"
                    print_status "You can still proceed, but certificates may not work"
                fi
            fi
            
            print_status "Starting services with SSL configuration..."
            docker compose up -d
            
            print_success "SSL setup completed!"
            print_status "Your application should now be available at:"
            print_status "  HTTP:  http://$FRONTEND_DOMAIN"
            print_status "  HTTPS: https://$FRONTEND_DOMAIN"
            print_status ""
            print_status "Certificate generation may take a few minutes."
            print_status "Run '$0 status $FRONTEND_DOMAIN' to check progress."
            ;;
            
        test)
            if [ -z "$domain" ]; then
                print_error "Please specify a domain to test"
                exit 1
            fi
            test_ssl_certificate "$domain"
            ;;
            
        status)
            if [ -z "$domain" ]; then
                print_error "Please specify a domain to check"
                exit 1
            fi
            show_ssl_status "$domain"
            ;;
            
        renew)
            if [ -z "$domain" ]; then
                print_error "Please specify a domain to renew"
                exit 1
            fi
            force_certificate_renewal "$domain"
            ;;
            
        logs)
            check_traefik_logs
            ;;
            
        help|--help|-h)
            show_usage
            ;;
            
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 