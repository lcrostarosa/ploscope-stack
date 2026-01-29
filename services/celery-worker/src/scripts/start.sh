#!/bin/bash

# Use default Python path. Avoid adding unrelated directories that could cause Celery
# to import unintended modules (e.g., backend or other app paths).

# Function to wait for RabbitMQ to be ready
wait_for_rabbitmq() {
    if [ "${SKIP_RABBITMQ_HEALTHCHECK:-0}" = "1" ]; then
        echo "Skipping RabbitMQ healthcheck (SKIP_RABBITMQ_HEALTHCHECK=1)"
        return 0
    fi

    echo "Waiting for RabbitMQ to be ready..."
    local max_attempts=30
    local attempt=1

    # Get RabbitMQ credentials and host/port from environment
    local username=${RABBITMQ_DEFAULT_USER:-${RABBITMQ_USERNAME:-plosolver}}
    local password=${RABBITMQ_DEFAULT_PASS:-${RABBITMQ_PASSWORD:-dev_password_2024}}
    local host=${RABBITMQ_HOST:-rabbitmq}
    local amqp_port=${RABBITMQ_PORT:-5672}
    local mgmt_port=${RABBITMQ_MANAGEMENT_PORT:-15672}

    while [ $attempt -le $max_attempts ]; do
        # Prefer AMQP port readiness
        if (echo > /dev/tcp/$host/$amqp_port) >/dev/null 2>&1; then
            echo "✅ RabbitMQ AMQP port $amqp_port is open!"
            return 0
        fi

        # Fallback to management API health if available
        if curl -s -f -u "$username:$password" http://$host:$mgmt_port/api/overview > /dev/null 2>&1; then
            echo "✅ RabbitMQ management API is ready!"
            return 0
        fi

        echo "⏳ RabbitMQ not ready yet at $host (amqp:$amqp_port mgmt:$mgmt_port) (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "⚠️  RabbitMQ readiness check timed out after $max_attempts attempts. Proceeding; Celery will retry."
    return 0
}

# Wait for RabbitMQ before starting Celery
if ! wait_for_rabbitmq; then
    echo "Failed to connect to RabbitMQ, exiting..."
    exit 1
fi

# Ensure we run from the application module directory so imports work
if [ -d "/app/celery-worker" ]; then
    cd /app/celery-worker || exit 1
elif [ -d "$(dirname "$0")/../celery-worker" ]; then
    cd "$(dirname "$0")/../celery-worker" || exit 1
elif [ -d "src/celery-worker" ]; then
    cd src/celery-worker || exit 1
fi
echo "Working directory: $(pwd)"

# Get concurrency from environment or default to CPU count (portable)
CELERY_CONCURRENCY=${CELERY_WORKER_CONCURRENCY:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)}
echo "Using Celery concurrency: $CELERY_CONCURRENCY"

# Start Celery worker in background
echo "Starting Celery worker..."
echo "Environment: ${ENVIRONMENT:-development}"
echo "Broker URL: ${CELERY_BROKER_URL:-amqp://rabbitmq:5672//}"

PYTHONPATH=src python -m celery_worker.main
CELERY_PID=$!

# Wait for either process to exit
wait $CELERY_PID
