#!/bin/bash

# Nexus Repository Setup Script for Isolated Environment
# This script sets up Nexus Repository for PyPI packages in an isolated environment

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
NEXUS_PYPI_PASSWORD="${NEXUS_PYPI_PASSWORD:-}"
NEXUS_NPM_PASSWORD="${NEXUS_NPM_PASSWORD:-}"
REPOSITORY_NAME="${REPOSITORY_NAME:-pypi-internal}"
REPOSITORY_GROUP_NAME="${REPOSITORY_GROUP_NAME:-pypi-all}"
NPM_REPOSITORY_NAME="${NPM_REPOSITORY_NAME:-npm-internal}"
NPM_REPOSITORY_GROUP_NAME="${NPM_REPOSITORY_GROUP_NAME:-npm-all}"

echo -e "${BLUE}🚀 Setting up Nexus Repository for Isolated Environment...${NC}"
echo ""

# Function to check if Nexus is running
check_nexus_running() {
    echo -e "${BLUE}Checking if Nexus Repository is running...${NC}"
    if curl -s -f "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is running at ${NEXUS_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Nexus Repository is not running at ${NEXUS_URL}${NC}"
        echo -e "${YELLOW}Please start Nexus first:${NC}"
        echo -e "${BLUE}  docker-compose -f docker-compose.staging.yml up -d nexus${NC}"
        return 1
    fi
}

# Function to wait for Nexus to be ready
wait_for_nexus() {
    echo -e "${BLUE}Waiting for Nexus Repository to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
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
    "writePolicy": "allow"
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
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/pypi/hosted" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI hosted repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist, attempting to update...${NC}"
        update_pypi_hosted_repository
    fi
}

# Function to update existing PyPI hosted repository to allow republishing
update_pypi_hosted_repository() {
    echo -e "${BLUE}Updating PyPI hosted repository: ${REPOSITORY_NAME} to allow republishing${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "${REPOSITORY_NAME}",
  "type": "hosted",
  "format": "pypi",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true,
    "writePolicy": "allow"
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
    
    if curl -s -f -X PUT \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/pypi/hosted/${REPOSITORY_NAME}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI hosted repository updated successfully to allow republishing${NC}"
    else
        echo -e "${RED}❌ Failed to update repository configuration${NC}"
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
      "userAgentSuffix": "PLOSolver-Nexus"
    }
  },
  "routingRuleName": "",
  "cleanup": {
    "policyNames": []
  }
}
EOF
)
    
    if curl -s -f -X POST \
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
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/pypi/group" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI group repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist or creation failed${NC}"
    fi
}

# Function to create NPM hosted repository
create_npm_hosted_repository() {
    echo -e "${BLUE}Creating NPM hosted repository: ${NPM_REPOSITORY_NAME}${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "${NPM_REPOSITORY_NAME}",
  "type": "hosted",
  "format": "npm",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true,
    "writePolicy": "allow"
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
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/npm/hosted" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM hosted repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist, attempting to update...${NC}"
        update_npm_hosted_repository
    fi
}

# Function to update existing NPM hosted repository to allow republishing
update_npm_hosted_repository() {
    echo -e "${BLUE}Updating NPM hosted repository: ${NPM_REPOSITORY_NAME} to allow republishing${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "${NPM_REPOSITORY_NAME}",
  "type": "hosted",
  "format": "npm",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true,
    "writePolicy": "allow"
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
    
    if curl -s -f -X PUT \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/npm/hosted/${NPM_REPOSITORY_NAME}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM hosted repository updated successfully to allow republishing${NC}"
    else
        echo -e "${RED}❌ Failed to update repository configuration${NC}"
    fi
}

# Function to create NPM proxy repository
create_npm_proxy_repository() {
    echo -e "${BLUE}Creating NPM proxy repository: npm-proxy${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "npm-proxy",
  "type": "proxy",
  "format": "npm",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "proxy": {
    "remoteUrl": "https://registry.npmjs.org/",
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
      "userAgentSuffix": "PLOSolver-Nexus"
    }
  },
  "routingRuleName": "",
  "cleanup": {
    "policyNames": []
  }
}
EOF
)
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/npm/proxy" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM proxy repository created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository may already exist or creation failed${NC}"
    fi
}

