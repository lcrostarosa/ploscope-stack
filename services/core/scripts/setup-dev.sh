#!/bin/bash

# Development setup script for PLOScope Core
# This script installs dependencies and sets up pre-commit hooks

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up PLOScope Core development environment...${NC}"
echo ""

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo -e "${RED}❌ Poetry is not installed. Please install Poetry first.${NC}"
    echo -e "${YELLOW}Visit: https://python-poetry.org/docs/#installation${NC}"
    exit 1
fi

# Install dependencies
echo -e "${GREEN}📦 Installing Python dependencies...${NC}"
poetry install
echo -e "${GREEN}✅ Dependencies installed!${NC}"
echo ""

# Install pre-commit hooks
echo -e "${GREEN}🔧 Installing pre-commit hooks...${NC}"
poetry run pre-commit install
echo -e "${GREEN}✅ Pre-commit hooks installed!${NC}"
echo ""

# Run pre-commit on all files to ensure everything is properly formatted
echo -e "${GREEN}🔍 Running pre-commit hooks on all files...${NC}"
poetry run pre-commit run --all-files || {
    echo -e "${YELLOW}⚠️  Some pre-commit hooks failed. This is normal for the first run.${NC}"
    echo -e "${YELLOW}   The hooks will fix formatting issues automatically.${NC}"
}
echo ""

echo -e "${GREEN}🎉 Development environment setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Available commands:${NC}"
echo -e "  ${BLUE}make help${NC}              - Show all available commands"
echo -e "  ${BLUE}make test${NC}              - Run tests"
echo -e "  ${BLUE}make lint${NC}              - Run linting"
echo -e "  ${BLUE}make build${NC}             - Build package"
echo -e "  ${BLUE}make pre-commit-run${NC}    - Run pre-commit hooks manually"
echo ""
echo -e "${BLUE}💡 Pre-commit hooks will now run automatically on every commit!${NC}"

