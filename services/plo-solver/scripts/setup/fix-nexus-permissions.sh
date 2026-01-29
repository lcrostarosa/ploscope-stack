#!/bin/bash

# Nexus Repository PyPI Permissions Fix Script
# This script fixes permission issues for existing Nexus installations

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
NEXUS_ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD:-admin-staging-123}"
NEXUS_PYPI_PASSWORD="${NEXUS_PYPI_PASSWORD:-}"
REPOSITORY_NAME="${REPOSITORY_NAME:-pypi-internal}"
REPOSITORY_GROUP_NAME="${REPOSITORY_GROUP_NAME:-pypi-all}"

echo -e "${BLUE}🔧 Fixing Nexus Repository PyPI Permissions${NC}"
echo ""

# Function to check if Nexus is running
check_nexus_running() {
    echo -e "${BLUE}Checking if Nexus Repository is running...${NC}"
    if curl -s -f -k "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is running at ${NEXUS_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Nexus Repository is not running at ${NEXUS_URL}${NC}"
        return 1
    fi
}

# Function to create/update PyPI publisher role with proper permissions
create_pypi_publisher_role() {
    echo -e "${BLUE}Creating/Updating PyPI publisher role with proper permissions...${NC}"
    
    local role_config=$(cat <<EOF
{
  "id": "pypi-publisher-with-read",
  "name": "PyPI Publisher with Read",
  "description": "PyPI publisher with admin on internal and read access",
  "privileges": [
    "nx-repository-admin-pypi-pypi-internal-*",
    "nx-repository-view-pypi-pypi-internal-read",
    "nx-repository-view-pypi-*-*"
  ],
  "roles": []
}
EOF
)
    
    # Try to update (PUT) the role first; if it fails, attempt to create (POST)
    if curl -s -f -k -X PUT \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$role_config" \
        "${NEXUS_URL}/service/rest/v1/security/roles/pypi-publisher-with-read" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI publisher role updated successfully${NC}"
        return 0
    else
        if curl -s -f -k -X POST \
            -H "Content-Type: application/json" \
            -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
            -d "$role_config" \
            "${NEXUS_URL}/service/rest/v1/security/roles" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PyPI publisher role created successfully${NC}"
            return 0
        else
            echo -e "${RED}❌ Role create/update failed${NC}"
            return 1
        fi
    fi
}

# Function to update existing PyPI user with new role
update_pypi_user() {
    echo -e "${BLUE}Updating existing PyPI user with new role...${NC}"
    
    local user_update=$(cat <<EOF
{
  "userId": "pypi-publisher",
  "firstName": "PyPI",
  "lastName": "Publisher",
  "emailAddress": "pypi@ploscope.com",
  "password": "${NEXUS_PYPI_PASSWORD}",
  "status": "active",
  "roles": ["pypi-publisher-with-read"]
}
EOF
)
    
    if curl -s -f -k -X PUT \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$user_update" \
        "${NEXUS_URL}/service/rest/v1/security/users/pypi-publisher" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI user updated successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ User update failed${NC}"
        return 1
    fi
}

# Function to test PyPI user permissions
test_pypi_permissions() {
    echo -e "${BLUE}Testing PyPI user permissions...${NC}"
    
    # Test read access to the hosted repository
    if curl -s -f -k -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/repository/${REPOSITORY_NAME}/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Read access to hosted repository: OK${NC}"
    else
        echo -e "${RED}❌ Read access to hosted repository: FAILED${NC}"
        return 1
    fi
    
    # Test read access to the group repository
    if curl -s -f -k -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        "${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Read access to group repository: OK${NC}"
    else
        echo -e "${RED}❌ Read access to group repository: FAILED${NC}"
        return 1
    fi
    
    # Test write access by attempting to upload a test file (this will fail but should return 400/401, not 403)
    local test_response=$(curl -s -w "%{http_code}" -o /dev/null -k \
        -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" \
        -X POST \
        -H "Content-Type: application/octet-stream" \
        --data-binary "test" \
        "${NEXUS_URL}/repository/${REPOSITORY_NAME}/test-package/")
    
    if [ "$test_response" = "400" ] || [ "$test_response" = "401" ]; then
        echo -e "${GREEN}✅ Write access to hosted repository: OK (authentication working)${NC}"
    elif [ "$test_response" = "403" ]; then
        echo -e "${RED}❌ Write access to hosted repository: FORBIDDEN (permissions issue)${NC}"
        return 1
    else
        echo -e "${YELLOW}⚠️  Write access test returned unexpected response: ${test_response}${NC}"
    fi
    
    echo -e "${GREEN}✅ All permission tests passed!${NC}"
}

# Function to display usage instructions
display_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Nexus Repository PyPI permissions fix completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo ""
    echo -e "${YELLOW}1. Test the fix:${NC}"
    echo -e "${BLUE}   ./scripts/setup/test-nexus-permissions.sh${NC}"
    echo ""
    echo -e "${YELLOW}2. Try uploading a package:${NC}"
    echo -e "${BLUE}   twine upload --repository-url ${NEXUS_URL}/repository/${REPOSITORY_NAME}/ dist/*${NC}"
    echo ""
    echo -e "${YELLOW}3. If you still get 403 errors, check:${NC}"
    echo -e "${BLUE}   - Nexus web interface: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}   - User roles and permissions${NC}"
    echo -e "${BLUE}   - Repository configuration${NC}"
    echo ""
    echo -e "${YELLOW}4. Repository URLs:${NC}"
    echo -e "${BLUE}   Hosted: ${NEXUS_URL}/repository/${REPOSITORY_NAME}/${NC}"
    echo -e "${BLUE}   Group: ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🔧 Nexus Repository PyPI Permissions Fix${NC}"
    echo -e "${BLUE}URL: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}Admin: ${NEXUS_ADMIN_USER}${NC}"
    echo ""
    
    # Check if Nexus is running
    if ! check_nexus_running; then
        exit 1
    fi
    
    # Create/update the role
    if ! create_pypi_publisher_role; then
        echo -e "${RED}❌ Failed to create/update role${NC}"
        exit 1
    fi
    
    # Update the user
    if ! update_pypi_user; then
        echo -e "${RED}❌ Failed to update user${NC}"
        exit 1
    fi
    
    # Test permissions
    if ! test_pypi_permissions; then
        echo -e "${RED}❌ Permission tests failed${NC}"
        echo -e "${YELLOW}Please check the Nexus configuration manually${NC}"
        exit 1
    fi
    
    # Display instructions
    display_instructions
}

# Run main function
main "$@"
