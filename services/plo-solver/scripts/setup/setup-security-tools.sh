#!/bin/bash

# PLOSolver Security Tools Setup Script
# Installs all security analysis tools for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command_exists node; then
        missing_tools+=("node")
    fi
    
    if ! command_exists npm; then
        missing_tools+=("npm")
    fi
    
    if ! command_exists python3; then
        missing_tools+=("python3")
    fi
    
    if ! command_exists pip; then
        missing_tools+=("pip")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Please install the missing tools:"
        echo "  - Node.js: https://nodejs.org/"
        echo "  - Python 3: https://python.org/"
        exit 1
    fi
    
    print_success "All prerequisites found"
}

# Install Node.js security tools
install_node_security_tools() {
    print_header "Installing Node.js Security Tools"
    
    print_status "Installing ESLint security plugins..."
    cd src/frontend && npm install --save-dev \
        eslint \
        eslint-plugin-security \
        eslint-plugin-react \
        eslint-plugin-react-hooks
    
    print_success "Node.js security tools installed"
}

# Install Python security tools
install_python_security_tools() {
    print_header "Installing Python Security Tools"
    
    print_status "Installing Python security analysis tools..."
    pip install --upgrade \
        bandit \
        safety \
        pip-audit \
        semgrep
    
    print_success "Python security tools installed"
}

# Install Trivy (cross-platform)
install_trivy() {
    print_header "Installing Trivy Scanner"
    
    if command_exists trivy; then
        print_status "Trivy already installed, updating..."
        if command_exists brew; then
            brew upgrade aquasecurity/trivy/trivy
        else
            print_warning "Cannot auto-update Trivy. Please update manually."
        fi
    else
        print_status "Installing Trivy..."
        
        # Detect OS and install accordingly
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists brew; then
                brew install aquasecurity/trivy/trivy
            else
                print_error "Homebrew not found. Please install Homebrew first or install Trivy manually."
                echo "Visit: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
                return 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            print_status "Downloading Trivy for Linux..."
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        else
            print_warning "Unsupported OS. Please install Trivy manually."
            echo "Visit: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
            return 1
        fi
    fi
    
    if command_exists trivy; then
        print_success "Trivy installed successfully"
        trivy --version
    else
        print_error "Trivy installation failed"
        return 1
    fi
}

# Verify installations
verify_installations() {
    print_header "Verifying Installations"
    
    local tools=(
        "eslint:ESLint"
        "bandit:Bandit"
        "safety:Safety"
        "pip-audit:pip-audit"
        "semgrep:Semgrep"
        "trivy:Trivy"
    )
    
    local all_good=true
    
    for tool_info in "${tools[@]}"; do
        local tool="${tool_info%%:*}"
        local name="${tool_info##*:}"
        
        if command_exists "$tool"; then
            print_success "$name is available"
        else
            print_error "$name is not available"
            all_good=false
        fi
    done
    
    if [ "$all_good" = true ]; then
        print_success "All security tools are properly installed!"
    else
        print_error "Some tools are missing. Please check the installation."
        return 1
    fi
}

# Create security config files
create_config_files() {
    print_header "Creating Configuration Files"
    
    # Create .bandit config if it doesn't exist
    if [ ! -f ".bandit" ]; then
        print_status "Creating .bandit configuration..."
        cat > .bandit << EOF
[bandit]
exclude_dirs = node_modules,dist,build,coverage,.git
skips = B101,B601
EOF
        print_success ".bandit configuration created"
    fi
    
    # Create semgrep config if it doesn't exist
    if [ ! -f ".semgrepignore" ]; then
        print_status "Creating .semgrepignore..."
        cat > .semgrepignore << EOF
node_modules/
dist/
build/
coverage/
.git/
*.min.js
*.bundle.js
EOF
        print_success ".semgrepignore created"
    fi
    
    print_success "Configuration files ready"
}

# Main installation function
main() {
    print_header "PLOSolver Security Tools Setup"
    print_status "This script will install all security analysis tools"
    
    # Check prerequisites
    check_prerequisites
    
    # Install tools
    install_node_security_tools
    install_python_security_tools
    install_trivy
    
    # Create config files
    create_config_files
    
    # Verify installations
    verify_installations
    
    print_header "Setup Complete!"
    print_success "All security tools have been installed successfully"
    
    echo ""
    print_status "Next steps:"
    echo "  1. Run './scripts/operations/security-check.sh' to perform a security analysis"
    echo "  2. Check the generated reports in the 'security-results' directory"
    echo "  3. Set up regular security scans in your development workflow"
    echo ""
    print_status "For help with the security checker, run:"
    echo "  ./scripts/operations/security-check.sh --help"
}

# Run main function
main "$@" 