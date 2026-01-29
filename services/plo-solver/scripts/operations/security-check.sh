#!/bin/bash

# Security check script for PLOSolver
# This script runs various security checks on the codebase

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

echo "🔒 PLOSolver Security Check"
echo "==========================="

# Check if we're in the right directory
if [ ! -f "../src/frontend/package.json" ] || [ ! -d "../src/backend" ]; then
    echo "❌ Error: This script must be run from the scripts directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: scripts/ directory with parent containing src/frontend/package.json and src/backend/"
    exit 1
fi

# Parse command line arguments
FRONTEND_ONLY=false
BACKEND_ONLY=false
VERBOSE=false
RESULTS_DIR="security-results"

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
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --results-dir)
            RESULTS_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --frontend-only     Run only frontend security checks"
            echo "  --backend-only      Run only backend security checks"
            echo "  --verbose, -v       Verbose output"
            echo "  --results-dir DIR   Directory to store results (default: security-results)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                  # Run all security checks"
            echo "  $0 --frontend-only  # Run only frontend checks"
            echo "  $0 --backend-only   # Run only backend checks"
            echo "  $0 --verbose        # Run with verbose output"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run frontend security checks
run_frontend_checks() {
    print_status "Running frontend security checks..."
    
    cd ../src/frontend
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_status "Installing frontend dependencies..."
        npm install
    fi
    
    # Run npm audit
    print_status "Running npm audit..."
    if npm audit --audit-level=moderate > "$RESULTS_DIR/npm-audit.txt" 2>&1; then
        print_success "npm audit completed"
    else
        print_warning "npm audit found vulnerabilities (see $RESULTS_DIR/npm-audit.txt)"
    fi
    
    # Run ESLint security rules
    print_status "Running ESLint security checks..."
    if npx eslint src/frontend/ --ext .js,.jsx --config .eslintrc.js > "$RESULTS_DIR/eslint-security.txt" 2>&1; then
        print_success "ESLint security checks passed"
    else
        print_warning "ESLint found issues (see $RESULTS_DIR/eslint-security.txt)"
    fi
    
    cd ../../scripts
}

# Function to run backend security checks
run_backend_checks() {
    print_status "Running backend security checks..."
    
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
    
    # Install security tools if not available
    if ! command_exists bandit; then
        print_status "Installing bandit..."
        pip install bandit
    fi
    
    if ! command_exists safety; then
        print_status "Installing safety..."
        pip install safety
    fi
    
    # Run bandit security checks
    print_status "Running bandit security checks..."
    bandit -r src/backend/ -f json -o "$RESULTS_DIR/bandit-results.json" 2>/dev/null || true
    bandit -r src/backend/ -f txt -o "$RESULTS_DIR/bandit-readable.txt" 2>/dev/null || true
    
    if [ -s "$RESULTS_DIR/bandit-readable.txt" ]; then
        print_warning "Bandit found security issues (see $RESULTS_DIR/bandit-readable.txt)"
    else
        print_success "Bandit security checks passed"
    fi
    
    # Run safety checks
    print_status "Running safety checks..."
    safety check --json --output "$RESULTS_DIR/safety-results.json" 2>/dev/null || true
    safety check --output "$RESULTS_DIR/safety-readable.txt" 2>/dev/null || true
    
    if [ -s "$RESULTS_DIR/safety-readable.txt" ]; then
        print_warning "Safety found vulnerabilities (see $RESULTS_DIR/safety-readable.txt)"
    else
        print_success "Safety checks passed"
    fi
    
    # Run flake8 security checks
    print_status "Running flake8 security checks..."
    if command_exists flake8; then
        flake8 . --select=S --output-file="$RESULTS_DIR/flake8-security.txt" 2>/dev/null || true
        
        if [ -s "$RESULTS_DIR/flake8-security.txt" ]; then
            print_warning "Flake8 found security issues (see $RESULTS_DIR/flake8-security.txt)"
        else
            print_success "Flake8 security checks passed"
        fi
    else
        print_warning "Flake8 not installed, skipping flake8 checks"
    fi
    
    cd ../../scripts
}

# Function to run general security checks
run_general_checks() {
    print_status "Running general security checks..."
    
    cd ..
    
    # Check for sensitive files
    print_status "Checking for sensitive files..."
    find . -name "*.env" -o -name ".env*" -o -name "*.key" -o -name "*.pem" -o -name "*.p12" > "$RESULTS_DIR/sensitive-files.txt" 2>/dev/null || true
    
    if [ -s "$RESULTS_DIR/sensitive-files.txt" ]; then
        print_warning "Found potentially sensitive files (see $RESULTS_DIR/sensitive-files.txt)"
    else
        print_success "No sensitive files found"
    fi
    
    # Check for hardcoded secrets
    print_status "Checking for hardcoded secrets..."
    grep -r -i "password\|secret\|key\|token" src/ --exclude-dir=node_modules --exclude-dir=venv --exclude-dir=__pycache__ > "$RESULTS_DIR/potential-secrets.txt" 2>/dev/null || true
    
    if [ -s "$RESULTS_DIR/potential-secrets.txt" ]; then
        print_warning "Found potential hardcoded secrets (see $RESULTS_DIR/potential-secrets.txt)"
    else
        print_success "No obvious hardcoded secrets found"
    fi
    
    cd scripts
}

# Function to generate summary report
generate_summary() {
    print_status "Generating security summary..."
    
    cat > "$RESULTS_DIR/security-summary.txt" << EOF
PLOSolver Security Check Summary
================================
Date: $(date)
Directory: $(pwd)

EOF
    
    # Add npm audit summary
    if [ -f "$RESULTS_DIR/npm-audit.txt" ]; then
        echo "NPM Audit:" >> "$RESULTS_DIR/security-summary.txt"
        grep -E "(found|vulnerabilities)" "$RESULTS_DIR/npm-audit.txt" >> "$RESULTS_DIR/security-summary.txt" 2>/dev/null || echo "  No vulnerabilities found" >> "$RESULTS_DIR/security-summary.txt"
        echo "" >> "$RESULTS_DIR/security-summary.txt"
    fi
    
    # Add bandit summary
    if [ -f "$RESULTS_DIR/bandit-readable.txt" ]; then
        echo "Bandit Security:" >> "$RESULTS_DIR/security-summary.txt"
        head -20 "$RESULTS_DIR/bandit-readable.txt" >> "$RESULTS_DIR/security-summary.txt"
        echo "" >> "$RESULTS_DIR/security-summary.txt"
    fi
    
    # Add safety summary
    if [ -f "$RESULTS_DIR/safety-readable.txt" ]; then
        echo "Safety Check:" >> "$RESULTS_DIR/security-summary.txt"
        head -20 "$RESULTS_DIR/safety-readable.txt" >> "$RESULTS_DIR/security-summary.txt"
        echo "" >> "$RESULTS_DIR/security-summary.txt"
    fi
    
    print_success "Security summary generated: $RESULTS_DIR/security-summary.txt"
}

# Main execution
print_status "Starting security checks..."

# Run checks based on options
if [ "$BACKEND_ONLY" = false ]; then
    run_frontend_checks
fi

if [ "$FRONTEND_ONLY" = false ]; then
    run_backend_checks
fi

run_general_checks
generate_summary

print_success "Security checks completed!"
echo ""
echo "📊 Results saved in: $RESULTS_DIR/"
echo "📋 Summary: $RESULTS_DIR/security-summary.txt"
echo ""
echo "For detailed results, check the files in the results directory." 