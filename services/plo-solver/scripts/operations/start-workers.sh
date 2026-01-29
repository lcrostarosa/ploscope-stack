#!/bin/bash

# Start job workers for PLOSolver
# This script starts the background job workers that process spot and solver jobs

echo "👷 Starting PLOSolver job workers..."

# Check if we're in the right directory
if [ ! -f "src/frontend/package.json" ] || [ ! -d "src/backend" ]; then
    echo "❌ Error: This script must be run from the PLOSolver root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Directory containing src/frontend/package.json and src/backend/"
    exit 1
fi

# Navigate to backend directory
cd src/backend

# Check if virtual environment exists and activate it
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
else
    echo "❌ Virtual environment not found. Please run 'make deps' first."
    exit 1
fi

# Start workers
echo "🚀 Starting workers with development settings..."
FLASK_ENV=development \
SPOT_WORKER_COUNT=2 \
SOLVER_WORKER_COUNT=1 \
WORKER_POLL_INTERVAL=5 \
python -m workers.job_worker 