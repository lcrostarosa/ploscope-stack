#!/bin/bash
# Development runner for PLOSolver
# This script starts the application in development mode

echo "🚀 Starting PLOSolver in development mode..."

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root directory
cd "$PROJECT_ROOT"

# Check if we're in the right directory
if [ ! -f "src/frontend/package.json" ] || [ ! -d "src/backend" ]; then
    echo "❌ Error: Cannot find required directories"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Directory containing src/frontend/package.json and src/backend/"
    exit 1
fi

# Create log directories if they don't exist
echo "📁 Setting up log directories..."
mkdir -p logs/plosolver
mkdir -p logs/application
mkdir -p logs/system

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5001 | xargs kill -9 2>/dev/null || true

# Start backend
echo "🔧 Starting backend server..."
(cd "$PROJECT_ROOT/src/backend" && python -m core.app) &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Start frontend with environment variables
echo "🎨 Starting frontend server..."
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "📄 Loading environment variables from .env file..."
    (cd "$PROJECT_ROOT/src/frontend" && env $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs) npx webpack serve --mode development) &
else
    (cd "$PROJECT_ROOT/src/frontend" && npx webpack serve --mode development) &
fi
FRONTEND_PID=$!

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping development servers..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    echo "✅ Development servers stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

echo ""
echo "🎉 Development servers started!"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:5001"
echo ""
echo "📊 Tailing logs (Press Ctrl+C to stop)..."
echo ""

# Tail the logs with color coding
tail -f \
    --pid=$$ \
    --retry \
    --follow=name \
    --max-unchanged-stats=1 \
    logs/application.log \
    logs/plosolver/*.log \
    logs/system/*.log \
    src/backend/logs/*.log \
    2>/dev/null | while read line; do
    # Color code different log sources
    if [[ $line == *"backend"* ]] || [[ $line == *"python"* ]]; then
        echo -e "\033[34m[BACKEND]\033[0m $line"
    elif [[ $line == *"frontend"* ]] || [[ $line == *"webpack"* ]]; then
        echo -e "\033[32m[FRONTEND]\033[0m $line"
    elif [[ $line == *"ERROR"* ]] || [[ $line == *"error"* ]]; then
        echo -e "\033[31m[ERROR]\033[0m $line"
    elif [[ $line == *"WARN"* ]] || [[ $line == *"warning"* ]]; then
        echo -e "\033[33m[WARN]\033[0m $line"
    else
        echo -e "\033[36m[LOG]\033[0m $line"
    fi
done