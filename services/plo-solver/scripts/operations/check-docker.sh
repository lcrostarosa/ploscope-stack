#!/bin/bash

# Docker Health Check Script
# This script checks Docker installation and running status

echo "🐳 Docker Health Check"
echo "======================="
echo ""

# Check if Docker command exists
if ! command -v docker &> /dev/null; then
    echo "❌ Docker command not found"
    echo "💡 Install Docker Desktop: brew install --cask docker"
    exit 1
else
    echo "✅ Docker command is available"
    echo "   Version: $(docker --version)"
fi

echo ""

# Check if Docker daemon is running
echo "🔍 Checking Docker daemon status..."
if docker info &> /dev/null; then
    echo "✅ Docker daemon is running"
    
    # Show Docker system info
    echo ""
    echo "📊 Docker System Info:"
    echo "   Containers: $(docker ps -q | wc -l | tr -d ' ') running, $(docker ps -aq | wc -l | tr -d ' ') total"
    echo "   Images: $(docker images -q | wc -l | tr -d ' ') total"
    
    # Check for PLO Solver containers
    echo ""
    echo "🔍 PLO Solver containers:"
    if docker ps -a --filter name=plosolver | grep -q plosolver; then
        docker ps -a --filter name=plosolver --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "   No PLO Solver containers found"
    fi
    
else
    echo "❌ Docker daemon is not running"
    echo ""
    echo "💡 Troubleshooting steps:"
    echo "   1. Start Docker Desktop from Applications folder"
    echo "   2. Wait for Docker Desktop to fully start (whale icon should be stable)"
    echo "   3. Run this script again to verify"
    echo ""
    
    # Check if Docker Desktop is installed
    if [[ -d "/Applications/Docker.app" ]]; then
        echo "✅ Docker Desktop is installed at /Applications/Docker.app"
        
        # Check if Docker Desktop process is running
        if pgrep -f "Docker Desktop" > /dev/null; then
            echo "⚠️  Docker Desktop process is running but daemon is not accessible"
            echo "   This usually means Docker is still starting up"
            echo "   Wait a minute and try again"
        else
            echo "⚠️  Docker Desktop is not running"
            echo "   Starting Docker Desktop..."
            open -a Docker
            echo "   Please wait for Docker Desktop to start completely"
        fi
    else
        echo "❌ Docker Desktop is not installed"
        echo "   Install with: brew install --cask docker"
    fi
    
    exit 1
fi

echo ""
echo "🎉 Docker is healthy and ready to use!"
echo ""
echo "📋 What you can do now:"
echo "   • Run PLO Solver with Docker support: ./run_with_traefik.sh --forum"
echo "   • Use Docker for PostgreSQL/RabbitMQ if local versions aren't available"
echo "   • Run containerized services for development" 