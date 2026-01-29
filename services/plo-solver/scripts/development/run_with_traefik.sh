#!/bin/bash

# Check if Traefik is installed
if ! command -v traefik &> /dev/null; then
    echo "Traefik is not installed. Please install it first:"
    echo "  macOS: brew install traefik"
    echo "  Linux: wget https://github.com/traefik/traefik/releases/download/v2.10.7/traefik_v2.10.7_linux_amd64.tar.gz"
    echo "  Or use Docker: docker run -d -p 80:80 -p 8080:8080 -v \$PWD:/etc/traefik traefik:v2.10"
    exit 1
fi

echo "Starting PLO Solver with Traefik reverse proxy..."

# Parse command line arguments
INCLUDE_FORUM=false
SHOW_HELP=false
NGROK_URL=""
NGROK_MODE=false
USE_DOCKER=false

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
        --docker)
            USE_DOCKER=true
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

# Redirect to Docker script if --docker flag is used
if [ "$USE_DOCKER" = true ]; then
    echo "🐳 Redirecting to Docker deployment..."
    DOCKER_ARGS=""
    if [ "$INCLUDE_FORUM" = true ]; then
        DOCKER_ARGS="$DOCKER_ARGS --forum"
    fi
    if [ "$NGROK_MODE" = true ]; then
        DOCKER_ARGS="$DOCKER_ARGS --ngrok $NGROK_URL"
    fi
    exec ./run_with_docker.sh $DOCKER_ARGS
fi

if [ "$SHOW_HELP" = true ]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --forum              Include Discourse forum"
    echo "  --ngrok <url>        Configure for ngrok URL (e.g. https://abc123.ngrok-free.app)"
    echo "  --docker             Use Docker for all services (redirects to run_with_docker.sh)"
    echo "  --help               Show this help message"
    echo ""
    echo "Services started (native mode):"
    echo "  • Traefik (reverse proxy)"
    echo "  • PostgreSQL (local or Docker fallback)"
    echo "  • RabbitMQ (local or Docker fallback)"
    echo "  • Backend (Flask API)"
    echo "  • Frontend (React app)"
    echo "  • Forum (Discourse via Docker) - optional with --forum"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start with native services"
    echo "  $0 --forum                          # Start with forum (requires Docker)"
    echo "  $0 --ngrok https://abc.ngrok-free.app  # Start with ngrok support"
    echo "  $0 --docker                         # Use Docker for all services"
    echo "  $0 --docker --forum                 # Docker mode with forum"
    exit 0
fi

# Validate ngrok URL if provided
if [ "$NGROK_MODE" = true ] && [ -z "$NGROK_URL" ]; then
    echo "❌ Error: --ngrok requires a URL"
    echo "Example: $0 --ngrok https://abc123.ngrok-free.app"
    exit 1
fi

# Database setup variables
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="postgres"  
DB_PASSWORD="postgres"
DB_NAME="plosolver"

# RabbitMQ setup variables
RABBITMQ_HOST="localhost"
RABBITMQ_PORT="5672"
RABBITMQ_USER="plosolver"
RABBITMQ_PASSWORD="dev_password_2024"
RABBITMQ_VHOST="/plosolver"

# Forum configuration
FORUM_ENABLED=$INCLUDE_FORUM
FORUM_DOMAIN="forum.localhost"
FORUM_PORT="4080"
DISCOURSE_VERSION="2.0.20241202-1135"
DISCOURSE_SSO_SECRET="36241cd9e33f8dbe7d768ff97164bc181a9070f0fc5bcc4e91ba5fef998b39c0"
DISCOURSE_DB_PASSWORD="discourse_secure_password"

# Function to check if PostgreSQL is running
check_postgres() {
    if command -v pg_isready &> /dev/null; then
        if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" &> /dev/null; then
            echo "✅ PostgreSQL is already running"
            return 0
        fi
    fi
    return 1
}

# Function to check if RabbitMQ is running
check_rabbitmq() {
    if curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASSWORD" http://$RABBITMQ_HOST:15672/api/whoami &> /dev/null; then
        echo "✅ RabbitMQ is already running"
        return 0
    fi
    # Also try with default guest credentials for locally installed RabbitMQ
    if curl -s -u guest:guest http://$RABBITMQ_HOST:15672/api/whoami &> /dev/null; then
        echo "✅ RabbitMQ is running with default credentials"
        return 0
    fi
    return 1
}

