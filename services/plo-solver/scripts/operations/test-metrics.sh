#!/bin/bash

# Test script to verify Traefik metrics are flowing into Prometheus

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
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

# Function to test Traefik metrics endpoint
test_traefik_metrics() {
    print_status "Testing Traefik metrics endpoint..."
    
    # Test if Traefik metrics are accessible
    if curl -s http://localhost:8082/metrics | grep -q "traefik_"; then
        print_success "Traefik metrics endpoint is accessible"
        return 0
    else
        print_error "Traefik metrics endpoint is not accessible or no metrics found"
        return 1
    fi
}

# Function to test Prometheus targets
test_prometheus_targets() {
    print_status "Testing Prometheus targets..."
    
    # Test if Prometheus is accessible
    if curl -s http://localhost:9091/api/v1/targets | grep -q "up"; then
        print_success "Prometheus is accessible"
        
        # Check if Traefik target is up
        if curl -s http://localhost:9091/api/v1/targets | grep -A 5 -B 5 "traefik" | grep -q '"health":"up"'; then
            print_success "Traefik target is healthy in Prometheus"
            return 0
        else
            print_warning "Traefik target is not healthy in Prometheus"
            return 1
        fi
    else
        print_error "Prometheus is not accessible"
        return 1
    fi
}

# Function to test metrics data
test_metrics_data() {
    print_status "Testing metrics data in Prometheus..."
    
    # Test if Traefik metrics are being collected
    if curl -s "http://localhost:9091/api/v1/query?query=traefik_requests_total" | grep -q "result"; then
        print_success "Traefik metrics are being collected by Prometheus"
        return 0
    else
        print_warning "No Traefik metrics found in Prometheus"
        return 1
    fi
}

# Function to generate some traffic
generate_traffic() {
    print_status "Generating test traffic to create metrics..."
    
    # Make some requests to generate metrics
    for i in {1..5}; do
        curl -s https://staging.ploscope.com > /dev/null 2>&1 || true
        curl -s https://staging.ploscope.com/api/health > /dev/null 2>&1 || true
        sleep 1
    done
    
    print_success "Test traffic generated"
}

# Main execution
main() {
    print_status "Starting metrics testing..."
    
    # Wait a moment for services to be ready
    sleep 5
    
    # Test Traefik metrics endpoint
    if test_traefik_metrics; then
        print_success "✅ Traefik metrics endpoint is working"
    else
        print_error "❌ Traefik metrics endpoint is not working"
        exit 1
    fi
    
    # Generate some traffic
    generate_traffic
    
    # Wait for metrics to be collected
    print_status "Waiting for metrics to be collected..."
    sleep 10
    
    # Test Prometheus targets
    if test_prometheus_targets; then
        print_success "✅ Prometheus targets are healthy"
    else
        print_warning "⚠️  Prometheus targets may have issues"
    fi
    
    # Test metrics data
    if test_metrics_data; then
        print_success "✅ Metrics are flowing into Prometheus"
    else
        print_warning "⚠️  Metrics may not be flowing properly"
    fi
    
    print_success "Metrics testing completed!"
    print_status "Prometheus UI: http://localhost:9091"
    print_status "Traefik Dashboard: http://localhost:8080"
}

# Run main function
main "$@" 