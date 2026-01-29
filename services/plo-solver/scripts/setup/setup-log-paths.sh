#!/bin/bash

# Setup Log Paths for ELK Stack
# This script creates necessary log directories and files with proper permissions

set -e

echo "🔧 Setting up log paths for ELK stack..."
echo "=========================================="

# Create log directories
echo "📁 Creating log directories..."

# Local development paths (relative to project)
if [ "$ENVIRONMENT" = "development" ] || [ -z "$ENVIRONMENT" ]; then
    echo "   Using local development paths..."
    
    # Create local log directories
    mkdir -p ./logs/traefik
    mkdir -p ./logs/plosolver
    mkdir -p ./logs/system
    
    # Set permissions
    chmod 755 ./logs
    chmod 755 ./logs/traefik
    chmod 755 ./logs/plosolver
    chmod 755 ./logs/system
    
    # Create empty log files if they don't exist
    touch ./logs/docker.log
    touch ./logs/system.log
    
    chmod 644 ./logs/docker.log
    chmod 644 ./logs/system.log
    
    echo "✅ Local log directories created:"
    echo "   - ./logs/traefik/"
    echo "   - ./logs/plosolver/"
    echo "   - ./logs/system/"
    echo "   - ./logs/docker.log"
    echo "   - ./logs/system.log"

# Staging/Production paths (system paths)
else
    echo "   Using system paths for $ENVIRONMENT..."
    
    # Check if running as root (needed for system paths)
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  Warning: Not running as root. System log paths may not be accessible."
        echo "   Consider running with sudo or using local development paths."
    fi
    
    # Create system log directories if they don't exist
    sudo mkdir -p /var/log/traefik 2>/dev/null || true
    sudo mkdir -p /var/log/plosolver 2>/dev/null || true
    
    # Create empty log files if they don't exist
    sudo touch /var/log/docker.log 2>/dev/null || true
    sudo touch /var/log/system.log 2>/dev/null || true
    
    # Set permissions
    sudo chmod 755 /var/log/traefik 2>/dev/null || true
    sudo chmod 755 /var/log/plosolver 2>/dev/null || true
    sudo chmod 644 /var/log/docker.log 2>/dev/null || true
    sudo chmod 644 /var/log/system.log 2>/dev/null || true
    
    echo "✅ System log directories created:"
    echo "   - /var/log/traefik/"
    echo "   - /var/log/plosolver/"
    echo "   - /var/log/docker.log"
    echo "   - /var/log/system.log"
fi

echo ""
echo "🔧 Setting environment variables..."

# Create environment-specific .env file
if [ "$ENVIRONMENT" = "development" ] || [ -z "$ENVIRONMENT" ]; then
    cat > env.development << EOF
# Development Environment - Local Log Paths
LOG_PATH=./logs/plosolver
TRAEFIK_LOG_PATH=./logs/traefik
SYSTEM_LOG_PATH=./logs/system
DOCKER_LOG_PATH=./logs/docker.log
ENVIRONMENT=development
EOF
    echo "✅ Created .env.development with local paths"
    
elif [ "$ENVIRONMENT" = "staging" ]; then
    cat > .env.staging << EOF
# Staging Environment - System Log Paths
LOG_PATH=/var/log/plosolver
TRAEFIK_LOG_PATH=/var/log/traefik
SYSTEM_LOG_PATH=/var/log
DOCKER_LOG_PATH=/var/log/docker.log
ENVIRONMENT=staging
EOF
    echo "✅ Created .env.staging with system paths"
    
elif [ "$ENVIRONMENT" = "production" ]; then
    cat > .env.production << EOF
# Production Environment - System Log Paths
LOG_PATH=/var/log/plosolver
TRAEFIK_LOG_PATH=/var/log/traefik
SYSTEM_LOG_PATH=/var/log
DOCKER_LOG_PATH=/var/log/docker.log
ENVIRONMENT=production
EOF
    echo "✅ Created .env.production with system paths"
fi

echo ""
echo "🔍 Testing log path accessibility..."

# Test if Docker can access the log paths
if docker info >/dev/null 2>&1; then
    echo "✅ Docker is running"
    
    # Test log path mounting
    if [ "$ENVIRONMENT" = "development" ] || [ -z "$ENVIRONMENT" ]; then
        echo "   Testing local log path mounting..."
        docker run --rm -v "$(pwd)/logs:/test-logs" alpine ls /test-logs >/dev/null 2>&1 && \
            echo "✅ Local log paths are accessible to Docker" || \
            echo "❌ Local log paths are not accessible to Docker"
    else
        echo "   Testing system log path mounting..."
        docker run --rm -v /var/log:/test-logs alpine ls /test-logs >/dev/null 2>&1 && \
            echo "✅ System log paths are accessible to Docker" || \
            echo "❌ System log paths are not accessible to Docker"
    fi
else
    echo "❌ Docker is not running"
fi

echo ""
echo "🎯 Setup complete!"
echo ""
echo "📋 Usage:"
echo "   # For development (local paths):"
echo "   ENVIRONMENT=development ./scripts/setup-log-paths.sh"
echo ""
echo "   # For staging/production (system paths):"
echo "   sudo ENVIRONMENT=staging ./scripts/setup-log-paths.sh"
echo ""
echo "   # Start services with proper environment:"
echo "   docker-compose --env-file env.development up -d"
echo "   docker-compose --env-file env.staging up -d" 