# Start PostgreSQL
start_postgres() {
    echo "🗄️ Setting up PostgreSQL..."
    
    if command -v postgres &> /dev/null || command -v pg_ctl &> /dev/null; then
        echo "Starting local PostgreSQL..."
        # Try to start local PostgreSQL
        if command -v brew &> /dev/null && brew services list | grep postgresql &> /dev/null; then
            brew services start postgresql
            sleep 3
        elif command -v pg_ctl &> /dev/null; then
            pg_ctl -D /usr/local/var/postgres start &
            sleep 3
        fi
        
        # Check if it's running now
        if check_postgres; then
            echo "✅ Local PostgreSQL started"
            return 0
        fi
    fi
    
    # PostgreSQL not available
    echo "❌ PostgreSQL is not running and could not be started!"
    echo ""
    echo "Please install and start PostgreSQL:"
    echo "  brew install postgresql"
    echo "  brew services start postgresql"
    echo ""
    echo "Or use Docker mode for automatic setup:"
    echo "  $0 --docker"
    exit 1
}

# Start Discourse Forum
start_forum() {
    if [ "$FORUM_ENABLED" = false ]; then
        return 0
    fi
    
    echo "❌ Forum is not supported in native mode!"
    echo ""
    echo "The Discourse forum requires Docker containers."
    echo "Please use Docker mode instead:"
    echo "  $0 --docker --forum"
    echo ""
    echo "Or run without the --forum option:"
    echo "  $0"
    exit 1
}

# Start RabbitMQ
start_rabbitmq() {
    echo "🐰 Setting up RabbitMQ..."
    
    # Check if RabbitMQ is already running locally
    if command -v rabbitmq-server &> /dev/null; then
        echo "Starting local RabbitMQ..."
        if command -v brew &> /dev/null && brew services list | grep rabbitmq &> /dev/null; then
            brew services start rabbitmq
            sleep 3
        else
            rabbitmq-server -detached &
            sleep 3
        fi
        
        # Check if it's running now
        if check_rabbitmq; then
            echo "✅ Local RabbitMQ started"
            return 0
        fi
    fi
    
    # RabbitMQ not available
    echo "❌ RabbitMQ is not running and could not be started!"
    echo ""
    echo "Please install and start RabbitMQ:"
    echo "  brew install rabbitmq"
    echo "  brew services start rabbitmq"
    echo ""
    echo "Then configure it with:"
    echo "  rabbitmqctl add_user plosolver dev_password_2024"
    echo "  rabbitmqctl set_user_tags plosolver administrator"
    echo "  rabbitmqctl add_vhost /plosolver"
    echo "  rabbitmqctl set_permissions -p /plosolver plosolver \".*\" \".*\" \".*\""
    echo ""
    echo "Or use Docker mode for automatic setup:"
    echo "  $0 --docker"
    exit 1
}

# Set up database environment variables for backend
export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
export POSTGRES_PASSWORD="$DB_PASSWORD"

# Set up RabbitMQ environment variables
export RABBITMQ_HOST="$RABBITMQ_HOST"
export RABBITMQ_PORT="$RABBITMQ_PORT"
export RABBITMQ_USERNAME="$RABBITMQ_USER"
export RABBITMQ_PASSWORD="$RABBITMQ_PASSWORD"
export RABBITMQ_VHOST="$RABBITMQ_VHOST"
export RABBITMQ_SPOT_QUEUE="spot-processing"
export RABBITMQ_SOLVER_QUEUE="solver-processing"
export RABBITMQ_SPOT_DLQ="spot-processing-dlq"
export RABBITMQ_SOLVER_DLQ="solver-processing-dlq"

# Forum environment variables
if [ "$FORUM_ENABLED" = true ]; then
    export DISCOURSE_URL="http://localhost:$FORUM_PORT"
    export DISCOURSE_DOMAIN="$FORUM_DOMAIN"
    export DISCOURSE_SSO_SECRET="$DISCOURSE_SSO_SECRET"
    export DISCOURSE_ENABLED=true
fi

# ngrok environment variables
if [ "$NGROK_MODE" = true ]; then
    export REACT_APP_API_URL="/api"
    export NODE_ENV="development"
fi

# Kill any existing processes on these ports
echo "🧹 Cleaning up existing processes..."
if [ "$NGROK_MODE" = false ]; then
    # Only kill port 80 processes if NOT using ngrok (ngrok needs port 80)
    lsof -ti:80 | xargs kill -9 2>/dev/null || true
else
    echo "⚠️  Skipping port 80 cleanup (ngrok is using it)"
    # Clean up ngrok-specific ports
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    lsof -ti:8081 | xargs kill -9 2>/dev/null || true
fi
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true
if [ "$FORUM_ENABLED" = true ]; then
    lsof -ti:$FORUM_PORT | xargs kill -9 2>/dev/null || true
fi

# Clean up existing processes
echo "🧹 Cleaning up existing processes..."

# Start PostgreSQL
if ! check_postgres; then
    if ! start_postgres; then
        echo "❌ Failed to start PostgreSQL"
        exit 1
    fi
fi

# Start RabbitMQ
if ! check_rabbitmq; then
    if ! start_rabbitmq; then
        echo "❌ Failed to start RabbitMQ"
        exit 1
    fi
fi

