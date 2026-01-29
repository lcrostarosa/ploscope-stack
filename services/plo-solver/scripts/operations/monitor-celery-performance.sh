#!/bin/bash

# Script to monitor Celery worker performance and CPU usage
# Usage: ./monitor-celery-performance.sh [environment] [duration_minutes]

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
DURATION=${2:-5}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_error "Valid environments: development, staging, production"
    exit 1
fi

# Validate duration
if [[ ! "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ] || [ "$DURATION" -gt 60 ]; then
    print_error "Invalid duration: $DURATION"
    print_error "Duration must be between 1 and 60 minutes"
    exit 1
fi

print_status "Monitoring Celery performance for environment: $ENVIRONMENT"
print_status "Monitoring duration: $DURATION minutes"

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi

# Get Celery worker containers
WORKER_CONTAINERS=$(docker compose -f "$COMPOSE_FILE" ps --filter "name=celeryworker" --format "{{.Names}}")

if [ -z "$WORKER_CONTAINERS" ]; then
    print_error "No Celery worker containers found"
    exit 1
fi

print_status "Found Celery worker containers:"
echo "$WORKER_CONTAINERS"

# Create monitoring directory
MONITOR_DIR="./logs/celery-monitoring"
mkdir -p "$MONITOR_DIR"

# Generate timestamp for this monitoring session
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MONITOR_FILE="$MONITOR_DIR/celery_performance_${ENVIRONMENT}_${TIMESTAMP}.log"

print_status "Starting performance monitoring..."
print_status "Log file: $MONITOR_FILE"

# Function to get container stats
get_container_stats() {
    local container=$1
    local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}")
    echo "$stats" | grep "$container" || echo "Container $container not found"
}

# Function to get Celery worker status
get_celery_status() {
    local container=$1
    docker exec "$container" ps aux | grep celery || echo "No Celery processes found"
}

# Function to get queue status
get_queue_status() {
    print_status "RabbitMQ Queue Status:"
    docker compose -f "$COMPOSE_FILE" exec rabbitmq rabbitmqctl list_queues name messages consumers | grep -E "(spot_simulation|solver_analysis)" || echo "No queues found"
}

# Main monitoring loop
{
    echo "=== Celery Performance Monitoring Started ==="
    echo "Environment: $ENVIRONMENT"
    echo "Duration: $DURATION minutes"
    echo "Timestamp: $(date)"
    echo "=============================================="
    echo
    
    # Initial queue status
    get_queue_status
    echo
    
    # Monitor for specified duration
    for ((i=1; i<=$((DURATION * 12)); i++)); do  # Check every 5 seconds
        echo "=== Monitoring Check $i ==="
        echo "Time: $(date)"
        echo
        
        # Container stats
        echo "Container Statistics:"
        for container in $WORKER_CONTAINERS; do
            echo "Container: $container"
            get_container_stats "$container"
            echo
        done
        
        # Celery process status
        echo "Celery Process Status:"
        for container in $WORKER_CONTAINERS; do
            echo "Container: $container"
            get_celery_status "$container"
            echo
        done
        
        # Queue status (every 12th check = every minute)
        if [ $((i % 12)) -eq 0 ]; then
            get_queue_status
            echo
        fi
        
        echo "=============================================="
        echo
        
        # Wait 5 seconds before next check
        sleep 5
    done
    
    echo "=== Monitoring Completed ==="
    echo "Final timestamp: $(date)"
    
} | tee "$MONITOR_FILE"

print_success "Performance monitoring completed!"
print_status "Results saved to: $MONITOR_FILE"

# Show summary
print_status "Summary of monitoring results:"
echo "  - Total monitoring time: $DURATION minutes"
echo "  - Worker containers monitored: $(echo "$WORKER_CONTAINERS" | wc -l)"
echo "  - Log file: $MONITOR_FILE"

# Show recent log entries
print_status "Recent Celery worker logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=20 celeryworker | grep -E "(Starting|completed|error|failed)" || echo "No recent activity found" 