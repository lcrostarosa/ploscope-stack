#!/bin/bash

# Setup Portainer with SSH-only access
# This script configures SSH tunneling to access Portainer securely

set -e

echo "🔧 Setting up Portainer with SSH-only access..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PORTAINER_PORT=9000
SSH_PORT=22
LOCAL_PORT=9000

echo -e "${BLUE}📋 Portainer SSH Access Setup${NC}"
echo "=================================="

# Check if docker-compose is running
if ! docker-compose ps | grep -q portainer; then
    echo -e "${YELLOW}⚠️  Portainer container not running. Starting services...${NC}"
    docker-compose up -d portainer
    sleep 10
fi

# Check if Portainer is healthy
if docker-compose ps portainer | grep -q "healthy"; then
    echo -e "${GREEN}✅ Portainer is running and healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Portainer is starting up, please wait...${NC}"
    echo "You can check status with: docker-compose ps portainer"
fi

echo ""
echo -e "${BLUE}🔐 SSH Access Instructions${NC}"
echo "================================"
echo ""
echo -e "${GREEN}To access Portainer via SSH tunnel:${NC}"
echo ""
echo "1. From your local machine, create SSH tunnel:"
echo -e "   ${YELLOW}ssh -L ${LOCAL_PORT}:localhost:${PORTAINER_PORT} user@your-server-ip${NC}"
echo ""
echo "2. Open your browser and go to:"
echo -e "   ${YELLOW}http://localhost:${LOCAL_PORT}${NC}"
echo ""
echo "3. First time setup:"
echo "   - Create admin user account"
echo "   - Select 'Local Docker Environment'"
echo "   - Connect to Docker socket"
echo ""

echo -e "${BLUE}🛡️  Security Notes${NC}"
echo "=================="
echo "• Portainer is NOT exposed to external network"
echo "• Access is only available via SSH tunnel"
echo "• No direct HTTP/HTTPS access from internet"
echo "• Use strong SSH keys for server access"
echo ""

echo -e "${BLUE}📊 Portainer Features${NC}"
echo "========================"
echo "• Container management and monitoring"
echo "• Docker image management"
echo "• Volume and network management"
echo "• Container logs and console access"
echo "• Resource usage monitoring"
echo ""

echo -e "${GREEN}✅ Portainer SSH setup complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Tip: Add this to your ~/.ssh/config for easier access:${NC}"
echo "Host plosolver-portainer"
echo "    HostName your-server-ip"
echo "    User your-username"
echo "    LocalForward ${LOCAL_PORT} localhost:${PORTAINER_PORT}"
echo ""
echo "Then connect with: ssh plosolver-portainer" 