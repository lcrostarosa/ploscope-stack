#!/bin/bash

# New Relic Setup Script for PLOSolver
# This script helps you configure New Relic monitoring

echo "🔍 New Relic Setup for PLOSolver"
echo "================================="
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from example..."
    cp env.example .env
fi

echo "Please provide your New Relic configuration:"
echo ""

# Get New Relic License Key
read -p "Enter your New Relic License Key: " NR_LICENSE_KEY
if [ -z "$NR_LICENSE_KEY" ]; then
    echo "❌ License key is required. Exiting."
    exit 1
fi

# Get environment
echo ""
echo "Select environment:"
echo "1) development"
echo "2) production"
echo "3) staging"
read -p "Choose (1-3): " ENV_CHOICE

case $ENV_CHOICE in
    1) NR_ENVIRONMENT="development" ;;
    2) NR_ENVIRONMENT="production" ;;
    3) NR_ENVIRONMENT="staging" ;;
    *) NR_ENVIRONMENT="development" ;;
esac

# Get frontend monitoring details
echo ""
echo "For frontend browser monitoring, you'll need:"
echo "1. Application ID"
echo "2. Account ID" 
echo "3. Trust Key"
echo ""
echo "You can find these in your New Relic Browser app settings."
echo ""

read -p "Enter your New Relic Application ID (optional, press enter to skip): " NR_APP_ID
read -p "Enter your New Relic Account ID (optional, press enter to skip): " NR_ACCOUNT_ID
read -p "Enter your New Relic Trust Key (optional, press enter to skip): " NR_TRUST_KEY

# Update .env file
echo ""
echo "Updating .env file..."

# Remove existing New Relic entries
sed -i.bak '/NEW_RELIC_/d' .env
sed -i.bak '/REACT_APP_NEW_RELIC_/d' .env

# Add New Relic configuration
echo "" >> .env
echo "# New Relic Configuration" >> .env
echo "NEW_RELIC_LICENSE_KEY=$NR_LICENSE_KEY" >> .env
echo "NEW_RELIC_ENVIRONMENT=$NR_ENVIRONMENT" >> .env

if [ ! -z "$NR_LICENSE_KEY" ]; then
    echo "REACT_APP_NEW_RELIC_LICENSE_KEY=$NR_LICENSE_KEY" >> .env
fi

if [ ! -z "$NR_APP_ID" ]; then
    echo "REACT_APP_NEW_RELIC_APPLICATION_ID=$NR_APP_ID" >> .env
fi

if [ ! -z "$NR_ACCOUNT_ID" ]; then
    echo "REACT_APP_NEW_RELIC_ACCOUNT_ID=$NR_ACCOUNT_ID" >> .env
fi

if [ ! -z "$NR_TRUST_KEY" ]; then
    echo "REACT_APP_NEW_RELIC_TRUST_KEY=$NR_TRUST_KEY" >> .env
fi

echo ""
echo "✅ New Relic configuration added to .env file!"
echo ""

# Install dependencies
echo "Installing New Relic dependencies..."
echo ""

# Backend dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Frontend dependencies  
echo "📦 Installing Node.js dependencies..."
cd src/frontend && npm install && cd ../..

echo ""
echo "🎉 New Relic setup complete!"
echo ""
echo "Next steps:"
echo "1. Start your application: docker compose up"
echo "2. Check your New Relic dashboard for incoming data"
echo "3. Review the setup guide: docs/NEW_RELIC_SETUP.md"
echo ""
echo "If you need to update browser monitoring settings later,"
echo "you can find them in your New Relic Browser app settings."
echo ""

# Check if Docker is running
if command -v docker &> /dev/null && docker info &> /dev/null; then
    read -p "Would you like to start the application now? (y/n): " START_APP
    if [ "$START_APP" = "y" ] || [ "$START_APP" = "Y" ]; then
        echo ""
        echo "Starting PLOSolver with New Relic monitoring..."
        docker compose up -d
        echo ""
        echo "Application started! Check:"
        echo "- App: http://localhost"
        echo "- New Relic dashboard for monitoring data"
    fi
else
    echo "Docker not found or not running. Start manually with: docker compose up"
fi 