#!/usr/bin/env bash
# Build all PLOScope Docker images locally
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"
REPOS_DIR="${STACK_DIR}/repos"

cd "$STACK_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           PLOScope Image Builder                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check repos directory
if [[ ! -d "$REPOS_DIR" ]]; then
    echo -e "${RED}Error: repos directory not found.${NC}"
    echo "Run './scripts/clone-repos.sh' first."
    exit 1
fi

# Parse arguments
TAG="${1:-dev}"
PUSH="${2:-false}"

echo "Building images with tag: ${TAG}"
echo ""

# Services to build (repo:image-name)
SERVICES=(
    "backend:ploscope/backend"
    "frontend:ploscope/frontend"
    "celery-worker:ploscope/celery-worker"
    "rabbitmq:ploscope/rabbitmq-init"
    "db-init:ploscope/db-init"
)

SUCCESS=()
FAILED=()

for service_spec in "${SERVICES[@]}"; do
    IFS=':' read -r repo image <<< "$service_spec"
    
    if [[ ! -d "${REPOS_DIR}/${repo}" ]]; then
        echo -e "${YELLOW}⏭️  Skipping ${image} (repo not found)${NC}"
        continue
    fi
    
    echo -n "🔨 Building ${image}:${TAG}..."
    
    if docker build \
        -t "${image}:${TAG}" \
        -t "${image}:latest" \
        --build-arg BUILD_ENV=production \
        "${REPOS_DIR}/${repo}" \
        >/dev/null 2>&1; then
        echo -e " ${GREEN}✅${NC}"
        SUCCESS+=("${image}")
        
        if [[ "$PUSH" == "true" || "$PUSH" == "--push" ]]; then
            echo -n "   📤 Pushing..."
            if docker push "${image}:${TAG}" >/dev/null 2>&1; then
                docker push "${image}:latest" >/dev/null 2>&1
                echo -e " ${GREEN}✅${NC}"
            else
                echo -e " ${RED}❌${NC}"
            fi
        fi
    else
        echo -e " ${RED}❌${NC}"
        FAILED+=("${image}")
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Summary:"
echo -e "  ${GREEN}✅ Built:  ${#SUCCESS[@]}${NC}"
echo -e "  ${RED}❌ Failed: ${#FAILED[@]}${NC}"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    echo "Failed builds:"
    for img in "${FAILED[@]}"; do
        echo "  - $img"
    done
    echo ""
    echo "Try building individually for more details:"
    echo "  docker build ./repos/<repo-name>"
fi

echo ""
echo "Images are tagged as:"
echo "  - ${TAG}"
echo "  - latest"
