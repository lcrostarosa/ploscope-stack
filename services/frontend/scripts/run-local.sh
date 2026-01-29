#!/bin/bash

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    echo -e "\n${RED}Stopping all services...${NC}"
    ENVIRONMENT=local POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres SECRET_KEY=dev-secret-key-for-local-development-only JWT_SECRET_KEY=dev-jwt-secret-key-for-local-development-only docker compose --profile localdev down
    echo -e "${GREEN}✅ All services stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup INT TERM

echo -e "${GREEN}Starting local development environment...${NC}"
echo -e "${YELLOW}Services will be available at:${NC}"
echo -e "${BLUE}  Frontend: http://localhost:3001 (npm/webpack)${NC}"
echo -e "${BLUE}  Backend API: http://localhost:5001 (Docker)${NC}"
echo -e "${BLUE}  Database: localhost:5432 (Docker)${NC}"
echo -e "${BLUE}  RabbitMQ: http://localhost:15672 (Docker)${NC}"

echo -e "${GREEN}Starting backend services with Docker Compose...${NC}"
ENVIRONMENT=local POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres SECRET_KEY=dev-secret-key-for-local-development-only JWT_SECRET_KEY=dev-jwt-secret-key-for-local-development-only docker compose --profile localdev up -d backend backend-grpc db rabbitmq rabbitmq-init db-migrate celeryworker

echo -e "${GREEN}Waiting for backend services to be ready...${NC}"
sleep 15

echo -e "${GREEN}Starting frontend development server...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Start the frontend server
PORT=3001 NODE_ENV=development npm start

# If we get here, the frontend server exited normally
cleanup
