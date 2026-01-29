#!/bin/bash

# OpenVPN Access Server Setup Script for PLOSolver
# This script helps configure OpenVPN Access Server after initial deployment

set -e

echo "🔧 Setting up OpenVPN Access Server for PLOSolver..."

# Check if OpenVPN container is running
if ! docker ps | grep -q "plosolver-openvpn"; then
    echo "❌ OpenVPN container is not running. Please start the services first:"
    echo "   docker-compose up -d openvpn"
    exit 1
fi

echo "✅ OpenVPN container is running"

# Get container name
CONTAINER_NAME=$(docker ps --filter "name=plosolver-openvpn" --format "{{.Names}}")

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ Could not find OpenVPN container"
    exit 1
fi

echo "📋 Container name: $CONTAINER_NAME"

# Wait for OpenVPN Access Server to be ready
echo "⏳ Waiting for OpenVPN Access Server to be ready..."
sleep 30

# Check if OpenVPN Access Server is responding
if ! docker exec "$CONTAINER_NAME" curl -f http://localhost:943/ > /dev/null 2>&1; then
    echo "⚠️  OpenVPN Access Server web interface not ready yet. Please wait a few more minutes."
    echo "   You can check the logs with: docker logs $CONTAINER_NAME"
    exit 1
fi

echo "✅ OpenVPN Access Server is ready!"

echo ""
echo "🌐 Access OpenVPN Access Server at: https://vpn.ploscope.com"
echo ""
echo "📋 Next steps:"
echo "1. Visit https://vpn.ploscope.com"
echo "2. Log in with the default credentials"
echo "3. Change the admin password"
echo "4. Configure your VPN settings"
echo "5. Download the client configuration for your devices"
echo ""
echo "🔗 For client downloads, visit: https://vpn.ploscope.com/"
echo "📱 Mobile clients can download from: https://vpn.ploscope.com/connect/"
echo ""
echo "⚠️  Remember to update the VPN_PASSWORD environment variable after changing the password" 