#!/bin/bash

# Nexus Repository PyPI Permissions Test Script
# This script tests that the pypi-publisher user has proper permissions

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NEXUS_URL="${NEXUS_URL:-http://localhost:8081}"
NEXUS_PYPI_PASSWORD="${NEXUS_PYPI_PASSWORD:-}"
REPOSITORY_NAME="${REPOSITORY_NAME:-pypi-internal}"
REPOSITORY_GROUP_NAME="${REPOSITORY_GROUP_NAME:-pypi-all}"

echo -e "${BLUE}🧪 Testing Nexus Repository PyPI Permissions${NC}"
echo ""

# Function to test basic connectivity
test_connectivity() {
    echo -e "${BLUE}Testing basic connectivity...${NC}"
    
    if curl -s -f "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ Cannot connect to Nexus Repository at ${NEXUS_URL}${NC}"
        return 1
    fi
}

# Function to test authentication
test_authentication() {
    echo -e "${BLUE}Testing pypi-publisher authentication...${NC}"
    
    if curl -s -f -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Authentication successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Authentication failed${NC}"
        return 1
    fi
}

# Function to test read access to hosted repository
test_hosted_read() {
    echo -e "${BLUE}Testing read access to hosted repository...${NC}"
    
    if curl -s -f -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/repository/${REPOSITORY_NAME}/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Read access to hosted repository: OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Read access to hosted repository: FAILED${NC}"
        return 1
    fi
}

# Function to test read access to group repository
test_group_read() {
    echo -e "${BLUE}Testing read access to group repository...${NC}"
    
    if curl -s -f -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Read access to group repository: OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Read access to group repository: FAILED${NC}"
        return 1
    fi
}

# Function to test write access to hosted repository
test_hosted_write() {
    echo -e "${BLUE}Testing write access to hosted repository...${NC}"
    
    # Test write access by attempting to upload a test file
    # This will fail with 400 (bad request) but should not be 403 (forbidden)
    local test_response=$(curl -s -w "%{http_code}" -o /dev/null \
        -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        -X POST \
        -H "Content-Type: application/octet-stream" \
        --data-binary "test" \
        "${NEXUS_URL}/repository/${REPOSITORY_NAME}/test-package/")
    
    if [ "$test_response" = "400" ] || [ "$test_response" = "401" ]; then
        echo -e "${GREEN}✅ Write access to hosted repository: OK (authentication working)${NC}"
        return 0
    elif [ "$test_response" = "403" ]; then
        echo -e "${RED}❌ Write access to hosted repository: FORBIDDEN (permissions issue)${NC}"
        return 1
    else
        echo -e "${YELLOW}⚠️  Write access test returned unexpected response: ${test_response}${NC}"
        return 1
    fi
}

# Function to test pip install simulation
test_pip_install() {
    echo -e "${BLUE}Testing pip install simulation...${NC}"
    
    # Test if we can access the simple index (what pip uses)
    if curl -s -f -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Pip install access: OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Pip install access: FAILED${NC}"
        return 1
    fi
}

# Function to test twine upload simulation
test_twine_upload() {
    echo -e "${BLUE}Testing twine upload simulation...${NC}"
    
    # Test if we can access the hosted repository for uploads
    if curl -s -f -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/repository/${REPOSITORY_NAME}/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Twine upload access: OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Twine upload access: FAILED${NC}"
        return 1
    fi
}

# Function to display test summary
display_summary() {
    echo ""
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo -e "${BLUE}===============${NC}"
    echo -e "${BLUE}Nexus URL: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}Hosted Repository: ${REPOSITORY_NAME}${NC}"
    echo -e "${BLUE}Group Repository: ${REPOSITORY_GROUP_NAME}${NC}"
    echo -e "${BLUE}User: pypi-publisher${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🔧 Nexus Repository PyPI Permissions Test${NC}"
    echo ""
    
    local tests_passed=0
    local tests_failed=0
    
    # Run all tests
    if test_connectivity; then
        ((tests_passed++))
    else
        ((tests_failed++))
        echo -e "${RED}❌ Cannot proceed with other tests due to connectivity issues${NC}"
        exit 1
    fi
    
    if test_authentication; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_hosted_read; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_group_read; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_hosted_write; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_pip_install; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_twine_upload; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Display summary
    display_summary
    
    echo -e "${BLUE}Tests Passed: ${tests_passed}${NC}"
    echo -e "${BLUE}Tests Failed: ${tests_failed}${NC}"
    echo ""
    
    if [ $tests_failed -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! PyPI permissions are working correctly.${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed. Please check the Nexus configuration.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
