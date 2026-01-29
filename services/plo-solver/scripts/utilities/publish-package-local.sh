#!/bin/bash

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

set -e  # Exit on any error

echo -e "${BLUE}📦 Local Package Publishing Tool${NC}"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "src/plosolver_core/pyproject.toml" ]; then
    echo -e "${RED}❌ Error: pyproject.toml not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Function to get version from pyproject.toml
get_version() {
    python -c "import tomllib; print(tomllib.load(open('src/plosolver_core/pyproject.toml', 'rb'))['project']['version'])"
}

# Function to build the package
build_package() {
    echo -e "${BLUE}🔨 Building package...${NC}"
    cd src/plosolver_core
    
    # Clean previous builds
    rm -rf dist/ build/ *.egg-info/
    
    # Build the package
    python -m build
    
    echo -e "${GREEN}✅ Package built successfully!${NC}"
    echo -e "${BLUE}📁 Distribution files created in: src/plosolver_core/dist/${NC}"
    ls -la dist/
    
    cd ../..
}

# Function to publish to TestPyPI (DISABLED - Public repository)
publish_to_testpypi() {
    echo -e "${RED}❌ Publishing to TestPyPI is disabled for security reasons${NC}"
    echo -e "${YELLOW}Use GitHub Packages for internal distribution instead${NC}"
    exit 1
}

# Function to publish to PyPI (DISABLED - Public repository)
publish_to_pypi() {
    echo -e "${RED}❌ Publishing to PyPI is disabled for security reasons${NC}"
    echo -e "${YELLOW}Use GitHub Packages for internal distribution instead${NC}"
    exit 1
}

# Function to publish to GitHub Packages
publish_to_github_packages() {
    echo -e "${BLUE}🚀 Publishing to GitHub Packages...${NC}"
    
    echo -e "${YELLOW}Note: GitHub Packages for Python requires complex setup and authentication.${NC}"
    echo -e "${YELLOW}The recommended approach is to use the existing GitHub Actions workflow.${NC}"
    echo ""
    echo -e "${BLUE}📋 Available options:${NC}"
    echo -e "${BLUE}1. Use 'make publish-package' to trigger GitHub Actions workflow${NC}"
    echo -e "${BLUE}2. Create local wheel file for internal use${NC}"
    echo ""
    echo -e "${YELLOW}Creating local wheel file for internal use...${NC}"
    
    # Copy wheel file to a shared location for internal use
    cd src/plosolver_core
    mkdir -p ../../packages
    wheel_file=$(ls dist/*.whl | head -n 1)
    if [ -z "$wheel_file" ]; then
        echo -e "${RED}❌ No wheel file found in dist/.${NC}"
        exit 1
    fi
    cp "$wheel_file" ../../packages/
    cd ../..
    
    echo -e "${GREEN}✅ Package wheel file created for internal use!${NC}"
    echo -e "${BLUE}📁 Wheel file location: packages/$(basename "$wheel_file")${NC}"
    echo -e "${BLUE}💡 To use this wheel file, add it to your requirements.txt:${NC}"
    echo -e "${BLUE}   ./packages/$(basename "$wheel_file")${NC}"
    echo ""
    echo -e "${BLUE}🚀 To publish to GitHub Packages, use:${NC}"
    echo -e "${BLUE}   make publish-package${NC}"
}

# Function to install locally for testing
install_locally() {
    echo -e "${BLUE}🧪 Installing package locally for testing...${NC}"
    
    cd src/plosolver_core
    
    # Install in development mode
    pip install -e .
    
    cd ../..
    
    echo -e "${GREEN}✅ Package installed locally!${NC}"
    echo -e "${BLUE}You can now import and test the package.${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  build                    Build the package only"
    echo "  github                   Build and create local wheel file"
    echo "  install                  Install locally for testing"
    echo "  help                     Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_TOKEN             Not used (use make publish-package instead)"
    echo ""
    echo "Security Note:"
    echo "  Public publishing (PyPI/TestPyPI) is disabled for security reasons."
    echo "  Local wheel files are created for internal distribution."
    echo "  Use 'make publish-package' to publish to GitHub Packages."
    echo ""
    echo "Examples:"
    echo "  $0 build                 # Build package only"
    echo "  $0 github                # Create local wheel file"
    echo "  $0 install               # Install locally for testing"
    echo "  make publish-package     # Publish to GitHub Packages via workflow"
}

# Main script logic
case "${1:-help}" in
    "build")
        build_package
        ;;
    "github")
        build_package
        publish_to_github_packages
        ;;
    "install")
        build_package
        install_locally
        ;;
    "help"|*)
        show_usage
        ;;
esac
