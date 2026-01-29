#!/bin/bash

# PLO Solver Vault Network Setup Script
# This script helps set up Vault with different network configurations

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
    echo "  isolated     - Run Vault in isolated network (default)"
    echo "  integrated   - Run Vault integrated with main app network"
    echo "  production   - Run Vault with production settings"
    echo "  external     - Connect to external Vault instance"
    echo ""
    echo "Options:"
    echo "  --vault-url <url>     - External Vault URL (for external mode)"
    echo "  --vault-token <token> - External Vault token (for external mode)"
    echo ""
    echo "Examples:"
    echo "  $0 isolated"
    echo "  $0 integrated"
    echo "  $0 production"
    echo "  $0 external --vault-url https://vault.company.com --vault-token s.abc123"
    exit 1
}

# Function to create networks
create_networks() {
    echo -e "${YELLOW}Creating Docker networks...${NC}"
    
    # Create Vault network
    if ! docker network ls | grep -q "plo-solver-vault-network"; then
        docker network create plo-solver-vault-network
        echo -e "${GREEN}Created vault network: plo-solver-vault-network${NC}"
    else
        echo -e "${GREEN}Vault network already exists${NC}"
    fi
    
    # Create main app network if it doesn't exist
    if ! docker network ls | grep -q "plo-solver-network"; then
        docker network create plo-solver-network
        echo -e "${GREEN}Created main app network: plo-solver-network${NC}"
    else
        echo -e "${GREEN}Main app network already exists${NC}"
    fi
}

# Function to run isolated Vault
run_isolated() {
    echo -e "${GREEN}Starting Vault in isolated mode...${NC}"
    create_networks
    
    cd "$VAULT_DIR"
    docker-compose -f docker-compose.yml up -d
    
    echo -e "${GREEN}Vault started in isolated mode!${NC}"
    echo -e "${YELLOW}Vault API: http://localhost:8200${NC}"
    echo -e "${YELLOW}Vault UI: http://localhost:8201${NC}"
    echo -e "${YELLOW}Network: plo-solver-vault-network (isolated)${NC}"
}

# Function to run integrated Vault
run_integrated() {
    echo -e "${GREEN}Starting Vault in integrated mode...${NC}"
    create_networks
    
    cd "$VAULT_DIR"
    docker-compose -f docker-compose-integrated.yml up -d
    
    echo -e "${GREEN}Vault started in integrated mode!${NC}"
    echo -e "${YELLOW}Vault API: http://localhost:8200${NC}"
    echo -e "${YELLOW}Vault UI: http://localhost:8201${NC}"
    echo -e "${YELLOW}Networks: plo-solver-vault-network + plo-solver-network${NC}"
    echo -e "${YELLOW}Applications can connect via: http://vault:8200${NC}"
}

# Function to run production Vault
run_production() {
    echo -e "${GREEN}Starting Vault in production mode...${NC}"
    
    # Check if running as root for production setup
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Production mode requires root privileges for volume setup${NC}"
        echo -e "${YELLOW}Run with sudo or set up volumes manually${NC}"
        exit 1
    fi
    
    # Create production data directory
    mkdir -p /var/lib/vault/data
    chown 1000:1000 /var/lib/vault/data
    chmod 700 /var/lib/vault/data
    
    create_networks
    
    cd "$VAULT_DIR"
    docker-compose -f docker-compose-production.yml up -d
    
    echo -e "${GREEN}Vault started in production mode!${NC}"
    echo -e "${YELLOW}Vault API: http://localhost:8200${NC}"
    echo -e "${YELLOW}Vault UI: http://localhost:8201${NC}"
    echo -e "${YELLOW}Data stored in: /var/lib/vault/data${NC}"
    echo -e "${YELLOW}Network: plo-solver-vault-network-prod${NC}"
}

# Function to configure external Vault
configure_external() {
    local vault_url=""
    local vault_token=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --vault-url)
                vault_url="$2"
                shift 2
                ;;
            --vault-token)
                vault_token="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                ;;
        esac
    done
    
    if [ -z "$vault_url" ] || [ -z "$vault_token" ]; then
        echo -e "${RED}Error: vault-url and vault-token are required for external mode${NC}"
        usage
    fi
    
    echo -e "${GREEN}Configuring external Vault connection...${NC}"
    
    # Create configuration file for external Vault
    cat > "$VAULT_DIR/config/external-vault.env" << EOF
# External Vault Configuration
VAULT_ADDR=$vault_url
VAULT_TOKEN=$vault_token
VAULT_SKIP_VERIFY=true
EOF
    
    # Create script to use external Vault
    cat > "$VAULT_DIR/scripts/use-external-vault.sh" << 'EOF'
#!/bin/bash
# Script to use external Vault instance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/external-vault.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: External Vault configuration not found"
    echo "Run vault-network-setup.sh external --vault-url <url> --vault-token <token>"
    exit 1
fi

# Source the configuration
set -a
source "$CONFIG_FILE"
set +a

# Execute the original command
exec "$@"
EOF
    
    chmod +x "$VAULT_DIR/scripts/use-external-vault.sh"
    
    echo -e "${GREEN}External Vault configured!${NC}"
    echo -e "${YELLOW}Vault URL: $vault_url${NC}"
    echo -e "${YELLOW}Configuration: $VAULT_DIR/config/external-vault.env${NC}"
    echo -e "${YELLOW}Usage: $VAULT_DIR/scripts/use-external-vault.sh <command>${NC}"
}

# Function to show network status
show_status() {
    echo -e "${GREEN}Vault Network Status:${NC}"
    echo ""
    
    echo -e "${YELLOW}Docker Networks:${NC}"
    docker network ls | grep -E "(plo-solver|vault)" || echo "No PLO Solver networks found"
    
    echo ""
    echo -e "${YELLOW}Running Vault Containers:${NC}"
    docker ps | grep -E "(vault|plo-solver)" || echo "No Vault containers running"
    
    echo ""
    echo -e "${YELLOW}Vault Health Check:${NC}"
    if curl -s -f "http://localhost:8200/v1/sys/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Vault is healthy${NC}"
    else
        echo -e "${RED}✗ Vault is not accessible${NC}"
    fi
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

MODE=$1
shift

# Execute based on mode
case "$MODE" in
    "isolated")
        run_isolated
        ;;
    "integrated")
        run_integrated
        ;;
    "production")
        run_production
        ;;
    "external")
        configure_external "$@"
        ;;
    "status")
        show_status
        ;;
    *)
        echo -e "${RED}Error: Unknown mode: $MODE${NC}"
        usage
        ;;
esac 