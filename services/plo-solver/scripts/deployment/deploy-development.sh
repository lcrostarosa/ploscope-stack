#!/bin/bash
# Development deployment script for PLOSolver

set -e

echo "🚀 Deploying PLOSolver to development environment..."

# Build the application
echo "🔨 Building application..."
make build

# Run with Docker in development mode
echo "🐳 Starting Docker containers..."
make run-docker

echo "✅ Development deployment complete!"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:5001" 