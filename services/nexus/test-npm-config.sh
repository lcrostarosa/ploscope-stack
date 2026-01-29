#!/bin/bash

# Test script for NPM registry configuration
# This script tests the NPM registry setup in Nexus

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NEXUS_URL="${NEXUS_URL:-https://nexus.ploscope.com}"
NEXUS_ADMIN_USER="${NEXUS_ADMIN_USER:-admin}"
NEXUS_ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD:-admin123}"
NPM_REPOSITORY_NAME="${NPM_REPOSITORY_NAME:-npm-internal}"
NPM_REPOSITORY_GROUP_NAME="${NPM_REPOSITORY_GROUP_NAME:-npm-all}"

echo -e "${BLUE}🧪 Testing NPM Registry Configuration...${NC}"
echo ""

# Function to check if Nexus is running
check_nexus_running() {
    echo -e "${BLUE}Checking if Nexus Repository is running...${NC}"
    if curl -s -f "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is running at ${NEXUS_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Nexus Repository is not running at ${NEXUS_URL}${NC}"
        return 1
    fi
}

# Function to test NPM repository access
test_npm_repositories() {
    echo -e "${BLUE}Testing NPM repository access...${NC}"
    
    # Test NPM hosted repository
    echo -e "${YELLOW}Testing NPM hosted repository: ${NPM_REPOSITORY_NAME}${NC}"
    if curl -s -f "${NEXUS_URL}/repository/${NPM_REPOSITORY_NAME}/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM hosted repository is accessible${NC}"
    else
        echo -e "${RED}❌ NPM hosted repository is not accessible${NC}"
    fi
    
    # Test NPM group repository
    echo -e "${YELLOW}Testing NPM group repository: ${NPM_REPOSITORY_GROUP_NAME}${NC}"
    if curl -s -f "${NEXUS_URL}/repository/${NPM_REPOSITORY_GROUP_NAME}/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM group repository is accessible${NC}"
    else
        echo -e "${RED}❌ NPM group repository is not accessible${NC}"
    fi
    
    # Test NPM proxy repository
    echo -e "${YELLOW}Testing NPM proxy repository: npm-proxy${NC}"
    if curl -s -f "${NEXUS_URL}/repository/npm-proxy/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM proxy repository is accessible${NC}"
    else
        echo -e "${RED}❌ NPM proxy repository is not accessible${NC}"
    fi
}

# Function to test NPM user authentication
test_npm_user() {
    echo -e "${BLUE}Testing NPM user authentication...${NC}"
    
    # Test if npm-publisher user exists
    if curl -s -f -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        "${NEXUS_URL}/service/rest/v1/security/users/npm-publisher" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM publisher user exists${NC}"
    else
        echo -e "${RED}❌ NPM publisher user does not exist${NC}"
    fi
}

# Function to test NPM registry endpoints
test_npm_endpoints() {
    echo -e "${BLUE}Testing NPM registry endpoints...${NC}"
    
    # Test NPM registry endpoint
    echo -e "${YELLOW}Testing NPM registry endpoint...${NC}"
    if curl -s -f "${NEXUS_URL}/repository/${NPM_REPOSITORY_GROUP_NAME}/-/v1/search?text=test" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM registry search endpoint is working${NC}"
    else
        echo -e "${YELLOW}⚠️  NPM registry search endpoint may not be working (this is normal for empty repositories)${NC}"
    fi
}

# Function to display test results
display_test_results() {
    echo ""
    echo -e "${GREEN}🎉 NPM Registry Configuration Test Complete!${NC}"
    echo ""
    echo -e "${BLUE}📋 Test Summary:${NC}"
    echo -e "${BLUE}  - Nexus Repository: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}  - NPM Hosted Repository: ${NEXUS_URL}/repository/${NPM_REPOSITORY_NAME}/${NC}"
    echo -e "${BLUE}  - NPM Group Repository: ${NEXUS_URL}/repository/${NPM_REPOSITORY_GROUP_NAME}/${NC}"
    echo -e "${BLUE}  - NPM Proxy Repository: ${NEXUS_URL}/repository/npm-proxy/${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "${BLUE}  1. Run the setup script: ./setup-nexus.sh${NC}"
    echo -e "${BLUE}  2. Configure your .npmrc file${NC}"
    echo -e "${BLUE}  3. Test publishing a package${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🔧 NPM Registry Configuration Test${NC}"
    echo -e "${BLUE}URL: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}Admin: ${NEXUS_ADMIN_USER}${NC}"
    echo ""
    
    # Check if Nexus is running
    if ! check_nexus_running; then
        echo -e "${RED}❌ Cannot proceed with tests - Nexus is not running${NC}"
        exit 1
    fi
    
    # Run tests
    test_npm_repositories
    test_npm_user
    test_npm_endpoints
    
    # Display results
    display_test_results
}

# Run main function
main "$@"
