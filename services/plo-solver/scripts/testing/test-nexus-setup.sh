#!/bin/bash

# Test Script for Nexus Repository Setup
# This script verifies that Nexus Repository is properly configured for PyPI packages

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Nexus Repository Setup...${NC}"
echo ""

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Test 1: Nexus Repository is running
run_test "Nexus Repository is running" \
    "curl -s -f http://localhost:8081/service/rest/v1/status"

# Test 2: PyPI hosted repository exists
run_test "PyPI hosted repository exists" \
    "curl -s -f http://localhost:8081/repository/pypi-internal/"

# Test 3: PyPI proxy repository exists
run_test "PyPI proxy repository exists" \
    "curl -s -f http://localhost:8081/repository/pypi-proxy/"

# Test 4: PyPI group repository exists
run_test "PyPI group repository exists" \
    "curl -s -f http://localhost:8081/repository/pypi-all/"

# Test 5: Authentication works
run_test "Authentication works" \
    "curl -s -f -u pypi-publisher:${NEXUS_PYPI_PASSWORD} http://localhost:8081/service/rest/v1/status"

# Test 6: Package can be published (if package exists)
if [ -d "src/plosolver_core" ]; then
    run_test "Package can be built" \
        "cd src/plosolver_core && python -m build"
else
    echo -e "${YELLOW}⚠️  SKIP: Package build test (src/plosolver_core not found)${NC}"
    echo ""
fi

# Test 7: pip configuration is correct
run_test "pip configuration exists" \
    "[ -f \"$HOME/.config/pip/pip.conf\" ]"

# Test 8: .pypirc configuration exists
run_test ".pypirc configuration exists" \
    "[ -f \".pypirc\" ]"

# Test 9: pip can access Nexus repository
run_test "pip can access Nexus repository" \
    "pip search --index http://localhost:8081/repository/pypi-all/pypi requests" 2>/dev/null || true

# Test 10: Docker Compose file exists
run_test "Docker Compose file exists" \
    "[ -f \"docker-compose-nexus.yml\" ]"

# Display test results
echo -e "${BLUE}📊 Test Results:${NC}"
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Nexus Repository is properly configured.${NC}"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "${BLUE}  1. Publish your first package: make nexus-publish-local${NC}"
    echo -e "${BLUE}  2. Install from Nexus: make nexus-install${NC}"
    echo -e "${BLUE}  3. Access web interface: http://localhost:8081${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the setup.${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo -e "${BLUE}  1. Start Nexus: make nexus-start${NC}"
    echo -e "${BLUE}  2. Set up repositories: make nexus-setup${NC}"
    echo -e "${BLUE}  3. Run migration: make nexus-migrate${NC}"
    exit 1
fi
