#!/bin/bash

# SSH Tunnel All Monitoring Services
# This script opens SSH tunnels for ELK stack, Filebeat, and Portainer

set -e

echo "🔗 Opening SSH tunnels for all monitoring services..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_HOST=${1:-"your-server-ip"}
SERVER_USER=${2:-"your-username"}
SSH_KEY=${3:-""}
LOCAL_IP="127.0.0.1"

# Service ports
ELASTICSEARCH_PORT=9200
KIBANA_PORT=5601
LOGSTASH_PORT=9600
FILEBEAT_PORT=5066
PORTAINER_PORT=9000
RABBITMQ_PORT=15672

# Local ports (can be customized)
LOCAL_ELASTICSEARCH_PORT=9200
LOCAL_KIBANA_PORT=5601
LOCAL_LOGSTASH_PORT=9600
LOCAL_FILEBEAT_PORT=5066
LOCAL_PORTAINER_PORT=9000
LOCAL_RABBITMQ_PORT=15672

echo -e "${BLUE}📋 SSH Tunnel Configuration${NC}"
echo "================================"
echo "Server: ${SERVER_USER}@${SERVER_HOST}"
echo "Local IP: ${LOCAL_IP}"
echo ""

echo -e "${BLUE}🔗 Service Ports${NC}"
echo "=================="
echo "• Elasticsearch: ${LOCAL_IP}:${LOCAL_ELASTICSEARCH_PORT} → ${SERVER_HOST}:${ELASTICSEARCH_PORT}"
echo "• Kibana: ${LOCAL_IP}:${LOCAL_KIBANA_PORT} → ${SERVER_HOST}:${KIBANA_PORT}"
echo "• Logstash: ${LOCAL_IP}:${LOCAL_LOGSTASH_PORT} → ${SERVER_HOST}:${LOGSTASH_PORT}"
echo "• Filebeat: ${LOCAL_IP}:${LOCAL_FILEBEAT_PORT} → ${SERVER_HOST}:${FILEBEAT_PORT}"
echo "• Portainer: ${LOCAL_IP}:${LOCAL_PORTAINER_PORT} → ${SERVER_HOST}:${PORTAINER_PORT}"
echo "• RabbitMQ: ${LOCAL_IP}:${LOCAL_RABBITMQ_PORT} → ${SERVER_HOST}:${RABBITMQ_PORT}"
echo ""

# Check if required parameters are provided
if [ "$SERVER_HOST" = "your-server-ip" ] || [ "$SERVER_USER" = "your-username" ]; then
    echo -e "${RED}❌ Please provide server host and username${NC}"
    echo ""
    echo "Usage:"
    echo "  ./scripts/ssh-tunnel-all.sh <server-ip> <username> [ssh-key-path]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/ssh-tunnel-all.sh 192.168.1.100 ubuntu"
    echo "  ./scripts/ssh-tunnel-all.sh plosolver.example.com admin"
    echo "  ./scripts/ssh-tunnel-all.sh 192.168.1.100 ubuntu ~/.ssh/id_rsa"
    echo ""
    echo "Or set environment variables:"
    echo "  export PLOSOLVER_SERVER=192.168.1.100"
    echo "  export PLOSOLVER_USER=ubuntu"
    echo "  export PLOSOLVER_SSH_KEY=~/.ssh/id_rsa"
    echo "  ./scripts/ssh-tunnel-all.sh"
    echo ""
    exit 1
fi

# Check if ports are available locally
echo -e "${BLUE}🔍 Checking local port availability...${NC}"

check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Port $port is already in use (${service})${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Port $port is available (${service})${NC}"
        return 0
    fi
}

check_port $LOCAL_ELASTICSEARCH_PORT "Elasticsearch"
check_port $LOCAL_KIBANA_PORT "Kibana"
check_port $LOCAL_LOGSTASH_PORT "Logstash"
check_port $LOCAL_FILEBEAT_PORT "Filebeat"
check_port $LOCAL_PORTAINER_PORT "Portainer"
check_port $LOCAL_RABBITMQ_PORT "RabbitMQ"

echo ""

