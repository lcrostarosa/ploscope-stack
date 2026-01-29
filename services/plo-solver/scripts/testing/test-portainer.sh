#!/bin/bash

# Test Portainer functionality and SSH access
# This script verifies Portainer is working correctly

set -e

echo "🧪 Testing Portainer setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PORTAINER_PORT=9000
LOCAL_PORT=9000

echo -e "${BLUE}📋 Portainer Test Suite${NC}"
echo "=========================="

# Test 1: Check if Portainer container is running
echo -e "${BLUE}1. Checking Portainer container status...${NC}"
if docker-compose ps portainer | grep -q "Up"; then
    echo -e "${GREEN}✅ Portainer container is running${NC}"
else
    echo -e "${RED}❌ Portainer container is not running${NC}"
    echo "Starting Portainer..."
    docker-compose up -d portainer
    sleep 15
fi

# Test 2: Check Portainer health
echo -e "${BLUE}2. Checking Portainer health...${NC}"
if docker-compose ps portainer | grep -q "healthy"; then
    echo -e "${GREEN}✅ Portainer is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Portainer is starting up or unhealthy${NC}"
    echo "Health check: docker-compose ps portainer"
fi

# Test 3: Check if Portainer is listening on port 9000
echo -e "${BLUE}3. Checking Portainer port accessibility...${NC}"
if docker exec plosolver-portainer-${ENVIRONMENT:-development} netstat -tlnp 2>/dev/null | grep -q ":9000"; then
    echo -e "${GREEN}✅ Portainer is listening on port 9000${NC}"
else
    echo -e "${YELLOW}⚠️  Portainer port check failed (may be starting up)${NC}"
fi

# Test 4: Check Docker socket access
echo -e "${BLUE}4. Checking Docker socket access...${NC}"
if docker exec plosolver-portainer-${ENVIRONMENT:-development} ls -la /var/run/docker.sock >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker socket is accessible${NC}"
else
    echo -e "${RED}❌ Docker socket is not accessible${NC}"
fi

# Test 5: Check Portainer API (if accessible locally)
echo -e "${BLUE}5. Testing Portainer API...${NC}"
if curl -s http://localhost:${LOCAL_PORT}/api/status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Portainer API is accessible locally${NC}"
    echo "   This means SSH tunnel is working"
else
    echo -e "${YELLOW}⚠️  Portainer API not accessible locally${NC}"
    echo "   This is expected if SSH tunnel is not established"
fi

echo ""
echo -e "${BLUE}🔐 SSH Tunnel Test${NC}"
echo "====================="
echo ""
echo -e "${GREEN}To test SSH tunnel access:${NC}"
echo ""
echo "1. Create SSH tunnel:"
echo -e "   ${YELLOW}ssh -L ${LOCAL_PORT}:localhost:${PORTAINER_PORT} user@your-server-ip${NC}"
echo ""
echo "2. Test API access:"
echo -e "   ${YELLOW}curl http://localhost:${LOCAL_PORT}/api/status${NC}"
echo ""
echo "3. Open in browser:"
echo -e "   ${YELLOW}http://localhost:${LOCAL_PORT}${NC}"
echo ""

echo -e "${BLUE}📊 Portainer Management Features${NC}"
echo "=================================="
echo "• Container management and monitoring"
echo "• Docker image management"
echo "• Volume and network management"
echo "• Container logs and console access"
echo "• Resource usage monitoring"
echo "• Stack deployment and management"
echo "• Environment management"
echo ""

echo -e "${GREEN}✅ Portainer test complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Set up SSH tunnel to access Portainer"
echo "2. Create admin account on first access"
echo "3. Configure Docker environment"
echo "4. Start managing your containers!" 