#!/bin/bash

# Dependency setup script for PLOSolver
# This script installs all required dependencies for development

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

echo "📦 PLOSolver Dependency Setup"
echo "=============================="

# Check if we're in the right directory
if [ ! -f "src/frontend/package.json" ] || [ ! -d "src/backend" ]; then
    echo "❌ Error: This script must be run from the PLOSolver root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Directory containing src/frontend/package.json and src/backend/"
    exit 1
fi

# Check operating system
OS=$(uname -s)
case "$OS" in
    Darwin*)    # macOS
        PLATFORM="macos"
        ;;
    Linux*)     # Linux
        PLATFORM="linux"
        ;;
    MINGW*|CYGWIN*|MSYS*)  # Windows
        PLATFORM="windows"
        ;;
    *)
        print_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

print_status "Detected platform: $PLATFORM"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    case $PLATFORM in
        macos)
            if ! command_exists brew; then
                print_error "Homebrew is required but not installed"
                echo "Please install Homebrew first: https://brew.sh/"
                exit 1
            fi
            
            print_status "Installing packages via Homebrew..."
            brew install python@3.11 pyenv node postgresql rabbitmq traefik
            
            ;;
        linux)
            if command_exists apt-get; then
                print_status "Installing packages via apt-get..."
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip python3-venv nodejs npm postgresql postgresql-contrib rabbitmq-server
            elif command_exists yum; then
                print_status "Installing packages via yum..."
                sudo yum install -y python3 python3-pip nodejs npm postgresql postgresql-server rabbitmq-server
            else
                print_error "Unsupported package manager"
                exit 1
            fi
            ;;
        windows)
            print_warning "Windows support is provided via WSL2 + Docker Desktop."
            echo "  👉 Run the PowerShell helper from repo root:"
            echo "     powershell -ExecutionPolicy Bypass -File .\\scripts\\setup\\setup-dependencies.ps1"
            echo "  This installs WSL Ubuntu 22.04, Docker Desktop, and runs 'make deps-*' inside WSL."
            ;;
    esac
}

# Function to install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    cd src/backend
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        print_error "Failed to activate virtual environment"
        exit 1
    fi
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install requirements
    print_status "Installing Python requirements..."
    pip install -r requirements.txt
    
    # Install test requirements if they exist
    if [[ -f "requirements-test.txt" ]]; then
        print_status "Installing test requirements..."
        pip3 install -r requirements-test.txt
    fi
    
    cd ../..
}

# Function to install Node.js dependencies
install_node_deps() {
    print_status "Installing Node.js dependencies..."
    
    # Check if Node.js is installed
    if ! command_exists node; then
        print_error "Node.js is not installed"
        exit 1
    fi
    
    # Check if npm is installed
    if ! command_exists npm; then
        print_error "npm is not installed"
        exit 1
    fi
    
    # Install dependencies
    print_status "Installing npm packages..."
    cd src/frontend
    npm install
    cd ../..
}

# Function to setup database
setup_database() {
    print_status "Setting up database..."
    
    case $PLATFORM in
        macos)
            # Create database and user for PostgreSQL
            if command_exists createdb; then
                print_status "Creating PostgreSQL database..."
                createdb plosolver 2>/dev/null || print_warning "Database 'plosolver' already exists"
            fi
            ;;
        linux)
            # For Linux, we'll let the application handle database creation
            print_status "Database setup will be handled by the application"
            ;;
        windows)
            print_warning "Please set up PostgreSQL database manually"
            ;;
    esac
}

# Function to setup RabbitMQ
setup_rabbitmq() {
    print_status "Setting up RabbitMQ..."
    
    case $PLATFORM in
        macos)
            # RabbitMQ is already started by brew services
            print_status "RabbitMQ should be running via brew services"
            ;;
        linux)
            if command_exists systemctl; then
                print_status "Starting RabbitMQ service..."
                sudo systemctl start rabbitmq-server
                sudo systemctl enable rabbitmq-server
            fi
            ;;
        windows)
            print_warning "Please start RabbitMQ service manually"
            ;;
    esac
}

# Function to verify installations
verify_installations() {
    print_status "Verifying installations..."
    
    # Check Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        print_success "Python: $PYTHON_VERSION"
    else
        print_error "Python 3 is not installed"
    fi
    
    # Check Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version 2>&1)
        print_success "Node.js: $NODE_VERSION"
    else
        print_error "Node.js is not installed"
    fi
    
    # Check npm
    if command_exists npm; then
        NPM_VERSION=$(npm --version 2>&1)
        print_success "npm: $NPM_VERSION"
    else
        print_error "npm is not installed"
    fi
    
    # Check PostgreSQL
    if command_exists psql; then
        PSQL_VERSION=$(psql --version 2>&1)
        print_success "PostgreSQL: $PSQL_VERSION"
    else
        print_error "PostgreSQL is not installed"
    fi
    
    # Check RabbitMQ
    if command_exists rabbitmqctl; then
        print_success "RabbitMQ: Installed"
    else
        print_error "RabbitMQ is not installed"
    fi
}

# Main execution
print_status "Starting dependency installation..."

# Install system dependencies
install_system_deps

# Install Python dependencies
install_python_deps

# Install Node.js dependencies
install_node_deps

# Setup database
setup_database

# Setup RabbitMQ
setup_rabbitmq

# Verify installations
verify_installations

print_success "Dependency installation completed!"
echo ""
echo "🎉 PLOSolver is ready for development!"
echo ""
echo "Next steps:"
echo "  1. Run 'make run' to start the application"
echo "  2. Run 'make test' to run tests"
echo "  3. Run 'make docs' to generate documentation"
echo ""
echo "For more information, see the README.md file." 