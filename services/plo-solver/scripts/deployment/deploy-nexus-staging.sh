#!/bin/bash

# Nexus Repository Staging Deployment Script
# This script deploys Nexus Repository to the staging environment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STAGING_HOST="${STAGING_HOST:-staging.ploscope.com}"
NEXUS_DOMAIN="nexus.staging.ploscope.com"
DOCKER_COMPOSE_FILE="docker-compose-staging-nexus.yml"

echo -e "${BLUE}🚀 Deploying Nexus Repository to Staging Environment...${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed${NC}"
        exit 1
    fi
    
    # Check if the Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        echo -e "${RED}❌ Docker Compose file not found: $DOCKER_COMPOSE_FILE${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to create staging network
create_staging_network() {
    echo -e "${BLUE}Creating staging network...${NC}"
    
    if ! docker network ls | grep -q "staging-network"; then
        docker network create staging-network
        echo -e "${GREEN}✅ Staging network created${NC}"
    else
        echo -e "${YELLOW}⚠️  Staging network already exists${NC}"
    fi
}

# Function to deploy Nexus Repository
deploy_nexus() {
    echo -e "${BLUE}Deploying Nexus Repository...${NC}"
    
    # Stop existing containers
    echo -e "${BLUE}Stopping existing containers...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" down --remove-orphans || true
    
    # Pull latest image
    echo -e "${BLUE}Pulling latest Nexus image...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" pull
    
    # Start services
    echo -e "${BLUE}Starting Nexus Repository...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    echo -e "${GREEN}✅ Nexus Repository deployed${NC}"
}

# Function to wait for Nexus to be ready
wait_for_nexus() {
    echo -e "${BLUE}Waiting for Nexus Repository to be ready...${NC}"
    
    local max_attempts=30
    local attempt=1
    local nexus_url="https://$NEXUS_DOMAIN"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f -k "$nexus_url/service/rest/v1/status" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Nexus Repository is ready!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}Attempt ${attempt}/${max_attempts}: Nexus not ready yet, waiting...${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Nexus Repository failed to start within expected time${NC}"
    return 1
}

# Function to set up repositories
setup_repositories() {
    echo -e "${BLUE}Setting up PyPI repositories...${NC}"
    
    # Set environment variables for staging
    export NEXUS_URL="https://$NEXUS_DOMAIN"
    export NEXUS_ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD:-admin-staging-123}"
    export NEXUS_PYPI_PASSWORD="${NEXUS_PYPI_PASSWORD:-}"
    
    # Run the setup script
    ./scripts/setup/setup-nexus-staging.sh
    
    echo -e "${GREEN}✅ Repositories configured${NC}"
}

# Function to verify deployment
verify_deployment() {
    echo -e "${BLUE}Verifying deployment...${NC}"
    
    local nexus_url="https://$NEXUS_DOMAIN"
    
    # Test basic connectivity
    if curl -s -f -k "$nexus_url/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Basic connectivity: OK${NC}"
    else
        echo -e "${RED}❌ Basic connectivity: FAILED${NC}"
        return 1
    fi
    
    # Test repository access
    if curl -s -f -k "$nexus_url/repository/pypi-all/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Repository access: OK${NC}"
    else
        echo -e "${RED}❌ Repository access: FAILED${NC}"
        return 1
    fi
    
    # Test authentication
    local pypi_password="${NEXUS_PYPI_PASSWORD}"
    if curl -s -f -k -u "pypi-publisher:$pypi_password" "$nexus_url/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Authentication: OK${NC}"
    else
        echo -e "${RED}❌ Authentication: FAILED${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All verification tests passed!${NC}"
}

# Function to display deployment information
display_deployment_info() {
    echo ""
    echo -e "${GREEN}🎉 Nexus Repository Staging Deployment Completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Deployment Information:${NC}"
    echo ""
    echo -e "${YELLOW}🌐 Access URLs:${NC}"
    echo -e "${BLUE}  Web Interface: https://$NEXUS_DOMAIN${NC}"
    echo -e "${BLUE}  API Endpoint: https://$NEXUS_DOMAIN/service/rest/v1${NC}"
    echo ""
    echo -e "${YELLOW}🔐 Credentials:${NC}"
    echo -e "${BLUE}  Admin User:${NC}"
    echo -e "${BLUE}    Username: admin${NC}"
    echo -e "${BLUE}    Password: ${NEXUS_ADMIN_PASSWORD:-admin-staging-123}${NC}"
    echo ""
    echo -e "${BLUE}  PyPI Publisher:${NC}"
    echo -e "${BLUE}    Username: pypi-publisher${NC}"
    echo -e "${BLUE}    Password: ********${NC}"
    echo ""
    echo -e "${YELLOW}📦 Repository URLs:${NC}"
    echo -e "${BLUE}  Hosted: https://$NEXUS_DOMAIN/repository/pypi-internal/${NC}"
    echo -e "${BLUE}  Group: https://$NEXUS_DOMAIN/repository/pypi-all/${NC}"
    echo -e "${BLUE}  Proxy: https://$NEXUS_DOMAIN/repository/pypi-proxy/${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Configuration Files:${NC}"
    echo -e "${BLUE}  .pypirc.staging - For package publishing${NC}"
    echo -e "${BLUE}  pip.conf.staging - For package installation${NC}"
    echo -e "${BLUE}  setup.cfg.staging - For easy_install${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo -e "${BLUE}  1. Update CI/CD pipelines to use staging Nexus${NC}"
    echo -e "${BLUE}  2. Test package publishing and installation${NC}"
    echo -e "${BLUE}  3. Configure monitoring and alerts${NC}"
    echo ""
}

# Function to rollback deployment
rollback() {
    echo -e "${YELLOW}🔄 Rolling back deployment...${NC}"
    
    # Stop and remove containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" down --volumes --remove-orphans
    
    # Remove staging network if it exists
    if docker network ls | grep -q "staging-network"; then
        docker network rm staging-network
    fi
    
    echo -e "${GREEN}✅ Rollback completed${NC}"
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}Showing Nexus logs...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f nexus
}

# Function to show status
show_status() {
    echo -e "${BLUE}Showing deployment status...${NC}"
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
}

# Main execution
main() {
    echo -e "${BLUE}🔧 Nexus Repository Staging Deployment${NC}"
    echo -e "${BLUE}Domain: $NEXUS_DOMAIN${NC}"
    echo -e "${BLUE}Compose File: $DOCKER_COMPOSE_FILE${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Create staging network
    create_staging_network
    
    # Deploy Nexus Repository
    deploy_nexus
    
    # Wait for Nexus to be ready
    if ! wait_for_nexus; then
        echo -e "${RED}❌ Deployment failed - Nexus not ready${NC}"
        rollback
        exit 1
    fi
    
    # Set up repositories
    setup_repositories
    
    # Verify deployment
    if ! verify_deployment; then
        echo -e "${RED}❌ Deployment verification failed${NC}"
        rollback
        exit 1
    fi
    
    # Display deployment information
    display_deployment_info
}

# Handle command line arguments
case "${1:-}" in
    "rollback")
        rollback
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "verify")
        verify_deployment
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Deploy Nexus Repository to staging"
        echo "  rollback   - Rollback deployment"
        echo "  logs       - Show Nexus logs"
        echo "  status     - Show deployment status"
        echo "  verify     - Verify deployment"
        echo "  help       - Show this help message"
        ;;
    *)
        main
        ;;
esac
