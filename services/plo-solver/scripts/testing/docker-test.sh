#!/bin/bash

# PLOSolver Docker Test Environment Management Script

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

# Start the test environment
start_test_env() {
    print_status "Starting PLOSolver test environment..."
    docker-compose -f docker-test-env.yml up -d
    print_success "Test environment started"
    print_status "Access the environment with: docker exec -it plosolver-test-env bash"
}

# Stop the test environment
stop_test_env() {
    print_status "Stopping PLOSolver test environment..."
    docker-compose -f docker-test-env.yml down
    print_success "Test environment stopped"
}

# Restart the test environment
restart_test_env() {
    stop_test_env
    start_test_env
}

# Destroy the test environment
destroy_test_env() {
    print_warning "This will completely destroy the test environment and all data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying PLOSolver test environment..."
        docker-compose -f docker-test-env.yml down -v
        docker system prune -f
        print_success "Test environment destroyed"
    else
        print_status "Operation cancelled"
    fi
}

# SSH into the test environment
ssh_test_env() {
    print_status "Connecting to test environment..."
    docker exec -it plosolver-test-env bash
}

# Run tests in the test environment
run_tests() {
    print_status "Running tests in test environment..."
    docker exec -it plosolver-test-env bash -c "cd /workspace && ./scripts/setup/setup-dependencies.sh"
    docker exec -it plosolver-test-env bash -c "cd /workspace && make test"
}

# Run Docker tests in the test environment
run_docker_tests() {
    print_status "Running Docker tests in test environment..."
    docker exec -it plosolver-test-env bash -c "cd /workspace && make run-docker"
}

# Check test environment status
status_test_env() {
    print_status "Checking test environment status..."
    docker-compose -f docker-test-env.yml ps
}

# Run a command in the test environment
run_in_test_env() {
    if [ -z "$1" ]; then
        print_error "Please specify a command to run"
        exit 1
    fi
    print_status "Running command in test environment: $1"
    docker exec -it plosolver-test-env bash -c "$1"
}

# Show test environment logs
show_logs() {
    print_status "Showing test environment logs..."
    docker-compose -f docker-test-env.yml logs -f
}

# Setup the test environment
setup_test_env() {
    print_status "Setting up PLOSolver test environment..."
    docker-compose -f docker-test-env.yml up -d --build
    print_success "Setup complete!"
    print_status "Access with: docker exec -it plosolver-test-env bash"
}

# Main function
main() {
    case "${1:-help}" in
        "start")
            start_test_env
            ;;
        "stop")
            stop_test_env
            ;;
        "restart")
            restart_test_env
            ;;
        "destroy")
            destroy_test_env
            ;;
        "ssh")
            ssh_test_env
            ;;
        "test")
            run_tests
            ;;
        "docker-test")
            run_docker_tests
            ;;
        "status")
            status_test_env
            ;;
        "run")
            run_in_test_env "$2"
            ;;
        "logs")
            show_logs
            ;;
        "setup")
            setup_test_env
            ;;
        "help"|*)
            echo "PLOSolver Docker Test Environment Management Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  setup      - Set up the test environment (first time)"
            echo "  start      - Start the test environment"
            echo "  stop       - Stop the test environment"
            echo "  restart    - Restart the test environment"
            echo "  destroy    - Destroy the test environment completely"
            echo "  ssh        - SSH into the test environment"
            echo "  test       - Run tests in the test environment"
            echo "  docker-test - Run Docker tests in the test environment"
            echo "  status     - Show test environment status"
            echo "  run <cmd>  - Run a command in the test environment"
            echo "  logs       - Show test environment logs"
            echo "  help       - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 setup"
            echo "  $0 start"
            echo "  $0 ssh"
            echo "  $0 run 'cd /workspace && make test'"
            ;;
    esac
}

# Run main function
main "$@" 