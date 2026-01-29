#!/bin/bash

# Migration Script: GitHub Packages to Nexus Repository
# This script helps migrate from GitHub Packages to Nexus Repository for PyPI packages

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Migrating from GitHub Packages to Nexus Repository...${NC}"
echo ""

# Function to check if Nexus is running
check_nexus() {
    echo -e "${BLUE}Checking Nexus Repository status...${NC}"
    if curl -s -f "http://localhost:8081/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Nexus Repository is not running${NC}"
        echo -e "${YELLOW}Please start Nexus first: make nexus-start${NC}"
        return 1
    fi
}

# Function to backup current configuration
backup_config() {
    echo -e "${BLUE}Creating backup of current configuration...${NC}"
    
    # Create backup directory
    mkdir -p backups/$(date +%Y%m%d_%H%M%S)
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    # Backup requirements files
    if [ -f "src/celery/requirements.txt" ]; then
        cp src/celery/requirements.txt "$backup_dir/celery-requirements.txt.bak"
    fi
    
    if [ -f "src/backend/requirements.txt" ]; then
        cp src/backend/requirements.txt "$backup_dir/backend-requirements.txt.bak"
    fi
    
    # Backup pip configuration
    if [ -f "$HOME/.pip/pip.conf" ]; then
        cp "$HOME/.pip/pip.conf" "$backup_dir/pip.conf.bak"
    fi
    
    if [ -f "$HOME/.config/pip/pip.conf" ]; then
        cp "$HOME/.config/pip/pip.conf" "$backup_dir/pip.conf.bak"
    fi
    
    # Backup .pypirc
    if [ -f ".pypirc" ]; then
        cp .pypirc "$backup_dir/pypirc.bak"
    fi
    
    echo -e "${GREEN}✅ Backup created in $backup_dir${NC}"
}

# Function to update requirements files
update_requirements() {
    echo -e "${BLUE}Updating requirements files...${NC}"
    
    # Update celery requirements
    if [ -f "src/celery/requirements.txt" ]; then
        echo -e "${BLUE}Updating src/celery/requirements.txt${NC}"
        sed -i.bak 's|git+https://github.com/PLOScope/plo-solver.git@v[0-9.]*#egg=plosolver-core&subdirectory=src/plosolver_core|plosolver-core>=1.0.0|' src/celery/requirements.txt
        echo -e "${GREEN}✅ Updated celery requirements${NC}"
    fi
    
    # Update backend requirements if it exists
    if [ -f "src/backend/requirements.txt" ]; then
        echo -e "${BLUE}Updating src/backend/requirements.txt${NC}"
        sed -i.bak 's|git+https://github.com/PLOScope/plo-solver.git@v[0-9.]*#egg=plosolver-core&subdirectory=src/plosolver_core|plosolver-core>=1.0.0|' src/backend/requirements.txt
        echo -e "${GREEN}✅ Updated backend requirements${NC}"
    fi
    
    # Add comments about Nexus configuration
    echo "" >> src/celery/requirements.txt
    echo "# Configure pip for Nexus Repository:" >> src/celery/requirements.txt
    echo "# pip config set global.index-url http://localhost:8081/repository/pypi-all/simple" >> src/celery/requirements.txt
    echo "# pip config set global.trusted-host localhost" >> src/celery/requirements.txt
}

# Function to configure pip for Nexus
configure_pip() {
    echo -e "${BLUE}Configuring pip for Nexus Repository...${NC}"
    
    # Create pip config directory if it doesn't exist
    mkdir -p "$HOME/.config/pip"
    
    # Create pip.conf
    cat > "$HOME/.config/pip/pip.conf" <<EOF
[global]
index = http://localhost:8081/repository/pypi-all/pypi
index-url = http://localhost:8081/repository/pypi-all/simple
trusted-host = localhost
EOF
    
    echo -e "${GREEN}✅ Pip configured for Nexus Repository${NC}"
}

# Function to create .pypirc for publishing
create_pypirc() {
    echo -e "${BLUE}Creating .pypirc for package publishing...${NC}"
    
    cat > .pypirc <<EOF
[distutils]
index-servers =
    nexus

[nexus]
repository: http://localhost:8081/repository/pypi-internal/
username: pypi-publisher
password: ${NEXUS_PYPI_PASSWORD}
EOF
    
    echo -e "${GREEN}✅ .pypirc created for Nexus publishing${NC}"
}

# Function to test Nexus connectivity
test_nexus() {
    echo -e "${BLUE}Testing Nexus Repository connectivity...${NC}"
    
    # Test basic connectivity
    if curl -s -f "http://localhost:8081/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nexus Repository is accessible${NC}"
    else
        echo -e "${RED}❌ Cannot access Nexus Repository${NC}"
        return 1
    fi
    
    # Test repository access
    if curl -s -f "http://localhost:8081/repository/pypi-all/simple/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PyPI group repository is accessible${NC}"
    else
        echo -e "${RED}❌ Cannot access PyPI group repository${NC}"
        return 1
    fi
    
    # Test authentication
    if curl -s -f -u "pypi-publisher:${NEXUS_PYPI_PASSWORD}" "http://localhost:8081/service/rest/v1/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Authentication works${NC}"
    else
        echo -e "${RED}❌ Authentication failed${NC}"
        return 1
    fi
}

