#!/bin/bash

# Test Database Bootstrap Script for PLOSolver
# This script tests the database bootstrap functionality

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
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

# Function to check if environment file exists and load it
load_env_file() {
    local env_file="$1"
    if [ -f "$env_file" ]; then
        print_status "Loading environment from $env_file"
        set -a
        source "$env_file"
        set +a
    else
        print_warning "Environment file $env_file not found, using current environment"
    fi
}

# Function to validate required environment variables
validate_env_vars() {
    local required_vars=("DATABASE_URL" "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_HOST")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        print_error "Please ensure these are set in your environment file or environment"
        exit 1
    fi
    
    print_success "All required environment variables are set"
    print_status "DATABASE_URL: $DATABASE_URL"
    print_status "POSTGRES_DB: $POSTGRES_DB"
    print_status "POSTGRES_USER: $POSTGRES_USER"
    print_status "POSTGRES_HOST: $POSTGRES_HOST"
}

# Function to test database connection
test_database_connection() {
    print_status "Testing database connection..."
    
    # Test with psql if available
    if command -v psql &> /dev/null; then
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "Database connection successful with psql"
            return 0
        else
            print_warning "Database connection failed with psql"
        fi
    fi
    
    # Test with Python using virtual environment
    print_status "Testing database connection with Python (virtual environment)..."
    cd src/backend
    
    # Activate virtual environment if it exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
    
    python3 -c "
import os
import sys
from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError

try:
    engine = create_engine(os.environ['DATABASE_URL'])
    with engine.connect() as conn:
        result = conn.execute('SELECT 1')
        print('Database connection successful with SQLAlchemy')
except OperationalError as e:
    print(f'Database connection failed: {e}')
    sys.exit(1)
except Exception as e:
    print(f'Unexpected error: {e}')
    sys.exit(1)
"
    
    cd - >/dev/null
}

# Function to check migration status
check_migration_status() {
    print_status "Checking current migration status..."
    
    cd src/backend
    
    # Activate virtual environment if it exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
    
    # Check if alembic_version table exists using Python
    python3 -c "
import os
import sys
from sqlalchemy import create_engine, text

try:
    engine = create_engine(os.environ['DATABASE_URL'])
    with engine.connect() as conn:
        result = conn.execute(text('SELECT version_num FROM alembic_version'))
        version = result.fetchone()
        if version:
            print(f'Current migration version: {version[0]}')
        else:
            print('No migration version found')
except Exception as e:
    print(f'Error checking migration status: {e}')
    sys.exit(1)
"
    
    cd - >/dev/null
}

# Function to run migrations
run_migrations() {
    print_status "Running database migrations..."
    
    cd src/backend
    
    # Activate virtual environment if it exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
    
    # Run migrations
    if alembic -c migrations/alembic.ini upgrade head; then
        print_success "Database migrations completed successfully"
    else
        print_error "Database migrations failed"
        exit 1
    fi
    
    cd - >/dev/null
}

# Main execution
main() {
    print_status "Starting database bootstrap test..."
    
    # Determine environment and load appropriate env file
    local env_file=""
    case "${ENV:-development}" in
        "production")
            env_file="env.production"
            ;;
        "staging")
            env_file="env.staging"
            ;;
        "development"|*)
            env_file="env.development"
            ;;
    esac
    
    print_status "Using environment: ${ENV:-development}"
    load_env_file "$env_file"
    
    # Validate environment variables
    validate_env_vars
    
    # Test database connection
    test_database_connection
    
    # Check migration status
    check_migration_status
    
    # Run migrations
    run_migrations
    
    # Final verification
    print_status "Verifying database setup..."
    check_migration_status
    
    print_success "Database bootstrap test completed successfully!"
}

# Run main function
main "$@" 