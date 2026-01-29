#!/bin/bash

# Docker-based Cucumber Test Runner for PLOSolver
# This script runs Cucumber integration tests entirely in Docker containers

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

echo "🥒 PLOSolver Docker-based Cucumber Test Suite"
echo "=============================================="

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

# Function to cleanup containers
cleanup() {
    print_status "Cleaning up Docker containers and networks..."
    docker compose -f docker-compose-test.yml down -v --remove-orphans >/dev/null 2>&1 || true
    
    # Clean up any orphaned networks
    print_status "Cleaning up orphaned networks..."
    docker network prune -f >/dev/null 2>&1 || true
    
    # Remove any test-specific networks that might be stuck
    docker network rm plosolver_plo-network >/dev/null 2>&1 || true
    docker network rm plosolver_default >/dev/null 2>&1 || true
    docker network rm plosolver-test-network >/dev/null 2>&1 || true
    
    print_success "Cleanup completed"
}

# Function to handle script interruption
handle_interrupt() {
    print_warning "Script interrupted. Cleaning up..."
    print_status "Dumping all container logs before cleanup..."
    docker compose -f docker-compose-test.yml ps || true
    docker compose -f docker-compose-test.yml logs --tail=200 --timestamps || true
    # Explicit key services for quick access
    docker compose -f docker-compose-test.yml logs traefik --tail=200 --timestamps || true
    docker compose -f docker-compose-test.yml logs backend --tail=200 --timestamps || true
    docker compose -f docker-compose-test.yml logs frontend --tail=200 --timestamps || true
    docker compose -f docker-compose-test.yml logs celeryworker --tail=200 --timestamps || true
    docker compose -f docker-compose-test.yml logs rabbitmq --tail=200 --timestamps || true
    docker compose -f docker-compose-test.yml logs db --tail=200 --timestamps || true
    cleanup
    exit 1
}

# Set up signal handlers
trap handle_interrupt INT TERM

# Parse command line arguments
VERBOSE=false
TAGS=""
FEATURES=""
KEEP_CONTAINERS=false

