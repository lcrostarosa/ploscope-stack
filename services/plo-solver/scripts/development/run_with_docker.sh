#!/bin/bash

# PLO Solver - Docker Deployment Script
# This script runs the entire PLO Solver stack using Docker containers

set -e  # Exit on any error

echo "🐳 Starting PLO Solver with Docker..."
echo ""

# Parse command line arguments
INCLUDE_FORUM=false
SHOW_HELP=false
NGROK_URL=""
NGROK_MODE=false
REBUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --forum)
            INCLUDE_FORUM=true
            shift
            ;;
        --ngrok)
            NGROK_MODE=true
            NGROK_URL="$2"
            shift 2
            ;;
        --rebuild)
            REBUILD=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --forum              Include Discourse forum"
    echo "  --ngrok <url>        Configure for ngrok URL (e.g. https://abc123.ngrok-free.app)"
    echo "  --rebuild            Rebuild Docker images before starting"
    echo "  --help               Show this help message"
    echo ""
    echo "Services started (all in Docker containers):"
    echo "  • Traefik (reverse proxy)"
    echo "  • PostgreSQL (database)"
    echo "  • RabbitMQ (message queue)"
    echo "  • Backend (Flask API)"
    echo "  • Frontend (React app)"
    echo "  • Forum (Discourse) - optional with --forum"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start without forum"
    echo "  $0 --forum                          # Start with forum"
    echo "  $0 --ngrok https://abc.ngrok-free.app  # Start with ngrok support"
    echo "  $0 --rebuild                        # Rebuild images and start"
    exit 0
fi

# Function to check if Docker is available and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker command not found"
        echo "💡 Install Docker Desktop: brew install --cask docker"
        return 1
    fi
    if ! docker info &> /dev/null; then
        echo "❌ Docker daemon is not running"
        echo "💡 Please start Docker Desktop and wait for it to be ready"
        return 1
    fi
    return 0
}

# Function to check if docker compose is available
check_docker_compose() {
    if ! command -v docker compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose not found"
        echo "💡 Docker Compose should be included with Docker Desktop"
        return 1
    fi
    return 0
}

# Validate ngrok URL if provided
if [ "$NGROK_MODE" = true ] && [ -z "$NGROK_URL" ]; then
    echo "❌ Error: --ngrok requires a URL"
    echo "Example: $0 --ngrok https://abc123.ngrok-free.app"
    exit 1
fi

# Check Docker availability
echo "🔍 Checking Docker availability..."
if ! check_docker; then
    exit 1
fi

echo "✅ Docker is available"

if ! check_docker_compose; then
    exit 1
fi

echo "✅ Docker Compose is available"
echo ""

# Source environment file for backend
if [ -f "env.development" ]; then
    echo "📄 Sourcing env.development..."
    export $(grep -v '^#' env.development | xargs)
elif [ -f ".env" ]; then
    echo "📄 Sourcing .env..."
    export $(grep -v '^#' .env | xargs)
fi

# ngrok configuration
if [ "$NGROK_MODE" = true ]; then
    echo "🔧 Configuring for ngrok mode..."
    NGROK_DOMAIN=$(echo $NGROK_URL | sed 's|https://||' | sed 's|http://||' | sed 's|/.*||')
    export FRONTEND_DOMAIN="$NGROK_DOMAIN"
    export TRAEFIK_DOMAIN="$NGROK_DOMAIN"
    export REACT_APP_API_URL="/api"
    echo "   Domain: $NGROK_DOMAIN"
fi

# Forum configuration
if [ "$INCLUDE_FORUM" = true ]; then
    echo "🗣️ Forum will be included in deployment"
    export DISCOURSE_ENABLED=true
    export DISCOURSE_URL="http://localhost:4080"
    export DISCOURSE_DOMAIN="forum.localhost"
    export DISCOURSE_SSO_SECRET=${DISCOURSE_SSO_SECRET:-change-this-secret}
fi

# Determine which services to start
if [ "$INCLUDE_FORUM" = true ]; then
    COMPOSE_PROFILES="app,forum"
else
    COMPOSE_PROFILES="app"
fi

echo "🧹 Cleaning up any existing containers..."
# Stop and remove existing containers
docker compose down --remove-orphans 2>/dev/null || true

# Remove specific PLO Solver containers if they exist
docker rm -f plosolver-postgres plosolver-rabbitmq plosolver-discourse 2>/dev/null || true

