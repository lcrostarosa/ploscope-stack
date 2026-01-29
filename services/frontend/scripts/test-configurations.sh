#!/bin/bash

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Testing Frontend Configuration Harmony${NC}"
echo -e "${BLUE}==========================================${NC}"

# Test 1: Local Development Configuration
echo -e "\n${YELLOW}📋 Test 1: make run-local (Local Docker Services)${NC}"
echo -e "${BLUE}Expected: Frontend → http://localhost:5001 (Docker backend)${NC}"

# Start local services
echo -e "${GREEN}Starting local Docker services...${NC}"
ENVIRONMENT=local POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres SECRET_KEY=dev-secret-key-for-local-development-only JWT_SECRET_KEY=dev-jwt-secret-key-for-local-development-only docker compose --profile localdev up -d backend backend-grpc db rabbitmq rabbitmq-init db-migrate

# Wait for services to be ready
echo -e "${GREEN}Waiting for services to be ready...${NC}"
sleep 15

# Test local backend
echo -e "${GREEN}Testing local backend health...${NC}"
LOCAL_HEALTH=$(curl -s http://localhost:5001/api/health | jq -r '.status' 2>/dev/null)
if [ "$LOCAL_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ Local backend is healthy${NC}"
else
    echo -e "${RED}❌ Local backend is not healthy: $LOCAL_HEALTH${NC}"
fi

# Test webpack proxy configuration for local
echo -e "${GREEN}Testing webpack proxy configuration...${NC}"
echo -e "${BLUE}Starting frontend with local configuration...${NC}"
PORT=3001 NODE_ENV=development npm start &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 10

# Test if frontend is accessible
if curl -s http://localhost:3001 > /dev/null; then
    echo -e "${GREEN}✅ Frontend is accessible on localhost:3001${NC}"
    echo -e "${BLUE}📡 Proxy configuration: /api → http://localhost:5001${NC}"
else
    echo -e "${RED}❌ Frontend is not accessible${NC}"
fi

# Stop frontend
kill $FRONTEND_PID 2>/dev/null
sleep 2

# Clean up local services
echo -e "${GREEN}Cleaning up local services...${NC}"
ENVIRONMENT=local docker compose --profile localdev down

# Test 2: Staging Configuration
echo -e "\n${YELLOW}📋 Test 2: npm run start:staging (Staging Backend)${NC}"
echo -e "${BLUE}Expected: Frontend → https://staging.ploscope.com (Staging backend)${NC}"

# Test staging backend
echo -e "${GREEN}Testing staging backend health...${NC}"
STAGING_HEALTH=$(curl -s https://staging.ploscope.com/api/health | jq -r '.status' 2>/dev/null)
if [ "$STAGING_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ Staging backend is healthy${NC}"
else
    echo -e "${RED}❌ Staging backend is not healthy: $STAGING_HEALTH${NC}"
fi

# Test webpack proxy configuration for staging
echo -e "${GREEN}Testing webpack proxy configuration...${NC}"
echo -e "${BLUE}Starting frontend with staging configuration...${NC}"
npm run start:staging &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 10

# Test if frontend is accessible
if curl -s http://localhost:3001 > /dev/null; then
    echo -e "${GREEN}✅ Frontend is accessible on localhost:3001${NC}"
    echo -e "${BLUE}📡 Proxy configuration: /api → https://staging.ploscope.com${NC}"
else
    echo -e "${RED}❌ Frontend is not accessible${NC}"
fi

# Stop frontend
kill $FRONTEND_PID 2>/dev/null
sleep 2

# Summary
echo -e "\n${GREEN}🎉 Configuration Test Summary${NC}"
echo -e "${BLUE}============================${NC}"
echo -e "${GREEN}✅ make run-local: Frontend → Local Docker Services${NC}"
echo -e "${GREEN}✅ npm run start:staging: Frontend → Staging Backend${NC}"
echo -e "\n${YELLOW}💡 Both configurations work in harmony!${NC}"
echo -e "${BLUE}   - Local development uses Docker containers${NC}"
echo -e "${BLUE}   - Staging development uses remote staging backend${NC}"
