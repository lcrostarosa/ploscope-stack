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
if [ ! -d "src" ] || [ ! -d "src/backend" ] || [ ! -d "src/frontend" ]; then
    echo -e "\033[1;31m❌ Error: This script must be run from the project root directory.\033[0m"
    echo -e "\033[1;31m   Current directory: $(pwd)\033[0m"
    echo -e "\033[1;31m   Expected to find: src/backend and src/frontend directories\033[0m"
    echo -e "\033[1;34m   Please run: cd /path/to/PLOSolver && ./scripts/development/run-local-with-docker-infra.sh\033[0m"
    exit 1
fi

# PLOSolver Local Development with Docker Infrastructure
# This script runs Traefik, RabbitMQ, and Postgres in Docker
# while running the frontend and backend locally

set -e

# After setting -e, enable job control so we can manage process groups
set -m

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Check for --recreate flag
RECREATE_SERVICES=false
for arg in "$@"; do
    if [ "$arg" = "--recreate" ]; then
        RECREATE_SERVICES=true
        break
    fi
done

echo -e "${GREEN}🚀 Starting PLOSolver with local frontend/backend and Docker infrastructure...${NC}"

# Function to kill any existing PLOSolver development processes
kill_existing_plosolver_processes() {
    echo -e "${BLUE}🔍 Checking for existing PLOSolver development processes...${NC}"
    
    # Kill any existing backend processes
    local backend_pids=$(pgrep -f "python.*core/app.py" 2>/dev/null || true)
    if [ ! -z "$backend_pids" ]; then
        echo -e "${YELLOW}🔫 Killing existing backend processes...${NC}"
        echo $backend_pids | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # Kill any existing frontend processes
    local frontend_pids=$(pgrep -f "webpack.*serve.*development" 2>/dev/null || true)
    if [ ! -z "$frontend_pids" ]; then
        echo -e "${YELLOW}🔫 Killing existing frontend processes...${NC}"
        echo $frontend_pids | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # Kill any processes using our development ports
    for port in 3001 5001; do
        local port_pids=$(lsof -ti :$port 2>/dev/null || true)
        if [ ! -z "$port_pids" ]; then
            echo -e "${YELLOW}🔫 Killing processes using port $port...${NC}"
            echo $port_pids | xargs kill -9 2>/dev/null || true
            sleep 2
        fi
    done
    
    echo -e "${GREEN}✅ Existing PLOSolver processes cleaned up${NC}"
}

# Kill any existing PLOSolver processes
kill_existing_plosolver_processes

# Function to check if PLOSolver services are running
check_existing_services() {
    local services_running=false
    
    # Check for plosolver-*-local containers
    if docker ps --format "{{.Names}}" | grep -q "plosolver-.*-local"; then
        services_running=true
        echo -e "${BLUE}🔍 Found existing PLOSolver services:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "plosolver-.*-local" || true
    fi
    
    echo $services_running
}

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

# Function to ensure local development ports are available
ensure_local_ports_available() {
    echo -e "${BLUE}🔍 Ensuring local development ports are available...${NC}"
    
    # Check and clear backend port (5001)
    if lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port 5001 (Backend) is in use. Stopping conflicting processes...${NC}"
        local backend_pids=$(lsof -ti :5001 2>/dev/null)
        if [ ! -z "$backend_pids" ]; then
            echo -e "${BLUE}🔫 Killing backend processes on port 5001...${NC}"
            echo $backend_pids | xargs kill -9 2>/dev/null || true
            sleep 3
        fi
    fi
    
    # Check and clear frontend port (3001)
    if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port 3001 (Frontend) is in use. Stopping conflicting processes...${NC}"
        local frontend_pids=$(lsof -ti :3001 2>/dev/null)
        if [ ! -z "$frontend_pids" ]; then
            echo -e "${BLUE}🔫 Killing frontend processes on port 3001...${NC}"
            echo $frontend_pids | xargs kill -9 2>/dev/null || true
            sleep 3
        fi
    fi
    
    # Final verification
    if lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}❌ Port 5001 is still in use after cleanup. Please manually stop the process.${NC}"
        echo -e "${BLUE}💡 Try: lsof -ti :5001 | xargs kill -9${NC}"
        return 1
    fi
    
    if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}❌ Port 3001 is still in use after cleanup. Please manually stop the process.${NC}"
        echo -e "${BLUE}💡 Try: lsof -ti :3001 | xargs kill -9${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Local development ports are available${NC}"
    return 0
}

# Check for existing services
EXISTING_SERVICES=$(check_existing_services)

