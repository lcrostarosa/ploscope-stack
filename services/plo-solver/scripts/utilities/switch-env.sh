#!/bin/bash

# Switch Environment Script
# This script helps switch between development and staging environments

set -e

echo "🔄 Switching environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if environment is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Please specify environment${NC}"
    echo ""
    echo "Usage:"
    echo "  ./scripts/switch-env.sh development"
    echo "  ./scripts/switch-env.sh staging"
    echo ""
    echo "Available environments:"
    echo "  • development - Uses local project paths for logs"
    echo "  • staging     - Uses system paths for logs"
    echo ""
    exit 1
fi

ENVIRONMENT=$1

echo -e "${BLUE}📋 Environment Switch${NC}"
echo "========================"
echo "Target Environment: $ENVIRONMENT"
echo ""

# Validate environment
if [ "$ENVIRONMENT" != "development" ] && [ "$ENVIRONMENT" != "staging" ]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo "Valid options: development, staging"
    exit 1
fi

# Source the appropriate environment file
if [ "$ENVIRONMENT" = "development" ]; then
    echo -e "${BLUE}🔧 Loading development environment...${NC}"
    source env.development
    
    # Setup local log directories
    echo -e "${BLUE}📁 Setting up local log directories...${NC}"
    ./scripts/setup-local-logs.sh
    
    echo -e "${GREEN}✅ Development environment loaded${NC}"
    echo "• Log paths: ./logs (local project directory)"
    echo "• System logs: ./logs/system"
    echo "• Traefik logs: ./logs/traefik"
    
elif [ "$ENVIRONMENT" = "staging" ]; then
    echo -e "${BLUE}🔧 Loading staging environment...${NC}"
    source env.staging
    
    echo -e "${GREEN}✅ Staging environment loaded${NC}"
    echo "• Log paths: /var/log/plosolver (system paths)"
    echo "• System logs: /var/log"
    echo "• Traefik logs: /var/log/traefik"
fi

echo ""
echo -e "${BLUE}📊 Current Configuration${NC}"
echo "=========================="
echo "ENVIRONMENT: $ENVIRONMENT"
echo "LOG_PATH: ${LOG_PATH:-./logs}"
echo "SYSTEM_LOG_PATH: ${SYSTEM_LOG_PATH:-/var/log}"
echo "TRAEFIK_LOG_PATH: ${TRAEFIK_LOG_PATH:-./logs/traefik}"
echo ""

echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Restart your containers:"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo ""
echo "2. Verify the environment:"
echo "   docker-compose ps"
echo ""
echo "3. Check logs are being written to the correct paths"
echo ""
echo -e "${GREEN}✅ Environment switch complete!${NC}" 