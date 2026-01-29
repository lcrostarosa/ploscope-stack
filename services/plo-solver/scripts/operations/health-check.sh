#!/bin/bash
# Health check script for PLOSolver
# This script checks if all services are running properly

echo "🏥 PLOSolver Health Check"
echo "========================="

# Check if backend is running
echo "🔧 Checking backend..."
if curl -s http://localhost:5001/health > /dev/null; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is not responding"
fi

# Check if frontend is running
echo "🎨 Checking frontend..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend is running"
else
    echo "❌ Frontend is not responding"
fi

# Check if database exists
echo "🗄️ Checking database..."
if [ -f "src/backend/instance/plosolver.db" ]; then
    echo "✅ Database file exists"
else
    echo "❌ Database file not found"
fi

# Check if RabbitMQ is running
echo "🐰 Checking RabbitMQ..."
if curl -s -u plosolver:dev_password_2024 http://localhost:15672/api/whoami > /dev/null; then
    echo "✅ RabbitMQ is running"
else
    echo "❌ RabbitMQ is not responding"
fi

echo ""
echo "🏥 Health check completed!" 