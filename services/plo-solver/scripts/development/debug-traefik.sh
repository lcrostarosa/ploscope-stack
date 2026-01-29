#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root directory
cd "$PROJECT_ROOT"

# Function to start Docker if not running
start_docker_if_needed() {
    if ! docker info >/dev/null 2>&1; then
        echo "🐳 Docker is not running. Starting Docker Desktop..."
        
        # Check if Docker Desktop is already running as a process
        if ! pgrep -f "Docker Desktop" >/dev/null; then
            open -a Docker
            echo "⏳ Starting Docker Desktop application..."
            sleep 10  # Give Docker Desktop time to launch
        else
            echo "⏳ Docker Desktop is starting up..."
        fi
        
        echo "⏳ Waiting for Docker daemon to be ready..."
        for i in {1..120}; do
            if docker info >/dev/null 2>&1; then
                echo ""
                echo "✅ Docker daemon is now running!"
                # Additional check to make sure Docker is fully ready
                sleep 3
                if docker ps >/dev/null 2>&1; then
                    echo "✅ Docker is fully operational!"
                    return 0
                fi
            fi
            if [ $i -eq 120 ]; then
                echo ""
                echo "❌ Docker failed to start within 4 minutes"
                echo "Current Docker status:"
                docker info 2>&1 || echo "Docker info failed"
                echo ""
                echo "Troubleshooting steps:"
                echo "1. Try starting Docker Desktop manually"
                echo "2. Check if Docker Desktop is installed: ls -la /Applications/Docker.app"
                echo "3. Check Docker processes: pgrep -f Docker"
                echo "4. Try: killall Docker && open -a Docker"
                exit 1
            fi
            if [ $((i % 10)) -eq 0 ]; then
                echo -n " ${i}s"
            else
                echo -n "."
            fi
            sleep 2
        done
    else
        echo "✅ Docker is already running"
        # Double-check that Docker is fully operational
        if ! docker ps >/dev/null 2>&1; then
            echo "⚠️ Docker info works but Docker seems not fully ready. Waiting..."
            sleep 5
        fi
    fi
}

# Check if Docker is running and start if needed
start_docker_if_needed

echo "🔍 Debugging PLO Solver Docker setup..."
echo "Working directory: $PROJECT_ROOT"

# Parse arguments
SILENT_MODE=false
ENV_FILE="env.development"

for arg in "$@"; do
    case $arg in
        --silent|-s)
            SILENT_MODE=true
            shift
            ;;
        production)
            ENV_FILE="env.production"
            shift
            ;;
        ngrok)
            ENV_FILE="env.ngrok"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [ENVIRONMENT]"
            echo ""
            echo "ENVIRONMENTS:"
            echo "  development  Use development environment (default)"
            echo "  production   Use production environment"
            echo "  ngrok        Use ngrok environment"
            echo ""
            echo "OPTIONS:"
            echo "  --silent, -s    Silent mode: exit after debugging"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "EXAMPLES:"
            echo "  $0                    # Debug in development mode"
            echo "  $0 --silent          # Debug and exit"
            echo "  $0 production        # Debug production environment"
            exit 0
            ;;
        *)
            # Unknown option
            ;;
    esac
done

echo "📁 Using environment: $ENV_FILE"

# Function to show service status
show_status() {
    echo "📊 Current service status:"
    docker compose --env-file="$ENV_FILE" ps
    echo ""
}

# Function to show logs
show_logs() {
    echo "📋 Recent logs:"
    docker compose --env-file="$ENV_FILE" logs --tail=10
    echo ""
}

# Kill any existing processes on these ports
echo "🧹 Cleaning up existing processes..."
lsof -ti:80 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true

# Stop any existing Docker services
echo "🐳 Stopping existing Docker services..."
docker compose --env-file="$ENV_FILE" down 2>/dev/null || true

echo "🔍 Testing Docker Compose configuration..."
if docker compose --env-file="$ENV_FILE" config >/dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration has errors:"
    docker compose --env-file="$ENV_FILE" config
    exit 1
fi

echo ""
echo "🚀 Step 1: Starting Traefik..."
docker compose --env-file="$ENV_FILE" --profile=traefik up -d
sleep 5
show_status

echo "🚀 Step 2: Starting Database..."
docker compose --env-file="$ENV_FILE" --profile=traefik --profile=database up -d
sleep 10
show_status

echo "🚀 Step 3: Starting Backend..."
docker compose --env-file="$ENV_FILE" --profile=traefik --profile=database --profile=backend up -d
sleep 10
show_status

echo "🚀 Step 4: Starting Frontend..."
docker compose --env-file="$ENV_FILE" --profile=traefik --profile=database --profile=backend --profile=frontend up -d
sleep 10
show_status

echo "🔍 Testing API endpoint..."
sleep 5
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health 2>/dev/null || echo "000")

if [ "$API_STATUS" = "200" ]; then
    echo "✅ API is responding"
elif [ "$API_STATUS" = "000" ]; then
    echo "⚠️ Could not connect to API endpoint"
else
    echo "⚠️ API returned HTTP $API_STATUS"
fi

echo ""
echo "🔍 Checking individual container health..."
docker compose --env-file="$ENV_FILE" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔍 Checking logs for errors..."
show_logs

echo ""
echo "🌐 If everything looks good, you can access:"
echo "📱 Frontend: http://localhost"
echo "🔧 Backend API: http://localhost/api"
echo "📊 Traefik Dashboard: http://localhost:8080"

echo ""
echo "🚀 To start forum services (optional):"
echo "docker compose --env-file=$ENV_FILE --profile=forum up -d"

echo ""
if [ "$SILENT_MODE" = true ]; then
    echo "🤫 Silent mode: Debug completed. Exiting..."
else
    echo "🔍 Debug completed. Services are running."
    echo "📋 To view continuous logs, run:"
    echo "   docker compose --env-file=$ENV_FILE logs -f"
    echo ""
    echo "📋 To stop services, run:"
    echo "   docker compose --env-file=$ENV_FILE down"
fi 