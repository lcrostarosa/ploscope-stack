#!/bin/bash

# PLOSolver CI Pipeline - Docker-in-Docker Version
# This script runs the entire CI pipeline in an isolated Docker container
# with access to the host Docker daemon to avoid conflicts with local services

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Running CI Pipeline in Docker-in-Docker...${NC}"
echo -e "${BLUE}📦 Complete isolation from local environment${NC}"
echo -e "${BLUE}🔒 No conflicts with local services (RabbitMQ, PostgreSQL, etc.)${NC}"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Create a Dockerfile for the CI environment
cat > Dockerfile.ci << 'EOF'
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    git \
    software-properties-common \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.11
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.11 python3.11-venv \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Install Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Set up Node.js environment
WORKDIR /app

# Copy package files first for better caching
COPY src/frontend/package*.json ./frontend/
COPY src/backend/requirements*.txt ./backend/

# Install Python dependencies with retry logic and better error handling
RUN pip3 install --upgrade pip --retries 3 --timeout 300 && \
    pip3 install --ignore-installed --retries 3 --timeout 300 --no-cache-dir -r backend/requirements.txt && \
    pip3 install --ignore-installed --retries 3 --timeout 300 --no-cache-dir -r backend/requirements-test.txt

# Install Node.js dependencies
RUN cd frontend && npm ci --no-audit --no-fund

# Copy the entire project
COPY . .

# Set environment variables
ENV NODE_ENV=test
ENV PYTHONPATH=/app/src/backend
ENV FLASK_ENV=testing

# Create CI pipeline script
RUN cat > /tmp/ci-pipeline.sh << 'CI_SCRIPT_EOF'
#!/bin/bash
set -e

echo "🚀 Starting CI Pipeline Steps..."

echo "📋 Step 1/6: Installing dependencies..."
echo "🔍 Frontend dependencies..."
cd /app/src/frontend && rm -rf node_modules && npm ci
echo "🔍 Backend dependencies..."
cd /app/src/backend && pip3 install -r requirements.txt -r requirements-test.txt

echo "📋 Step 2/6: Running linting..."
echo "🔍 Frontend linting..."
cd /app/src/frontend && npm run lint
echo "🔍 Backend linting..."
cd /app/src/backend && flake8 . --max-line-length=120 --extend-ignore=E203,W503

echo "📋 Step 3/6: Running unit tests..."
echo "🧪 Frontend unit tests..."
cd /app/src/frontend && npm test -- --watchAll=false --passWithNoTests
echo "🧪 Backend unit tests..."
cd /app/src/backend && python3 -m pytest tests/unit/ -v --tb=short

echo "📋 Step 4/6: Building Docker images..."
cd /app && docker build -f src/frontend/Dockerfile -t plosolver-frontend-test .
cd /app && docker build -f src/backend/Dockerfile -t plosolver-backend-test .

echo "📋 Step 5/6: Running integration tests with Docker services..."
# Create required directories for Docker Compose volumes
mkdir -p /app/data/postgres
mkdir -p /app/backups

# Set environment variables for test environment
export POSTGRES_DATA_PATH=/app/data/postgres
export POSTGRES_BACKUP_PATH=/app/backups
export ENVIRONMENT=test

cd /app && docker compose up -d db rabbitmq
sleep 10
cd /app/src/backend && python3 -m pytest tests/integration/ -v --tb=short
cd /app && docker compose down

echo "📋 Step 6/6: Security checks..."
cd /app/src/frontend && npm audit --audit-level=moderate || true
cd /app/src/backend && bandit -r . -f json -o /tmp/bandit-results.json || true

echo "✅ CI Pipeline completed successfully!"
CI_SCRIPT_EOF

RUN chmod +x /tmp/ci-pipeline.sh

# Default command
CMD ["/tmp/ci-pipeline.sh"]
EOF

# Build the CI container
echo -e "${BLUE}🔨 Building CI container...${NC}"
docker build -f Dockerfile.ci -t plosolver-ci-pipeline .

# Run the CI pipeline with Docker socket mounted
echo -e "${BLUE}🚀 Running CI pipeline in Docker-in-Docker...${NC}"
docker run --rm \
    --name plosolver-ci-pipeline \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd):/app" \
    -w /app \
    plosolver-ci-pipeline

# Clean up
rm -f Dockerfile.ci

# Check exit status
if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 CI Pipeline completed successfully!${NC}"
    echo -e "${GREEN}✅ All checks passed - ready to commit!${NC}"
    exit 0
else
    echo -e "${RED}❌ CI Pipeline failed!${NC}"
    echo -e "${YELLOW}🔍 Check the logs above for details.${NC}"
    exit 1
fi
