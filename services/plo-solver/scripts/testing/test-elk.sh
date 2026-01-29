#!/bin/bash

# Test ELK Stack
# This script tests the ELK stack functionality

set -e

echo "Testing ELK Stack..."

# Test Elasticsearch
echo "Testing Elasticsearch..."
if curl -f http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "✅ Elasticsearch is healthy"
    curl -s http://localhost:9200/_cluster/health | jq .
else
    echo "❌ Elasticsearch is not responding"
    exit 1
fi

# Test Kibana
echo "Testing Kibana..."
if curl -f http://localhost:5601/api/status > /dev/null 2>&1; then
    echo "✅ Kibana is healthy"
    curl -s http://localhost:5601/api/status | jq .
else
    echo "❌ Kibana is not responding"
    exit 1
fi

# Test Logstash
echo "Testing Logstash..."
if curl -f http://localhost:9600/_node/stats/pipeline > /dev/null 2>&1; then
    echo "✅ Logstash is healthy"
    curl -s http://localhost:9600/_node/stats/pipeline | jq .
else
    echo "❌ Logstash is not responding"
    exit 1
fi

# Test log ingestion
echo "Testing log ingestion..."
test_log='{"timestamp":"2025-07-12T04:30:00.000Z","level":"INFO","logger":"test","message":"Test log entry","request_id":"test123","ip":"127.0.0.1","user_id":"test_user","user_agent":"test-agent","referer":"test"}'

# Write test log
echo $test_log >> logs/application.log

echo "Waiting for log to be processed..."
sleep 10

# Check if log appears in Elasticsearch
echo "Checking if log appears in Elasticsearch..."
if curl -s "http://localhost:9200/plosolver-logs-*/_search?q=message:test" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ Log ingestion is working"
else
    echo "❌ Log ingestion failed"
    exit 1
fi

echo ""
echo "🎉 ELK Stack test completed successfully!"
echo ""
echo "Access Kibana at: http://localhost:5601"
echo "Access Elasticsearch at: http://localhost:9200"
echo ""
echo "To access via SSH tunnel:"
echo "  ssh -L 5601:localhost:5601 user@your-server"
echo "  ssh -L 9200:localhost:9200 user@your-server" 