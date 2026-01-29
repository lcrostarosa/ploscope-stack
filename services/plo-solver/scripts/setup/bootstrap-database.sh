#!/bin/bash

# Database Bootstrap Script for PLOSolver
# This script ensures the database is properly initialized with all migrations

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
}

# Function to wait for database to be ready
wait_for_database() {
    print_status "Waiting for database to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_MIGRATE_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "Database is ready"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts: Database not ready, waiting 2 seconds..."
        sleep 2
        ((attempt++))
    done
    
    print_error "Database failed to become ready after $max_attempts attempts"
    exit 1
}

# Function to check if database exists
check_database_exists() {
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_MIGRATE_HOST" -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
        print_success "Database '$POSTGRES_DB' exists"
        return 0
    else
        print_warning "Database '$POSTGRES_DB' does not exist"
        return 1
    fi
}

# Function to create database if it doesn't exist
create_database() {
    print_status "Creating database '$POSTGRES_DB'..."
    PGPASSWORD="$POSTGRES_PASSWORD" createdb -h "$POSTGRES_MIGRATE_HOST" -U "$POSTGRES_USER" "$POSTGRES_DB" 2>/dev/null || {
        print_warning "Database creation failed (might already exist)"
    }
    print_success "Database '$POSTGRES_DB' is ready"
}

# Function to check current migration status
check_migration_status() {
    print_status "Checking current migration status..."
    
    cd src/backend
    
    # Check if alembic_version table exists
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_MIGRATE_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT * FROM alembic_version;" >/dev/null 2>&1; then
        local current_version=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_MIGRATE_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT version_num FROM alembic_version;" | xargs)
        print_status "Current migration version: $current_version"
    else
        print_warning "No alembic_version table found - database needs initial migration"
        return 1
    fi
    
    cd - >/dev/null
}

# Function to run migrations
run_migrations() {
    print_status "Running database migrations using migration container..."
    
    # Find project root by looking for Makefile
    local current_dir="$(pwd)"
    local project_root=""
    
    # Start from current directory and go up until we find Makefile
    while [ "$(pwd)" != "/" ]; do
        if [ -f "Makefile" ]; then
            project_root="$(pwd)"
            break
        fi
        cd ..
    done
    
    # Go back to original directory
    cd "$current_dir"
    
    if [ -z "$project_root" ]; then
        print_error "Could not find project root (Makefile not found)"
        exit 1
    fi
    
    local backend_dir="$project_root/src/backend"
    
    # Check if backend directory exists
    if [ ! -d "$backend_dir" ]; then
        print_error "Backend directory not found: $backend_dir"
        exit 1
    fi
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not available. Please install Docker first."
        exit 1
    fi
    
    # Build and run migrations using docker-compose db-migrate service
    print_status "Running migrations using docker-compose db-migrate service..."
    if docker compose -f docker-compose-localdev.yml --profile migrate up db-migrate --build --abort-on-container-exit --remove-orphans; then
        print_success "Database migrations completed successfully"
    else
        print_error "Database migrations failed"
        exit 1
    fi
}

# Function to stamp database with current migration
stamp_database() {
    print_status "Stamping database with current migration..."
    
    # Find project root by looking for Makefile
    local current_dir="$(pwd)"
    local project_root=""
    
    # Start from current directory and go up until we find Makefile
    while [ "$(pwd)" != "/" ]; do
        if [ -f "Makefile" ]; then
            project_root="$(pwd)"
            break
        fi
        cd ..
    done
    
    # Go back to original directory
    cd "$current_dir"
    
    if [ -z "$project_root" ]; then
        print_error "Could not find project root (Makefile not found)"
        exit 1
    fi
    
    local backend_dir="$project_root/src/backend"
    
    # Check if backend directory exists
    if [ ! -d "$backend_dir" ]; then
        print_error "Backend directory not found: $backend_dir"
        exit 1
    fi
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not available. Please install Docker first."
        exit 1
    fi
    
    # Stamp database using db-migrate service container
    print_status "Stamping database using db-migrate service..."
    if docker compose -f docker-compose-localdev.yml run --rm db-migrate alembic -c /app/migrations/alembic.ini stamp head; then
        print_success "Database stamped successfully"
    else
        print_error "Database stamping failed"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting database bootstrap process..."
    
    # Check if env file was provided as argument
    local env_file=""
    if [ -n "$1" ]; then
        env_file="$1"
        print_status "Using provided env file: $env_file"
    else
        # Determine environment and load appropriate env file
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
    fi
    
    load_env_file "$env_file"
    
    # Validate environment variables
    validate_env_vars
    
    # Wait for database to be ready
    wait_for_database
    
    # Check if database exists, create if needed
    if ! check_database_exists; then
        create_database
    fi
    
    # Check migration status
    if ! check_migration_status; then
        print_status "Database needs initial migration setup"
        stamp_database
    fi
    
    # Run migrations
    run_migrations
    
    # Final verification
    print_status "Verifying database setup..."
    check_migration_status
    
    print_success "Database bootstrap completed successfully!"
    print_status "Database '$POSTGRES_DB' is ready for use"
}

# Run main function
main "$@" 