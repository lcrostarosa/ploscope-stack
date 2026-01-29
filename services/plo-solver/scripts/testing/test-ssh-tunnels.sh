#!/bin/bash

# Test SSH Tunnels for All Monitoring Services
# This script tests connectivity to all monitoring services via SSH tunnels

set -e

echo "🧪 Testing SSH tunnels for all monitoring services..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOCAL_IP="127.0.0.1"

# Service ports
ELASTICSEARCH_PORT=9200
KIBANA_PORT=5601
LOGSTASH_PORT=9600
FILEBEAT_PORT=5066
PORTAINER_PORT=9000
RABBITMQ_PORT=15672

# SSH Key (optional)
SSH_KEY=${PLOSOLVER_SSH_KEY:-""}
if [ -n "$SSH_KEY" ]; then
    SSH_KEY_OPTION="-i $SSH_KEY"
else
    SSH_KEY_OPTION=""
fi

echo -e "${BLUE}📋 SSH Tunnel Test Suite${NC}"
echo "============================="

# Function to test service connectivity
test_service() {
    local service=$1
    local port=$2
    local endpoint=$3
    local description=$4
    
    echo -e "${BLUE}Testing ${service}...${NC}"
    
    # Test basic connectivity
    if curl -s --connect-timeout 5 http://${LOCAL_IP}:${port}${endpoint} >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ${service} is accessible${NC}"
        echo "   URL: http://localhost:${port}${endpoint}"
        echo "   Description: ${description}"
        return 0
    else
        echo -e "${RED}❌ ${service} is not accessible${NC}"
        echo "   URL: http://localhost:${port}${endpoint}"
        echo "   Description: ${description}"
        return 1
    fi
}

# Test Elasticsearch
echo ""
test_service "Elasticsearch" $ELASTICSEARCH_PORT "/_cluster/health" "Search and analytics engine"

# Test Kibana
echo ""
test_service "Kibana" $KIBANA_PORT "/api/status" "Log visualization and dashboards"

# Test Logstash
echo ""
test_service "Logstash" $LOGSTASH_PORT "/_node/stats/pipeline" "Log processing pipeline"

# Test Filebeat
echo ""
test_service "Filebeat" $FILEBEAT_PORT "/stats" "Infrastructure log collection"

# Test Portainer
echo ""
test_service "Portainer" $PORTAINER_PORT "/api/status" "Docker container management"

# Test RabbitMQ
echo ""
test_service "RabbitMQ" $RABBITMQ_PORT "/api/overview" "Message queue management"

echo ""
echo -e "${BLUE}📊 Test Summary${NC}"
echo "================"

# Count successful tests
success_count=0
total_count=6

# Test each service and count successes
if curl -s --connect-timeout 5 http://${LOCAL_IP}:${ELASTICSEARCH_PORT}/_cluster/health >/dev/null 2>&1; then
    ((success_count++))
fi

if curl -s --connect-timeout 5 http://${LOCAL_IP}:${KIBANA_PORT}/api/status >/dev/null 2>&1; then
    ((success_count++))
fi

if curl -s --connect-timeout 5 http://${LOCAL_IP}:${LOGSTASH_PORT}/_node/stats/pipeline >/dev/null 2>&1; then
    ((success_count++))
fi

if curl -s --connect-timeout 5 http://${LOCAL_IP}:${FILEBEAT_PORT}/stats >/dev/null 2>&1; then
    ((success_count++))
fi

if curl -s --connect-timeout 5 http://${LOCAL_IP}:${PORTAINER_PORT}/api/status >/dev/null 2>&1; then
    ((success_count++))
fi

if curl -s --connect-timeout 5 http://${LOCAL_IP}:${RABBITMQ_PORT}/api/overview >/dev/null 2>&1; then
    ((success_count++))
fi

echo "• Elasticsearch: $(if curl -s --connect-timeout 5 http://${LOCAL_IP}:${ELASTICSEARCH_PORT}/_cluster/health >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi)"
echo "• Kibana: $(if curl -s --connect-timeout 5 http://${LOCAL_IP}:${KIBANA_PORT}/api/status >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi)"
echo "• Logstash: $(if curl -s --connect-timeout 5 http://${LOCAL_IP}:${LOGSTASH_PORT}/_node/stats/pipeline >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi)"
echo "• Filebeat: $(if curl -s --connect-timeout 5 http://${LOCAL_IP}:${FILEBEAT_PORT}/stats >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi)"
echo "• Portainer: $(if curl -s --connect-timeout 5 http://${LOCAL_IP}:${PORTAINER_PORT}/api/status >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi)"
echo "• RabbitMQ: $(if curl -s --connect-timeout 5 http://${LOCAL_IP}:${RABBITMQ_PORT}/api/overview >/dev/null 2>&1; then echo "✅"; else echo "❌"; fi)"

echo ""
echo -e "${BLUE}📈 Results${NC}"
echo "=========="
echo "• Successful connections: ${success_count}/${total_count}"
echo "• Success rate: $((success_count * 100 / total_count))%"

if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 All services are accessible!${NC}"
elif [ $success_count -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Some services are accessible${NC}"
else
    echo -e "${RED}❌ No services are accessible${NC}"
fi

echo ""
echo -e "${BLUE}🌐 Access URLs${NC}"
echo "================"
echo "• Elasticsearch: http://localhost:${ELASTICSEARCH_PORT}"
echo "• Kibana: http://localhost:${KIBANA_PORT}"
echo "• Logstash: http://localhost:${LOGSTASH_PORT}"
echo "• Filebeat: http://localhost:${FILEBEAT_PORT}"
echo "• Portainer: http://localhost:${PORTAINER_PORT}"
echo "• RabbitMQ: http://localhost:${RABBITMQ_PORT}"
echo ""

echo -e "${YELLOW}💡 Troubleshooting${NC}"
echo "=================="
if [ $success_count -lt $total_count ]; then
    echo "• Ensure SSH tunnels are active: ./scripts/ssh-tunnel-all.sh <server> <user> [ssh-key]"
    echo "• Check if services are running on the server"
    echo "• Verify firewall settings on the server"
    echo "• Check SSH connection to the server"
    echo "• Ensure ports are not blocked locally"
    echo "• Verify SSH key permissions if using key-based auth"
else
    echo "• All services are working correctly!"
    echo "• You can now access all monitoring tools"
    echo "• Keep the SSH tunnel terminal open"
fi

echo ""
echo -e "${BLUE}🔐 Security Notes${NC}"
echo "====================="
echo "• All access is via encrypted SSH tunnels"
echo "• No direct internet exposure"
echo "• Use strong SSH authentication"
echo "• Monitor access logs regularly"
echo ""

echo -e "${GREEN}✅ SSH tunnel test complete!${NC}" 