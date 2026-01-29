#!/bin/bash

# PLO Solver Vault Application Connection Script
# This script helps applications connect to Vault in different network configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to display usage
usage() {
    echo "Usage: $0 <mode> [options]"
    echo ""
    echo "Modes:"
    echo "  connect-app <app-container> - Connect app container to Vault network"
    echo "  connect-backend             - Connect backend to Vault network"
    echo "  connect-frontend            - Connect frontend to Vault network"
    echo "  connect-all                 - Connect all app containers to Vault"
    echo "  disconnect <container>      - Disconnect container from Vault network"
    echo "  list-connections            - List containers connected to Vault"
    echo ""
    echo "Options:"
    echo "  --vault-network <name>      - Specify Vault network name"
    echo "  --app-network <name>        - Specify app network name"
    echo ""
    echo "Examples:"
    echo "  $0 connect-backend"
    echo "  $0 connect-app plo-solver-backend"
    echo "  $0 connect-all"
    echo "  $0 list-connections"
    exit 1
}

# Function to get network names
get_network_names() {
    VAULT_NETWORK=${VAULT_NETWORK:-"plo-solver-vault-network"}
    APP_NETWORK=${APP_NETWORK:-"plo-solver-network"}
}

# Function to check if container exists
container_exists() {
    local container=$1
    docker ps -a --format "table {{.Names}}" | grep -q "^$container$"
}

# Function to check if container is running
container_running() {
    local container=$1
    docker ps --format "table {{.Names}}" | grep -q "^$container$"
}

# Function to connect container to Vault network
connect_container() {
    local container=$1
    local vault_network=$2
    
    if ! container_exists "$container"; then
        echo -e "${RED}Error: Container '$container' does not exist${NC}"
        return 1
    fi
    
    if ! container_running "$container"; then
        echo -e "${YELLOW}Warning: Container '$container' is not running${NC}"
        echo -e "${YELLOW}Starting container...${NC}"
        docker start "$container"
    fi
    
    # Check if already connected
    if docker network inspect "$vault_network" 2>/dev/null | grep -q "$container"; then
        echo -e "${GREEN}Container '$container' is already connected to Vault network${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Connecting '$container' to Vault network...${NC}"
    docker network connect "$vault_network" "$container"
    echo -e "${GREEN}Successfully connected '$container' to Vault network${NC}"
}

# Function to disconnect container from Vault network
disconnect_container() {
    local container=$1
    local vault_network=$2
    
    if ! container_exists "$container"; then
        echo -e "${RED}Error: Container '$container' does not exist${NC}"
        return 1
    fi
    
    # Check if connected
    if ! docker network inspect "$vault_network" 2>/dev/null | grep -q "$container"; then
        echo -e "${YELLOW}Container '$container' is not connected to Vault network${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Disconnecting '$container' from Vault network...${NC}"
    docker network disconnect "$vault_network" "$container"
    echo -e "${GREEN}Successfully disconnected '$container' from Vault network${NC}"
}

# Function to connect backend
connect_backend() {
    local vault_network=$1
    
    echo -e "${GREEN}Connecting backend to Vault...${NC}"
    
    # Try different possible backend container names
    local backend_containers=(
        "plo-solver-backend"
        "plosolver-backend"
        "backend"
        "plo-solver_backend_1"
    )
    
    local connected=false
    for container in "${backend_containers[@]}"; do
        if container_exists "$container"; then
            connect_container "$container" "$vault_network"
            connected=true
            break
        fi
    done
    
    if [ "$connected" = false ]; then
        echo -e "${RED}Error: Backend container not found${NC}"
        echo -e "${YELLOW}Available containers:${NC}"
        docker ps -a --format "table {{.Names}}" | grep -E "(backend|plo)" || echo "No backend containers found"
        return 1
    fi
}

