#!/bin/bash

# Cucumber Test Runner for PLOSolver
# This script runs Cucumber integration tests against different environments

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

echo "🥒 PLOSolver Cucumber Test Suite"
echo "================================"

# Determine project root
if [ -f "src/frontend/package.json" ] && [ -d "src/backend" ]; then
    PROJECT_ROOT="$(pwd)"
elif [ -f "../src/frontend/package.json" ] && [ -d "../src/backend" ]; then
    PROJECT_ROOT="$(cd .. && pwd)"
else
    print_error "❌ Error: Could not find project root (src/frontend/package.json and src/backend)"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Parse command line arguments
ENVIRONMENT="containerized"  # containerized, local, ci
HEADLESS=true
VERBOSE=false
TAGS=""
FEATURES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment|-e)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --local)
            ENVIRONMENT="local"
            shift
            ;;
        --containerized)
            ENVIRONMENT="containerized"
            shift
            ;;
        --ci)
            ENVIRONMENT="ci"
            shift
            ;;
        --headless)
            HEADLESS=true
            shift
            ;;
        --no-headless)
            HEADLESS=false
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --tags|-t)
            TAGS="$2"
            shift 2
            ;;
        --features|-f)
            FEATURES="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --environment, -e <env>    Environment to test against (containerized|local|ci)"
            echo "  --local                    Use local development environment"
            echo "  --containerized            Use Docker containerized environment (default)"
            echo "  --ci                       Use CI environment"
            echo "  --headless                 Run tests in headless mode (default)"
            echo "  --no-headless              Run tests with browser visible"
            echo "  --verbose, -v              Verbose output"
            echo "  --tags, -t <tags>          Run only tests with specific tags"
            echo "  --features, -f <features>  Run only specific feature files"
            echo "  --help, -h                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --local                 # Run against local development environment"
            echo "  $0 --containerized         # Run against Docker containers"
            echo "  $0 --ci                    # Run in CI environment"
            echo "  $0 --tags @authentication  # Run only authentication tests"
            echo "  $0 --features plo-specific # Run only PLO-specific features"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to check if local development environment is running
check_local_environment() {
    print_status "Checking local development environment..."
    
    # Check if frontend is accessible on port 80 (via Traefik)
    if ! nc -z localhost 80 2>/dev/null; then
        print_error "Frontend is not accessible on port 80"
        print_warning "Please start the local development environment with: make run-local"
        return 1
    fi
    
    # Check if backend is running on port 5001
    if ! nc -z localhost 5001 2>/dev/null; then
        print_error "Backend is not running on port 5001"
        print_warning "Please start the local development environment with: make run-local"
        return 1
    fi
    
    print_success "Local development environment is running"
    return 0
}

# Function to start containerized environment
start_containerized_environment() {
    print_status "Starting containerized test environment..."
    
    cd "$PROJECT_ROOT"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not available. Cannot run containerized tests."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Stop any existing containers to avoid conflicts
    print_status "Stopping any existing test containers..."
    docker compose -f docker-compose-test.yml down -v 2>/dev/null || true
    
    # Start the test environment
    print_status "Starting test environment..."
    docker compose -f docker-compose-test.yml --profile bootstrap up -d traefik backend rabbitmq db celeryworker
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    timeout=120
    while [ $timeout -gt 0 ]; do
        if docker compose -f docker-compose-test.yml ps backend | grep -q "healthy"; then
            print_success "Backend is ready!"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Backend failed to start within 120 seconds"
        docker compose -f docker-compose-test.yml logs backend
        exit 1
    fi
    
    print_success "Containerized test environment is ready!"
}

# Function to stop containerized environment
stop_containerized_environment() {
    print_status "Stopping containerized test environment..."
    cd "$PROJECT_ROOT"
    docker compose -f docker-compose-test.yml down -v >/dev/null
    print_success "Containerized test environment stopped"
}

# Function to run Cucumber tests
run_cucumber_tests() {
    print_status "Running Cucumber tests..."
    
    cd "$PROJECT_ROOT/src/frontend"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_warning "node_modules not found. Installing dependencies..."
        npm install
    fi
    
    # Build cucumber command
    CUCUMBER_CMD="npm run test:cucumber"
    
    # Add headless flag if needed
    if [ "$HEADLESS" = true ]; then
        CUCUMBER_CMD="$CUCUMBER_CMD --headless"
    fi
    
    # Add tags if specified
    if [ -n "$TAGS" ]; then
        CUCUMBER_CMD="$CUCUMBER_CMD --tags \"$TAGS\""
    fi
    
    # Add features if specified
    if [ -n "$FEATURES" ]; then
        CUCUMBER_CMD="$CUCUMBER_CMD --features \"$FEATURES\""
    fi
    
    # Add verbose flag if needed
    if [ "$VERBOSE" = true ]; then
        CUCUMBER_CMD="$CUCUMBER_CMD --verbose"
    fi
    
    print_status "Executing: $CUCUMBER_CMD"
    
    # Run the tests
    if eval $CUCUMBER_CMD; then
        print_success "Cucumber tests completed successfully!"
        return 0
    else
        print_error "Cucumber tests failed!"
        return 1
    fi
}

# Main execution
main() {
    print_status "Environment: $ENVIRONMENT"
    print_status "Headless: $HEADLESS"
    print_status "Verbose: $VERBOSE"
    if [ -n "$TAGS" ]; then
        print_status "Tags: $TAGS"
    fi
    if [ -n "$FEATURES" ]; then
        print_status "Features: $FEATURES"
    fi
    echo ""
    
    # Set up environment based on type
    case $ENVIRONMENT in
        "local")
            if ! check_local_environment; then
                exit 1
            fi
            export CUCUMBER_BASE_URL="http://localhost"
            ;;
        "containerized")
            start_containerized_environment
            export CUCUMBER_BASE_URL="http://localhost"
            ;;
        "ci")
            export CUCUMBER_BASE_URL="http://localhost"
            export CUCUMBER_CI=true
            ;;
        *)
            print_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    # Run the tests
    if run_cucumber_tests; then
        print_success "All Cucumber tests passed!"
        EXIT_CODE=0
    else
        print_error "Some Cucumber tests failed!"
        EXIT_CODE=1
    fi
    
    # Clean up containerized environment if needed
    if [ "$ENVIRONMENT" = "containerized" ]; then
        stop_containerized_environment
    fi
    
    exit $EXIT_CODE
}

# Handle script interruption
trap 'print_warning "Script interrupted. Cleaning up..."; if [ "$ENVIRONMENT" = "containerized" ]; then stop_containerized_environment; fi; exit 1' INT TERM

# Run main function
main "$@" 