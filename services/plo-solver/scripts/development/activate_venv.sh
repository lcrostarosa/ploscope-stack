#!/bin/bash

# Virtual Environment Activation Helper
# This script ensures the Python virtual environment is properly activated
# and all required dependencies are available

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/src/backend"
VENV_DIR="$BACKEND_DIR/venv"

echo -e "${BLUE}🔍 Checking virtual environment...${NC}"

# Check if we're in the right directory structure
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Error: Backend directory not found at $BACKEND_DIR${NC}"
    echo -e "${RED}   Please run this script from the project root directory${NC}"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}📦 Virtual environment not found. Creating new one...${NC}"
    cd "$BACKEND_DIR"
    python3 -m venv venv
    cd "$PROJECT_ROOT"
fi

# Activate virtual environment
echo -e "${BLUE}🔧 Activating virtual environment...${NC}"
source "$VENV_DIR/bin/activate"

# Verify activation
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${RED}❌ Error: Virtual environment activation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Virtual environment activated: $VIRTUAL_ENV${NC}"

# Check Python path
PYTHON_PATH=$(python -c "import sys; print(sys.executable)")
echo -e "${BLUE}🐍 Using Python: $PYTHON_PATH${NC}"

# Verify pip is pointing to the virtual environment
PIP_PATH=$(pip --version | grep -o '/.*/site-packages' | head -1)
if [[ "$PIP_PATH" != *"venv"* ]]; then
    echo -e "${RED}❌ Error: pip is not pointing to virtual environment${NC}"
    echo -e "${RED}   Expected: $VENV_DIR/lib/python*/site-packages${NC}"
    echo -e "${RED}   Got: $PIP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ pip is correctly configured for virtual environment${NC}"

# Check for required dependencies
echo -e "${BLUE}🔍 Checking required dependencies...${NC}"

REQUIRED_PACKAGES=("flask" "celery" "pika" "flask_socketio")

for package in "${REQUIRED_PACKAGES[@]}"; do
    if python -c "import $package" 2>/dev/null; then
        echo -e "${GREEN}✅ $package is available${NC}"
    else
        echo -e "${YELLOW}⚠️  $package not found. Installing dependencies...${NC}"
        cd "$BACKEND_DIR"
        pip install -r requirements.txt
        cd "$PROJECT_ROOT"
        break
    fi
done

echo -e "${GREEN}✅ Virtual environment is ready!${NC}"

# Export environment variables for child processes
export VIRTUAL_ENV
export PATH="$VENV_DIR/bin:$PATH"
export PYTHONPATH="$BACKEND_DIR:$PYTHONPATH"

# If this script is sourced, we're done
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    return 0
fi

# If this script is executed directly, run the command passed as arguments
if [ $# -gt 0 ]; then
    echo -e "${BLUE}🚀 Executing: $*${NC}"
    exec "$@"
fi 