# Function to create NPM group repository
create_npm_group_repository() {
    echo -e "${BLUE}Creating NPM group repository: ${NPM_REPOSITORY_GROUP_NAME}${NC}"
    
    local repo_config=$(cat <<EOF
{
  "name": "${NPM_REPOSITORY_GROUP_NAME}",
  "type": "group",
  "format": "npm",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "group": {
    "memberNames": ["${NPM_REPOSITORY_NAME}", "npm-proxy"]
  }
}
EOF
)
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$repo_config" \
        "${NEXUS_URL}/service/rest/v1/repositories/npm/group" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM group repository created successfully${NC}"
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
    "nx-repository-admin-pypi-pypi-all-*"
    "nx-repository-view-pypi-pypi-internal-read",
    "nx-repository-view-pypi-*-*"
  ],
  "roles": []
}
EOF
)
    
    # Try to update (PUT) the role first; if it fails, attempt to create (POST)
    if curl -s -f -X PUT \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$role_config" \
        "${NEXUS_URL}/service/rest/v1/security/roles/pypi-publisher-with-read" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI publisher role updated successfully${NC}"
    else
        if curl -s -f -X POST \
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
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$user_config" \
        "${NEXUS_URL}/service/rest/v1/security/users" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI user created successfully${NC}"
        echo -e "${BLUE}Username: pypi-publisher${NC}"
    else
        echo -e "${YELLOW}⚠️  User may already exist or creation failed${NC}"
    fi
}

# Function to create NPM publisher role with proper permissions
create_npm_publisher_role() {
    echo -e "${BLUE}Creating/Updating NPM publisher role with proper permissions...${NC}"
    
    local role_config=$(cat <<EOF
{
  "id": "npm-publisher-with-read",
  "name": "NPM Publisher with Read",
  "description": "NPM publisher with admin on internal and read access",
  "privileges": [
    "nx-repository-admin-npm-npm-internal-*",
    "nx-repository-admin-npm-npm-all-*",
    "nx-repository-view-npm-npm-internal-read",
    "nx-repository-view-npm-*-*"
  ],
  "roles": []
}
EOF
)
    
    # Try to update (PUT) the role first; if it fails, attempt to create (POST)
    if curl -s -f -X PUT \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$role_config" \
        "${NEXUS_URL}/service/rest/v1/security/roles/npm-publisher-with-read" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM publisher role updated successfully${NC}"
    else
        if curl -s -f -X POST \
            -H "Content-Type: application/json" \
            -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
            -d "$role_config" \
            "${NEXUS_URL}/service/rest/v1/security/roles" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ NPM publisher role created successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Role create/update failed${NC}"
        fi
    fi
}

# Function to create NPM user for package publishing
create_npm_user() {
    echo -e "${BLUE}Creating NPM user for package publishing...${NC}"
    
    # First, ensure the role exists
    create_npm_publisher_role
    
    local user_config=$(cat <<EOF
{
  "userId": "npm-publisher",
  "firstName": "NPM",
  "lastName": "Publisher",
  "emailAddress": "npm@ploscope.com",
  "password": "${NEXUS_NPM_PASSWORD}",
  "status": "active",
  "roles": ["npm-publisher-with-read"]
}
EOF
)
    
    if curl -s -f -X POST \
        -H "Content-Type: application/json" \
        -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASSWORD}" \
        -d "$user_config" \
        "${NEXUS_URL}/service/rest/v1/security/users" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ NPM user created successfully${NC}"
        echo -e "${BLUE}Username: npm-publisher${NC}"
    else
        echo -e "${YELLOW}⚠️  User may already exist or creation failed${NC}"
    fi
}

# Function to generate configuration files
generate_config_files() {
    echo -e "${BLUE}Generating configuration files...${NC}"
    
    # Create .pypirc file
    cat > .pypirc <<EOF
[distutils]
index-servers =
    nexus

[nexus]
repository: ${NEXUS_URL}/repository/${REPOSITORY_NAME}/
username: pypi-publisher
password: ${NEXUS_PYPI_PASSWORD}
EOF
    
    # Create pip.conf file
    cat > pip.conf <<EOF
[global]
index = ${NEXUS_URL}/repository/${REPOSITORY_NAME}/pypi
index-url = ${NEXUS_URL}/repository/${REPOSITORY_NAME}/simple
trusted-host = $(echo $NEXUS_URL | sed 's|https?://||')

[search]
index = ${NEXUS_URL}/repository/${REPOSITORY_NAME}/pypi

[install]
index-url = ${NEXUS_URL}/repository/${REPOSITORY_NAME}/simple
trusted-host = $(echo $NEXUS_URL | sed 's|https?://||')
EOF
    
    # Create setup.cfg file for easy_install
    cat > setup.cfg <<EOF
[easy_install]
index-url = ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/simple
EOF
    
    # Create .npmrc file for npm registry
    cat > .npmrc <<EOF
registry=${NEXUS_URL}/repository/${NPM_REPOSITORY_GROUP_NAME}/
//$(echo $NEXUS_URL | sed 's|https?://||')/repository/${NPM_REPOSITORY_NAME}/:_authToken=\${NPM_TOKEN}
//$(echo $NEXUS_URL | sed 's|https?://||')/repository/${NPM_REPOSITORY_GROUP_NAME}/:_authToken=\${NPM_TOKEN}
always-auth=true
EOF
    
    echo -e "${GREEN}✅ Configuration files generated:${NC}"
    echo -e "${BLUE}  - .pypirc (for twine uploads)${NC}"
    echo -e "${BLUE}  - pip.conf (for pip installs)${NC}"
    echo -e "${BLUE}  - setup.cfg (for easy_install)${NC}"
    echo -e "${BLUE}  - .npmrc (for npm registry)${NC}"
}

