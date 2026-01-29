#!/bin/bash

# Kibana Debug Script
# This script helps diagnose Kibana 400 Bad Request errors

set -e

echo "🔍 Kibana Debug Script"
echo "======================"

# Check if Kibana container is running
echo "1. Checking Kibana container status..."
if docker ps | grep -q "plosolver-kibana"; then
    echo "✅ Kibana container is running"
    CONTAINER_NAME=$(docker ps | grep "plosolver-kibana" | awk '{print $NF}')
    echo "   Container: $CONTAINER_NAME"
else
    echo "❌ Kibana container is not running"
    exit 1
fi

# Check Kibana health
echo ""
echo "2. Checking Kibana health..."
KIBANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/api/status)
if [ "$KIBANA_STATUS" = "200" ]; then
    echo "✅ Kibana is responding (HTTP $KIBANA_STATUS)"
else
    echo "❌ Kibana is not responding properly (HTTP $KIBANA_STATUS)"
fi

# Check Elasticsearch connection
echo ""
echo "3. Checking Elasticsearch connection..."
ES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9200/_cluster/health)
if [ "$ES_STATUS" = "200" ]; then
    echo "✅ Elasticsearch is accessible"
    ES_HEALTH=$(curl -s http://localhost:9200/_cluster/health | jq -r '.status')
    echo "   Cluster status: $ES_HEALTH"
else
    echo "❌ Elasticsearch is not accessible (HTTP $ES_STATUS)"
fi

# Check recent Kibana logs for errors
echo ""
echo "4. Checking recent Kibana logs for errors..."
echo "   Recent error logs:"
docker logs "$CONTAINER_NAME" 2>&1 | grep -i "error\|400\|bad request" | tail -5

# Check Kibana configuration
echo ""
echo "5. Checking Kibana configuration..."
echo "   Environment variables:"
docker exec "$CONTAINER_NAME" env | grep -E "ELASTICSEARCH|KIBANA" || echo "   No specific Kibana env vars found"

# Check for common 400 error causes
echo ""
echo "6. Checking for common 400 error causes..."

# Check if Kibana can connect to Elasticsearch
echo "   Testing Kibana -> Elasticsearch connection..."
if docker exec "$CONTAINER_NAME" curl -s http://elasticsearch:9200/_cluster/health > /dev/null 2>&1; then
    echo "   ✅ Kibana can reach Elasticsearch"
else
    echo "   ❌ Kibana cannot reach Elasticsearch"
fi

# Check Kibana data directory permissions
echo "   Checking Kibana data directory..."
if docker exec "$CONTAINER_NAME" test -w /usr/share/kibana/data; then
    echo "   ✅ Kibana data directory is writable"
else
    echo "   ❌ Kibana data directory is not writable"
fi

# Check for memory issues
echo ""
echo "7. Checking resource usage..."
MEMORY_USAGE=$(docker stats "$CONTAINER_NAME" --no-stream --format "table {{.MemUsage}}" | tail -1)
echo "   Memory usage: $MEMORY_USAGE"

# Check for specific API endpoints that commonly cause 400 errors
echo ""
echo "8. Testing common API endpoints..."
ENDPOINTS=(
    "/api/status"
    "/api/saved_objects/_find?type=dashboard"
    "/api/index_patterns"
    "/api/management/kibana/index_patterns"
)

for endpoint in "${ENDPOINTS[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5601$endpoint")
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "404" ]; then
        echo "   ✅ $endpoint (HTTP $STATUS)"
    else
        echo "   ❌ $endpoint (HTTP $STATUS) - Potential issue"
    fi
done

# Check for saved objects issues
echo ""
echo "9. Checking saved objects..."
SAVED_OBJECTS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5601/api/saved_objects/_find?type=dashboard&per_page=1")
if [ "$SAVED_OBJECTS_STATUS" = "200" ]; then
    echo "   ✅ Saved objects API is working"
else
    echo "   ❌ Saved objects API returned HTTP $SAVED_OBJECTS_STATUS"
fi

# Check for index pattern issues
echo ""
echo "10. Checking index patterns..."
INDEX_PATTERNS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5601/api/index_patterns")
if [ "$INDEX_PATTERNS_STATUS" = "200" ]; then
    echo "   ✅ Index patterns API is working"
else
    echo "   ❌ Index patterns API returned HTTP $INDEX_PATTERNS_STATUS"
fi

echo ""
echo "🔧 Common 400 Bad Request Solutions:"
echo "====================================="
echo "1. Restart Kibana: docker restart $CONTAINER_NAME"
echo "2. Clear Kibana cache: docker exec $CONTAINER_NAME rm -rf /usr/share/kibana/data/.kibana_*"
echo "3. Check Elasticsearch indices: curl http://localhost:9200/_cat/indices"
echo "4. Recreate Kibana index: curl -X DELETE http://localhost:9200/.kibana*"
echo "5. Check for corrupted saved objects: curl http://localhost:5601/api/saved_objects/_find?type=dashboard"
echo "6. Verify network connectivity: docker exec $CONTAINER_NAME ping elasticsearch"

echo ""
echo "📊 For detailed logs, run: docker logs $CONTAINER_NAME --tail 100"
echo "🌐 Access Kibana UI at: http://localhost:5601" 