if [ "$EXISTING_SERVICES" = "true" ]; then
    if [ "$RECREATE_SERVICES" = "true" ]; then
        echo -e "${YELLOW}🔄 --recreate flag detected. Stopping existing services...${NC}"
        docker-compose -f docker-compose-local-services.yml down 2>/dev/null || true
        docker-compose -f docker-compose-localdev.yml down 2>/dev/null || true
        echo -e "${GREEN}✅ Existing services stopped${NC}"
    else
        echo -e "${GREEN}✅ Using existing PLOSolver services${NC}"
        echo -e "${BLUE}💡 To recreate services, run: make run-local -- --recreate${NC}"
        # Ensure metrics stack is running even when reusing existing services
        echo -e "${BLUE}📊 Ensuring Prometheus and Grafana are running...${NC}"
        docker-compose -f docker-compose-local-services.yml up -d prometheus grafana >/dev/null 2>&1 || true
    fi
else
    echo -e "${BLUE}🔍 No existing PLOSolver services found${NC}"
fi

# Only check ports and start services if we're recreating or no services exist
if [ "$RECREATE_SERVICES" = "true" ] || [ "$EXISTING_SERVICES" = "false" ]; then
    # Check for required ports
    echo -e "${BLUE}🔍 Checking port availability...${NC}"
    check_port 80 "Traefik"
    check_port 5432 "PostgreSQL"
    check_port 5672 "RabbitMQ"
    check_port 15672 "RabbitMQ Management"
    check_port 3001 "Frontend"
    check_port 5001 "Backend"

    # Continue even if some ports are still in use (they might be freed up later)
    echo -e "${BLUE}🚀 Proceeding with startup...${NC}"

    # Stop any existing PLOSolver containers
    echo -e "${BLUE}🧹 Cleaning up existing PLOSolver containers...${NC}"
    docker-compose -f docker-compose-local-services.yml down 2>/dev/null || true
    docker-compose -f docker-compose-localdev.yml down 2>/dev/null || true

    # Start infrastructure services in Docker
    echo -e "${BLUE}🐳 Starting infrastructure services in Docker...${NC}"
    docker-compose -f docker-compose-local-services.yml up -d
fi


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


# Wait for Traefik
echo -e "${BLUE}🌐 Waiting for Traefik...${NC}"
until curl -s http://localhost:8081/dashboard/ >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ Traefik is ready${NC}"

# Optionally wait for Prometheus and Grafana if present
if docker-compose -f docker-compose-local-services.yml ps prometheus >/dev/null 2>&1; then
  echo -e "${BLUE}📈 Waiting for Prometheus...${NC}"
  until curl -s http://localhost:9091/-/ready >/dev/null 2>&1; do
      echo -n "."
      sleep 2
  done
  echo -e "${GREEN}✅ Prometheus is ready${NC}"
fi

if docker-compose -f docker-compose-local-services.yml ps grafana >/dev/null 2>&1; then
  echo -e "${BLUE}📊 Waiting for Grafana...${NC}"
  until curl -s http://localhost:3006/api/health >/dev/null 2>&1; do
      echo -n "."
      sleep 2
  done
  echo -e "${GREEN}✅ Grafana is ready${NC}"
fi


# Variables to track shutdown state
SHUTDOWN_STAGE=0
DOCKER_STOPPED=false

