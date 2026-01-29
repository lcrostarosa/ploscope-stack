#!/bin/bash

# Stop Local Docker Infrastructure Services
# This script stops the Traefik, RabbitMQ, and Postgres containers

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🛑 Stopping local Docker infrastructure services...${NC}"

# Stop Docker services
echo -e "${BLUE}🐳 Stopping Docker containers...${NC}"
docker-compose -f docker-compose-local-services.yml down

echo -e "${GREEN}✅ Local infrastructure services stopped${NC}"
echo -e "${BLUE}📝 Services stopped:${NC}"
echo -e "${BLUE}   • PostgreSQL${NC}"
echo -e "${BLUE}   • RabbitMQ${NC}"
echo -e "${BLUE}   • Traefik${NC}" 