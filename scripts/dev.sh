#!/usr/bin/env bash
# PLOScope Development Environment Manager
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"

cd "$STACK_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           PLOScope Development Environment                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_prerequisites() {
    local missing=()
    
    command -v docker >/dev/null 2>&1 || missing+=("docker")
    command -v docker compose >/dev/null 2>&1 || missing+=("docker compose")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing prerequisites: ${missing[*]}${NC}"
        exit 1
    fi
    
    if [[ ! -f ".env" ]]; then
        echo -e "${YELLOW}Warning: .env file not found. Creating from .env.example...${NC}"
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            echo -e "${GREEN}Created .env from .env.example. Please edit it with your values.${NC}"
        else
            echo -e "${RED}Error: .env.example not found${NC}"
            exit 1
        fi
    fi
    
    # Check if repos directory exists for dev mode
    if [[ ! -d "repos" ]]; then
        echo -e "${YELLOW}Warning: repos directory not found.${NC}"
        echo "Run './scripts/clone-repos.sh' to clone repositories for local development."
        echo ""
    fi
}

compose_dev() {
    docker compose -f docker-compose.yml -f docker-compose.dev.yml "$@"
}

compose_prod() {
    docker compose -f docker-compose.yml -f docker-compose.prod.yml "$@"
}

cmd_up() {
    echo -e "${GREEN}Starting PLOScope development stack...${NC}"
    compose_dev up -d "$@"
    echo ""
    echo -e "${GREEN}Stack started! Services:${NC}"
    echo "  🌐 Frontend:    http://localhost:3000"
    echo "  🔌 Backend:     http://localhost:5001"
    echo "  📊 Grafana:     http://localhost:3001"
    echo "  🐰 RabbitMQ:    http://localhost:15672"
    echo "  🔧 Traefik:     http://localhost:8080"
    echo "  📦 Portainer:   http://localhost:9000"
}

cmd_down() {
    echo -e "${YELLOW}Stopping PLOScope stack...${NC}"
    compose_dev down "$@"
}

cmd_restart() {
    local service="${1:-}"
    if [[ -n "$service" ]]; then
        echo -e "${YELLOW}Restarting $service...${NC}"
        compose_dev restart "$service"
    else
        echo -e "${YELLOW}Restarting all services...${NC}"
        compose_dev restart
    fi
}

cmd_logs() {
    compose_dev logs -f "$@"
}

cmd_build() {
    echo -e "${GREEN}Building development images...${NC}"
    compose_dev build "$@"
}

cmd_pull() {
    echo -e "${GREEN}Pulling latest images...${NC}"
    docker compose pull "$@"
}

cmd_ps() {
    compose_dev ps "$@"
}

cmd_exec() {
    compose_dev exec "$@"
}

cmd_shell() {
    local service="${1:-backend}"
    echo -e "${GREEN}Opening shell in $service...${NC}"
    compose_dev exec "$service" /bin/sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}

cmd_reset() {
    echo -e "${RED}Warning: This will destroy all data volumes!${NC}"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping and removing everything...${NC}"
        compose_dev down -v --remove-orphans
        echo -e "${GREEN}Done. Run './scripts/dev.sh up' to start fresh.${NC}"
    fi
}

cmd_status() {
    echo -e "${BLUE}Service Status:${NC}"
    echo ""
    compose_dev ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
}

show_help() {
    print_header
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  up [services...]     Start development environment"
    echo "  down                 Stop all services"
    echo "  restart [service]    Restart service(s)"
    echo "  logs [service]       Follow service logs"
    echo "  build [service]      Build images from source"
    echo "  pull                 Pull latest images"
    echo "  ps                   List running services"
    echo "  status               Show detailed status"
    echo "  exec <service> <cmd> Execute command in service"
    echo "  shell [service]      Open shell in service (default: backend)"
    echo "  reset                Stop and remove all containers/volumes"
    echo ""
    echo "Examples:"
    echo "  $0 up                       # Start all services"
    echo "  $0 up backend frontend      # Start specific services"
    echo "  $0 logs backend             # Follow backend logs"
    echo "  $0 shell frontend           # Shell into frontend"
    echo "  $0 build backend            # Rebuild backend image"
}

# Main
print_header
check_prerequisites

case "${1:-help}" in
    up)      shift; cmd_up "$@" ;;
    down)    shift; cmd_down "$@" ;;
    restart) shift; cmd_restart "$@" ;;
    logs)    shift; cmd_logs "$@" ;;
    build)   shift; cmd_build "$@" ;;
    pull)    shift; cmd_pull "$@" ;;
    ps)      shift; cmd_ps "$@" ;;
    status)  cmd_status ;;
    exec)    shift; cmd_exec "$@" ;;
    shell)   shift; cmd_shell "$@" ;;
    reset)   cmd_reset ;;
    help|--help|-h) show_help ;;
    *)       echo -e "${RED}Unknown command: $1${NC}"; show_help; exit 1 ;;
esac
