#!/bin/bash

# Script to scale Celery workers for better performance
# Usage: ./scale-celery-workers.sh [environment] [number_of_workers]

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

# Default values
ENVIRONMENT=${1:-production}
WORKER_COUNT=${2:-2}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_error "Valid environments: development, staging, production"
    exit 1
fi

# Validate worker count
if [[ ! "$WORKER_COUNT" =~ ^[0-9]+$ ]] || [ "$WORKER_COUNT" -lt 1 ] || [ "$WORKER_COUNT" -gt 10 ]; then
    print_error "Invalid worker count: $WORKER_COUNT"
    print_error "Worker count must be between 1 and 10"
    exit 1
fi

print_status "Scaling Celery workers for environment: $ENVIRONMENT"
print_status "Target worker count: $WORKER_COUNT"

# Determine docker-compose file
case $ENVIRONMENT in
    development)
        COMPOSE_FILE="docker-compose-localdev.yml"
        ;;
    staging)
        COMPOSE_FILE="docker-compose.staging.yml"
        ;;
    production)
        COMPOSE_FILE="docker-compose.production.yml"
        ;;
esac

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "Docker Compose file not found: $COMPOSE_FILE"
    exit 1
fi

print_status "Using Docker Compose file: $COMPOSE_FILE"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi

# Check current worker count
print_status "Checking current Celery worker status..."
CURRENT_WORKERS=$(docker compose -f "$COMPOSE_FILE" ps --filter "name=celeryworker" --format "table {{.Names}}" | grep -c celeryworker || echo "0")

print_status "Current Celery workers: $CURRENT_WORKERS"

if [ "$CURRENT_WORKERS" -eq "$WORKER_COUNT" ]; then
    print_success "Celery workers are already at the target count ($WORKER_COUNT)"
    exit 0
fi

# Scale Celery workers
print_status "Scaling Celery workers to $WORKER_COUNT..."

if docker compose -f "$COMPOSE_FILE" up -d --scale celeryworker=$WORKER_COUNT; then
    print_success "Successfully scaled Celery workers to $WORKER_COUNT"
    
    # Wait a moment for workers to start
    print_status "Waiting for workers to start..."
    sleep 10
    
    # Check final status
    FINAL_WORKERS=$(docker compose -f "$COMPOSE_FILE" ps --filter "name=celeryworker" --format "table {{.Names}}" | grep -c celeryworker || echo "0")
    
    if [ "$FINAL_WORKERS" -eq "$WORKER_COUNT" ]; then
        print_success "All $WORKER_COUNT Celery workers are running"
        
        # Show worker status
        print_status "Celery worker status:"
        docker compose -f "$COMPOSE_FILE" ps --filter "name=celeryworker"
        
        # Show health check
        print_status "Checking worker health..."
        docker compose -f "$COMPOSE_FILE" logs --tail=20 celeryworker | grep -E "(Starting|ready|healthy|error)" || true
        
    else
        print_warning "Expected $WORKER_COUNT workers but found $FINAL_WORKERS"
        print_status "Checking for any startup issues..."
        docker compose -f "$COMPOSE_FILE" logs --tail=50 celeryworker
    fi
    
else
    print_error "Failed to scale Celery workers"
    print_status "Checking for errors..."
    docker compose -f "$COMPOSE_FILE" logs --tail=50 celeryworker
    exit 1
fi

print_success "Celery worker scaling completed!"
print_status "You can monitor worker performance with:"
echo "  docker compose -f $COMPOSE_FILE logs -f celeryworker"
echo "  docker compose -f $COMPOSE_FILE ps" 