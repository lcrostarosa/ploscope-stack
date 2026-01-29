#!/bin/bash

# Source environment variables
if [ -f "env.development" ]; then
    set -a
    source env.development
    set +a
    echo -e "\033[1;32mLoaded environment variables from env.development\033[0m"
else
    echo -e "\033[1;31mWarning: env.development not found. Proceeding without sourcing.\033[0m"
fi

# Check if we're in the project root directory
if [ ! -d "src" ] || [ ! -d "src/frontend" ]; then
    echo -e "\033[1;31m❌ Error: This script must be run from the project root directory.\033[0m"
    echo -e "\033[1;31m   Current directory: $(pwd)\033[0m"
    echo -e "\033[1;31m   Expected to find: src/frontend directory\033[0m"
    echo -e "\033[1;34m   Please run: cd /path/to/PLOSolver && ./scripts/development/run-frontend-only.sh\033[0m"
    exit 1
fi

# PLOSolver Frontend Only
# This script runs Traefik, RabbitMQ, and Postgres in Docker
# while running only the frontend locally

set -e

# After setting -e, enable job control so we can manage process groups
set -m

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting PLOSolver Frontend Only with Docker infrastructure...${NC}"

# Function to check if a port is available
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $port is already in use by $service. Attempting to stop conflicting services...${NC}"
        
        # Try to stop Docker containers that might be using this port
        if docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -q ":$port->"; then
            echo -e "${BLUE}🐳 Stopping Docker containers using port $port...${NC}"
            docker ps --format "{{.Names}}" | xargs -I {} docker stop {} 2>/dev/null || true
            sleep 2
        fi
        
        # Try to kill processes using the port
        local pids=$(lsof -ti :$port 2>/dev/null)
        if [ ! -z "$pids" ]; then
            echo -e "${BLUE}🔫 Killing processes using port $port...${NC}"
            echo $pids | xargs kill -9 2>/dev/null || true
            sleep 2
        fi
        
        # Check again
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${RED}❌ Port $port is still in use after cleanup attempts. Please manually stop services on port $port.${NC}"
            return 1
        else
            echo -e "${GREEN}✅ Port $port is now available${NC}"
            return 0
        fi
    fi
    return 0
}

# Check for required ports
echo -e "${BLUE}🔍 Checking port availability...${NC}"
check_port 80 "Traefik"
check_port 5432 "PostgreSQL"
check_port 5672 "RabbitMQ"
check_port 15672 "RabbitMQ Management"
check_port 3001 "Frontend"

# Continue even if some ports are still in use (they might be freed up later)
echo -e "${BLUE}🚀 Proceeding with startup...${NC}"

# Stop any existing PLOSolver containers
echo -e "${BLUE}🧹 Cleaning up existing PLOSolver containers...${NC}"
docker-compose -f docker-compose-local-services.yml down 2>/dev/null || true

# Start infrastructure services in Docker
echo -e "${BLUE}🐳 Starting infrastructure services in Docker...${NC}"
docker-compose -f docker-compose-local-services.yml up -d

# Wait for services to be ready
echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"

# Wait for PostgreSQL
echo -e "${BLUE}🗄️  Waiting for PostgreSQL...${NC}"
until docker-compose -f docker-compose-local-services.yml exec db pg_isready -U postgres >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"

# Wait for RabbitMQ
echo -e "${BLUE}🐰 Waiting for RabbitMQ...${NC}"
until curl -s -u plosolver:dev_password_2024 http://localhost:15672/api/whoami >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ RabbitMQ is ready${NC}"

# Bootstrap RabbitMQ queues
echo -e "${BLUE}🔧 Bootstrapping RabbitMQ queues...${NC}"
if ./scripts/setup/bootstrap-rabbitmq.sh; then
    echo -e "${GREEN}✅ RabbitMQ queues bootstrapped successfully${NC}"
else
    echo -e "${RED}❌ Failed to bootstrap RabbitMQ queues${NC}"
    exit 1
fi

# Wait for Traefik
echo -e "${BLUE}🌐 Waiting for Traefik...${NC}"
until curl -s http://localhost:8081/dashboard/ >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ Traefik is ready${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "${YELLOW}🛑 Shutting down...${NC}"
    # Kill background processes (entire process groups)
    if [ ! -z "$FRONTEND_PID" ]; then
        echo -e "${BLUE}🔫 Terminating frontend process group...${NC}"
        kill -- -$FRONTEND_PID 2>/dev/null || true
    fi
    # Stop Docker services
    docker-compose -f docker-compose-local-services.yml down
    # Kill any process using relevant ports
    for port in 80 8081 5432 5672 15672 3001; do
        pids=$(lsof -ti :$port 2>/dev/null)
        if [ ! -z "$pids" ]; then
            echo -e "${BLUE}🔫 Killing processes using port $port...${NC}"
            echo $pids | xargs kill -9 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if dependencies are installed
echo -e "${BLUE}🔍 Checking dependencies...${NC}"

# Check Node.js dependencies
if [ ! -d "src/frontend/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
    cd src/frontend
    npm install
    cd ../..
fi

# Start frontend
echo -e "${BLUE}⚛️  Starting frontend development server...${NC}"
cd src/frontend
npx webpack serve --mode development &
FRONTEND_PID=$!
cd ../..

# Wait for frontend to be accessible
echo -e "${BLUE}⏳ Waiting for frontend to be accessible...${NC}"
until curl -s http://localhost:3001 >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ Frontend is accessible${NC}"

echo -e "${GREEN}🎉 PLOSolver Frontend is running!${NC}"
echo -e "${BLUE}📱 Frontend: http://localhost (via Traefik)${NC}"
echo -e "${BLUE}📱 Frontend Direct: http://localhost:3001${NC}"
echo -e "${BLUE}🌐 Traefik Dashboard: http://localhost:8081${NC}"
echo -e "${BLUE}🐰 RabbitMQ Management: http://localhost:15672${NC}"
echo -e "${BLUE}🗄️  PostgreSQL: localhost:5432${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Wait for user to stop
wait 