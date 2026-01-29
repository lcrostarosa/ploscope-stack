#!/bin/bash

# Deploy Redis to staging environment
# This script updates the staging environment to include Redis

set -e

echo "🚀 Deploying Redis to staging environment..."

# Check if we're in the right directory
if [ ! -f "docker-compose.staging.yml" ]; then
    echo "❌ Error: docker-compose.staging.yml not found. Please run this script from the project root."
    exit 1
fi

# Check if env.staging exists
if [ ! -f "env.staging" ]; then
    echo "❌ Error: env.staging not found. Please ensure the environment file exists."
    exit 1
fi

echo "✅ Configuration files found"

# Copy updated files to staging server
echo "📋 Copying updated configuration files..."

# You'll need to update these paths based on your staging server setup
STAGING_SERVER="your-staging-server"
STAGING_PATH="/path/to/staging"

# Copy the updated files
scp docker-compose.staging.yml ${STAGING_SERVER}:${STAGING_PATH}/
scp env.staging ${STAGING_SERVER}:${STAGING_PATH}/

echo "✅ Files copied to staging server"

# Deploy using Ansible (if you have Ansible set up)
echo "🔧 Deploying with Ansible..."
cd server/ansible

# Run the deployment playbook
ansible-playbook -i inventories/inventory.yml playbooks/03_deploy/01_deploy.yml \
    --extra-vars "target=staging" \
    --tags "deploy"

echo "✅ Redis deployment completed!"

echo ""
echo "📊 Next steps:"
echo "1. Check the staging environment logs:"
echo "   docker compose -f docker-compose.staging.yml logs redis"
echo ""
echo "2. Verify Redis is working:"
echo "   docker compose -f docker-compose.staging.yml exec redis redis-cli ping"
echo ""
echo "3. Check backend logs for Redis connection:"
echo "   docker compose -f docker-compose.staging.yml logs backend"
echo ""
echo "4. Test rate limiting functionality in your application"
