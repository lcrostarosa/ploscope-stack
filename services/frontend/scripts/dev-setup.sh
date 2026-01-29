#!/bin/bash

# Frontend Development Setup Script
# This script helps set up the development environment and fixes common npm run issues

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Frontend Development Setup${NC}"
echo ""

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: package.json not found in current directory${NC}"
    echo -e "${YELLOW}💡 Make sure you're in the frontend directory${NC}"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
    npm install
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
else
    echo -e "${GREEN}✅ Dependencies already installed${NC}"
fi

# Install and configure pre-commit hooks
echo -e "${YELLOW}🔧 Setting up pre-commit hooks...${NC}"
if [ ! -d ".husky" ]; then
    echo -e "${YELLOW}📦 Installing husky...${NC}"
    npx husky init
    echo -e "${GREEN}✅ Husky initialized!${NC}"
else
    echo -e "${GREEN}✅ Husky already configured${NC}"
fi

# Make sure the pre-commit hook is executable
if [ -f ".husky/pre-commit" ]; then
    chmod +x .husky/pre-commit
    echo -e "${GREEN}✅ Pre-commit hook is executable${NC}"
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📄 Creating .env file from env.development...${NC}"
    if [ -f "env.development" ]; then
        cp env.development .env
        echo -e "${GREEN}✅ .env file created!${NC}"
    else
        echo -e "${YELLOW}⚠️  No env.development file found, creating basic .env${NC}"
        cat > .env << EOF
NODE_ENV=development
REACT_APP_API_URL=http://localhost:5001/api
REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false
REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=false
REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=false
REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED=true
REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED=false
EOF
        echo -e "${GREEN}✅ Basic .env file created!${NC}"
    fi
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Check if src directory exists
if [ ! -d "src" ]; then
    echo -e "${RED}❌ Error: src directory not found${NC}"
    echo -e "${YELLOW}💡 Make sure you're in the frontend directory with the correct structure${NC}"
    exit 1
fi

# Check if public directory exists
if [ ! -d "src/public" ]; then
    echo -e "${RED}❌ Error: src/public directory not found${NC}"
    echo -e "${YELLOW}💡 Make sure you're in the frontend directory with the correct structure${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Development environment is ready!${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo -e "  ${GREEN}npm start${NC}     - Start development server on port 3001"
echo -e "  ${GREEN}npm run dev${NC}   - Start development server on port 3001"
echo -e "  ${GREEN}npm test${NC}      - Run tests"
echo -e "  ${GREEN}npm run build${NC} - Build for production"
echo ""
echo -e "${BLUE}Docker commands:${NC}"
echo -e "  ${GREEN}make docker-compose-services${NC} - Start backend services"
echo -e "  ${GREEN}make docker-compose-frontend${NC} - Start frontend in Docker"
echo -e "  ${GREEN}make docker-compose-up${NC}      - Start all services"
echo ""
echo -e "${YELLOW}💡 Frontend will be available at: http://localhost:3001${NC}"
echo -e "${YELLOW}💡 Backend API will be available at: http://localhost:5001${NC}"