# Function to connect frontend
connect_frontend() {
    local vault_network=$1
    
    echo -e "${GREEN}Connecting frontend to Vault...${NC}"
    
    # Try different possible frontend container names
    local frontend_containers=(
        "plo-solver-frontend"
        "plosolver-frontend"
        "frontend"
        "plo-solver_frontend_1"
    )
    
    local connected=false
    for container in "${frontend_containers[@]}"; do
        if container_exists "$container"; then
            connect_container "$container" "$vault_network"
            connected=true
            break
        fi
    done
    
    if [ "$connected" = false ]; then
        echo -e "${RED}Error: Frontend container not found${NC}"
        echo -e "${YELLOW}Available containers:${NC}"
        docker ps -a --format "table {{.Names}}" | grep -E "(frontend|plo)" || echo "No frontend containers found"
        return 1
    fi
}

# Function to connect all app containers
connect_all() {
    local vault_network=$1
    
    echo -e "${GREEN}Connecting all application containers to Vault...${NC}"
    
    # Connect backend
    if connect_backend "$vault_network"; then
        echo -e "${GREEN}Backend connected successfully${NC}"
    else
        echo -e "${YELLOW}Backend connection failed${NC}"
    fi
    
    # Connect frontend
    if connect_frontend "$vault_network"; then
        echo -e "${GREEN}Frontend connected successfully${NC}"
    else
        echo -e "${YELLOW}Frontend connection failed${NC}"
    fi
    
    echo -e "${GREEN}All connections completed!${NC}"
}

# Function to list connections
list_connections() {
    local vault_network=$1
    
    echo -e "${GREEN}Vault Network Connections:${NC}"
    echo ""
    
    if ! docker network ls | grep -q "$vault_network"; then
        echo -e "${RED}Vault network '$vault_network' does not exist${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Containers connected to '$vault_network':${NC}"
    docker network inspect "$vault_network" --format '{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "No containers connected"
    
    echo ""
    echo -e "${YELLOW}All PLO Solver containers:${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}" | grep -E "(plo|vault)" || echo "No PLO Solver containers found"
}

# Function to create environment file for app
create_app_env() {
    local vault_network=$1
    
    echo -e "${GREEN}Creating application environment configuration...${NC}"
    
    # Check if Vault is accessible
    if curl -s -f "http://localhost:8200/v1/sys/health" > /dev/null 2>&1; then
        VAULT_ADDR="http://vault:8200"
    else
        VAULT_ADDR="http://localhost:8200"
    fi
    
    # Create environment file for applications
    cat > "$VAULT_DIR/config/app-vault.env" << EOF
# Vault Configuration for Applications
VAULT_ADDR=$VAULT_ADDR
VAULT_SKIP_VERIFY=true

# Application can use these environment variables to connect to Vault
# In Docker containers, use: http://vault:8200
# From host, use: http://localhost:8200
EOF
    
    echo -e "${GREEN}Application Vault configuration created: $VAULT_DIR/config/app-vault.env${NC}"
    echo -e "${YELLOW}Vault Address: $VAULT_ADDR${NC}"
}

# Parse command line arguments
get_network_names

while [[ $# -gt 0 ]]; do
    case $1 in
        --vault-network)
            VAULT_NETWORK="$2"
            shift 2
            ;;
        --app-network)
            APP_NETWORK="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1
shift

# Execute based on command
case "$COMMAND" in
    "connect-app")
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            usage
        fi
        connect_container "$1" "$VAULT_NETWORK"
        ;;
    "connect-backend")
        connect_backend "$VAULT_NETWORK"
        ;;
    "connect-frontend")
        connect_frontend "$VAULT_NETWORK"
        ;;
    "connect-all")
        connect_all "$VAULT_NETWORK"
        create_app_env "$VAULT_NETWORK"
        ;;
    "disconnect")
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Container name required${NC}"
            usage
        fi
        disconnect_container "$1" "$VAULT_NETWORK"
        ;;
    "list-connections")
        list_connections "$VAULT_NETWORK"
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        usage
        ;;
esac 