# Function to cleanup on exit
cleanup() {
    SHUTDOWN_STAGE=$((SHUTDOWN_STAGE + 1))
    
    if [ $SHUTDOWN_STAGE -eq 1 ]; then
        echo -e "${YELLOW}🛑 First Ctrl+C detected. Stopping local development processes...${NC}"
        echo -e "${BLUE}💡 Press Ctrl+C again to stop Docker containers${NC}"
        
        # Kill background processes (entire process groups)
        if [ ! -z "$FRONTEND_PID" ]; then
            echo -e "${BLUE}🔫 Terminating frontend process group...${NC}"
            kill -- -$FRONTEND_PID 2>/dev/null || true
        fi
        if [ ! -z "$BACKEND_PID" ]; then
            echo -e "${BLUE}🔫 Terminating backend process group...${NC}"
            kill -- -$BACKEND_PID 2>/dev/null || true
        fi
        if [ ! -z "$CELERY_PID" ]; then
            echo -e "${BLUE}🔫 Terminating Celery worker process group...${NC}"
            kill -- -$CELERY_PID 2>/dev/null || true
        fi
        if [ ! -z "$CELERY_HEALTH_PID" ]; then
            echo -e "${BLUE}🔫 Terminating Celery health check server...${NC}"
            kill $CELERY_HEALTH_PID 2>/dev/null || true
        fi
        
        # Kill any process using development ports
        for port in 3001 5001; do
            pids=$(lsof -ti :$port 2>/dev/null)
            if [ ! -z "$pids" ]; then
                echo -e "${BLUE}🔫 Killing processes using port $port...${NC}"
                echo $pids | xargs kill -9 2>/dev/null || true
            fi
        done
        
        # Additional cleanup for common development processes
        echo -e "${BLUE}🧹 Cleaning up development processes...${NC}"
        
        # Kill any remaining Python processes that might be our backend
        pkill -f "python.*core/app.py" 2>/dev/null || true
        pkill -f "python.*app.py" 2>/dev/null || true
        
        # Kill any remaining Node.js processes that might be our frontend
        pkill -f "webpack.*serve" 2>/dev/null || true
        pkill -f "node.*webpack" 2>/dev/null || true
        
        # Wait a moment for processes to terminate
        sleep 2
        
        # Final check and force kill if needed
        for port in 3001 5001; do
            pids=$(lsof -ti :$port 2>/dev/null)
            if [ ! -z "$pids" ]; then
                echo -e "${RED}🔫 Force killing remaining processes on port $port...${NC}"
                echo $pids | xargs kill -9 2>/dev/null || true
            fi
        done
        
        echo -e "${GREEN}✅ Local development processes stopped${NC}"
        echo -e "${YELLOW}🐳 Docker containers are still running. Press Ctrl+C again to stop them.${NC}"
        
        # Set up a new trap for the second Ctrl+C
        trap cleanup SIGINT SIGTERM
        
    elif [ $SHUTDOWN_STAGE -eq 2 ] && [ "$DOCKER_STOPPED" = "false" ]; then
        echo -e "${YELLOW}🛑 Second Ctrl+C detected. Stopping Docker containers...${NC}"
        DOCKER_STOPPED=true
        
        # Stop Docker services
        echo -e "${BLUE}🐳 Stopping Docker containers...${NC}"
        docker-compose -f docker-compose-local-services.yml down
        
        # Kill any remaining processes using infrastructure ports
        for port in 80 8081 5432 5672 15672; do
            pids=$(lsof -ti :$port 2>/dev/null)
            if [ ! -z "$pids" ]; then
                echo -e "${BLUE}🔫 Killing processes using port $port...${NC}"
                echo $pids | xargs kill -9 2>/dev/null || true
            fi
        done
        
        echo -e "${GREEN}✅ Docker containers stopped${NC}"
        echo -e "${GREEN}✅ Cleanup complete${NC}"
        exit 0
        
    else
        echo -e "${YELLOW}🛑 Force exit...${NC}"
        exit 1
    fi
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Activate virtual environment and check dependencies
echo -e "${BLUE}🔍 Checking dependencies...${NC}"
source "$(dirname "$0")/activate_venv.sh"

# Check Node.js dependencies
if [ ! -d "src/frontend/node_modules" ]; then
    echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
    cd src/frontend
    npm install
    cd ../..
fi

# Ensure local development ports are available
ensure_local_ports_available

# Start backend with hot reloading
echo -e "${BLUE}🐍 Starting backend server with hot reloading...${NC}"
cd src/backend
# Virtual environment is already activated by activate_venv.sh
export PYTHONPATH=${PYTHONPATH}:$(pwd)
# Environment variables are already loaded from env.development at the top of the script
python core/app.py &
BACKEND_PID=$!
cd ../..

# Remove Celery worker startup and health check
# Restore message to user

# Note: Celery worker is now run natively with hot reloading
# Use 'make run-celery-dev' to start the Celery worker in development mode
echo -e "${BLUE}💡 Celery worker is now run natively with hot reloading${NC}"
echo -e "${BLUE}   Use 'make run-celery-dev' in a separate terminal to start the Celery worker${NC}"

# Wait a moment for backend to start
sleep 3

# Start frontend
echo -e "${BLUE}⚛️  Starting frontend development server...${NC}"
cd src/frontend
npx webpack serve --mode development &
FRONTEND_PID=$!
cd ../..

# Wait for services to be accessible
echo -e "${BLUE}⏳ Waiting for services to be accessible...${NC}"

# Wait for backend
until curl -s http://localhost:5001/api/health >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ Backend is accessible${NC}"

# Wait for frontend
until curl -s http://localhost:3001 >/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ Frontend is accessible${NC}"

echo -e "${GREEN}🎉 PLOSolver is running!${NC}"
echo -e "${BLUE}📱 Frontend: http://localhost (via Traefik)${NC}"
echo -e "${BLUE}🔧 Backend API: http://localhost/api (via Traefik)${NC}"
echo -e "${BLUE}🌐 Traefik Dashboard: http://localhost:8081${NC}"
echo -e "${BLUE}🐰 RabbitMQ Management: http://localhost:15672${NC}"
echo -e "${BLUE}🗄️  PostgreSQL: localhost:5432${NC}"
echo -e "${GREEN}🔥 Hot reloading is enabled for both frontend and backend${NC}"
echo -e "${YELLOW}Press Ctrl+C once to stop local processes, twice to stop Docker containers${NC}"

# Wait for user to stop
wait $BACKEND_PID $FRONTEND_PID 