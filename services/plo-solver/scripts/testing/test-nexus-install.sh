#!/bin/bash

# Test Nexus Repository connectivity and package installation
# This script verifies that plosolver-core can be installed from Nexus

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Nexus Repository connectivity and package installation...${NC}"

# Test 1: Check if Nexus is accessible
echo -e "${BLUE}1. Testing Nexus Repository accessibility...${NC}"
if curl -s -f "https://nexus.ploscope.com/service/rest/v1/status" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Nexus Repository is accessible${NC}"
else
    echo -e "${RED}❌ Cannot access Nexus Repository${NC}"
    exit 1
fi

# Test 2: Check if PyPI group repository is accessible
echo -e "${BLUE}2. Testing PyPI group repository accessibility...${NC}"
if curl -s -f "https://nexus.ploscope.com/repository/pypi-all/simple/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PyPI group repository is accessible${NC}"
else
    echo -e "${YELLOW}⚠️  PyPI group repository not accessible, but this may be normal for empty repositories${NC}"
fi

# Test 3: Check if plosolver-core package is available
echo -e "${BLUE}3. Testing plosolver-core package availability...${NC}"
if curl -s -f -u "${NEXUS_ADMIN_USER:-admin}:${NEXUS_ADMIN_PASSWORD}" "https://nexus.ploscope.com/service/rest/v1/components?repository=pypi-internal" | jq -e '.items[] | select(.name == "plosolver-core")' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ plosolver-core package is available in Nexus${NC}"
else
    echo -e "${RED}❌ plosolver-core package not found in Nexus${NC}"
    exit 1
fi

# Test 4: Configure pip and test installation
echo -e "${BLUE}4. Testing pip configuration and package installation...${NC}"

# Create a temporary pip configuration
mkdir -p /tmp/nexus-test
cat > /tmp/nexus-test/pip.conf <<EOF
[global]
index = https://nexus.ploscope.com/repository/pypi-all/pypi
index-url = https://nexus.ploscope.com/repository/pypi-all/simple
trusted-host = nexus.ploscope.com
EOF

# Test installation in a temporary environment
export PIP_CONFIG_FILE=/tmp/nexus-test/pip.conf

if pip install --dry-run plosolver-core > /dev/null 2>&1; then
    echo -e "${GREEN}✅ pip can resolve plosolver-core from Nexus${NC}"
else
    echo -e "${RED}❌ pip cannot resolve plosolver-core from Nexus${NC}"
    exit 1
fi

# Clean up
rm -rf /tmp/nexus-test

echo -e "${GREEN}🎉 All Nexus Repository tests passed!${NC}"
echo -e "${BLUE}The Docker containers should now be able to pull plosolver-core from Nexus.${NC}"
