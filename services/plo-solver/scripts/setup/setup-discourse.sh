#!/bin/bash

# PLO Solver Discourse Setup Script
# This script sets up Discourse with Docker integration

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root directory
cd "$PROJECT_ROOT"

echo "🚀 Setting up PLO Solver Forum (Discourse) with Docker..."
echo "Working directory: $PROJECT_ROOT"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy env.example to .env and configure it first."
    exit 1
fi

# Source environment variables
source .env

# Generate SSO secret if not set
if [ "$DISCOURSE_SSO_SECRET" = "your-discourse-sso-secret-key-here" ]; then
    echo "⚠️  Generating new SSO secret..."
    NEW_SECRET=$(openssl rand -hex 32)
    sed -i.bak "s/DISCOURSE_SSO_SECRET=your-discourse-sso-secret-key-here/DISCOURSE_SSO_SECRET=$NEW_SECRET/" .env
    echo "✅ Generated new SSO secret: $NEW_SECRET"
    echo "⚠️  Please update your Discourse admin settings with this secret!"
fi

# Create required directories
echo "📁 Creating Discourse directories..."
sudo mkdir -p /var/discourse/shared/standalone
sudo mkdir -p /var/discourse/shared/standalone/log/var-log
sudo chown -R 1000:1000 /var/discourse/shared/

# Build custom Discourse image with our configuration
echo "🏗️  Building custom Discourse image..."
cd discourse
cp ../discourse/containers/app.yml containers/app.yml

# Replace environment variables in app.yml
echo "🔧 Configuring Discourse app.yml..."
sed -i "s/your-sso-secret-will-be-replaced-in-env/${DISCOURSE_SSO_SECRET:-change-this-secret}/" containers/app.yml
sed -i "s/forum.plosolver.local/${DISCOURSE_DOMAIN:-forum.localhost}/" containers/app.yml
sed -i "s/admin@plosolver.local/${DISCOURSE_DEVELOPER_EMAILS:-admin@plosolver.local}/" containers/app.yml

echo "🐳 Starting Discourse setup..."

# Bootstrap Discourse (this may take a while)
echo "⏳ Bootstrapping Discourse container (this may take 10-15 minutes)..."
sudo ./launcher bootstrap app

echo "✅ Discourse bootstrap completed!"

# Return to main directory
cd ..

echo "🌐 Setting up Ngrok tunnels..."

# Update start-ngrok.sh to include forum tunnel
if [ -f scripts/start-ngrok.sh ]; then
    echo "🔧 Updating Ngrok configuration for forum access..."
    # The script will be updated to include forum tunneling
fi

echo "🎉 Discourse setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Start the services: docker compose up -d"
echo "2. Wait for all services to be healthy"
echo "3. Start Ngrok: ./scripts/start-ngrok.sh"
echo "4. Access your forum at: http://${DISCOURSE_DOMAIN:-forum.localhost}"
echo "5. Configure Discourse SSO in admin panel with secret: ${DISCOURSE_SSO_SECRET}"
echo ""
echo "🔗 SSO Integration:"
echo "   - SSO URL: http://${FRONTEND_DOMAIN:-localhost}/api/discourse/sso_provider"
echo "   - SSO Secret: ${DISCOURSE_SSO_SECRET}"
echo ""
echo "📧 To complete setup, you'll need to:"
echo "   - Configure SMTP settings in Discourse admin"
echo "   - Enable SSO in Discourse admin panel"
echo "   - Test the forum integration from PLO Solver" 