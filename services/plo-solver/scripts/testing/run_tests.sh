#!/bin/bash

# Test runner for PLOSolver
# This script runs both frontend and backend tests

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

echo "🧪 PLOSolver Test Suite"
echo "========================"

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
FRONTEND_ONLY=false
BACKEND_ONLY=false
COVERAGE=false
VERBOSE=false
CI_MODE=false
TEST_TYPE="all"  # all, unit, integration

while [[ $# -gt 0 ]]; do
    case $1 in
        --frontend-only)
            FRONTEND_ONLY=true
            shift
            ;;
        --backend-only)
            BACKEND_ONLY=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options] [backend] [unit|integration]"
            echo ""
            echo "Options:"
            echo "  --frontend-only     Run only frontend tests"
            echo "  --backend-only      Run only backend tests"
            echo "  --coverage          Run tests with coverage"
            echo "  --verbose, -v       Verbose output"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Arguments:"
            echo "  backend             Run backend tests"
            echo "  unit                Run unit tests only"
            echo "  integration         Run integration tests only"
            echo "  ci                  Use CI mode (skip Docker containers)"
            echo ""
            echo "Examples:"
            echo "  $0                  # Run all tests"
            echo "  $0 --frontend-only  # Run only frontend tests"
            echo "  $0 --backend-only   # Run only backend tests"
            echo "  $0 backend unit     # Run backend unit tests only"
            echo "  $0 backend integration # Run backend integration tests only"
            echo "  $0 backend integration ci # Run backend integration tests in CI mode"
            echo "  $0 --coverage       # Run tests with coverage"
            exit 0
            ;;
        backend)
            BACKEND_ONLY=true
            shift
            ;;
        unit)
            TEST_TYPE="unit"
            shift
            ;;
        integration)
            TEST_TYPE="integration"
            shift
            ;;
        ci)
            CI_MODE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to start Docker containers for testing
start_test_containers() {
    print_status "Starting Docker containers for testing..."
    
    cd "$PROJECT_ROOT"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not available. Cannot run integration tests."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Stop any existing containers to avoid conflicts
    print_status "Stopping any existing test containers..."
    docker compose -f docker-compose-test.yml down -v 2>/dev/null || true
    
    # Clean up any existing database volumes to ensure fresh state
    print_status "Cleaning up database volumes for fresh state..."
    docker volume rm plosolver_postgres_data 2>/dev/null || true
    
    # Start only the required services for testing (db and rabbitmq)
    print_status "Building and starting full test stack (docker-compose-test.yml)..."
    # Build images first to avoid race conditions on first run
    docker compose -f docker-compose-test.yml build --quiet

    # Bring up the entire stack (all services defined in compose file)
    docker compose -f docker-compose-test.yml --profile bootstrap up -d
    
    # Wait for containers to be healthy
    print_status "Waiting for PostgreSQL to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose -f docker-compose-test.yml ps db | grep -q "healthy"; then
            print_success "PostgreSQL is ready!"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "PostgreSQL failed to start within 60 seconds"
        docker compose -f docker-compose-test.yml logs db
        exit 1
    fi
    
    print_status "Waiting for RabbitMQ to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose -f docker-compose-test.yml ps rabbitmq | grep -q "healthy"; then
            print_success "RabbitMQ is ready!"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "RabbitMQ failed to start within 60 seconds"
        docker compose -f docker-compose-test.yml logs rabbitmq
        exit 1
    fi
    
    # Verify containers are accessible on the expected ports
    print_status "Verifying container connectivity..."
    if ! nc -z localhost 5432 2>/dev/null; then
        print_error "PostgreSQL is not accessible on port 5432"
        exit 1
    fi
    
    if ! nc -z localhost 5672 2>/dev/null; then
        print_error "RabbitMQ is not accessible on port 5672"
        exit 1
    fi
    
    if ! nc -z localhost 15672 2>/dev/null; then
        print_error "RabbitMQ management is not accessible on port 15672"
        exit 1
    fi
    
    # Wait for db-migrate to complete
    print_status "Waiting for database migrations to complete..."
    timeout=120
    while [ $timeout -gt 0 ]; do
        if docker compose -f docker-compose-test.yml --profile bootstrap ps -a db-migrate 2>/dev/null | grep -qi "exited (0)"; then
            print_success "Database migrations completed successfully!"
            break
        elif docker compose -f docker-compose-test.yml --profile bootstrap ps -a db-migrate 2>/dev/null | grep -qi "exited (1)"; then
            print_error "Database migrations failed!"
            docker compose -f docker-compose-test.yml --profile bootstrap logs db-migrate
            exit 1
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Database migrations did not complete within 120 seconds"
        docker compose -f docker-compose-test.yml --profile bootstrap logs db-migrate
        exit 1
    fi
    
    print_success "All test containers are ready!"
}

# Function to stop Docker containers
stop_test_containers() {
    print_status "Stopping test containers..."
    cd "$PROJECT_ROOT"
    docker compose -f docker-compose-test.yml stop db rabbitmq
}

# Load test environment variables if env.test exists

# For integration tests, start docker stack early so frontend tests can hit live backend
if [[ "$TEST_TYPE" =~ ^(integration|all)$ ]]; then
    echo "Integration tests are now handled by Cucumber. Use 'make test-cucumber' instead."
    exit 1
fi
if [ -f "$PROJECT_ROOT/env.test" ]; then
    print_status "Loading test environment variables from env.test..."
    set -a
    source "$PROJECT_ROOT/env.test"
    set +a
