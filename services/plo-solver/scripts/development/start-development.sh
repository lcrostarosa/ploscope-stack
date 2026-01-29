#!/bin/bash
# Development environment setup script
# Sets up the development environment and starts the application

echo "🚀 Setting up PLOSolver development environment..."

# Check if we're in the right directory
if [ ! -f "src/frontend/package.json" ] || [ ! -d "src/backend" ]; then
    echo "❌ Error: This script must be run from the PLOSolver root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Directory containing src/frontend/package.json and src/backend/"
    exit 1
fi

# Check if virtual environment exists
if [ ! -f "src/backend/venv/bin/activate" ] && [ ! -f "src/backend/venv/Scripts/activate" ]; then
    echo "❌ Virtual environment not found. Creating one..."
    cd src/backend
    python3 -m venv venv
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    elif [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
    else
        echo "❌ Failed to create virtual environment"
        exit 1
    fi
    pip install -r requirements.txt
    pip install -r requirements-test.txt
    cd ../..
else
    echo "✅ Virtual environment already exists"
fi

# Install dependencies if needed
if [ ! -d "src/frontend/node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    cd src/frontend
    npm install
    cd ../..
fi

# Start the application
echo "🎉 Starting development environment..."
./scripts/run-development.sh 