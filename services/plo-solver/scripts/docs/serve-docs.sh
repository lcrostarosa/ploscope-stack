#!/bin/bash
# Documentation server for PLOSolver

set -e

echo "📚 Starting documentation server..."

# Function to find an available port
find_available_port() {
    local port=8000
    while lsof -i :$port >/dev/null 2>&1; do
        echo "⚠️  Port $port is in use, trying next port..."
        port=$((port + 1))
        if [ $port -gt 8010 ]; then
            echo "❌ No available ports found between 8000-8010"
            exit 1
        fi
    done
    echo $port
}

PORT=$(find_available_port)
echo "🚀 Using port $PORT"

# Check if python3-http-server is available
if command -v python3 &> /dev/null; then
    echo "🐍 Using Python 3 HTTP server"
    cd ../docs
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    echo "🐍 Using Python HTTP server"
    cd ../docs
    python -m http.server $PORT
elif command -v npx &> /dev/null; then
    echo "📦 Using npx serve"
    npx serve ../docs -p $PORT
else
    echo "❌ No suitable HTTP server found. Please install Python 3 or Node.js"
    exit 1
fi

echo "✅ Documentation available at: http://localhost:$PORT"
echo "🔗 Swagger UI available at: http://localhost:$PORT/swagger-ui/" 