fi



# Initialize exit codes
FRONTEND_EXIT_CODE=0
BACKEND_EXIT_CODE=0

# Frontend Tests
if [ "$BACKEND_ONLY" = false ]; then
    print_status "Running Frontend Tests..."
    
    cd "$PROJECT_ROOT/src/frontend"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_warning "node_modules not found. Installing dependencies..."
        npm install
    fi
    
    # For integration tests, set environment to point to live backend
    if [ "$TEST_TYPE" = "integration" ] || [ "$TEST_TYPE" = "all" ]; then
        print_status "Integration tests are now handled by Cucumber. Use 'make test-cucumber' instead."
        exit 1
    else
        # Run frontend tests
        if [ "$COVERAGE" = true ]; then
            print_status "Running frontend tests with coverage..."
            npm run test:coverage
        else
            print_status "Running frontend tests..."
            npm test
        fi
    fi
    
    FRONTEND_EXIT_CODE=$?
    
    if [ $FRONTEND_EXIT_CODE -eq 0 ]; then
        print_success "Frontend tests passed!"
    else
        print_error "Frontend tests failed!"
    fi
    
    cd ../../scripts
fi

# Backend Tests
if [ "$FRONTEND_ONLY" = false ]; then
    print_status "Running Backend Tests..."
    
    # Only start Docker containers for integration tests (unless in CI mode)
    if [ "$TEST_TYPE" = "integration" ] || [ "$TEST_TYPE" = "all" ]; then
        print_status "Integration tests are now handled by Cucumber. Use 'make test-cucumber' instead."
        exit 1
    fi
    
    cd "$PROJECT_ROOT/src/backend"
    print_status "Running from directory: $(pwd)"
    
    # Create necessary directories
    mkdir -p logs
    mkdir -p uploads/hand_histories
    
    # Check if venv exists and activate it
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        print_warning "Python venv not found. Creating venv..."
        python3 -m venv venv
        if [ -f "venv/bin/activate" ]; then
            source venv/bin/activate
        elif [ -f "venv/Scripts/activate" ]; then
            source venv/Scripts/activate
        else
            print_error "Failed to create or activate virtual environment"
            exit 1
        fi
        pip install -r requirements-test.txt
    fi
    
    # Set environment variables based on test type
    if [ "$TEST_TYPE" = "integration" ] || [ "$TEST_TYPE" = "all" ]; then
        print_status "Integration tests are now handled by Cucumber. Use 'make test-cucumber' instead."
        exit 1
    else
        # Unit test environment - use in-memory or mock services
        export CONTAINER_ENV=unit
        # Override Docker service names with localhost for unit tests
        export RABBITMQ_HOST=localhost
        export DATABASE_URL=postgresql://testuser:testpassword@localhost:5432/plosolver
        # Unit tests should use mocked services or in-memory databases
    fi
    
    # Run backend tests based on type
    if [ "$TEST_TYPE" = "unit" ]; then
        print_status "Running backend unit tests..."
        # Temporarily rename integration conftest to avoid conflicts
        if [ -f "tests/conftest.py" ]; then
            mv tests/conftest.py tests/conftest_integration.py
        fi
        if [ "$COVERAGE" = true ]; then
            python -m pytest tests/unit/ --cov=. --cov-report=html --cov-report=term-missing
        else
            python -m pytest tests/unit/
        fi
        # Restore integration conftest
        if [ -f "tests/conftest_integration.py" ]; then
            mv tests/conftest_integration.py tests/conftest.py
        fi
    elif [ "$TEST_TYPE" = "integration" ]; then
        print_status "Integration tests are now handled by Cucumber. Use 'make test-cucumber' instead."
        exit 1
    else
        print_status "Running all backend tests..."
        if [ "$COVERAGE" = true ]; then
            python -m pytest --cov=. --cov-report=html --cov-report=term-missing
        else
            python -m pytest
        fi
    fi
    
    BACKEND_EXIT_CODE=$?
    
    if [ $BACKEND_EXIT_CODE -eq 0 ]; then
        print_success "Backend tests passed!"
    else
        print_error "Backend tests failed!"
    fi
    
    cd "$PROJECT_ROOT/scripts"
    
    # Stop test containers only if they were started (not in CI mode)
    if [ "$TEST_TYPE" = "integration" ] || [ "$TEST_TYPE" = "all" ]; then
        print_status "Integration tests are now handled by Cucumber. Use 'make test-cucumber' instead."
        exit 1
    fi
fi

# Summary
echo ""
echo "📊 Test Results Summary"
echo "========================"

if [ "$BACKEND_ONLY" = false ]; then
    if [ $FRONTEND_EXIT_CODE -eq 0 ]; then
        print_success "Frontend: ✅ PASSED"
    else
        print_error "Frontend: ❌ FAILED"
    fi
fi

if [ "$FRONTEND_ONLY" = false ]; then
    if [ $BACKEND_EXIT_CODE -eq 0 ]; then
        print_success "Backend: ✅ PASSED"
    else
        print_error "Backend: ❌ FAILED"
    fi
fi

# Exit with appropriate code
if [ "$BACKEND_ONLY" = false ] && [ $FRONTEND_EXIT_CODE -ne 0 ]; then
    exit $FRONTEND_EXIT_CODE
fi

if [ "$FRONTEND_ONLY" = false ] && [ $BACKEND_EXIT_CODE -ne 0 ]; then
    exit $BACKEND_EXIT_CODE
fi

print_success "All tests completed successfully!" 