#!/bin/sh
set -e

RABBITMQ_CONTAINER=${RABBITMQ_CONTAINER:-plosolver-rabbitmq-localdev}
RABBITMQ_USER=${2:-plosolver}
RABBITMQ_PASS=${3:-dev_password_2024}
RABBITMQ_VHOST=${4:-/plosolver}

# Wait for RabbitMQ to be ready
printf "Waiting for RabbitMQ to be ready..."
until docker exec "$RABBITMQ_CONTAINER" rabbitmqctl status > /dev/null 2>&1; do
  printf "."
  sleep 2
done
printf "\nRabbitMQ is ready.\n"

# Create user if not exists
if ! docker exec "$RABBITMQ_CONTAINER" rabbitmqctl list_users | grep -q "$RABBITMQ_USER"; then
  docker exec "$RABBITMQ_CONTAINER" rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS"
fi

# Create vhost if not exists
if ! docker exec "$RABBITMQ_CONTAINER" rabbitmqctl list_vhosts | grep -q "$RABBITMQ_VHOST"; then
  docker exec "$RABBITMQ_CONTAINER" rabbitmqctl add_vhost "$RABBITMQ_VHOST"
fi

# Set permissions

docker exec "$RABBITMQ_CONTAINER" rabbitmqctl set_permissions -p "$RABBITMQ_VHOST" "$RABBITMQ_USER" ".*" ".*" ".*"

echo "RabbitMQ bootstrap complete." 