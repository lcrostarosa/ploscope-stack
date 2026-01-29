#!/bin/bash

# Set Python path to include celery-worker modules
export PYTHONPATH="/app/celery-worker:/app:$PYTHONPATH"

# Function to wait for RabbitMQ to be ready
wait_for_rabbitmq() {
    echo "Waiting for RabbitMQ to be ready..."
    local max_attempts=30
    local attempt=1

    # Get RabbitMQ credentials from environment
    local username=${RABBITMQ_DEFAULT_USER:-${RABBITMQ_USERNAME:-plosolver}}
    local password=${RABBITMQ_DEFAULT_PASS:-${RABBITMQ_PASSWORD:-dev_password_2024}}

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f -u "$username:$password" http://rabbitmq:15672/api/overview > /dev/null 2>&1; then
            echo "✅ RabbitMQ is ready!"
            return 0
        fi

        echo "⏳ RabbitMQ not ready yet (attempt $attempt/$max_attempts)..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "❌ RabbitMQ failed to become ready after $max_attempts attempts"
    return 1
}

# Wait for RabbitMQ before starting Celery
if ! wait_for_rabbitmq; then
    echo "Failed to connect to RabbitMQ, exiting..."
    exit 1
fi

# Get concurrency from environment or default to CPU count
CELERY_CONCURRENCY=${CELERY_WORKER_CONCURRENCY:-$(nproc)}
echo "Using Celery concurrency: $CELERY_CONCURRENCY"

# Start Celery worker in background
echo "Starting Celery worker..."
echo "Environment: ${ENVIRONMENT:-development}"
echo "Broker URL: ${CELERY_BROKER_URL:-amqp://rabbitmq:5672/}"

celery -A celery-worker.celery_app.celery worker --loglevel=info --concurrency=$CELERY_CONCURRENCY --queues=spot_simulation,solver_analysis &
CELERY_PID=$!

# Wait for either process to exit
wait $CELERY_PID
