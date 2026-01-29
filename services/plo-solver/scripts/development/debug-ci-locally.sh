#!/bin/bash

# Debug CI Locally Script
# This script creates an interactive GitHub Actions runner environment locally
# for debugging CI issues in real-time

set -e

echo "🔧 Setting up interactive GitHub Actions environment for local debugging..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RUNNER_NAME="local-debug-runner"
CONTAINER_NAME="github-actions-debug"
NETWORK_NAME="ci-debug-network"

# Function to cleanup on exit
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up containers and networks...${NC}"
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    docker network rm $NETWORK_NAME 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Set up cleanup on script exit
trap cleanup EXIT

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Create network for services
echo -e "${BLUE}🌐 Creating Docker network...${NC}"
docker network create $NETWORK_NAME 2>/dev/null || echo "Network already exists"

# Start PostgreSQL container
echo -e "${BLUE}🗄️  Starting PostgreSQL container...${NC}"
docker run -d \
    --name postgres-ci-debug \
    --network $NETWORK_NAME \
    -e POSTGRES_USER=testuser \
    -e POSTGRES_PASSWORD=testpassword \
    -e POSTGRES_DB=testdb \
    -p 5432:5432 \
    postgres:15

# Start RabbitMQ container
echo -e "${BLUE}🐰 Starting RabbitMQ container...${NC}"
docker run -d \
    --name rabbitmq-ci-debug \
    --network $NETWORK_NAME \
    -e RABBITMQ_DEFAULT_USER=plosolver \
    -e RABBITMQ_DEFAULT_PASS=dev_password_2024 \
    -e RABBITMQ_DEFAULT_VHOST=/plosolver \
    -p 5672:5672 \
    -p 15672:15672 \
    rabbitmq:3.13-management

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Function to wait for service with timeout (macOS compatible)
wait_for_service() {
    local service_name=$1
    local test_command=$2
    local max_attempts=15
    local attempt=1
    
    echo -e "${YELLOW}⏳ Waiting for $service_name...${NC}"
    while [ $attempt -le $max_attempts ]; do
        if eval "$test_command" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready${NC}"
            return 0
        fi
        echo -e "${YELLOW}  Attempt $attempt/$max_attempts - $service_name not ready yet...${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
    return 1
}

# Test PostgreSQL connectivity
echo -e "${BLUE}🔍 Testing PostgreSQL connectivity...${NC}"
wait_for_service "PostgreSQL" "pg_isready -h localhost -p 5432 -U testuser -d testdb" || exit 1

# Test RabbitMQ connectivity
echo -e "${BLUE}🔍 Testing RabbitMQ connectivity...${NC}"
wait_for_service "RabbitMQ" "curl -f -u plosolver:dev_password_2024 http://localhost:15672/api/overview" || exit 1

# Setup Traefik configuration
echo -e "${BLUE}🔧 Setting up Traefik configuration...${NC}"
echo -e "${GREEN}✅ Using Traefik configuration files directly${NC}"

# Start Traefik container
echo -e "${BLUE}🌐 Starting Traefik container...${NC}"
docker run -d \
    --name traefik-ci-debug \
    --network $NETWORK_NAME \
    -p 80:80 \
    -p 8082:8082 \
    -v "$(pwd)/server/traefik/ci/traefik.yml:/etc/traefik/traefik.yml:ro" \
    -v "$(pwd)/server/traefik/ci/dynamic.docker.yml:/etc/traefik/dynamic.yml:ro" \
    traefik:v3.0

# Wait for Traefik to be ready
echo -e "${YELLOW}⏳ Waiting for Traefik to be ready...${NC}"
sleep 10
wait_for_service "Traefik" "curl -f http://localhost:8082/api/overview" || exit 1

# Start interactive GitHub Actions runner container
echo -e "${BLUE}🚀 Starting interactive GitHub Actions runner container...${NC}"
echo -e "${GREEN}✅ All services are running!${NC}"
echo -e "${YELLOW}📋 Available services:${NC}"
echo -e "  • PostgreSQL: localhost:5432"
echo -e "  • RabbitMQ: localhost:5672 (Management: localhost:15672)"
echo -e "  • Traefik: localhost:80 (API: localhost:8082)"
echo -e ""
echo -e "${YELLOW}🔧 Starting interactive shell...${NC}"
echo -e "${BLUE}💡 You can now run CI commands manually to debug issues${NC}"
echo -e "${BLUE}💡 Type 'exit' to stop the container and cleanup${NC}"

# Start interactive container with all necessary tools
docker run -it --rm \
    --name $CONTAINER_NAME \
    --network $NETWORK_NAME \
    -v "$(pwd):/workspace" \
    -w /workspace \
    -e POSTGRES_USER=testuser \
    -e POSTGRES_PASSWORD=testpassword \
    -e POSTGRES_DB=testdb \
    -e POSTGRES_HOST=postgres-ci-debug \
    -e DATABASE_URL=postgresql://testuser:testpassword@postgres-ci-debug:5432/testdb \
    -e RABBITMQ_HOST=rabbitmq-ci-debug \
    -e RABBITMQ_PORT=5672 \
    -e RABBITMQ_USERNAME=plosolver \
    -e RABBITMQ_PASSWORD=dev_password_2024 \
    -e RABBITMQ_VHOST=/plosolver \
    -e TRAEFIK_ENABLED=true \
    -e TRAEFIK_HOST=traefik-ci-debug \
    -e TRAEFIK_PORT=80 \
    -e TRAEFIK_API_PORT=8082 \
    -e FRONTEND_URL=http://localhost \
    -e REACT_APP_API_URL=http://localhost/api \
    -e CONTAINER_ENV=ci \
    -e ENVIRONMENT=test \
    ubuntu:22.04 \
    bash -c "
        echo '🔧 Installing dependencies...'
        apt-get update
        apt-get install -y curl wget git python3 python3-pip python3-venv nodejs npm postgresql-client
        
        echo '📦 Setting up Python environment...'
        cd /workspace/src/backend
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        pip install -r requirements-test.txt
        
        echo '📦 Setting up Node.js environment...'
        cd /workspace/src/frontend
        npm ci
        
        echo '✅ Environment setup complete!'
        echo '🔧 You can now run CI commands manually:'
        echo '  • cd /workspace/src/backend && source venv/bin/activate'
        echo '  • cd /workspace/src/frontend && npm start'
        echo '  • Test Traefik: curl http://localhost/api/health'
        echo ''
        bash
    "

echo -e "${GREEN}✅ Interactive session completed${NC}" 