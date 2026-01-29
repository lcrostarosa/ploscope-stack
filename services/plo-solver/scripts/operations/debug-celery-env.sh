#!/bin/bash

# ===========================================
# Celery Environment Debug Script
# ===========================================
#
# This script helps debug Celery worker environment variable issues
# Run this script to check and fix environment variable problems
#
# Usage:
# ./scripts/operations/debug-celery-env.sh [production|staging|development]

set -e

ENVIRONMENT=${1:-production}
CONTAINER_NAME="plosolver-celeryworker-${ENVIRONMENT}"

echo "==========================================="
echo "PLO Solver - Celery Environment Debug"
echo "Environment: $ENVIRONMENT"
echo "Container: $CONTAINER_NAME"
echo "==========================================="
echo ""

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Error: Container $CONTAINER_NAME is not running"
    echo ""
    echo "To start the container:"
    echo "docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d celeryworker"
    exit 1
fi

echo "✅ Container $CONTAINER_NAME is running"
echo ""

# Check environment variables in the container
echo "🔍 Checking environment variables in Celery container..."
echo ""

echo "DATABASE_URL:"
docker exec "$CONTAINER_NAME" sh -c 'echo "DATABASE_URL: $DATABASE_URL"'

echo ""
echo "RABBITMQ variables:"
docker exec "$CONTAINER_NAME" sh -c 'echo "RABBITMQ_DEFAULT_USER: $RABBITMQ_DEFAULT_USER"'
docker exec "$CONTAINER_NAME" sh -c 'echo "RABBITMQ_DEFAULT_PASS: $RABBITMQ_DEFAULT_PASS"'
docker exec "$CONTAINER_NAME" sh -c 'echo "RABBITMQ_HOST: $RABBITMQ_HOST"'

echo ""
echo "PostgreSQL variables:"
docker exec "$CONTAINER_NAME" sh -c 'echo "POSTGRES_USER: $POSTGRES_USER"'
docker exec "$CONTAINER_NAME" sh -c 'echo "POSTGRES_PASSWORD: $POSTGRES_PASSWORD"'
docker exec "$CONTAINER_NAME" sh -c 'echo "POSTGRES_DB: $POSTGRES_DB"'

echo ""
echo "Celery variables:"
docker exec "$CONTAINER_NAME" sh -c 'echo "CELERY_BROKER_URL: $CELERY_BROKER_URL"'
docker exec "$CONTAINER_NAME" sh -c 'echo "CELERY_RESULT_BACKEND: $CELERY_RESULT_BACKEND"'

echo ""
echo "==========================================="
echo "Testing Database Connection"
echo "==========================================="

# Test database connection
echo "Testing database connection from Celery container..."
docker exec "$CONTAINER_NAME" python -c "
import os
from sqlalchemy import create_engine, text

database_url = os.environ.get('DATABASE_URL')
print(f'Database URL: {database_url}')

if not database_url:
    print('❌ DATABASE_URL is not set!')
    exit(1)

try:
    engine = create_engine(database_url)
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print('✅ Database connection successful')
        print(f'Test query result: {result.fetchone()[0]}')
except Exception as e:
    print(f'❌ Database connection failed: {str(e)}')
    exit(1)
"

echo ""
echo "==========================================="
echo "Testing RabbitMQ Connection"
echo "==========================================="

# Test RabbitMQ connection
echo "Testing RabbitMQ connection from Celery container..."
docker exec "$CONTAINER_NAME" python -c "
import os
import pika

try:
    username = os.environ.get('RABBITMQ_DEFAULT_USER', 'plosolver')
    password = os.environ.get('RABBITMQ_DEFAULT_PASS', 'dev_password_2024')
    host = os.environ.get('RABBITMQ_HOST', 'rabbitmq')
    vhost = os.environ.get('RABBITMQ_DEFAULT_VHOST', '/plosolver')
    
    print(f'Connecting to RabbitMQ: {username}@{host}/{vhost}')
    
    credentials = pika.PlainCredentials(username, password)
    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=host,
        credentials=credentials,
        virtual_host=vhost
    ))
    print('✅ RabbitMQ connection successful')
    connection.close()
except Exception as e:
    print(f'❌ RabbitMQ connection failed: {str(e)}')
"

echo ""
echo "==========================================="
echo "Checking Celery Worker Status"
echo "==========================================="

# Check Celery worker status
echo "Checking Celery worker processes..."
docker exec "$CONTAINER_NAME" sh -c 'ps aux | grep celery'

echo ""
echo "Checking Celery health endpoint..."
if docker exec "$CONTAINER_NAME" curl -f http://localhost:5002/health 2>/dev/null; then
    echo "✅ Celery health endpoint is responding"
else
    echo "❌ Celery health endpoint is not responding"
fi

echo ""
echo "==========================================="
echo "Recent Celery Logs"
echo "==========================================="

# Show recent logs
echo "Recent Celery worker logs (last 20 lines):"
docker logs --tail 20 "$CONTAINER_NAME"

echo ""
echo "==========================================="
echo "Troubleshooting Steps"
echo "==========================================="

echo "If you see issues above, try these steps:"
echo ""
echo "1. Restart the Celery worker:"
echo "   docker restart $CONTAINER_NAME"
echo ""
echo "2. Check the environment file:"
echo "   ./scripts/setup/validate-env.sh $ENVIRONMENT"
echo ""
echo "3. Rebuild the Celery container:"
echo "   docker-compose -f docker-compose.${ENVIRONMENT}.yml build celeryworker"
echo "   docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d celeryworker"
echo ""
echo "4. Check if the env file is properly loaded:"
echo "   docker exec $CONTAINER_NAME cat /proc/1/environ | tr '\0' '\n' | grep DATABASE_URL"
echo ""
echo "5. Manually set environment variables if needed:"
echo "   docker exec $CONTAINER_NAME sh -c 'export DATABASE_URL=\"your-database-url\"'" 