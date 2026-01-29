#!/bin/bash

# Celery Worker Development Script
# This script runs the Celery worker natively with hot reloading for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
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

# Kill any existing Celery worker processes for this project
EXISTING_CELERY_PIDS=$(pgrep -f "celery.*main.celery_app.celery" || true)
if [ ! -z "$EXISTING_CELERY_PIDS" ]; then
    print_warning "Killing existing Celery worker processes: $EXISTING_CELERY_PIDS"
    echo $EXISTING_CELERY_PIDS | xargs kill -9 2>/dev/null || true
    sleep 2
    print_success "Old Celery worker processes killed."
fi

# Check if we're in the right directory
if [ ! -f "Makefile" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Starting Celery Worker in Development Mode..."

# Load environment variables
if [ -f "env.development" ]; then
    print_status "Loading environment variables from env.development"
    export $(grep -v '^#' env.development | xargs)
else
    print_warning "env.development not found, using default values"
fi

# The following variables are sourced from env.development:
#   CELERY_BROKER_URL
#   DATABASE_URL
#   PGPASSWORD (as POSTGRES_PASSWORD)
#   ...and all other required environment variables

# Check if virtual environment exists
if [ ! -d "src/backend/venv" ]; then
    print_error "Virtual environment not found. Please run 'make setup' first."
    exit 1
fi

# Activate virtual environment
print_status "Activating virtual environment..."
if [ -f "src/backend/venv/bin/activate" ]; then
    source src/backend/venv/bin/activate
elif [ -f "src/backend/venv/Scripts/activate" ]; then
    source src/backend/venv/Scripts/activate
else
    print_error "Failed to activate virtual environment"
    exit 1
fi

# Check if required packages are installed
print_status "Checking dependencies..."
if ! python -c "import celery" 2>/dev/null; then
    print_error "Celery not found. Installing dependencies..."
    pip install -r src/celery/requirements.txt
fi

# No need to pip-install plosolver_core in dev mode; PYTHONPATH handles it

# Check if backend dependencies are available
if ! python -c "import flask" 2>/dev/null; then
    print_error "Flask not found. Installing backend dependencies..."
    pip install -r src/backend/requirements.txt
fi

# Check if RabbitMQ is running
print_status "Checking RabbitMQ connection..."
if ! curl -s http://localhost:15672/api/overview > /dev/null 2>&1; then
    print_error "RabbitMQ is not running. Please start the infrastructure services first:"
    echo "  docker compose -f docker-compose-local-services.yml up -d"
    exit 1
fi

# Check if PostgreSQL is running
print_status "Checking PostgreSQL connection..."
if ! pg_isready -h localhost -p 5432 -U postgres > /dev/null 2>&1; then
    print_error "PostgreSQL is not running. Please start the infrastructure services first:"
    echo "  docker compose -f docker-compose-local-services.yml up -d"
    exit 1
fi

# Record repo root and set up PYTHONPATH with absolute path so it works after cd
REPO_ROOT="$(pwd)"
export PYTHONPATH="${PYTHONPATH}:${REPO_ROOT}/src"

print_success "Environment ready!"

# Function to cleanup on exit
cleanup() {
    print_status "Shutting down Celery worker..."
    if [ ! -z "$CELERY_PID" ]; then
        kill $CELERY_PID 2>/dev/null || true
    fi
    print_success "Celery worker stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

print_status "Starting Celery worker with hot reloading..."

# Start Celery worker with auto-reload
cd src/celery/src
celery -A main.celery_app.celery worker \
    --loglevel=info \
    --concurrency=2 \
    --include=main.tasks \
    --queues=spot_simulation,solver_analysis \
    &
CELERY_PID=$!

print_success "Celery worker started!"
print_success "Worker PID: $CELERY_PID"
print_success "Health check available at: http://localhost:5002/health"
print_success "Celery worker will auto-reload when files change"
echo ""
print_status "Press Ctrl+C to stop the worker"

# Wait for processes
wait $CELERY_PID