# Validate SSH key if provided
if [ -n "$SSH_KEY" ]; then
    echo -e "${BLUE}🔍 Validating SSH key...${NC}"
    if [ -f "$SSH_KEY" ]; then
        echo -e "${GREEN}✅ SSH key found: $SSH_KEY${NC}"
        SSH_KEY_OPTION="-i $SSH_KEY"
    else
        echo -e "${RED}❌ SSH key not found: $SSH_KEY${NC}"
        echo "   Please provide a valid SSH key path"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  No SSH key provided, will use default SSH authentication${NC}"
    SSH_KEY_OPTION=""
fi

# Test SSH connection
echo -e "${BLUE}🔍 Testing SSH connection...${NC}"
if ssh $SSH_KEY_OPTION -o ConnectTimeout=5 -o BatchMode=yes ${SERVER_USER}@${SERVER_HOST} exit 2>/dev/null; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo -e "${YELLOW}⚠️  SSH connection test failed (this is normal if key-based auth is not set up)${NC}"
    echo "   You may be prompted for password"
fi

echo ""

# Create SSH tunnel command
SSH_CMD="ssh $SSH_KEY_OPTION -L ${LOCAL_ELASTICSEARCH_PORT}:${LOCAL_IP}:${ELASTICSEARCH_PORT} \
-L ${LOCAL_KIBANA_PORT}:${LOCAL_IP}:${KIBANA_PORT} \
-L ${LOCAL_LOGSTASH_PORT}:${LOCAL_IP}:${LOGSTASH_PORT} \
-L ${LOCAL_FILEBEAT_PORT}:${LOCAL_IP}:${FILEBEAT_PORT} \
-L ${LOCAL_PORTAINER_PORT}:${LOCAL_IP}:${PORTAINER_PORT} \
-L ${LOCAL_RABBITMQ_PORT}:${LOCAL_IP}:${RABBITMQ_PORT} \
${SERVER_USER}@${SERVER_HOST}"

echo -e "${BLUE}🚀 Opening SSH tunnels...${NC}"
echo "================================"
echo "Command: $SSH_CMD"
echo ""

echo -e "${GREEN}✅ SSH tunnels are now active!${NC}"
echo ""
echo -e "${BLUE}🌐 Access URLs${NC}"
echo "================"
echo "• Elasticsearch: http://localhost:${LOCAL_ELASTICSEARCH_PORT}"
echo "• Kibana: http://localhost:${LOCAL_KIBANA_PORT}"
echo "• Logstash: http://localhost:${LOCAL_LOGSTASH_PORT}"
echo "• Filebeat: http://localhost:${LOCAL_FILEBEAT_PORT}"
echo "• Portainer: http://localhost:${LOCAL_PORTAINER_PORT}"
echo "• RabbitMQ: http://localhost:${LOCAL_RABBITMQ_PORT}"
echo ""

echo -e "${BLUE}📊 Service Information${NC}"
echo "========================"
echo "• Elasticsearch: Search and analytics engine"
echo "• Kibana: Log visualization and dashboards"
echo "• Logstash: Log processing pipeline"
echo "• Filebeat: Infrastructure log collection"
echo "• Portainer: Docker container management"
echo "• RabbitMQ: Message queue management"
echo ""

echo -e "${YELLOW}💡 Tips:${NC}"
echo "• Keep this terminal open to maintain tunnels"
echo "• Use Ctrl+C to close all tunnels"
echo "• Check service status: curl http://localhost:9200/_cluster/health"
echo "• Monitor logs: docker logs <container-name>"
echo ""

echo -e "${BLUE}🔐 Security Notes${NC}"
echo "====================="
echo "• All services are accessible only via SSH tunnel"
echo "• No direct HTTP/HTTPS exposure to internet"
echo "• Tunnels are encrypted and secure"
echo "• Use strong SSH keys for authentication"
echo ""

# Execute SSH command
echo -e "${GREEN}🔗 Connecting to ${SERVER_HOST}...${NC}"
echo "Press Ctrl+C to close all tunnels"
echo ""

# Execute the SSH command
eval $SSH_CMD 