echo ""
if [ "$REBUILD" = true ]; then
    echo "🔨 Rebuilding Docker images..."
    COMPOSE_PROFILES="$COMPOSE_PROFILES" docker compose build --no-cache
    echo "✅ Images rebuilt"
    echo ""
fi

echo "🚀 Starting services with Docker Compose..."
echo "   Profiles: $COMPOSE_PROFILES"

# Start services
COMPOSE_PROFILES="$COMPOSE_PROFILES" docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."

# Wait for database to be ready
echo "🗄️ Waiting for PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T db pg_isready -U "$POSTGRES_USER" &> /dev/null; then
        echo "✅ PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ PostgreSQL failed to start within 60 seconds"
        exit 1
    fi
    sleep 2
done

# Wait for RabbitMQ to be ready
echo "🐰 Waiting for RabbitMQ..."
for i in {1..30}; do
    if docker compose exec -T rabbitmq rabbitmq-diagnostics ping &> /dev/null; then
        echo "✅ RabbitMQ is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ RabbitMQ failed to start within 60 seconds"
        exit 1
    fi
    sleep 2
done

# Bootstrap RabbitMQ queues
echo "🔧 Bootstrapping RabbitMQ queues..."
if ./scripts/setup/bootstrap-rabbitmq.sh; then
    echo "✅ RabbitMQ queues bootstrapped successfully"
else
    echo "❌ Failed to bootstrap RabbitMQ queues"
    exit 1
fi

# Wait for backend to be ready
echo "🖥️ Waiting for backend..."
for i in {1..30}; do
    if curl -s http://localhost/api/health &> /dev/null; then
        echo "✅ Backend is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "⚠️ Backend may still be starting up"
        break
    fi
    sleep 2
done

echo ""
if [ "$NGROK_MODE" = true ]; then
    echo "🚀 PLO Solver is now running with Docker + ngrok support!"
    echo "📱 Local Frontend: http://localhost (via Traefik)"
    echo "🌐 ngrok Frontend: $NGROK_URL"
    echo "🔧 Local Backend API: http://localhost/api"
    echo "🌐 ngrok Backend API: $NGROK_URL/api"
    echo "📊 Traefik Dashboard: http://localhost:8080"
    echo "🐰 RabbitMQ Management: http://localhost:15672 ($RABBITMQ_USERNAME/$RABBITMQ_PASSWORD)"
    
    if [ "$INCLUDE_FORUM" = true ]; then
        echo "🗣️ Local Forum: http://localhost/forum"
        echo "🌐 ngrok Forum: $NGROK_URL/forum"
    fi
    
    echo ""
    echo "💡 Make sure ngrok is running with:"
    echo "   ngrok http 80"
    echo ""
    echo "🔗 Your app is accessible at: $NGROK_URL"
else
    echo "🚀 PLO Solver is now running with Docker!"
    echo "📱 Frontend: http://localhost (via Traefik)"
    echo "🔧 Backend API: http://localhost/api"
    echo "📊 Traefik Dashboard: http://localhost:8080"
    echo "🐰 RabbitMQ Management: http://localhost:15672 ($RABBITMQ_USERNAME/$RABBITMQ_PASSWORD)"
    
    if [ "$INCLUDE_FORUM" = true ]; then
        echo "🗣️ Forum: http://localhost/forum"
    fi
    
    echo ""
    echo "🌐 For NGROK support:"
    echo "1. Run: ngrok http 80"
    echo "2. Use: $0 --ngrok https://your-ngrok-url.ngrok-free.app"
fi

echo ""
echo "🐳 All services running in Docker containers:"
echo "   Database: PostgreSQL container"
echo "   Message Queue: RabbitMQ container"
echo "   Reverse Proxy: Traefik container"
echo "   Backend: Flask container"
echo "   Frontend: React container"
if [ "$INCLUDE_FORUM" = true ]; then
    echo "   Forum: Discourse container"
fi

echo ""
echo "📋 Management Commands:"
echo "   View logs: docker compose logs -f [service_name]"
echo "   Stop all: docker compose down"
echo "   Restart: docker compose restart [service_name]"
echo "   Rebuild: $0 --rebuild"

echo ""
echo "Press Ctrl+C to stop all services, or run 'docker compose down' in another terminal"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all Docker services..."
    docker compose down
    echo "✅ All services stopped."
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Keep the script running
if [ -t 0 ]; then
    # Interactive mode - wait for user input
    echo ""
    echo "🖥️ Running in interactive mode. Press Ctrl+C to stop all services."
    wait
else
    # Non-interactive mode - just exit
    echo ""
    echo "🖥️ Services started in background. Use 'docker compose down' to stop."
fi 