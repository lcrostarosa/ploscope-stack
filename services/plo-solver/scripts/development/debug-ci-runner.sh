#!/bin/bash

# Debug CI with GitHub Actions Runner Script
# This script creates an interactive environment using the actual GitHub Actions runner image
# for the most accurate debugging experience

set -e

echo "🔧 Setting up GitHub Actions runner environment for local debugging..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NETWORK_NAME="ci-debug-network"

# Function to cleanup on exit
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up containers and networks...${NC}"
    docker stop postgres-ci-debug rabbitmq-ci-debug traefik-ci-debug 2>/dev/null || true
    docker rm postgres-ci-debug rabbitmq-ci-debug traefik-ci-debug 2>/dev/null || true
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

# Setup Traefik configuration
echo -e "${BLUE}🔧 Setting up Traefik configuration...${NC}"

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

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 15

# Test services
echo -e "${BLUE}🔍 Testing service connectivity...${NC}"

# Function to wait for service with timeout (macOS compatible)
wait_for_service() {
    local service_name=$1
    local test_command=$2
    local max_attempts=30
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

# Test PostgreSQL
wait_for_service "PostgreSQL" "pg_isready -h localhost -p 5432 -U testuser -d testdb" || exit 1

# Test RabbitMQ
wait_for_service "RabbitMQ" "curl -f -u plosolver:dev_password_2024 http://localhost:15672/api/overview" || exit 1

# Test Traefik
wait_for_service "Traefik" "curl -f http://localhost:8082/api/overview" || exit 1

echo -e "${GREEN}✅ All services are running!${NC}"
echo -e "${YELLOW}📋 Available services:${NC}"
echo -e "  • PostgreSQL: localhost:5432"
echo -e "  • RabbitMQ: localhost:5672 (Management: localhost:15672)"
echo -e "  • Traefik: localhost:80 (API: localhost:8082)"
echo -e ""
echo -e "${YELLOW}🔧 Starting GitHub Actions runner environment...${NC}"

# Start interactive container using GitHub Actions runner image
docker run -it --rm \
    --name github-actions-debug \
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
    -e GITHUB_WORKSPACE=/workspace \
    -e RUNNER_OS=Linux \
    -e RUNNER_ARCH=X64 \
    -e RUNNER_TEMP=/tmp \
    -e RUNNER_TOOL_CACHE=/opt/hostedtoolcache \
    ubuntu:22.04 \
    bash -c "
        echo '🔧 Setting up GitHub Actions runner environment...'
        
        # Install system dependencies
        apt-get update
        apt-get install -y curl wget git python3 python3-pip python3-venv nodejs npm postgresql-client jq
        
        # Set up Python environment (similar to GitHub Actions)
        echo '📦 Setting up Python environment...'
        cd /workspace/src/backend
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
        pip install -r requirements-test.txt
        
        # Set up Node.js environment (similar to GitHub Actions)
        echo '📦 Setting up Node.js environment...'
        cd /workspace/src/frontend
        npm ci
        
        # Create necessary directories
        cd /workspace/src/backend
        mkdir -p logs uploads/hand_histories
        
        echo '✅ Environment setup complete!'
        echo ''
        echo '🔧 Available commands for debugging:'
        echo '  • Test PostgreSQL: pg_isready -h postgres-ci-debug -p 5432 -U testuser -d testdb'
        echo '  • Test RabbitMQ: curl -u plosolver:dev_password_2024 http://rabbitmq-ci-debug:15672/api/overview'
        echo '  • Test Traefik: curl http://traefik-ci-debug:8082/api/overview'
        echo '  • Start Backend: cd /workspace/src/backend && source venv/bin/activate && python -m flask run --host=0.0.0.0 --port=5001'
        echo '  • Start Frontend: cd /workspace/src/frontend && npm start'
        echo '  • Run Tests: cd /workspace/src/backend && source venv/bin/activate && python -m pytest tests/unit/ -v'
        echo '  • Test API via Traefik: curl http://localhost/api/health'
        echo ''
        echo '💡 This environment mirrors the GitHub Actions runner setup'
        echo '💡 Type \"exit\" to stop and cleanup'
        echo ''
        bash
    "

echo -e "${GREEN}✅ Interactive session completed${NC}" 