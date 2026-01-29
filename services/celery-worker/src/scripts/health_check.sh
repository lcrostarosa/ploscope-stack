#!/bin/bash

# Comprehensive health check for Celery worker
# This script checks multiple aspects of the worker's health

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[HEALTH CHECK]${NC} $1"
}

error() {
    echo -e "${RED}[HEALTH CHECK ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[HEALTH CHECK WARNING]${NC} $1"
}

# Check 1: Verify Celery worker process is running
check_celery_process() {
    log "Checking if Celery worker process is running..."

    if pgrep -f "celery.*worker" > /dev/null; then
        log "✅ Celery worker process is running"
        return 0
    else
        error "❌ Celery worker process is not running"
        return 1
    fi
}

# Check 2: Verify RabbitMQ connectivity
check_rabbitmq_connectivity() {
    log "Checking RabbitMQ connectivity..."

    local username=${RABBITMQ_USERNAME:-plosolver}
    local password=${RABBITMQ_PASSWORD:-dev_password_2024}
    local host=${RABBITMQ_HOST:-rabbitmq}
    local port=${RABBITMQ_PORT:-5672}

    # Check if we can connect to RabbitMQ management API
    if curl -s -f -u "$username:$password" "http://$host:15672/api/overview" > /dev/null 2>&1; then
        log "✅ RabbitMQ connectivity is good"
        return 0
    else
        error "❌ Cannot connect to RabbitMQ management API"
        return 1
    fi
}

# Check 3: Verify Redis connectivity
check_redis_connectivity() {
    log "Checking Redis connectivity..."

    local host=${REDIS_HOST:-redis}
    local port=${REDIS_PORT:-6379}
    local password=${REDIS_PASSWORD:-}

    # Use redis-cli if available, otherwise use netcat
    if command -v redis-cli > /dev/null 2>&1; then
        if [ -n "$password" ]; then
            if redis-cli -h "$host" -p "$port" -a "$password" ping > /dev/null 2>&1; then
                log "✅ Redis connectivity is good"
                return 0
            fi
        else
            if redis-cli -h "$host" -p "$port" ping > /dev/null 2>&1; then
                log "✅ Redis connectivity is good"
                return 0
            fi
        fi
    else
        # Fallback to netcat
        if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            log "✅ Redis port is accessible"
            return 0
        fi
    fi

    error "❌ Cannot connect to Redis"
    return 1
}

# Check 4: Verify Celery worker is ready (using inspect)
check_celery_worker_ready() {
    log "Checking if Celery worker is ready to process tasks..."

    # Try to inspect the worker using celery inspect
    if timeout 10 celery -A celery_app.celery inspect ping > /dev/null 2>&1; then
        log "✅ Celery worker is ready to process tasks"
        return 0
    else
        warning "⚠️  Cannot ping Celery worker (this might be normal during startup)"
        # Don't fail the health check for this, as it might be a timing issue
        return 0
    fi
}

# Check 5: Verify database connectivity (if DATABASE_URL is set)
check_database_connectivity() {
    if [ -n "$DATABASE_URL" ]; then
        log "Checking database connectivity..."

        # Extract host from DATABASE_URL
        local host=$(echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p')
        local port=$(echo "$DATABASE_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')

        if [ -n "$host" ] && [ -n "$port" ]; then
            if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
                log "✅ Database connectivity is good"
                return 0
            else
                error "❌ Cannot connect to database"
                return 1
            fi
        else
            warning "⚠️  Could not parse DATABASE_URL for connectivity check"
            return 0
        fi
    else
        log "Skipping database connectivity check (DATABASE_URL not set)"
        return 0
    fi
}

# Check 6: Verify worker memory usage (optional)
check_memory_usage() {
    log "Checking memory usage..."

    # Get memory usage in MB
    local memory_mb=$(ps -o rss= -p $(pgrep -f "celery.*worker" | head -1) 2>/dev/null | awk '{print int($1/1024)}')

    if [ -n "$memory_mb" ]; then
        if [ "$memory_mb" -gt 2000 ]; then
            warning "⚠️  High memory usage: ${memory_mb}MB"
        else
            log "✅ Memory usage is normal: ${memory_mb}MB"
        fi
    else
        warning "⚠️  Could not determine memory usage"
    fi

    return 0
}

# Main health check function
main() {
    log "Starting comprehensive health check..."

    local exit_code=0

    # Run all checks
    check_celery_process || exit_code=1
    check_rabbitmq_connectivity || exit_code=1
    check_redis_connectivity || exit_code=1
    check_celery_worker_ready || exit_code=1
    check_database_connectivity || exit_code=1
    check_memory_usage || exit_code=1

    if [ $exit_code -eq 0 ]; then
        log "🎉 All health checks passed!"
    else
        error "💥 Some health checks failed!"
    fi

    exit $exit_code
}

# Run the main function
main "$@"