# Function to display usage instructions
display_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Nexus Repository setup completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Usage Instructions:${NC}"
    echo ""
    echo -e "${YELLOW}1. Publishing PyPI packages:${NC}"
    echo -e "${BLUE}   twine upload --repository nexus dist/*${NC}"
    echo ""
    echo -e "${YELLOW}2. Publishing NPM packages:${NC}"
    echo -e "${BLUE}   npm publish --registry ${NEXUS_URL}/repository/${NPM_REPOSITORY_NAME}/${NC}"
    echo ""
    echo -e "${YELLOW}3. Installing PyPI packages:${NC}"
    echo -e "${BLUE}   pip install plosolver-core${NC}"
    echo ""
    echo -e "${YELLOW}4. Installing NPM packages:${NC}"
    echo -e "${BLUE}   npm install --registry ${NEXUS_URL}/repository/${NPM_REPOSITORY_GROUP_NAME}/${NC}"
    echo ""
    echo -e "${YELLOW}5. Repository URLs:${NC}"
    echo -e "${BLUE}   PyPI Hosted: ${NEXUS_URL}/repository/${REPOSITORY_NAME}/${NC}"
    echo -e "${BLUE}   PyPI Group: ${NEXUS_URL}/repository/${REPOSITORY_GROUP_NAME}/${NC}"
    echo -e "${BLUE}   PyPI Proxy: ${NEXUS_URL}/repository/pypi-proxy/${NC}"
    echo -e "${BLUE}   NPM Hosted: ${NEXUS_URL}/repository/${NPM_REPOSITORY_NAME}/${NC}"
    echo -e "${BLUE}   NPM Group: ${NEXUS_URL}/repository/${NPM_REPOSITORY_GROUP_NAME}/${NC}"
    echo -e "${BLUE}   NPM Proxy: ${NEXUS_URL}/repository/npm-proxy/${NC}"
    echo ""
    echo -e "${YELLOW}6. Web Interface:${NC}"
    echo -e "${BLUE}   ${NEXUS_URL}${NC}"
    echo -e "${BLUE}   Username: ${NEXUS_ADMIN_USER}${NC}"
    echo ""
    echo -e "${YELLOW}7. Publisher Credentials:${NC}"
    echo -e "${BLUE}   PyPI Username: pypi-publisher${NC}"
    echo -e "${BLUE}   NPM Username: npm-publisher${NC}"
    echo ""
    echo -e "${YELLOW}8. Management Commands:${NC}"
    echo -e "${BLUE}   Start: docker-compose -f docker-compose.staging.yml up -d nexus${NC}"
    echo -e "${BLUE}   Stop: docker-compose -f docker-compose.staging.yml stop nexus${NC}"
    echo -e "${BLUE}   Logs: docker-compose -f docker-compose.staging.yml logs -f nexus${NC}"
    echo ""
    echo -e "${YELLOW}9. Repository Configuration:${NC}"
    echo -e "${BLUE}   Update for republishing: ./setup-nexus.sh --update${NC}"
    echo -e "${BLUE}   The repository is configured to allow republishing the same version numbers${NC}"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🔧 Nexus Repository Isolated Setup${NC}"
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
    
    # Create PyPI repositories
    create_pypi_hosted_repository
    create_pypi_proxy_repository
    create_pypi_group_repository
    
    # Create NPM repositories
    create_npm_hosted_repository
    create_npm_proxy_repository
    create_npm_group_repository
    
    # Create users
    create_pypi_user
    create_npm_user
    
    # Generate configuration files
    generate_config_files
    
    # Display instructions
    display_instructions
}

# Function to update existing repository to allow republishing (standalone)
update_repository_for_republishing() {
    echo -e "${BLUE}🔧 Updating existing PyPI repository to allow republishing...${NC}"
    echo -e "${BLUE}URL: ${NEXUS_URL}${NC}"
    echo -e "${BLUE}Admin: ${NEXUS_ADMIN_USER}${NC}"
    echo ""
    
    # Check if Nexus is running
    if ! check_nexus_running; then
        exit 1
    fi
    
    # Update the repository
    update_pypi_hosted_repository
    
    echo ""
    echo -e "${GREEN}🎉 Repository update completed!${NC}"
    echo -e "${BLUE}The repository now allows republishing the same version numbers.${NC}"
}

# Check if script is called with --update flag
if [[ "$1" == "--update" ]]; then
    update_repository_for_republishing
    exit 0
fi

# Run main function
main "$@"
