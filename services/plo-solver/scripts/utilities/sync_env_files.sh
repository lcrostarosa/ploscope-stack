#!/bin/sh
# Environment File Synchronization Script Wrapper
#
# This script provides a convenient way to run the environment file
# synchronization utility with proper error handling and logging.
#
# Usage:
#   ./scripts/utilities/sync_env_files.sh [--dry-run] [--backup]
#   make sync-env-files [DRY_RUN=1] [BACKUP=1]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Function to print colored output
print_info() {
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

# Function to show usage
show_usage() {
    cat << EOF
Environment File Synchronization Script

This script synchronizes the order of environment variables across all env files
in the project, using env.example as the master template.

Usage:
    $0 [OPTIONS]

Options:
    --dry-run     Show what would be changed without making changes
    --backup      Create backup copies of files before modifying them
    --help        Show this help message

Examples:
    $0 --dry-run
    $0 --backup
    $0 --dry-run --backup

Environment Variables:
    DRY_RUN=1     Same as --dry-run
    BACKUP=1      Same as --backup

Makefile Integration:
    make sync-env-files [DRY_RUN=1] [BACKUP=1]
EOF
}

# Parse command line arguments
DRY_RUN=false
BACKUP=false

# Check for environment variables first
if [ "$DRY_RUN" = "1" ]; then
    DRY_RUN=true
fi

if [ "$BACKUP" = "1" ]; then
    BACKUP=true
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup)
            BACKUP=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
print_info "Validating environment..."

# Check if we're in the project root
if [ ! -f "$PROJECT_ROOT/env.example" ]; then
    print_error "env.example not found in project root"
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Check if Python is available
if ! command -v python3 >/dev/null 2>&1; then
    print_error "Python 3 is required but not installed"
    exit 1
fi

# Check if the Python script exists
PYTHON_SCRIPT="$SCRIPT_DIR/sync_env_files.py"
if [ ! -f "$PYTHON_SCRIPT" ]; then
    print_error "Python script not found: $PYTHON_SCRIPT"
    exit 1
fi

# Make the Python script executable
chmod +x "$PYTHON_SCRIPT"

# Build command
CMD="python3 \"$PYTHON_SCRIPT\""

if [ "$DRY_RUN" = true ]; then
    CMD="$CMD --dry-run"
    print_info "Running in dry-run mode (no changes will be made)"
fi

if [ "$BACKUP" = true ]; then
    CMD="$CMD --backup"
    print_info "Backup mode enabled"
fi

# Run the synchronization
print_info "Starting environment file synchronization..."
print_info "Project root: $PROJECT_ROOT"
print_info "Command: $CMD"

# Change to project root and run
cd "$PROJECT_ROOT"

if eval "$CMD"; then
    print_success "Environment file synchronization completed successfully"
    exit 0
else
    print_error "Environment file synchronization failed"
    exit 1
fi 