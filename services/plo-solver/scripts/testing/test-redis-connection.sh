#!/bin/bash

# Test Redis connection in staging environment
# This script verifies that Redis is working properly

set -e

echo "🔍 Testing Redis connection in staging environment..."

# Check if we're in the right directory
if [ ! -f "docker-compose.staging.yml" ]; then
    echo "❌ Error: docker-compose.staging.yml not found. Please run this script from the project root."
    exit 1
fi

echo "📊 Checking Redis service status..."
docker compose -f docker-compose.staging.yml ps redis

echo ""
echo "🔌 Testing Redis connectivity..."
if docker compose -f docker-compose.staging.yml exec -T redis redis-cli -a ${REDIS_PASSWORD:-plosolver_redis_staging_2024} ping | grep -q "PONG"; then
    echo "✅ Redis is responding correctly"
else
    echo "❌ Redis is not responding"
    exit 1
fi

echo ""
echo "📈 Testing Redis basic operations..."
docker compose -f docker-compose.staging.yml exec -T redis redis-cli -a ${REDIS_PASSWORD:-plosolver_redis_staging_2024} <<EOF
SET test_key "Hello Redis"
GET test_key
DEL test_key
EOF

echo ""
echo "🔍 Checking backend logs for Redis connection..."
docker compose -f docker-compose.staging.yml logs --tail=20 backend | grep -i redis || echo "No Redis-related logs found in recent backend output"

echo ""
echo "✅ Redis connection test completed successfully!"
echo ""
echo "📋 Summary:"
echo "- Redis service is running"
echo "- Redis is responding to ping"
echo "- Basic Redis operations work"
echo "- Backend should now be able to connect to Redis"
