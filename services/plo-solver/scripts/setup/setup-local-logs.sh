#!/bin/bash

# Setup Local Log Directories for Development
# This script creates the necessary log directories for local development

set -e

echo "📁 Setting up local log directories for development..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Local Log Setup${NC}"
echo "====================="

# Create log directories
echo -e "${BLUE}🔧 Creating log directories...${NC}"

# Main logs directory
if [ ! -d "./logs" ]; then
    mkdir -p ./logs
    echo -e "${GREEN}✅ Created ./logs directory${NC}"
else
    echo -e "${YELLOW}⚠️  ./logs directory already exists${NC}"
fi

# System logs directory
if [ ! -d "./logs/system" ]; then
    mkdir -p ./logs/system
    echo -e "${GREEN}✅ Created ./logs/system directory${NC}"
else
    echo -e "${YELLOW}⚠️  ./logs/system directory already exists${NC}"
fi

# Traefik logs directory
if [ ! -d "./logs/traefik" ]; then
    mkdir -p ./logs/traefik
    echo -e "${GREEN}✅ Created ./logs/traefik directory${NC}"
else
    echo -e "${YELLOW}⚠️  ./logs/traefik directory already exists${NC}"
fi

# Application logs directory
if [ ! -d "./logs/application" ]; then
    mkdir -p ./logs/application
    echo -e "${GREEN}✅ Created ./logs/application directory${NC}"
else
    echo -e "${YELLOW}⚠️  ./logs/application directory already exists${NC}"
fi

# Set proper permissions
echo -e "${BLUE}🔐 Setting permissions...${NC}"
chmod 755 ./logs
chmod 755 ./logs/system
chmod 755 ./logs/traefik
chmod 755 ./logs/application

# Create empty log files if they don't exist
touch ./logs/docker.log
touch ./logs/system/syslog
touch ./logs/traefik/access.log

echo -e "${GREEN}✅ Permissions set correctly${NC}"

echo ""
echo -e "${BLUE}📊 Directory Structure${NC}"
echo "========================"
echo "• ./logs/ - Main logs directory"
echo "• ./logs/system/ - System logs"
echo "• ./logs/traefik/ - Traefik logs"
echo "• ./logs/application/ - Application logs"
echo "• ./logs/docker.log - Docker daemon logs"
echo ""

echo -e "${BLUE}🔧 Environment Configuration${NC}"
echo "================================"
echo "For local development, use:"
echo "  source env.development"
echo ""
echo "For staging/production, use:"
echo "  source env.staging"
echo ""

echo -e "${GREEN}✅ Local log setup complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Source the appropriate environment file:"
echo "   source env.development  # for local development"
echo "   source env.staging      # for staging/production"
echo ""
echo "2. Start your services:"
echo "   docker-compose up -d"
echo ""
echo "3. Check logs are being written to local directories" 