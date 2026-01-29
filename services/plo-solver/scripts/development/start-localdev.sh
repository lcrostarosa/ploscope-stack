#!/bin/bash

# PLOSolver Local Development Startup Script
# This script starts the local development environment and checks that all services are healthy

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting PLOSolver Local Development Environment...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Stop any existing containers
echo -e "${BLUE}🛑 Stopping any existing containers...${NC}"
docker compose -f docker-compose-localdev.yml down --remove-orphans

# Start the services
echo -e "${BLUE}🐳 Starting Docker containers...${NC}"
docker compose -f docker-compose-localdev.yml up -d

# Wait for services to be ready
echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"
sleep 15

# Check service health
echo -e "${BLUE}🔍 Checking service health...${NC}"

# Check database
if docker compose -f docker-compose-localdev.yml exec -T db pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Database health check failed (may still be starting)${NC}"
fi

# Check RabbitMQ
if curl -f http://localhost:15672 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ RabbitMQ is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  RabbitMQ health check failed (may still be starting)${NC}"
fi

# Check backend API
if curl -f http://localhost:5001/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend API is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API health check failed (may still be starting)${NC}"
fi

# Check frontend
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend health check failed (may still be starting)${NC}"
fi

# Check Traefik proxy
if curl -f http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Traefik proxy is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Traefik proxy health check failed (may still be starting)${NC}"
fi

echo -e "${GREEN}🎉 Local development environment is starting up!${NC}"
echo -e "${BLUE}📱 Access your application at:${NC}"
echo -e "   🌐 Frontend: ${GREEN}http://localhost${NC}"
echo -e "   🔧 Backend API: ${GREEN}http://localhost:5001${NC}"
echo -e "   📊 Traefik Dashboard: ${GREEN}http://localhost:8080${NC}"
echo -e "   🐰 RabbitMQ Management: ${GREEN}http://localhost:15672${NC}"
echo -e "   🗄️  Database: ${GREEN}localhost:5432${NC}"
echo ""
echo -e "${BLUE}💡 Useful commands:${NC}"
echo -e "   View logs: ${GREEN}docker compose -f docker-compose-localdev.yml logs -f${NC}"
echo -e "   Stop services: ${GREEN}docker compose -f docker-compose-localdev.yml down${NC}"
echo -e "   Restart services: ${GREEN}./scripts/development/start-localdev.sh${NC}"
echo ""
echo -e "${YELLOW}⚠️  Note: Services may take a few more seconds to be fully ready.${NC}"
echo -e "${YELLOW}   If you see health check warnings, wait a moment and try again.${NC}" 