#!/usr/bin/env bash
# PLOScope Stack Setup Wizard
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"

cd "$STACK_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
    ____  __    ____  _____                     
   / __ \/ /   / __ \/ ___/_________  ____  ___ 
  / /_/ / /   / / / /\__ \/ ___/ __ \/ __ \/ _ \
 / ____/ /___/ /_/ /___/ / /__/ /_/ / /_/ /  __/
/_/   /_____/\____//____/\___/\____/ .___/\___/ 
                                  /_/            
                                  
EOF
echo -e "${NC}"
echo -e "${BLUE}Stack Setup Wizard${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "  ✅ $1"
        return 0
    else
        echo -e "  ❌ $1 (not found)"
        return 1
    fi
}

MISSING=0
check_cmd docker || MISSING=1
check_cmd "docker compose" || check_cmd docker-compose || MISSING=1
check_cmd gh || echo -e "  ⚠️  gh (optional - for cloning repos)"
check_cmd make || echo -e "  ⚠️  make (optional - for Makefile)"

echo ""

if [[ $MISSING -eq 1 ]]; then
    echo -e "${RED}Error: Missing required tools. Please install Docker.${NC}"
    exit 1
fi

# Create .env if needed
if [[ ! -f ".env" ]]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cp .env.example .env
    
    # Generate secure secrets
    generate_secret() {
        openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64
    }
    
    echo "Generating secure secrets..."
    
    # Replace placeholders with generated secrets
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SED_INPLACE="sed -i ''"
    else
        SED_INPLACE="sed -i"
    fi
    
    $SED_INPLACE "s/CHANGE_ME_STRONG_PASSWORD/$(generate_secret | tr -d '/+=')/" .env
    $SED_INPLACE "s/CHANGE_ME_REDIS_PASSWORD/$(generate_secret | tr -d '/+=')/" .env
    $SED_INPLACE "s/CHANGE_ME_RABBITMQ_PASSWORD/$(generate_secret | tr -d '/+=')/" .env
    $SED_INPLACE "s/CHANGE_ME_GENERATE_SECURE_KEY/$(generate_secret)/" .env
    $SED_INPLACE "s/CHANGE_ME_GENERATE_JWT_KEY/$(generate_secret)/" .env
    $SED_INPLACE "s/CHANGE_ME_GRAFANA_PASSWORD/$(generate_secret | tr -d '/+=')/" .env
    
    echo -e "  ✅ Generated secure passwords"
    echo -e "  ${YELLOW}⚠️  Review .env and add any missing values (Google OAuth, etc.)${NC}"
else
    echo -e "  ✅ .env already exists"
fi

echo ""

# Create Docker network
echo -e "${YELLOW}Creating Docker network...${NC}"
if docker network inspect plo-network-cloud >/dev/null 2>&1; then
    echo -e "  ✅ Network plo-network-cloud already exists"
else
    docker network create --driver bridge --subnet 172.30.1.0/24 plo-network-cloud
    echo -e "  ✅ Created network plo-network-cloud"
fi

echo ""

# Ask about development setup
echo -e "${BLUE}Setup Mode:${NC}"
echo "  1) Production (pull pre-built images)"
echo "  2) Development (clone repos and build from source)"
echo ""
read -p "Select mode [1]: " MODE
MODE=${MODE:-1}

if [[ "$MODE" == "2" ]]; then
    echo ""
    echo -e "${YELLOW}Cloning repositories...${NC}"
    "$SCRIPT_DIR/clone-repos.sh"
    
    echo ""
    echo -e "${GREEN}Development setup complete!${NC}"
    echo ""
    echo "To start the development stack:"
    echo -e "  ${CYAN}./scripts/dev.sh up${NC}"
else
    echo ""
    echo -e "${GREEN}Production setup complete!${NC}"
    echo ""
    echo "To start the production stack:"
    echo -e "  ${CYAN}docker compose up -d${NC}"
    echo ""
    echo "Or with production optimizations:"
    echo -e "  ${CYAN}docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}Setup complete! 🎉${NC}"
echo ""
echo "Useful commands:"
echo "  docker compose ps              # Check service status"
echo "  docker compose logs -f         # View logs"
echo "  make help                      # See all make targets"
echo ""
echo "Service URLs (after starting):"
echo "  🌐 Frontend:    http://localhost:3000"
echo "  🔌 API:         http://localhost:5001/api"
echo "  📊 Grafana:     http://localhost:3001"
echo "  🐰 RabbitMQ:    http://localhost:15672"
echo "  🔧 Traefik:     http://localhost:8080"
