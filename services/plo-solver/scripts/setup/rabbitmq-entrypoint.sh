#!/bin/bash
set -e

# Custom entrypoint for RabbitMQ that ensures idempotent initialization
echo "🚀 Starting RabbitMQ with automatic user setup..."

# Start RabbitMQ server in the background
echo "🐰 Starting RabbitMQ server..."
rabbitmq-server &
RABBITMQ_PID=$!

# Wait for RabbitMQ to be ready
echo "⏳ Waiting for RabbitMQ to be ready..."
until rabbitmqctl status > /dev/null 2>&1; do
  echo "Waiting for RabbitMQ to start..."
  sleep 2
done
echo "✅ RabbitMQ is ready."

# Get environment variables with defaults
# Try DEFAULT variables first, then fall back to regular variables, then hardcoded defaults
RABBITMQ_USER=${RABBITMQ_DEFAULT_USER:-${RABBITMQ_USERNAME:-plosolver}}
RABBITMQ_PASS=${RABBITMQ_DEFAULT_PASS:-${RABBITMQ_PASSWORD:-dev_password_2024}}
RABBITMQ_VHOST=${RABBITMQ_DEFAULT_VHOST:-${RABBITMQ_VHOST:-/plosolver}}

echo "🔍 Environment variables:"
echo "   RABBITMQ_DEFAULT_USER: ${RABBITMQ_DEFAULT_USER:-not set}"
echo "   RABBITMQ_DEFAULT_PASS: ${RABBITMQ_DEFAULT_PASS:-not set}"
echo "   RABBITMQ_DEFAULT_VHOST: ${RABBITMQ_DEFAULT_VHOST:-not set}"
echo "   RABBITMQ_USERNAME: ${RABBITMQ_USERNAME:-not set}"
echo "   RABBITMQ_PASSWORD: ${RABBITMQ_PASSWORD:-not set}"
echo "   RABBITMQ_VHOST: ${RABBITMQ_VHOST:-not set}"
echo "   Using: USER=$RABBITMQ_USER, VHOST=$RABBITMQ_VHOST"
echo "   Password length: ${#RABBITMQ_PASS} characters"

echo "🔧 Setting up RabbitMQ user and vhost..."

# Create user if not exists, or update password if exists
if ! rabbitmqctl list_users | grep -q "$RABBITMQ_USER"; then
  echo "👤 Creating user: $RABBITMQ_USER"
  rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS"
  rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
else
  echo "👤 User $RABBITMQ_USER already exists, updating password..."
  rabbitmqctl change_password "$RABBITMQ_USER" "$RABBITMQ_PASS"
  rabbitmqctl set_user_tags "$RABBITMQ_USER" administrator
fi

# Create vhost if not exists
if ! rabbitmqctl list_vhosts | grep -q "$RABBITMQ_VHOST"; then
  echo "🏠 Creating vhost: $RABBITMQ_VHOST"
  rabbitmqctl add_vhost "$RABBITMQ_VHOST"
else
  echo "🏠 Vhost $RABBITMQ_VHOST already exists"
fi

# Set permissions
echo "🔐 Setting permissions for user $RABBITMQ_USER on vhost $RABBITMQ_VHOST"
rabbitmqctl set_permissions -p "$RABBITMQ_VHOST" "$RABBITMQ_USER" ".*" ".*" ".*"

# Create required queues for Celery
echo "📋 Creating Celery queues..."
rabbitmqctl set_policy -p "$RABBITMQ_VHOST" ha-all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}'

# Note: Queues will be created automatically when Celery workers connect
echo "   ℹ️  Queues will be created automatically when Celery workers connect"

echo "✅ RabbitMQ initialization complete!"

# Wait for the RabbitMQ process
wait $RABBITMQ_PID 