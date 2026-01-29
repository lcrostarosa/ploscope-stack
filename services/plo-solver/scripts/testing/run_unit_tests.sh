#!/bin/bash

# Unit Test Runner for PLOSolver Backend
# This script runs only unit tests, excluding integration tests

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

echo "🧪 PLOSolver Unit Test Suite"
echo "============================="

# Determine project root
if [ -d "../src/backend" ]; then
    PROJECT_ROOT="$(cd .. && pwd)"
elif [ -d "src/backend" ]; then
    PROJECT_ROOT="$(pwd)"
else
    print_error "❌ Error: Could not find project root (src/backend)"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Parse command line arguments
COVERAGE=false
VERBOSE=false
FAIL_FAST=false

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
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --coverage          Run tests with coverage"
            echo "  --verbose, -v       Verbose output"
            echo "  --fail-fast, -x     Stop on first failure"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                  # Run unit tests"
            echo "  $0 --coverage       # Run unit tests with coverage"
            echo "  $0 --verbose        # Run unit tests with verbose output"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Backend Unit Tests
print_status "Running Backend Unit Tests..."
print_status "Excluding integration tests..."

# Load test environment variables if env.test exists
if [ -f "$PROJECT_ROOT/env.test" ]; then
    print_status "Loading test environment variables from env.test..."
    set -a
    source "$PROJECT_ROOT/env.test"
    set +a
fi

cd "$PROJECT_ROOT/src/backend"

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
fi

# Always ensure dependencies are installed/updated for reproducible tests
print_status "Ensuring backend test dependencies are installed..."
if [ -n "$NEXUS_PYPI_URL" ]; then
    PIP_INDEX_URL="$NEXUS_PYPI_URL" PIP_TRUSTED_HOST="nexus.ploscope.com" pip install -r requirements.txt
    PIP_INDEX_URL="$NEXUS_PYPI_URL" PIP_TRUSTED_HOST="nexus.ploscope.com" pip install -r requirements-test.txt
else
    pip install -r requirements.txt
    pip install -r requirements-test.txt
fi

# Ensure plosolver_core is available as an installed package (treat as external)
python - <<'PY'
import sys
try:
    import plosolver_core  # noqa: F401
    print("plosolver_core already installed")
except Exception:
    print("plosolver_core not installed; installing editable from local source...")
    import subprocess, os
    repo_root = os.path.abspath(os.path.join(os.getcwd(), os.pardir, os.pardir))
    core_path = os.path.join(repo_root, 'src', 'plosolver_core')
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-e', core_path])
PY

# Build pytest command
PYTEST_CMD="python -m pytest"

# Use unit test configuration file and specify test path
PYTEST_CMD="$PYTEST_CMD -c pytest_unit.ini tests/unit/"

# Add options
if [ "$COVERAGE" = true ]; then
    print_status "Running unit tests with coverage..."
    PYTEST_CMD="$PYTEST_CMD --cov=. --cov-report=html --cov-report=term-missing"
fi

if [ "$VERBOSE" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -v"
fi

if [ "$FAIL_FAST" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -x"
fi

print_status "Command: $PYTEST_CMD"

# Run backend unit tests
eval $PYTEST_CMD

UNIT_EXIT_CODE=$?

if [ $UNIT_EXIT_CODE -eq 0 ]; then
    print_success "Backend unit tests passed!"
else
    print_error "Backend unit tests failed!"
fi

cd "$PROJECT_ROOT/scripts"

# Summary
echo ""
echo "📊 Unit Test Results Summary"
echo "============================"

if [ $UNIT_EXIT_CODE -eq 0 ]; then
    print_success "Backend Unit Tests: ✅ PASSED"
else
    print_error "Backend Unit Tests: ❌ FAILED"
fi

# Exit with appropriate code
if [ $UNIT_EXIT_CODE -ne 0 ]; then
    exit $UNIT_EXIT_CODE
fi

print_success "All unit tests completed successfully!" 