# Bootstrap RabbitMQ queues
echo "🔧 Bootstrapping RabbitMQ queues..."
if ./scripts/setup/bootstrap-rabbitmq.sh; then
    echo "✅ RabbitMQ queues bootstrapped successfully"
else
    echo "❌ Failed to bootstrap RabbitMQ queues"
    exit 1
fi

# Start forum if requested
if [ "$FORUM_ENABLED" = true ]; then
    start_forum
fi

# Update Traefik configuration
update_traefik_config

# Start Traefik in background
if [ "$NGROK_MODE" = true ]; then
    echo "🔀 Starting Traefik on port 8080 (ngrok will proxy port 80 to this)..."
    # Create ngrok-specific traefik config
    cat > traefik-ngrok.yml << EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":8080"
  traefik:
    address: ":8081"

providers:
  file:
    filename: dynamic.yml
    watch: true

log:
  level: INFO

accessLog: {}
EOF
    traefik --configfile=traefik-ngrok.yml &
    TRAEFIK_PID=$!
else
    echo "🔀 Starting Traefik on port 80..."
    traefik --configfile=server/traefik/traefik.yml &
    TRAEFIK_PID=$!
fi

# Start backend server
echo "🖥️ Starting backend server on port 5001..."

# Source environment file for backend
if [ -f "env.development" ]; then
    echo "📄 Sourcing env.development..."
    export $(grep -v '^#' env.development | xargs)
elif [ -f ".env" ]; then
    echo "📄 Sourcing .env..."
    export $(grep -v '^#' .env | xargs)
fi

(cd src/backend && python -m core.app) &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Start frontend
echo "🎨 Starting frontend server..."
cd src/frontend
npx webpack serve --mode development &
cd ../..

# Job processing is integrated into the main Flask application
echo "🔄 Job processing integrated into main application..."

echo ""
if [ "$NGROK_MODE" = true ]; then
    echo "🚀 PLO Solver is now running with ngrok support!"
    echo "📱 Local Frontend: http://localhost:8080 (via Traefik)"
    echo "🌐 ngrok Frontend: $NGROK_URL"
    echo "🔧 Local Backend API: http://localhost:8080/api"
    echo "🌐 ngrok Backend API: $NGROK_URL/api"
    echo "📊 Traefik Dashboard: http://localhost:8081"
    echo "🐰 RabbitMQ Management: http://localhost:15672 ($RABBITMQ_USER/$RABBITMQ_PASSWORD)"
    
    if [ "$FORUM_ENABLED" = true ]; then
        echo "🗣️ Local Forum: http://localhost:8080/forum"
        echo "🌐 ngrok Forum: $NGROK_URL/forum"
    fi
    
    echo ""
    echo "💡 Make sure ngrok is running with:"
    echo "   ngrok http 8080"
    echo ""
    echo "🔗 Your app is accessible at: $NGROK_URL"
else
    echo "🚀 PLO Solver is now running!"
    echo "📱 Frontend: http://localhost (via Traefik)"
    echo "🔧 Backend API: http://localhost/api"
    echo "📊 Traefik Dashboard: http://localhost:8080"
    echo "🐰 RabbitMQ Management: http://localhost:15672 ($RABBITMQ_USER/$RABBITMQ_PASSWORD)"
    
    if [ "$FORUM_ENABLED" = true ]; then
        echo "🗣️ Forum: http://localhost/forum or http://$FORUM_DOMAIN"
        echo "   Direct access: http://localhost:$FORUM_PORT"
    fi
    
    echo ""
    echo "🌐 For NGROK support:"
    echo "1. Run: ngrok http 8080"
    echo "2. Use: $0 --ngrok https://your-ngrok-url.ngrok-free.app"
    if [ "$FORUM_ENABLED" = true ]; then
        echo "3. Or: $0 --ngrok https://your-ngrok-url.ngrok-free.app --forum"
    fi
fi

echo "🗄️ Database: PostgreSQL (local installation)"
echo "🐰 Message Queue: RabbitMQ (local installation)"
echo "🔄 Job Workers: 2 spot workers, 1 solver worker"

echo ""
echo "Press Ctrl+C to stop all services"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all services..."
    kill $TRAEFIK_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    
    # Stop PostgreSQL (if we started it)
    if command -v brew &> /dev/null && brew services list | grep postgresql | grep started &> /dev/null; then
        echo "🗄️ Stopping local PostgreSQL..."
        brew services stop postgresql
    fi
    
    # Stop RabbitMQ (if we started it)
    if command -v brew &> /dev/null && brew services list | grep rabbitmq | grep started &> /dev/null; then
        echo "🐰 Stopping local RabbitMQ..."
        brew services stop rabbitmq
    fi
    
    # Clean up ngrok config files
    if [ "$NGROK_MODE" = true ]; then
        rm -f traefik-ngrok.yml
    fi
    
    echo "✅ All services stopped."
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for user to stop
wait 