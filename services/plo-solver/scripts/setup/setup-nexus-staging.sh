#!/bin/bash

# Nexus Repository Staging Setup Script
# This script sets up Nexus Repository for the staging environment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NEXUS_URL="${NEXUS_URL:-https://nexus.staging.ploscope.com}"
NEXUS_ADMIN_USER="${NEXUS_ADMIN_USER:-admin}"
NEXUS_ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD:-admin-staging-123}"
NEXUS_PYPI_PASSWORD="${NEXUS_PYPI_PASSWORD:-}"
REPOSITORY_NAME="${REPOSITORY_NAME:-pypi-internal}"
REPOSITORY_GROUP_NAME="${REPOSITORY_GROUP_NAME:-pypi-all}"

echo -e "${BLUE}🚀 Setting up Nexus Repository for Staging Environment...${NC}"
echo ""

# Function to check if Nexus is running
check_nexus_running() {
    echo -e "${BLUE}Checking if Nexus Repository is running...${NC}"
    if curl -s -f -k "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is running at ${NEXUS_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Nexus Repository is not running at ${NEXUS_URL}${NC}"
        echo -e "${YELLOW}Please start Nexus first:${NC}"
        echo -e "${BLUE}  docker-compose -f docker-compose-staging-nexus.yml up -d${NC}"
        return 1
    fi
}

# Function to wait for Nexus to be ready
wait_for_nexus() {
    echo -e "${BLUE}Waiting for Nexus Repository to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f -k "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
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

# Function to create PyPI hosted repository
create_pypi_hosted_repository() {
    echo -e "${BLUE}Creating PyPI hosted repository: ${REPOSITORY_NAME}${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "${REPOSITORY_NAME}",
  "type": "hosted",
  "format": "pypi",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true,
    "writePolicy": "allow_once"
  },
  "cleanup": {
    "policyNames": []
  },
  "component": {
    "proprietaryComponents": true
  }
}
EOF
)
    
    if curl -s -f -k -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/pypi/hosted" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI hosted repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist or creation failed${NC}"
    fi
}

# Function to create PyPI proxy repository
create_pypi_proxy_repository() {
    echo -e "${BLUE}Creating PyPI proxy repository: pypi-proxy${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "pypi-proxy",
  "type": "proxy",
  "format": "pypi",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "proxy": {
    "remoteUrl": "https://pypi.org/",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true,
    "connection": {
      "retries": 3,
      "timeout": 30,
      "userAgentSuffix": "PLOSolver-Staging"
    }
  },
  "routingRuleName": "",
  "cleanup": {
    "policyNames": []
  }
}
EOF
)
    
    if curl -s -f -k -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/pypi/proxy" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI proxy repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist or creation failed${NC}"
    fi
}

# Function to create PyPI group repository
create_pypi_group_repository() {
    echo -e "${BLUE}Creating PyPI group repository: ${REPOSITORY_GROUP_NAME}${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "${REPOSITORY_GROUP_NAME}",
  "type": "group",
  "format": "pypi",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "group": {
    "memberNames": ["${REPOSITORY_NAME}", "pypi-proxy"]
  }
}
EOF
)
    
    if curl -s -f -k -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/pypi/group" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI group repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist or creation failed${NC}"
    fi
}

# Function to create PyPI publisher role with proper permissions
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
    else
        if curl -s -f -k -X POST \
            -H "Content-Type: application/json" \
            -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
            -d "$role_config" \
            "${NEXUS_URL}/service/rest/v1/security/roles" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PyPI publisher role created successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Role create/update failed${NC}"
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
        echo -e "${YELLOW}⚠️  User update failed${NC}"
        return 1
    fi
}