while [[ $# -gt 0 ]]; do
    case $1 in
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
        --keep-containers|-k)
            KEEP_CONTAINERS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v              Verbose output"
            echo "  --tags, -t <tags>          Run only tests with specific tags"
            echo "  --features, -f <features>  Run only specific feature files"
            echo "  --keep-containers, -k      Keep containers running after tests"
            echo "  --help, -h                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                         # Run all tests"
            echo "  $0 --tags @authentication  # Run only authentication tests"
            echo "  $0 --features plo-specific # Run only PLO-specific features"
            echo "  $0 --keep-containers       # Keep containers for debugging"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Create test directories if they don't exist
mkdir -p test-results screenshots reports

print_status "Starting Docker-based test environment..."

# Stop any existing containers and ensure clean state
print_status "Stopping any existing test containers..."
cleanup

# Additional cleanup to ensure no conflicts
print_status "Ensuring clean Docker state..."
docker system prune -f >/dev/null 2>&1 || true

# Start the test environment with all required services
print_status "Starting test environment services..."
docker compose -f docker-compose-test.yml --profile bootstrap --profile test up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
timeout=180
while [ $timeout -gt 0 ]; do
    print_status "Checking service health... (timeout: ${timeout}s remaining)"
    
    # Check each service individually for better debugging
    BACKEND_HEALTHY=$(docker compose -f docker-compose-test.yml ps backend | grep -q "healthy" && echo "healthy" || echo "unhealthy")
    FRONTEND_HEALTHY=$(docker compose -f docker-compose-test.yml ps frontend | grep -q "healthy" && echo "healthy" || echo "unhealthy")
    CELERY_HEALTHY=$(docker compose -f docker-compose-test.yml ps celeryworker | grep -q "healthy" && echo "healthy" || echo "unhealthy")
    
    print_status "Backend: $BACKEND_HEALTHY, Frontend: $FRONTEND_HEALTHY, Celery: $CELERY_HEALTHY"
    
    if [ "$BACKEND_HEALTHY" = "healthy" ] && [ "$FRONTEND_HEALTHY" = "healthy" ] && [ "$CELERY_HEALTHY" = "healthy" ]; then
        print_success "All services are ready!"
        break
    fi
    
    sleep 5
    timeout=$((timeout - 5))
done

if [ $timeout -le 0 ]; then
    print_error "Services failed to start within 180 seconds"
    print_status "Container status:"
    docker compose -f docker-compose-test.yml ps
    print_status "Container logs:"
    docker compose -f docker-compose-test.yml logs --tail=100
    print_status "Individual service logs:"
    print_status "Backend logs:"
    docker compose -f docker-compose-test.yml logs backend --tail=50
    print_status "Frontend logs:"
    docker compose -f docker-compose-test.yml logs frontend --tail=50
    print_status "Celery logs:"
    docker compose -f docker-compose-test.yml logs celeryworker --tail=50
    cleanup
    exit 1
fi

# Ensure Playwright image is available (pull prebuilt image per compose config)
print_status "Pulling Playwright test helper image..."
docker compose -f docker-compose-test.yml --profile bootstrap --profile test pull playwright || true

# Prepare test command
TEST_CMD="npm run test:cucumber:ci"

# Add tags if specified
if [ -n "$TAGS" ]; then
    TEST_CMD="$TEST_CMD -- --tags \"$TAGS\""
fi

# Add features if specified
if [ -n "$FEATURES" ]; then
    TEST_CMD="$TEST_CMD -- --features \"$FEATURES\""
fi

print_status "Running Cucumber tests in Docker container..."
print_status "Command: $TEST_CMD"

# Always run with verbose output for better debugging
docker compose -f docker-compose-test.yml --profile bootstrap --profile test run --rm playwright sh -c "$TEST_CMD"
EXIT_CODE=$?

# Check test results
if [ $EXIT_CODE -eq 0 ]; then
    print_success "All Cucumber tests passed!"
    
    # Copy test results if they exist
    if [ -d "test-results" ] && [ "$(ls -A test-results)" ]; then
        print_status "Test results available in: test-results/"
    fi
    
    if [ -d "screenshots" ] && [ "$(ls -A screenshots)" ]; then
        print_status "Screenshots available in: screenshots/"
    fi
    
    if [ -d "reports" ] && [ "$(ls -A reports)" ]; then
        print_status "Reports available in: reports/"
    fi
else
    print_error "Some Cucumber tests failed!"
    
    # Show container logs for debugging
    print_status "Container logs for debugging:"
    docker compose -f docker-compose-test.yml ps || true
    docker compose -f docker-compose-test.yml logs --tail=200 --timestamps || true
    
    # Show service logs for debugging
    print_status "Service logs for debugging:"
    print_status "Backend logs:"
    docker compose -f docker-compose-test.yml logs backend --tail=200 --timestamps || true
    print_status "Frontend logs:"
    docker compose -f docker-compose-test.yml logs frontend --tail=200 --timestamps || true
    print_status "Celery logs:"
    docker compose -f docker-compose-test.yml logs celeryworker --tail=200 --timestamps || true
    print_status "Traefik logs:"
    docker compose -f docker-compose-test.yml logs traefik --tail=200 --timestamps || true
    print_status "RabbitMQ logs:"
    docker compose -f docker-compose-test.yml logs rabbitmq --tail=200 --timestamps || true
    print_status "Postgres logs:"
    docker compose -f docker-compose-test.yml logs db --tail=200 --timestamps || true
    
    # Copy test results even on failure
    if [ -d "test-results" ] && [ "$(ls -A test-results)" ]; then
        print_status "Test results available in: test-results/"
    fi
    
    if [ -d "screenshots" ] && [ "$(ls -A screenshots)" ]; then
        print_status "Screenshots available in: screenshots/"
    fi
    
    if [ -d "reports" ] && [ "$(ls -A reports)" ]; then
        print_status "Reports available in: reports/"
    fi
fi

# Cleanup unless --keep-containers is specified
if [ "$KEEP_CONTAINERS" = false ]; then
    cleanup
else
    print_warning "Containers kept running. Use 'docker compose -f docker-compose-test.yml down -v' to stop them."
fi

exit $EXIT_CODE 