# Function to build and publish test package
test_publishing() {
    echo -e "${BLUE}Testing package publishing...${NC}"
    
    # Check if plosolver_core directory exists
    if [ ! -d "src/plosolver_core" ]; then
        echo -e "${RED}❌ src/plosolver_core directory not found${NC}"
        return 1
    fi
    
    # Build package
    echo -e "${BLUE}Building package...${NC}"
    cd src/plosolver_core
    python -m build
    
    # Publish to Nexus
    echo -e "${BLUE}Publishing to Nexus Repository...${NC}"
    twine upload --repository nexus dist/*
    
    cd ../..
    echo -e "${GREEN}✅ Package published successfully${NC}"
}

# Function to test package installation
test_installation() {
    echo -e "${BLUE}Testing package installation...${NC}"
    
    # Install package from Nexus
    pip install plosolver-core --force-reinstall
    
    # Test import
    python -c "import plosolver_core; print('✅ Package imported successfully')"
    
    echo -e "${GREEN}✅ Package installation test passed${NC}"
}

# Function to display migration summary
display_summary() {
    echo ""
    echo -e "${GREEN}🎉 Migration to Nexus Repository completed!${NC}"
    echo ""
    echo -e "${BLUE}📋 Migration Summary:${NC}"
    echo ""
    echo -e "${YELLOW}✅ What was done:${NC}"
    echo -e "${BLUE}  - Created backup of current configuration${NC}"
    echo -e "${BLUE}  - Updated requirements.txt files${NC}"
    echo -e "${BLUE}  - Configured pip for Nexus Repository${NC}"
    echo -e "${BLUE}  - Created .pypirc for publishing${NC}"
    echo -e "${BLUE}  - Tested connectivity and publishing${NC}"
    echo ""
    echo -e "${YELLOW}📁 Files created/modified:${NC}"
    echo -e "${BLUE}  - $HOME/.config/pip/pip.conf${NC}"
    echo -e "${BLUE}  - .pypirc${NC}"
    echo -e "${BLUE}  - src/celery/requirements.txt${NC}"
    echo -e "${BLUE}  - src/backend/requirements.txt (if exists)${NC}"
    echo ""
    echo -e "${YELLOW}🚀 Next steps:${NC}"
    echo -e "${BLUE}  1. Update CI/CD pipelines to use Nexus${NC}"
    echo -e "${BLUE}  2. Add Nexus secrets to GitHub repository${NC}"
    echo -e "${BLUE}  3. Test automated publishing workflow${NC}"
    echo -e "${BLUE}  4. Update documentation for team members${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Useful commands:${NC}"
    echo -e "${BLUE}  make nexus-start          # Start Nexus Repository${NC}"
    echo -e "${BLUE}  make nexus-publish-local  # Publish package locally${NC}"
    echo -e "${BLUE}  make nexus-install        # Install from Nexus${NC}"
    echo -e "${BLUE}  make publish-package      # Publish via GitHub Actions${NC}"
    echo ""
    echo -e "${YELLOW}🌐 Web Interface:${NC}"
    echo -e "${BLUE}  http://localhost:8081${NC}"
    echo -e "${BLUE}  Username: admin${NC}"
    echo -e "${BLUE}  Password: admin123${NC}"
    echo ""
}

# Function to rollback changes
rollback() {
    echo -e "${YELLOW}🔄 Rolling back changes...${NC}"
    
    # Find latest backup
    local latest_backup=$(ls -t backups/ | head -1)
    
    if [ -z "$latest_backup" ]; then
        echo -e "${RED}❌ No backup found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Restoring from backup: $latest_backup${NC}"
    
    # Restore requirements files
    if [ -f "backups/$latest_backup/celery-requirements.txt.bak" ]; then
        cp "backups/$latest_backup/celery-requirements.txt.bak" "src/celery/requirements.txt"
    fi
    
    if [ -f "backups/$latest_backup/backend-requirements.txt.bak" ]; then
        cp "backups/$latest_backup/backend-requirements.txt.bak" "src/backend/requirements.txt"
    fi
    
    # Restore pip configuration
    if [ -f "backups/$latest_backup/pip.conf.bak" ]; then
        cp "backups/$latest_backup/pip.conf.bak" "$HOME/.config/pip/pip.conf"
    fi
    
    # Restore .pypirc
    if [ -f "backups/$latest_backup/pypirc.bak" ]; then
        cp "backups/$latest_backup/pypirc.bak" ".pypirc"
    fi
    
    echo -e "${GREEN}✅ Rollback completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🔄 GitHub Packages to Nexus Repository Migration${NC}"
    echo ""
    
    # Check if Nexus is running
    if ! check_nexus; then
        exit 1
    fi
    
    # Create backup
    backup_config
    
    # Update requirements files
    update_requirements
    
    # Configure pip
    configure_pip
    
    # Create .pypirc
    create_pypirc
    
    # Test connectivity
    if ! test_nexus; then
        echo -e "${RED}❌ Nexus connectivity test failed${NC}"
        echo -e "${YELLOW}Run 'make nexus-setup' to configure repositories${NC}"
        exit 1
    fi
    
    # Test publishing
    if ! test_publishing; then
        echo -e "${RED}❌ Publishing test failed${NC}"
        exit 1
    fi
    
    # Test installation
    if ! test_installation; then
        echo -e "${RED}❌ Installation test failed${NC}"
        exit 1
    fi
    
    # Display summary
    display_summary
}

# Handle command line arguments
case "${1:-}" in
    "rollback")
        rollback
        ;;
    "test")
        test_nexus
        test_publishing
        test_installation
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Run full migration"
        echo "  rollback   - Rollback to previous configuration"
        echo "  test       - Test Nexus connectivity and publishing"
        echo "  help       - Show this help message"
        ;;
    *)
        main
        ;;
esac
