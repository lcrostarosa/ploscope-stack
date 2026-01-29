#!/bin/sh
set -e

# Strip newlines and whitespace from all input parameters
# This handles cases where GitHub Actions secrets/vars have trailing newlines
strip_whitespace() {
    echo "$1" | tr -d '\r\n' | xargs
}

RABBITMQ_CONTAINER=$(strip_whitespace "${1:-plosolver-rabbitmq-localdev}")
RABBITMQ_USER=$(strip_whitespace "${2:-plosolver}")
RABBITMQ_PASS=$(strip_whitespace "${3:-dev_password_2024}")
RABBITMQ_VHOST=$(strip_whitespace "${4:-/plosolver}")

echo "🔧 Bootstrap script starting..."
echo "   Container: $RABBITMQ_CONTAINER"
echo "   User: $RABBITMQ_USER"
echo "   VHost: $RABBITMQ_VHOST"
echo "   Usage: $0 <container> <user> <pass> <vhost> [main_exchange] [dlq_exchange]"

# Wait for RabbitMQ to be ready
printf "Waiting for RabbitMQ to be ready..."
TIMEOUT=120  # 2 minutes timeout
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if docker exec "$RABBITMQ_CONTAINER" rabbitmqctl status > /dev/null 2>&1; then
    printf "\n✅ RabbitMQ is ready.\n"
    break
  fi
  printf "."
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "❌ Timeout waiting for RabbitMQ to be ready"
  echo "📋 Container status:"
  docker ps | grep "$RABBITMQ_CONTAINER" || echo "Container not found"
  echo "📋 Container logs:"
  docker logs "$RABBITMQ_CONTAINER" | tail -20 || echo "Could not retrieve logs"
  exit 1
fi

# Create user if not exists
echo "👤 Checking/creating user: $RABBITMQ_USER"
if ! docker exec "$RABBITMQ_CONTAINER" rabbitmqctl list_users | grep -q "$RABBITMQ_USER"; then
  echo "   Creating user..."
  docker exec "$RABBITMQ_CONTAINER" rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS"
  echo "   ✅ User created"
else
  echo "   ✅ User already exists"
fi

# Create vhost if not exists
echo "📁 Checking/creating vhost: $RABBITMQ_VHOST"
if ! docker exec "$RABBITMQ_CONTAINER" rabbitmqctl list_vhosts | grep -q "$RABBITMQ_VHOST"; then
  echo "   Creating vhost..."
  docker exec "$RABBITMQ_CONTAINER" rabbitmqctl add_vhost "$RABBITMQ_VHOST"
  echo "   ✅ VHost created"
else
  echo "   ✅ VHost already exists"
fi

# Set permissions
echo "🔐 Setting permissions..."
docker exec "$RABBITMQ_CONTAINER" rabbitmqctl set_permissions -p "$RABBITMQ_VHOST" "$RABBITMQ_USER" ".*" ".*" ".*"
echo "   ✅ Permissions set"

# Set management tag for HTTP API access
echo "🏷️  Setting management tag..."
docker exec "$RABBITMQ_CONTAINER" rabbitmqctl set_user_tags "$RABBITMQ_USER" management
echo "   ✅ Management tag set"

echo "📋 Setting HA policy..."
docker exec "$RABBITMQ_CONTAINER" rabbitmqctl set_policy -p "$RABBITMQ_VHOST" ha-all ".*" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
echo "   ✅ HA policy set"

# Create exchanges using rabbitmqadmin (proper way)
echo "📋 Creating exchanges..."
MAIN_EXCHANGE=$(strip_whitespace "${5:-plosolver.main}")
DLQ_EXCHANGE=$(strip_whitespace "${6:-plosolver.dlq}")

# Create main exchange (direct type, durable)
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare exchange \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  name="$MAIN_EXCHANGE" \
  type=direct \
  durable=true \
  auto_delete=false || echo "   ⚠️  Exchange may already exist: $MAIN_EXCHANGE"
echo "   ✅ Configured main exchange: $MAIN_EXCHANGE"

# Create DLQ exchange (direct type, durable)
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare exchange \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  name="$DLQ_EXCHANGE" \
  type=direct \
  durable=true \
  auto_delete=false || echo "   ⚠️  Exchange may already exist: $DLQ_EXCHANGE"
