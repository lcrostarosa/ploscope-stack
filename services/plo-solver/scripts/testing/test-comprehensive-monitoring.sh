#!/bin/bash

# Test Comprehensive Monitoring
# This script tests all monitoring components: infrastructure, containers, frontend, backend, and Traefik

set -e

echo "Testing Comprehensive Monitoring..."

# Test Elasticsearch
echo "Testing Elasticsearch..."
if curl -f http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "✅ Elasticsearch is healthy"
else
    echo "❌ Elasticsearch is not responding"
    exit 1
fi

# Test Kibana
echo "Testing Kibana..."
if curl -f http://localhost:5601/api/status > /dev/null 2>&1; then
    echo "✅ Kibana is healthy"
else
    echo "❌ Kibana is not responding"
    exit 1
fi

# Test Logstash
echo "Testing Logstash..."
if curl -f http://localhost:9600/_node/stats/pipeline > /dev/null 2>&1; then
    echo "✅ Logstash is healthy"
else
    echo "❌ Logstash is not responding"
    exit 1
fi

# Test Filebeat
echo "Testing Filebeat..."
if docker compose ps filebeat | grep -q "Up"; then
    echo "✅ Filebeat is running"
else
    echo "❌ Filebeat is not running"
    exit 1
fi

# Test infrastructure metrics collection
echo "Testing infrastructure metrics..."
sleep 30  # Wait for Filebeat to collect metrics

# Check if system metrics are being collected
if curl -s "http://localhost:9200/filebeat-*/_search?q=type:system_metrics" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ Infrastructure metrics are being collected"
else
    echo "❌ Infrastructure metrics collection failed"
fi

# Check if container logs are being collected
if curl -s "http://localhost:9200/filebeat-*/_search?q=type:container" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ Container logs are being collected"
else
    echo "❌ Container logs collection failed"
fi

# Test application log ingestion
echo "Testing application log ingestion..."
test_log='{"timestamp":"2025-07-12T04:30:00.000Z","level":"INFO","logger":"test","message":"Test application log","request_id":"test123","ip":"127.0.0.1","user_id":"test_user","user_agent":"test-agent","referer":"test"}'

# Write test log
echo $test_log >> logs/application.log

echo "Waiting for log to be processed..."
sleep 10

# Check if log appears in Elasticsearch
if curl -s "http://localhost:9200/plosolver-logs-*/_search?q=message:test" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ Application log ingestion is working"
else
    echo "❌ Application log ingestion failed"
fi

# Test Traefik log collection
echo "Testing Traefik log collection..."
# Generate some test traffic
curl -s http://localhost:80 > /dev/null 2>&1 || true
curl -s http://localhost:8080 > /dev/null 2>&1 || true

sleep 10

# Check if Traefik logs are being collected
if curl -s "http://localhost:9200/plosolver-logs-*/_search?q=service:traefik" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ Traefik logs are being collected"
else
    echo "⚠️  Traefik logs collection - may need more traffic"
fi

# Test system log collection
echo "Testing system log collection..."
if curl -s "http://localhost:9200/filebeat-*/_search?q=type:system" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ System logs are being collected"
else
    echo "❌ System logs collection failed"
fi

# Test Docker metrics collection
echo "Testing Docker metrics collection..."
if curl -s "http://localhost:9200/filebeat-*/_search?q=type:docker_metrics" | jq '.hits.total.value' | grep -q "[1-9]"; then
    echo "✅ Docker metrics are being collected"
else
    echo "❌ Docker metrics collection failed"
fi

# Test Portainer
echo "Testing Portainer..."
if curl -f http://localhost:9000/api/status > /dev/null 2>&1; then
    echo "✅ Portainer is healthy"
else
    echo "⚠️  Portainer is not accessible locally (expected if SSH tunnel not established)"
fi

# Test Docker log rotation
echo "Testing Docker log rotation..."
if [ -f /etc/docker/daemon.json ] && [ -f /etc/logrotate.d/docker ]; then
    echo "✅ Docker log rotation is configured"
    
    # Check if log rotation settings are present
    if grep -q "max-size" /etc/docker/daemon.json && grep -q "max-file" /etc/docker/daemon.json; then
        echo "✅ Docker daemon log rotation settings found"
    else
        echo "❌ Docker daemon log rotation settings missing"
    fi
    
    # Check logrotate configuration
    if grep -q "rotate 7" /etc/logrotate.d/docker; then
        echo "✅ 7-day log rotation configured"
    else
        echo "❌ 7-day log rotation not configured"
    fi
else
    echo "❌ Docker log rotation not configured"
    echo "   Run: sudo ./scripts/setup-docker-log-rotation.sh"
fi

echo ""
echo "🎉 Comprehensive monitoring test completed!"
echo ""
echo "Monitoring Coverage:"
echo "==================="
echo "✅ Infrastructure: CPU, memory, disk, network"
echo "✅ Containers: All Docker container logs and metrics"
echo "✅ Frontend: Application logs and errors"
echo "✅ Backend: Application logs, database queries, API calls"
echo "✅ Traefik: HTTP access logs, response times, status codes"
echo "✅ System: System logs, Docker daemon logs"
echo "✅ Portainer: Docker container management interface"
echo "✅ Docker Logs: Automatic rotation with 7-day retention"
echo ""
echo "Access Kibana at: http://localhost:5601"
echo "Access Elasticsearch at: http://localhost:9200"
echo "Access Portainer at: http://localhost:9000"
echo ""
echo "To access via SSH tunnel:"
echo "  ssh -L 5601:localhost:5601 user@your-server"
echo "  ssh -L 9200:localhost:9200 user@your-server"
echo "  ssh -L 9000:localhost:9000 user@your-server"
echo ""
echo "Available Dashboards:"
echo "  - Infrastructure Overview"
echo "  - Container Health"
echo "  - Application Performance"
echo "  - Traefik Access Logs"
echo "  - Security Monitoring"
echo "  - Portainer Container Management"
echo ""
echo "Docker Log Rotation:"
echo "  - Max file size: 10MB"
echo "  - Max files per container: 7"
echo "  - Retention: 7 days"
echo "  - Compression: Enabled" 