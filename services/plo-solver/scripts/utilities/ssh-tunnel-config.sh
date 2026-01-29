#!/bin/bash

# SSH Tunnel Configuration
# This file contains configuration for SSH tunnels to monitoring services

# Server Configuration
# Change these values to match your server
export PLOSOLVER_SERVER=${PLOSOLVER_SERVER:-"your-server-ip"}
export PLOSOLVER_USER=${PLOSOLVER_USER:-"your-username"}
export PLOSOLVER_SSH_KEY=${PLOSOLVER_SSH_KEY:-""}

# Local IP (usually 127.0.0.1)
export LOCAL_IP=${LOCAL_IP:-"127.0.0.1"}

# Service Ports (on the server)
export ELASTICSEARCH_PORT=9200
export KIBANA_PORT=5601
export LOGSTASH_PORT=9600
export FILEBEAT_PORT=5066
export PORTAINER_PORT=9000
export RABBITMQ_PORT=15672

# Local Ports (can be customized to avoid conflicts)
export LOCAL_ELASTICSEARCH_PORT=${LOCAL_ELASTICSEARCH_PORT:-9200}
export LOCAL_KIBANA_PORT=${LOCAL_KIBANA_PORT:-5601}
export LOCAL_LOGSTASH_PORT=${LOCAL_LOGSTASH_PORT:-9600}
export LOCAL_FILEBEAT_PORT=${LOCAL_FILEBEAT_PORT:-5066}
export LOCAL_PORTAINER_PORT=${LOCAL_PORTAINER_PORT:-9000}
export LOCAL_RABBITMQ_PORT=${LOCAL_RABBITMQ_PORT:-15672}

# SSH Options
export SSH_OPTS=${SSH_OPTS:-"-o ConnectTimeout=10 -o ServerAliveInterval=60 -o ServerAliveCountMax=3"}

# SSH Key Options
if [ -n "$PLOSOLVER_SSH_KEY" ]; then
    export SSH_KEY_OPTS="-i $PLOSOLVER_SSH_KEY"
else
    export SSH_KEY_OPTS=""
fi

# Service Information
export SERVICES=(
    "elasticsearch:${ELASTICSEARCH_PORT}:${LOCAL_ELASTICSEARCH_PORT}:Search and analytics engine"
    "kibana:${KIBANA_PORT}:${LOCAL_KIBANA_PORT}:Log visualization and dashboards"
    "logstash:${LOGSTASH_PORT}:${LOCAL_LOGSTASH_PORT}:Log processing pipeline"
    "filebeat:${FILEBEAT_PORT}:${LOCAL_FILEBEAT_PORT}:Infrastructure log collection"
    "portainer:${PORTAINER_PORT}:${LOCAL_PORTAINER_PORT}:Docker container management"
    "rabbitmq:${RABBITMQ_PORT}:${LOCAL_RABBITMQ_PORT}:Message queue management"
)

# Function to get service info
get_service_info() {
    local service_name=$1
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r name server_port local_port description <<< "$service"
        if [ "$name" = "$service_name" ]; then
            echo "$server_port:$local_port:$description"
            return 0
        fi
    done
    return 1
}

# Function to list all services
list_services() {
    echo "Available services:"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r name server_port local_port description <<< "$service"
        echo "  • $name: http://localhost:$local_port ($description)"
    done
}

# Function to validate configuration
validate_config() {
    local errors=0
    
    if [ "$PLOSOLVER_SERVER" = "your-server-ip" ]; then
        echo "❌ PLOSOLVER_SERVER not configured"
        ((errors++))
    fi
    
    if [ "$PLOSOLVER_USER" = "your-username" ]; then
        echo "❌ PLOSOLVER_USER not configured"
        ((errors++))
    fi
    
    # Validate SSH key if provided
    if [ -n "$PLOSOLVER_SSH_KEY" ] && [ ! -f "$PLOSOLVER_SSH_KEY" ]; then
        echo "❌ SSH key not found: $PLOSOLVER_SSH_KEY"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "✅ Configuration is valid"
        return 0
    else
        echo "❌ Configuration has $errors error(s)"
        return 1
    fi
}

# Function to show current configuration
show_config() {
    echo "Current SSH Tunnel Configuration:"
    echo "================================="
    echo "Server: $PLOSOLVER_USER@$PLOSOLVER_SERVER"
    echo "Local IP: $LOCAL_IP"
    if [ -n "$PLOSOLVER_SSH_KEY" ]; then
        echo "SSH Key: $PLOSOLVER_SSH_KEY"
    else
        echo "SSH Key: Not specified (will use default authentication)"
    fi
    echo ""
    echo "Service Mappings:"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r name server_port local_port description <<< "$service"
        echo "  • $name: $LOCAL_IP:$local_port → $PLOSOLVER_SERVER:$server_port"
    done
    echo ""
    echo "SSH Options: $SSH_OPTS"
    if [ -n "$SSH_KEY_OPTS" ]; then
        echo "SSH Key Options: $SSH_KEY_OPTS"
    fi
}

# Export functions for use in other scripts
export -f get_service_info
export -f list_services
export -f validate_config
export -f show_config

# If this script is run directly, show configuration
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_config
    echo ""
    validate_config
fi 