#!/bin/bash

# ===========================================
# Fix Celery Worker Script
# ===========================================
#
# This script fixes common Celery worker issues and restarts the worker
# Run this script when Celery workers are having environment variable issues
#
# Usage:
# ./scripts/operations/fix-celery-worker.sh [production|staging|development]

set -e

ENVIRONMENT=${1:-production}
COMPOSE_FILE="docker-compose.${ENVIRONMENT}.yml"

echo "==========================================="
echo "PLO Solver - Fix Celery Worker"
echo "Environment: $ENVIRONMENT"
echo "Compose file: $COMPOSE_FILE"
echo "==========================================="
echo ""

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: Compose file $COMPOSE_FILE not found"
    exit 1
fi

# Check if env file exists
ENV_FILE="env.${ENVIRONMENT}"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Environment file $ENV_FILE not found"
    echo ""
    echo "To create the environment file:"
    if [ "$ENVIRONMENT" = "production" ]; then
        echo "cp env.production.template env.production"
        echo "Edit env.production with your actual values"
    elif [ "$ENVIRONMENT" = "staging" ]; then
        echo "cp env.staging.template env.staging"
        echo "Edit env.staging with your actual values"
    fi
    exit 1
fi

echo "✅ Environment file $ENV_FILE found"
echo ""

# Stop the Celery worker
echo "🛑 Stopping Celery worker..."
docker-compose -f "$COMPOSE_FILE" stop celeryworker

# Remove the container to ensure clean restart
echo "🗑️ Removing Celery worker container..."
docker-compose -f "$COMPOSE_FILE" rm -f celeryworker

# Rebuild the Celery worker to ensure latest code
echo "🔨 Rebuilding Celery worker..."
docker-compose -f "$COMPOSE_FILE" build celeryworker

# Start the Celery worker
echo "🚀 Starting Celery worker..."
docker-compose -f "$COMPOSE_FILE" up -d celeryworker

# Wait a moment for the container to start
echo "⏳ Waiting for Celery worker to start..."
sleep 10

# Check if the container is running
if docker ps | grep -q "plosolver-celeryworker-${ENVIRONMENT}"; then
    echo "✅ Celery worker container is running"
else
    echo "❌ Celery worker container failed to start"
    echo ""
    echo "Check the logs:"
    echo "docker-compose -f $COMPOSE_FILE logs celeryworker"
    exit 1
fi

# Wait for health check
echo "⏳ Waiting for Celery worker to be healthy..."
for i in {1..30}; do
    if docker exec "plosolver-celeryworker-${ENVIRONMENT}" pgrep -f "celery" >/dev/null 2>&1; then
        echo "✅ Celery worker is healthy"
        break
    fi
    echo "⏳ Waiting... (attempt $i/30)"
    sleep 2
done

# Test database connection
echo ""
echo "🔍 Testing database connection..."
docker exec "plosolver-celeryworker-${ENVIRONMENT}" python -c "
import os
from sqlalchemy import create_engine, text

database_url = os.environ.get('DATABASE_URL')
if not database_url:
    print('❌ DATABASE_URL is not set!')
    exit(1)

try:
    engine = create_engine(database_url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {str(e)}')
    exit(1)
"

# Show recent logs
echo ""
echo "📋 Recent Celery worker logs:"
docker logs --tail 10 "plosolver-celeryworker-${ENVIRONMENT}"

echo ""
echo "==========================================="
echo "Celery Worker Fix Complete"
echo "==========================================="
echo ""
echo "If you still see issues, run the debug script:"
echo "./scripts/operations/debug-celery-env.sh $ENVIRONMENT"
echo ""
echo "To monitor the worker in real-time:"
echo "docker logs -f plosolver-celeryworker-${ENVIRONMENT}" 