echo "   ✅ Configured DLQ exchange: $DLQ_EXCHANGE"

# Create queues with proper dead letter configuration
echo "📋 Creating queues with dead letter configuration..."

# Queue names
SPOT_QUEUE="spot-processing"
SOLVER_QUEUE="solver-processing"
SPOT_DLQ="spot-processing-dlq"
SOLVER_DLQ="solver-processing-dlq"

# Function to delete queue if it exists (to handle configuration conflicts)
delete_queue_if_exists() {
    local queue_name="$1"
    echo "   Checking queue: $queue_name"
    if docker exec "$RABBITMQ_CONTAINER" rabbitmqctl list_queues -p "$RABBITMQ_VHOST" | grep -q "^$queue_name"; then
        echo "   Deleting existing queue: $queue_name (to fix configuration)"
        docker exec "$RABBITMQ_CONTAINER" rabbitmqctl delete_queue -p "$RABBITMQ_VHOST" "$queue_name" || echo "   ⚠️  Could not delete queue: $queue_name"
    fi
}

# Delete existing queues to avoid configuration conflicts
delete_queue_if_exists "$SPOT_QUEUE"
delete_queue_if_exists "$SOLVER_QUEUE"
delete_queue_if_exists "$SPOT_DLQ"
delete_queue_if_exists "$SOLVER_DLQ"

# Create dead letter queues first
echo "   Creating dead letter queues..."

# Spot processing DLQ
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare queue \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  name="$SPOT_DLQ" \
  durable=true \
  arguments='{"x-message-ttl":1209600000}' || echo "   ⚠️  Could not create DLQ: $SPOT_DLQ"

# Bind DLQ to DLQ exchange
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare binding \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  source="$DLQ_EXCHANGE" \
  destination="$SPOT_DLQ" \
  routing_key="$SPOT_DLQ" || echo "   ⚠️  Could not bind DLQ: $SPOT_DLQ"

echo "   ✅ Created DLQ: $SPOT_DLQ"

# Solver processing DLQ
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare queue \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  name="$SOLVER_DLQ" \
  durable=true \
  arguments='{"x-message-ttl":1209600000}' || echo "   ⚠️  Could not create DLQ: $SOLVER_DLQ"

# Bind DLQ to DLQ exchange
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare binding \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  source="$DLQ_EXCHANGE" \
  destination="$SOLVER_DLQ" \
  routing_key="$SOLVER_DLQ" || echo "   ⚠️  Could not bind DLQ: $SOLVER_DLQ"

echo "   ✅ Created DLQ: $SOLVER_DLQ"

# Create main queues with dead letter configuration
echo "   Creating main queues with dead letter configuration..."

# Spot processing queue
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare queue \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  name="$SPOT_QUEUE" \
  durable=true \
  arguments="{\"x-dead-letter-exchange\":\"$DLQ_EXCHANGE\",\"x-dead-letter-routing-key\":\"$SPOT_DLQ\",\"x-max-retries\":3}" || echo "   ⚠️  Could not create queue: $SPOT_QUEUE"

# Bind queue to main exchange
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare binding \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  source="$MAIN_EXCHANGE" \
  destination="$SPOT_QUEUE" \
  routing_key="spot.*" || echo "   ⚠️  Could not bind queue: $SPOT_QUEUE"

echo "   ✅ Created queue: $SPOT_QUEUE"

# Solver processing queue
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare queue \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  name="$SOLVER_QUEUE" \
  durable=true \
  arguments="{\"x-dead-letter-exchange\":\"$DLQ_EXCHANGE\",\"x-dead-letter-routing-key\":\"$SOLVER_DLQ\",\"x-max-retries\":3}" || echo "   ⚠️  Could not create queue: $SOLVER_QUEUE"

# Bind queue to main exchange
docker exec "$RABBITMQ_CONTAINER" rabbitmqadmin declare binding \
  --vhost="$RABBITMQ_VHOST" \
  --user="$RABBITMQ_USER" \
  --password="$RABBITMQ_PASS" \
  source="$MAIN_EXCHANGE" \
  destination="$SOLVER_QUEUE" \
  routing_key="solver.*" || echo "   ⚠️  Could not bind queue: $SOLVER_QUEUE"

echo "   ✅ Created queue: $SOLVER_QUEUE"

echo "✅ RabbitMQ bootstrap complete."
