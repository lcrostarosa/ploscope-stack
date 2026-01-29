#!/bin/bash

# GitHub Actions Self-Hosted Runner Setup Script for macOS
# This script sets up a local runner to test CI pipelines without consuming GitHub minutes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RUNNER_VERSION="2.311.0"
RUNNER_DIR="$HOME/actions-runner"
RUNNER_USER="$USER"
SERVICE_NAME="github.actions.runner"

print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "🚀 GitHub Actions Self-Hosted Runner Setup (macOS)"
    echo "================================================="
    echo -e "${NC}"
}

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --install     Install the self-hosted runner"
    echo "  --configure   Configure the runner (requires token)"
    echo "  --start       Start the runner service"
    echo "  --stop        Stop the runner service"
    echo "  --status      Check runner status"
    echo "  --remove      Remove the runner"
    echo "  --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --install"
    echo "  $0 --configure"
    echo "  $0 --start"
    echo "  $0 --status"
}

check_dependencies() {
    print_status "Checking system dependencies..."
    
    # Check for required commands
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Some CI jobs may fail."
        echo "Install Docker Desktop from https://www.docker.com/products/docker-desktop"
    fi
    
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Frontend tests may fail."
        echo "Install Node.js from https://nodejs.org/"
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_warning "Python3 not found. Backend tests may fail."
        echo "Install Python from https://www.python.org/downloads/"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies and try again."
        echo "You can install them using Homebrew: brew install ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "Dependencies check completed"
}

install_runner() {
    print_status "Installing GitHub Actions runner..."
    
    # Create runner directory
    mkdir -p "$RUNNER_DIR"
    cd "$RUNNER_DIR"
    
    # Download runner for macOS
    print_status "Downloading runner version $RUNNER_VERSION for macOS..."
    curl -o actions-runner-osx-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-osx-x64-$RUNNER_VERSION.tar.gz
    
    # Extract runner
    print_status "Extracting runner..."
    tar xzf ./actions-runner-osx-x64-$RUNNER_VERSION.tar.gz
    
    # Clean up download
    rm actions-runner-osx-x64-$RUNNER_VERSION.tar.gz
    
    print_success "Runner installed successfully"
}

configure_runner() {
    print_status "Configuring runner..."
    
    if [ ! -d "$RUNNER_DIR" ]; then
        print_error "Runner not installed. Run --install first."
        exit 1
    fi
    
    cd "$RUNNER_DIR"
    
    print_warning "You need to configure the runner with a token from GitHub."
    echo ""
    echo "To get a token:"
    echo "1. Go to your GitHub repository"
    echo "2. Settings → Actions → Runners"
    echo "3. Click 'New self-hosted runner'"
    echo "4. Copy the token from the configuration command"
    echo ""
    echo "Or use the GitHub CLI:"
    echo "  gh api repos/:owner/:repo/actions/runners/token --method POST"
    echo ""
    
    read -p "Enter the runner token: " RUNNER_TOKEN
    
    if [ -z "$RUNNER_TOKEN" ]; then
        print_error "Token is required"
        exit 1
    fi
    
    # Configure runner
    ./config.sh --url https://github.com/PLOScope/plo-solver --token "$RUNNER_TOKEN" --unattended --replace
    
    print_success "Runner configured successfully"
}

install_service() {
    print_status "Installing runner as a launchd service..."
    
    if [ ! -f "$RUNNER_DIR/config.sh" ]; then
        print_error "Runner not configured. Run --configure first."
        exit 1
    fi
    
    cd "$RUNNER_DIR"
    
    # Install service
    ./svc.sh install "$RUNNER_USER"
    
    print_success "Runner service installed"
}

start_runner() {
    print_status "Starting runner service..."
    
    if [ ! -f "$RUNNER_DIR/config.sh" ]; then
        print_error "Runner not configured. Run --configure first."
        exit 1
    fi
    
    cd "$RUNNER_DIR"
    
    if [ -f "./svc.sh" ]; then
        # Start as service
        ./svc.sh start
        print_success "Runner service started"
    else
        # Start manually
        print_warning "Starting runner manually (not as service)"
        ./run.sh &
        print_success "Runner started manually (PID: $!)"
    fi
}

stop_runner() {
    print_status "Stopping runner..."
    
    cd "$RUNNER_DIR"
    
    if [ -f "./svc.sh" ]; then
        ./svc.sh stop
        print_success "Runner service stopped"
    else
        # Stop manual process
        local pid=$(pgrep -f "run.sh")
        if [ -n "$pid" ]; then
            kill "$pid"
            print_success "Runner stopped (PID: $pid)"
        else
            print_warning "No runner process found"
        fi
    fi
}

check_status() {
    print_status "Checking runner status..."
    
    if [ ! -d "$RUNNER_DIR" ]; then
        print_error "Runner not installed"
        exit 1
    fi
    
    cd "$RUNNER_DIR"
    
    # Check if runner is configured
    if [ -f ".runner" ]; then
        print_success "Runner is configured"
        
        # Check service status
        if [ -f "./svc.sh" ]; then
            local status=$(./svc.sh status 2>/dev/null || echo "not running")
            echo "Service status: $status"
        fi
        
        # Check if process is running
        local pid=$(pgrep -f "run.sh")
        if [ -n "$pid" ]; then
            print_success "Runner process is running (PID: $pid)"
        else
            print_warning "Runner process is not running"
        fi
    else
        print_warning "Runner is not configured"
    fi
}

remove_runner() {
    print_status "Removing runner..."
    
    # Stop runner first
    if [ -d "$RUNNER_DIR" ]; then
        cd "$RUNNER_DIR"
        
        if [ -f "./svc.sh" ]; then
            ./svc.sh stop 2>/dev/null || true
            ./svc.sh uninstall 2>/dev/null || true
        fi
        
        # Remove runner directory
        cd ..
        rm -rf "$RUNNER_DIR"
        print_success "Runner removed"
    else
        print_warning "Runner directory not found"
    fi
}

setup_environment() {
    print_status "Setting up environment for CI testing..."
    
    # Create necessary directories
    mkdir -p "$HOME/.cache/pip"
    mkdir -p "$HOME/.npm"
    
    # Set environment variables for local testing
    export RUNNER_OS="macOS"
    export RUNNER_ARCH="X64"
    export RUNNER_TEMP="$HOME/actions-runner/_work/_temp"
    export RUNNER_TOOL_CACHE="$HOME/actions-runner/_work/_tool"
    
    print_success "Environment setup completed"
}

# Main script logic
main() {
    print_header
    
    case "${1:-}" in
        --install)
            check_dependencies
            install_runner
            ;;
        --configure)
            configure_runner
            ;;
        --install-service)
            install_service
            ;;
        --start)
            start_runner
            ;;
        --stop)
            stop_runner
            ;;
        --status)
            check_status
            ;;
        --remove)
            remove_runner
            ;;
        --setup-env)
            setup_environment
            ;;
        --help|-h)
            print_usage
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 