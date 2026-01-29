#!/bin/bash

# Test runner for PLOSolver with optional backend services
# This script can run tests with or without starting backend services

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

echo "🧪 PLOSolver Test Suite with Services"
echo "====================================="

# Parse command line arguments
FRONTEND_ONLY=false
BACKEND_ONLY=false
WITH_SERVICES=false
COVERAGE=false
VERBOSE=false
STOP_SERVICES=true

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
        --with-services)
            WITH_SERVICES=true
            shift
            ;;
        --keep-services)
            WITH_SERVICES=true
            STOP_SERVICES=false
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
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --frontend-only     Run only frontend tests"
            echo "  --backend-only      Run only backend tests"
            echo "  --with-services     Start backend services before testing"
            echo "  --keep-services     Start services and keep them running after tests"
            echo "  --coverage          Run tests with coverage"
            echo "  --verbose, -v       Verbose output"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                  # Run all tests with mocked services"
            echo "  $0 --with-services  # Run tests with real backend services"
            echo "  $0 --frontend-only --with-services  # Run frontend tests with real backend"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to start backend services
start_backend_services() {
    print_status "Starting backend services for testing..."
    
    # Start PostgreSQL
    if ! docker ps | grep -q "plosolver-test-postgres"; then
        print_status "Starting test PostgreSQL..."
        docker run -d \
            --name plosolver-test-postgres \
            -e POSTGRES_USER=test_user \
            -e POSTGRES_PASSWORD=test_password \
            -e POSTGRES_DB=test_plosolver \
            -p 5433:5432 \
            postgres:15
    fi
    
    # Start RabbitMQ
    if ! docker ps | grep -q "plosolver-test-rabbitmq"; then
        print_status "Starting test RabbitMQ..."
        docker run -d \
            --name plosolver-test-rabbitmq \
            -e RABBITMQ_DEFAULT_USER=test_user \
            -e RABBITMQ_DEFAULT_PASS=test_password \
            -e RABBITMQ_DEFAULT_VHOST=/test \
            -p 15673:15672 \
            -p 5673:5672 \
            rabbitmq:3.13-management
    fi
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Start Flask backend
    print_status "Starting Flask backend..."
    cd src/backend
    
    # Set up virtual environment if needed
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
    
    # Set test environment variables
    export FLASK_APP=backend.core.app
    export FLASK_DEBUG=false
    export DATABASE_URL=postgresql://test_user:test_password@localhost:5433/test_plosolver
    export SECRET_KEY=test-secret-key
    export JWT_SECRET_KEY=test-jwt-secret-key
    export LOG_LEVEL=DEBUG
    export QUEUE_PROVIDER=rabbitmq
    export RABBITMQ_HOST=localhost
    export RABBITMQ_PORT=5673
    export RABBITMQ_USERNAME=test_user
    export RABBITMQ_PASSWORD=test_password
    export RABBITMQ_VHOST=/test
    
    # Start Flask in background
    python -m flask run --host=0.0.0.0 --port=5001 &
    FLASK_PID=$!
    
    # Wait for Flask to start
    sleep 5
    
    cd ../../scripts
}

# Function to stop backend services
stop_backend_services() {
    if [ "$STOP_SERVICES" = true ]; then
        print_status "Stopping backend services..."
        
        # Stop Flask
        if [ ! -z "$FLASK_PID" ]; then
            kill $FLASK_PID 2>/dev/null || true
        fi
        
        # Stop containers
        docker stop plosolver-test-postgres plosolver-test-rabbitmq 2>/dev/null || true
        docker rm plosolver-test-postgres plosolver-test-rabbitmq 2>/dev/null || true
    else
        print_warning "Keeping services running (use --keep-services to keep them running)"
    fi
}

# Set up cleanup on exit
trap stop_backend_services EXIT

# Start services if requested
if [ "$WITH_SERVICES" = true ]; then
    start_backend_services
fi

# Frontend Tests
if [ "$BACKEND_ONLY" = false ]; then
    print_status "Running Frontend Tests..."
    
    cd ../src/frontend
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_warning "node_modules not found. Installing dependencies..."
        npm install
    fi
    
    # Set API URL to local backend if services are running
    if [ "$WITH_SERVICES" = true ]; then
        export REACT_APP_API_URL=http://localhost:5001/api
        print_status "Using real backend at http://localhost:5001/api"
    else
        print_status "Using mocked API calls"
    fi
    
    # Run frontend tests
    if [ "$COVERAGE" = true ]; then
        print_status "Running frontend tests with coverage..."
        npm run test:coverage
    else
        print_status "Running frontend tests..."
        npm test
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
    
    # Set test environment variables
    export FLASK_APP=backend.core.app
    export FLASK_DEBUG=false
    export DATABASE_URL=postgresql://test_user:test_password@localhost:5433/test_plosolver
    export SECRET_KEY=test-secret-key
    export JWT_SECRET_KEY=test-jwt-secret-key
    export LOG_LEVEL=DEBUG
    export QUEUE_PROVIDER=rabbitmq
    export RABBITMQ_HOST=localhost
    export RABBITMQ_PORT=5673
    export RABBITMQ_USERNAME=test_user
    export RABBITMQ_PASSWORD=test_password
    export RABBITMQ_VHOST=/test
    
    # Run backend tests
    if [ "$COVERAGE" = true ]; then
        print_status "Running backend tests with coverage..."
        python -m pytest --cov=. --cov-report=html --cov-report=term-missing
    else
        print_status "Running backend tests..."
        python -m pytest
    fi
    
    BACKEND_EXIT_CODE=$?
    
    if [ $BACKEND_EXIT_CODE -eq 0 ]; then
        print_success "Backend tests passed!"
    else
        print_error "Backend tests failed!"
    fi
    
    cd ../../scripts
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
if [ "$FRONTEND_ONLY" = false ] && [ $FRONTEND_EXIT_CODE -ne 0 ]; then
    exit $FRONTEND_EXIT_CODE
fi

if [ "$BACKEND_ONLY" = false ] && [ $BACKEND_EXIT_CODE -ne 0 ]; then
    exit $BACKEND_EXIT_CODE
fi

print_success "All tests completed successfully!" 