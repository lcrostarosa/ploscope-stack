#!/bin/bash

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Required Docker resources
REQUIRED_NETWORKS=("plo-network-cloud")
REQUIRED_VOLUMES=("shared-logs" "postgres-data" "rabbitmq-data")

echo -e "${GREEN}🔍 Validating Docker Prerequisites for Local Development${NC}"
echo -e "${BLUE}======================================================${NC}"

# Function to check if Docker is running
check_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running or not accessible${NC}"
        echo -e "${YELLOW}💡 Please start Docker Desktop and try again${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Docker is running${NC}"
    return 0
}

# Function to check if a network exists
check_network() {
    local network_name=$1
    if docker network ls --format "{{.Name}}" | grep -q "^${network_name}$"; then
        echo -e "${GREEN}✅ Network '${network_name}' exists${NC}"
        return 0
    else
        echo -e "${RED}❌ Network '${network_name}' is missing${NC}"
        return 1
    fi
}

# Function to check if a volume exists
check_volume() {
    local volume_name=$1
    if docker volume ls --format "{{.Name}}" | grep -q "^${volume_name}$"; then
        echo -e "${GREEN}✅ Volume '${volume_name}' exists${NC}"
        return 0
    else
        echo -e "${RED}❌ Volume '${volume_name}' is missing${NC}"
        return 1
    fi
}

# Function to create missing network
create_network() {
    local network_name=$1
    echo -e "${YELLOW}🔧 Creating network '${network_name}'...${NC}"
    if docker network create --driver bridge --subnet=172.30.1.0/24 ${network_name}; then
        echo -e "${GREEN}✅ Network '${network_name}' created successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create network '${network_name}'${NC}"
        return 1
    fi
}

# Function to create missing volume
create_volume() {
    local volume_name=$1
    echo -e "${YELLOW}🔧 Creating volume '${volume_name}'...${NC}"
    if docker volume create ${volume_name}; then
        echo -e "${GREEN}✅ Volume '${volume_name}' created successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create volume '${volume_name}'${NC}"
        return 1
    fi
}

# Main validation function
validate_prerequisites() {
    local all_good=true
    
    echo -e "\n${BLUE}📋 Checking Docker prerequisites...${NC}"
    
    # Check if Docker is running
    if ! check_docker_running; then
        return 1
    fi
    
    # Check networks
    echo -e "\n${BLUE}🌐 Checking required networks...${NC}"
    for network in "${REQUIRED_NETWORKS[@]}"; do
        if ! check_network "$network"; then
            all_good=false
        fi
    done
    
    # Check volumes
    echo -e "\n${BLUE}💾 Checking required volumes...${NC}"
    for volume in "${REQUIRED_VOLUMES[@]}"; do
        if ! check_volume "$volume"; then
            all_good=false
        fi
    done
    
    # If something is missing, offer to create it
    if [ "$all_good" = false ]; then
        echo -e "\n${YELLOW}⚠️  Some prerequisites are missing.${NC}"
        echo -e "${BLUE}Would you like to create the missing resources? (y/N)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo -e "\n${GREEN}🔧 Creating missing resources...${NC}"
            
            # Create missing networks
            for network in "${REQUIRED_NETWORKS[@]}"; do
                if ! check_network "$network" >/dev/null 2>&1; then
                    create_network "$network"
                fi
            done
            
            # Create missing volumes
            for volume in "${REQUIRED_VOLUMES[@]}"; do
                if ! check_volume "$volume" >/dev/null 2>&1; then
                    create_volume "$volume"
                fi
            done
            
            echo -e "\n${GREEN}🎉 All prerequisites are now available!${NC}"
            return 0
        else
            echo -e "\n${RED}❌ Cannot proceed without required Docker resources${NC}"
            echo -e "${YELLOW}💡 Please create the missing networks and volumes manually:${NC}"
            echo -e "${BLUE}   Networks: ${REQUIRED_NETWORKS[*]}${NC}"
            echo -e "${BLUE}   Volumes: ${REQUIRED_VOLUMES[*]}${NC}"
            return 1
        fi
    else
        echo -e "\n${GREEN}🎉 All prerequisites are available!${NC}"
        return 0
    fi
}

# Function to show current Docker resources
show_docker_resources() {
    echo -e "\n${BLUE}📊 Current Docker Resources:${NC}"
    echo -e "\n${YELLOW}Networks:${NC}"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    echo -e "\n${YELLOW}Volumes:${NC}"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}"
}

# Main execution
main() {
    if validate_prerequisites; then
        show_docker_resources
        echo -e "\n${GREEN}✅ Ready to start local development!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Prerequisites validation failed${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
