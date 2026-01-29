#!/bin/bash

echo "🔄 Restarting Docker Desktop..."

# Kill all Docker processes
echo "🛑 Stopping Docker Desktop..."
killall Docker 2>/dev/null || true
killall "Docker Desktop" 2>/dev/null || true

# Wait a moment for processes to fully stop
sleep 5

# Check if any Docker processes are still running
if pgrep -f Docker >/dev/null; then
    echo "⚠️ Some Docker processes are still running. Force killing..."
    sudo pkill -f Docker 2>/dev/null || true
    sleep 3
fi

# Start Docker Desktop again
echo "🚀 Starting Docker Desktop..."
open -a Docker

# Wait for Docker to be ready
echo "⏳ Waiting for Docker to fully initialize..."
for i in {1..120}; do
    if docker info >/dev/null 2>&1 && docker ps >/dev/null 2>&1; then
        echo ""
        echo "✅ Docker Desktop has been successfully restarted!"
        echo "🐳 Docker is now fully operational"
        exit 0
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo -n " ${i}s"
    else
        echo -n "."
    fi
    sleep 2
done

echo ""
echo "❌ Docker failed to start properly after restart"
echo "Please check Docker Desktop manually"
exit 1 