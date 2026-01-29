#!/bin/bash
# Production deployment script for PLOSolver

set -e

echo "🚀 Deploying PLOSolver to production environment..."

# Warning for production deployment
echo "⚠️  WARNING: This will deploy to PRODUCTION environment"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Production deployment cancelled"
    exit 1
fi

# Set production environment
echo "⚙️  Setting production environment..."
cp env.production .env

# Build the application
echo "🔨 Building application for production..."
make build

# Run security checks
echo "🔐 Running security checks..."
make security

# Deploy with Traefik
echo "🐳 Starting production containers..."
make run-traefik

echo "✅ Production deployment complete!"
echo "   Application: http://localhost"
echo "   Traefik Dashboard: http://localhost:8080" 