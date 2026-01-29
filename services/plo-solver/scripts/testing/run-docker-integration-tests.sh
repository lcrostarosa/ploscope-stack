#!/bin/bash

# Docker Integration Tests Runner
# This script runs integration tests against live Docker containers

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Configuration
TEST_COMPOSE_FILE="docker compose.test.yml"
BACKEND_DIR="src/backend"

echo -e "${BLUE}🐳 PLOSolver Docker Integration Tests${NC}"
echo "=================================="

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up Docker containers...${NC}"
    docker compose -f $TEST_COMPOSE_FILE down --volumes --remove-orphans 2>/dev/null || true
    docker network rm plosolver-test-network 2>/dev/null || true
    docker network rm test-plo-network 2>/dev/null || true
    docker container prune -f 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Set up trap to cleanup on script exit
trap cleanup EXIT

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if docker compose is available
if ! command -v docker compose >/dev/null 2>&1; then
    echo -e "${RED}❌ docker compose is not installed. Please install it and try again.${NC}"
    exit 1
fi

# Check if test compose file exists
if [ ! -f "$TEST_COMPOSE_FILE" ]; then
    echo -e "${RED}❌ Test compose file not found: $TEST_COMPOSE_FILE${NC}"
    exit 1
fi

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Backend directory not found: $BACKEND_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}🔍 Checking prerequisites...${NC}"

# Check if required Python packages are available
cd $BACKEND_DIR
if ! python -c "import docker" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Docker Python package not found. Installing...${NC}"
    pip install docker
fi

if ! python -c "import pytest" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Pytest not found. Installing...${NC}"
    pip install pytest
fi

cd - >/dev/null

echo -e "${GREEN}✅ Prerequisites check complete${NC}"

# Stop any existing test containers
echo -e "${YELLOW}🛑 Stopping any existing test containers...${NC}"
docker compose -f $TEST_COMPOSE_FILE down --volumes --remove-orphans 2>/dev/null || true

# Start test services
echo -e "${GREEN}🚀 Starting test services...${NC}"
docker compose -f $TEST_COMPOSE_FILE build
docker compose -f $TEST_COMPOSE_FILE up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
timeout=60
counter=0

while [ $counter -lt $timeout ]; do
    if docker compose -f $TEST_COMPOSE_FILE exec -T test-postgres pg_isready -U test_user >/dev/null 2>&1; then
        if docker compose -f $TEST_COMPOSE_FILE exec -T test-rabbitmq rabbitmq-diagnostics ping >/dev/null 2>&1; then
            echo -e "${GREEN}✅ All services are ready${NC}"
            break
        fi
    fi
    
    counter=$((counter + 1))
    echo -n "."
    sleep 1
done

if [ $counter -eq $timeout ]; then
    echo -e "\n${RED}❌ Services failed to start within $timeout seconds${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎯 Running Docker integration tests...${NC}"

# Run the tests
cd $BACKEND_DIR

# Set environment variables for Docker containers
export RABBITMQ_HOST=localhost
export RABBITMQ_PORT=5673
export RABBITMQ_USERNAME=test_user
export RABBITMQ_PASSWORD=test_password
export RABBITMQ_VHOST=/test
export DATABASE_URL=postgresql://test_user:test_password@localhost:5433/test_plosolver

# Run Docker integration tests (using Docker-specific config to avoid coverage permission issues)
echo -e "${BLUE}📋 Running RabbitMQ integration tests...${NC}"
python -m pytest -c pytest_docker.ini tests/integration/test_docker_rabbitmq_integration.py::TestDockerRabbitMQIntegration -v -m docker

echo -e "${BLUE}📋 Running job workflow integration tests...${NC}"
python -m pytest -c pytest_docker.ini tests/integration/test_docker_job_workflow.py::TestDockerJobWorkflow -v -m docker

cd - >/dev/null

echo -e "\n${GREEN}✅ Docker integration tests completed successfully!${NC}"

# Show test results summary
echo -e "\n${BLUE}📊 Test Summary:${NC}"
echo "  - RabbitMQ integration tests: ✅"
echo "  - Job workflow integration tests: ✅"
echo "  - All tests passed against live Docker containers"

echo -e "\n${GREEN}🎉 Integration tests completed successfully!${NC}" 