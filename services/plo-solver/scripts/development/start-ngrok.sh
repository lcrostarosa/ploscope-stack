#!/bin/bash

# ngrok integration script for PLOSolver
# This script starts the application with ngrok tunnel support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🌐 PLOSolver ngrok Integration"
echo "=============================="

# Check if we're in the right directory
if [ ! -f "src/frontend/package.json" ] || [ ! -d "src/backend" ]; then
    echo "❌ Error: This script must be run from the PLOSolver root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Directory containing src/frontend/package.json and src/backend/"
    exit 1
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    print_error "ngrok is not installed"
    echo "Please install ngrok first:"
    echo "  macOS: brew install ngrok/ngrok/ngrok"
    echo "  Or download from: https://ngrok.com/download"
    exit 1
fi

# Parse command line arguments
SHOW_HELP=false
NGROK_AUTH_TOKEN=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auth-token)
            NGROK_AUTH_TOKEN="$2"
            shift 2
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --auth-token TOKEN    Set ngrok auth token"
    echo "  --force, -f           Force start without confirmation"
    echo "  --help, -h            Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Start ngrok tunnel"
    echo "  2. Start backend server"
    echo "  3. Start frontend server"
    echo "  4. Configure for ngrok URL"
    echo ""
    echo "Examples:"
    echo "  $0                    # Start with default settings"
    echo "  $0 --auth-token abc123 # Start with auth token"
    echo "  $0 --force            # Start without confirmation"
    exit 0
fi

# Function to get ngrok URL
get_ngrok_url() {
    # Wait for ngrok to start and get the URL
    print_status "Waiting for ngrok to start..."
    for i in {1..30}; do
        if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
            NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4)
            if [ -n "$NGROK_URL" ]; then
                print_success "ngrok URL: $NGROK_URL"
                return 0
            fi
        fi
        sleep 1
    done
    print_error "Failed to get ngrok URL"
    return 1
}

# Function to cleanup on exit
cleanup() {
    echo ""
    print_status "Cleaning up..."
    
    # Kill all background processes
    kill $NGROK_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    
    print_success "Cleanup completed"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Main execution
print_status "Starting PLOSolver with ngrok..."

# Kill any existing processes
print_status "Cleaning up existing processes..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true
lsof -ti:4040 | xargs kill -9 2>/dev/null || true

# Set ngrok auth token if provided
if [ -n "$NGROK_AUTH_TOKEN" ]; then
    print_status "Setting ngrok auth token..."
    ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
fi

# Start ngrok tunnel
print_status "Starting ngrok tunnel..."
ngrok http 80 &
NGROK_PID=$!

# Wait for ngrok to start and get URL
if ! get_ngrok_url; then
    print_error "Failed to start ngrok"
    exit 1
fi

# Set environment variables for ngrok
export NGROK_URL="$NGROK_URL"
export REACT_APP_API_URL="/api"

# Start backend server
print_status "Starting backend server on port 5001..."
(cd src/backend && python equity_server.py) &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Check if backend is running
if curl -s http://localhost:5001/health > /dev/null; then
    print_success "Backend started successfully"
else
    print_error "Backend failed to start"
    exit 1
fi

# Start frontend with ngrok support
echo "🎨 Starting frontend with ngrok support..."
cd src/frontend
npm run start:ngrok &
cd ../..
FRONTEND_PID=$!

# Wait for frontend to start
print_status "Waiting for frontend to start..."
for i in {1..30}; do
    if curl -s http://localhost:3000 > /dev/null; then
        print_success "Frontend started successfully"
        break
    fi
    sleep 2
done

# Show status
echo ""
print_success "PLOSolver is running with ngrok!"
echo ""
echo "🌐 ngrok URL: $NGROK_URL"
echo "🎨 Frontend: $NGROK_URL"
echo "🔧 Backend API: $NGROK_URL/api"
echo "📊 ngrok Dashboard: http://localhost:4040"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for user to stop
wait 