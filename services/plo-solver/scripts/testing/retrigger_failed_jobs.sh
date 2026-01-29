#!/bin/sh
"""
Shell script wrapper for retriggering failed jobs from RabbitMQ DLQs.

This script provides a convenient way to manage failed jobs in the PLOSolver system.

Usage:
    ./retrigger_failed_jobs.sh --list
    ./retrigger_failed_jobs.sh --retrigger-all
    ./retrigger_failed_jobs.sh --retrigger-job <job_id>
    ./retrigger_failed_jobs.sh --clear-all
    ./retrigger_failed_jobs.sh --help

Examples:
    # List all failed jobs
    ./retrigger_failed_jobs.sh --list
    
    # Retrigger all failed jobs
    ./retrigger_failed_jobs.sh --retrigger-all
    
    # Retrigger a specific job
    ./retrigger_failed_jobs.sh --retrigger-job abc123-def456
    
    # Clear all DLQs (dangerous!)
    ./retrigger_failed_jobs.sh --clear-all
"""

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show help
show_help() {
    cat << EOF
PLOSolver Failed Jobs Retrigger Script

This script helps manage failed jobs in RabbitMQ dead letter queues.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --list                    List all failed jobs in DLQs
    --retrigger-all           Retrigger all failed jobs
    --retrigger-job <job_id>  Retrigger a specific job by ID
    --clear-all               Clear all DLQs (DANGEROUS - requires confirmation)
    --help                    Show this help message

EXAMPLES:
    # List all failed jobs
    $0 --list
    
    # Retrigger all failed jobs
    $0 --retrigger-all
    
    # Retrigger a specific job
    $0 --retrigger-job abc123-def456
    
    # Clear all DLQs (dangerous!)
    $0 --clear-all

ENVIRONMENT:
    The script uses the following environment variables:
    - RABBITMQ_HOST: RabbitMQ host (default: localhost)
    - RABBITMQ_PORT: RabbitMQ port (default: 5672)
    - RABBITMQ_USERNAME: RabbitMQ username (default: guest)
    - RABBITMQ_PASSWORD: RabbitMQ password (default: guest)
    - RABBITMQ_VHOST: RabbitMQ virtual host (default: /)
    - DATABASE_URL: PostgreSQL connection string

EOF
}

# Function to check if we're in the right environment
check_environment() {
    print_info "Checking environment..."
    
    # Check if we're in the project root or a subdirectory
    if [ ! -f "$PROJECT_ROOT/Makefile" ]; then
        print_error "Could not find project root. Make sure you're running this from the PLOSolver project directory."
        exit 1
    fi
    
    # Check if Python script exists
    if [ ! -f "$SCRIPT_DIR/retrigger_failed_jobs.py" ]; then
        print_error "Python script not found: $SCRIPT_DIR/retrigger_failed_jobs.py"
        exit 1
    fi
    
    # Check if we have the required Python environment
    if ! command -v python3 >/dev/null 2>&1; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    print_success "Environment check passed"
}

# Function to setup environment variables
setup_environment() {
    print_info "Setting up environment variables..."
    
    # Load environment file if it exists
    if [ -f "$PROJECT_ROOT/env.development" ]; then
        print_info "Loading environment from env.development"
        export $(grep -v '^#' "$PROJECT_ROOT/env.development" | xargs)
    elif [ -f "$PROJECT_ROOT/.env" ]; then
        print_info "Loading environment from .env"
        export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
    else
        print_warning "No environment file found, using defaults"
    fi
    
    # Set default values for required variables
    export RABBITMQ_HOST=${RABBITMQ_HOST:-localhost}
    export RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
    export RABBITMQ_USERNAME=${RABBITMQ_USERNAME:-guest}
    export RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-guest}
    export RABBITMQ_VHOST=${RABBITMQ_VHOST:-/}
    export DATABASE_URL=${DATABASE_URL:-postgresql://postgres:postgres@db:5432/plosolver}
    
    print_success "Environment variables configured"
}

# Function to run the Python script
run_python_script() {
    local args="$@"
    
    print_info "Running Python script with arguments: $args"
    
    # Change to the script directory and run the Python script
    cd "$SCRIPT_DIR"
    
    # Run the Python script with the provided arguments
    python3 retrigger_failed_jobs.py $args
    
    # Check the exit code
    if [ $? -eq 0 ]; then
        print_success "Script completed successfully"
    else
        print_error "Script failed with exit code $?"
        exit 1
    fi
}

# Main script logic
main() {
    # Show help if requested
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    print_info "PLOSolver Failed Jobs Retrigger Script"
    echo
    
    # Check environment
    check_environment
    
    # Setup environment variables
    setup_environment
    
    # Run the Python script with all arguments
    run_python_script "$@"
}

# Run the main function with all arguments
main "$@" 