# Function to create user for package publishing
create_pypi_user() {
    echo -e "${BLUE}Creating PyPI user for package publishing...${NC}"
    
    # First, ensure the role exists
    create_pypi_publisher_role
    
    local user_config=$(cat <<EOF
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
    
    if curl -s -f -k -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$user_config" \
        "${NEXUS_URL}/service/rest/v1/security/users" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI user created successfully${NC}"
        echo -e "${BLUE}Username: pypi-publisher${NC}"
        echo -e "${BLUE}Password: ${NEXUS_PYPI_PASSWORD}${NC}"
    else
        echo -e "${YELLOW}⚠️  User may already exist, attempting to update...${NC}"
        if update_pypi_user; then
            echo -e "${GREEN}✅ PyPI user updated successfully${NC}"
            echo -e "${BLUE}Username: pypi-publisher${NC}"
            echo -e "${BLUE}Password: ${NEXUS_PYPI_PASSWORD}${NC}"
        else
            echo -e "${RED}❌ Failed to create or update PyPI user${NC}"
            return 1
        fi
    fi
}

# Function to generate configuration files
generate_config_files() {
    echo -e "${BLUE}Generating configuration files...${NC}"
    
    # Create .pypirc file for staging
    cat > .pypirc.staging <<EOF
[distutils]
index-servers =
    nexus-staging

[nexus-staging]
repository: ${NEXUS_URL}/repository/${REPOSITORY_NAME}/
username: pypi-publisher
password: ${NEXUS_PYPI_PASSWORD}
EOF
    
    # Create pip.conf file for staging
    cat > pip.conf.staging <<EOF
[global]
index = ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/pypi
index-url = ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple
trusted-host = $(echo $NEXUS_URL | sed 's|https?://||')
EOF
    
    # Create setup.cfg file for easy_install
    cat > setup.cfg.staging <<EOF
[easy_install]
index-url = ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple
EOF
    
    echo -e "${GREEN}✅ Configuration files generated:${NC}"
    echo -e "${BLUE}  - .pypirc.staging (for twine uploads)${NC}"
    echo -e "${BLUE}  - pip.conf.staging (for pip installs)${NC}"
    echo -e "${BLUE}  - setup.cfg.staging (for easy_install)${NC}"
}

# Function to display usage instructions
display_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Nexus Repository Staging setup completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Usage Instructions:${NC}"
    echo ""
    echo -e "${YELLOW}1. Publishing packages:${NC}"
    echo -e "${BLUE}   twine upload --repository nexus-staging dist/*${NC}"
    echo ""
    echo -e "${YELLOW}2. Installing packages:${NC}"
    echo -e "${BLUE}   pip install plosolver-core${NC}"
    echo ""
    echo -e "${YELLOW}3. Repository URLs:${NC}"
    echo -e "${BLUE}   Hosted: ${NEXUS_URL}/repository/${REPOSITORY_NAME}/${NC}"
    echo -e "${BLUE}   Group: ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/${NC}"
    echo -e "${BLUE}   Proxy: ${NEXUS_URL}/repository/pypi-proxy/${NC}"
    echo ""
    echo -e "${YELLOW}4. Web Interface:${NC}"
    echo -e "${BLUE}   ${NEXUS_URL}${NC}"
    echo -e "${BLUE}   Username: ${NEXUS_ADMIN_USER}${NC}"
    echo -e "${BLUE}   Password: ${NEXUS_ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${YELLOW}5. PyPI Publisher Credentials:${NC}"
    echo -e "${BLUE}   Username: pypi-publisher${NC}"
    echo -e "${BLUE}   Password: ${NEXUS_PYPI_PASSWORD}${NC}"
    echo ""
    echo -e "${YELLOW}6. Environment Variables:${NC}"
    echo -e "${BLUE}   NEXUS_URL=${NEXUS_URL}${NC}"
    echo -e "${BLUE}   NEXUS_ADMIN_PASSWORD=${NEXUS_ADMIN_PASSWORD}${NC}"
    echo -e "${BLUE}   NEXUS_PYPI_PASSWORD=${NEXUS_PYPI_PASSWORD}${NC}"
    echo ""
}

# Function to test connectivity
test_connectivity() {
    echo -e "${BLUE}Testing connectivity and repositories...${NC}"
    
    # Test basic connectivity
    if curl -s -f -k "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Basic connectivity: OK${NC}"
    else
        echo -e "${RED}❌ Basic connectivity: FAILED${NC}"
        return 1
    fi
    
    # Test repository access
    if curl -s -f -k "${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Repository access: OK${NC}"
    else
        echo -e "${RED}❌ Repository access: FAILED${NC}"
        return 1
    fi
    
    # Test authentication
    if curl -s -f -k -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Authentication: OK${NC}"
    else
        echo -e "${RED}❌ Authentication: FAILED${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All connectivity tests passed!${NC}"
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

# Main execution
main() {
    echo -e "${BLUE}🔧 Nexus Repository Staging Setup${NC}"
    echo -e "${BLUE}URL: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}Admin: ${NEXUS_ADMIN_USER}${NC}"
    echo ""
    
    # Check if Nexus is running
    if ! check_nexus_running; then
        exit 1
    fi
    
    # Wait for Nexus to be ready
    if ! wait_for_nexus; then
        exit 1
    fi
    
    # Create repositories
    create_pypi_hosted_repository
    create_pypi_proxy_repository
    create_pypi_group_repository
    
    # Create user
    create_pypi_user
    
    # Generate configuration files
    generate_config_files
    
    # Test connectivity
    test_connectivity
    
    # Test permissions
    test_pypi_permissions
    
    # Display instructions
    display_instructions
}

# Run main function
main "$@"
