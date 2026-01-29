#!/bin/bash

# Development script for hot reloading setup
# This script starts the development environment with hot reloading enabled

set -e

echo "🚀 Starting PLOSolver Development Environment with Hot Reloading..."

# Function to cleanup on exit
cleanup() {
    echo "🛑 Stopping development environment..."
    docker-compose -f docker-compose-localdev.yml down
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose -f docker-compose-localdev.yml down

# Build and start the development environment
echo "🐳 Building and starting development containers..."
docker-compose -f docker-compose-localdev.yml up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."
for service in db rabbitmq backend frontend; do
    echo "Checking $service..."
    if docker-compose -f docker-compose-localdev.yml exec -T $service wget --no-verbose --tries=1 --spider http://localhost:3000 2>/dev/null || \
       docker-compose -f docker-compose-localdev.yml exec -T $service curl -f http://localhost:5001/api/health 2>/dev/null || \
       docker-compose -f docker-compose-localdev.yml exec -T $service pg_isready -U postgres 2>/dev/null || \
       docker-compose -f docker-compose-localdev.yml exec -T $service rabbitmq-diagnostics ping 2>/dev/null; then
        echo "✅ $service is healthy"
    else
        echo "⚠️  $service health check failed (may still be starting)"
    fi
done

echo ""
echo "🎉 Development environment is ready!"
echo ""
echo "📱 Access your application at:"
echo "   🌐 Frontend: http://localhost:3000"
echo "   🔧 Backend API: http://localhost:5001"
echo "   📊 Traefik Dashboard: http://localhost:8080"
echo "   🐰 RabbitMQ Management: http://localhost:15672"
echo "   🗄️  Database: localhost:5432"
echo ""
echo "🔥 Hot reloading is enabled:"
echo "   • Frontend changes will automatically reload in the browser"
echo "   • Backend changes will automatically restart the Flask server"
echo "   • CSS changes will be applied instantly"
echo ""
echo "💡 Useful commands:"
echo "   View logs: docker-compose -f docker-compose-localdev.yml logs -f"
echo "   View frontend logs: docker-compose -f docker-compose-localdev.yml logs -f frontend"
echo "   View backend logs: docker-compose -f docker-compose-localdev.yml logs -f backend"
echo "   Stop services: docker-compose -f docker-compose-localdev.yml down"
echo "   Restart services: docker-compose -f docker-compose-localdev.yml restart"
echo ""
echo "Press Ctrl+C to stop the development environment"

# Keep the script running and show logs
docker-compose -f docker-compose-localdev.yml logs -f 