#!/bin/bash

# Integration Test Runner for PLOSolver Backend
# This script runs only integration tests, excluding unit tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🧪 PLOSolver Integration Test Suite"
echo "==================================="

# Check if we're in the right directory
if [ ! -d "../src/backend" ]; then
    echo "❌ Error: This script must be run from the scripts directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: scripts/ directory with parent containing src/backend/"
    exit 1
fi

# Parse command line arguments
COVERAGE=false
VERBOSE=false
FAIL_FAST=false
DOCKER_ONLY=false
RABBITMQ_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            COVERAGE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --fail-fast|-x)
            FAIL_FAST=true
            shift
            ;;
        --docker-only)
            DOCKER_ONLY=true
            shift
            ;;
        --rabbitmq-only)
            RABBITMQ_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --coverage          Run tests with coverage"
            echo "  --verbose, -v       Verbose output"
            echo "  --fail-fast, -x     Stop on first failure"
            echo "  --docker-only       Run only Docker integration tests"
            echo "  --rabbitmq-only     Run only RabbitMQ integration tests"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                  # Run all integration tests"
            echo "  $0 --coverage       # Run integration tests with coverage"
            echo "  $0 --docker-only    # Run only Docker integration tests"
            echo "  $0 --rabbitmq-only  # Run only RabbitMQ integration tests"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to check if Docker services are available
check_docker_services() {
    local postgres_available=false
    local rabbitmq_available=false
    
    # Check PostgreSQL on port 5433
    if nc -z localhost 5433 2>/dev/null; then
        postgres_available=true
    fi
    
    # Check RabbitMQ management on port 15673
    if nc -z localhost 15673 2>/dev/null; then
        rabbitmq_available=true
    fi
    
    if [ "$postgres_available" = true ] && [ "$rabbitmq_available" = true ]; then
        return 0  # Both services available
    else
        return 1  # Services not available
    fi
}

# Check for Docker if running Docker tests
if [ "$DOCKER_ONLY" = true ] || [ "$RABBITMQ_ONLY" = false ] && [ "$DOCKER_ONLY" = false ]; then
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not available. Skipping Docker integration tests."
        print_warning "Use 'make test-integration' to run integration tests with Docker containers."
        exit 0
    fi
    
    if ! docker info &> /dev/null; then
        print_warning "Docker is not running. Skipping Docker integration tests."
        print_warning "Use 'make test-integration' to run integration tests with Docker containers."
        exit 0
    fi
    
    # Check if test containers are running
    if ! check_docker_services; then
        print_warning "Docker test containers are not running on expected ports (PostgreSQL:5433, RabbitMQ:15673)."
        print_warning "Use 'make test-integration' to run integration tests with Docker containers."
        print_warning "Skipping Docker integration tests."
        exit 0
    fi
fi

# Backend Integration Tests
print_status "Running Backend Integration Tests..."
print_status "Excluding unit tests..."

cd ../src/backend

# Check if virtual environment exists and activate it
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
else
    print_warning "Virtual environment not found. Creating one..."
    python3 -m venv venv
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        print_error "Failed to create or activate virtual environment"
        exit 1
    fi
    pip install -r requirements.txt
    pip install -r requirements-test.txt
fi

# Build pytest command
PYTEST_CMD="python -m pytest"

# Add test path based on options
if [ "$DOCKER_ONLY" = true ]; then
    print_status "Running Docker integration tests only..."
    PYTEST_CMD="$PYTEST_CMD tests/integration/ -m docker"
elif [ "$RABBITMQ_ONLY" = true ]; then
    print_status "Running RabbitMQ integration tests only..."
    PYTEST_CMD="$PYTEST_CMD tests/integration/test_rabbitmq_integration.py"
else
    print_status "Running all integration tests..."
    PYTEST_CMD="$PYTEST_CMD tests/integration/ -m integration"
fi

# Use integration test configuration with PostgreSQL Docker containers
PYTEST_CMD="$PYTEST_CMD -c pytest_integration.ini"

# Add options
if [ "$COVERAGE" = true ]; then
    print_status "Running integration tests with coverage..."
    PYTEST_CMD="$PYTEST_CMD --cov=. --cov-report=html --cov-report=term-missing"
fi

if [ "$VERBOSE" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -v"
fi

if [ "$FAIL_FAST" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -x"
fi

print_status "Command: $PYTEST_CMD"

# Run backend integration tests
eval $PYTEST_CMD

INTEGRATION_EXIT_CODE=$?

if [ $INTEGRATION_EXIT_CODE -eq 0 ]; then
    print_success "Backend integration tests passed!"
else
    print_error "Backend integration tests failed!"
fi

cd ../../scripts

# Summary
echo ""
echo "📊 Integration Test Results Summary"
echo "==================================="

if [ $INTEGRATION_EXIT_CODE -eq 0 ]; then
    print_success "Backend Integration Tests: ✅ PASSED"
else
    print_error "Backend Integration Tests: ❌ FAILED"
fi

# Exit with appropriate code
if [ $INTEGRATION_EXIT_CODE -ne 0 ]; then
    exit $INTEGRATION_EXIT_CODE
fi

print_success "All integration tests completed successfully!" 