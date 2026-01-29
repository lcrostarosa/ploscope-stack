#!/bin/bash

# Simple OpenVPN Certificate Fix Script
# This script manually copies certificates to the right place

set -e

echo "🔧 Simple OpenVPN certificate fix..."
echo "===================================="

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

echo "📦 Container: $CONTAINER_NAME"

# Extract certificates from Traefik
echo "📋 Extracting certificates from Traefik..."
docker exec "$CONTAINER_NAME" /scripts/cert-monitor.sh

# Check if certificates were extracted
echo "🔍 Checking if certificates were extracted..."
if docker exec "$CONTAINER_NAME" test -f /openvpn/etc/web-ssl/server.crt; then
    echo "✅ Certificate extracted successfully"
    
    # Check if certificate contains the full chain
    if docker exec "$CONTAINER_NAME" grep -q "-----BEGIN CERTIFICATE-----" /openvpn/etc/web-ssl/server.crt; then
        CERT_COUNT=$(docker exec "$CONTAINER_NAME" grep -c "-----BEGIN CERTIFICATE-----" /openvpn/etc/web-ssl/server.crt)
        echo "✅ Certificate contains $CERT_COUNT certificates (should be 2 for full chain)"
    else
        echo "❌ Certificate file is empty or invalid"
        exit 1
    fi
else
    echo "❌ Certificate extraction failed"
    exit 1
fi

# Restart OpenVPN to reload certificates
echo "🔄 Restarting OpenVPN to reload certificates..."
docker exec "$CONTAINER_NAME" pkill -HUP openvpnas || true

# Wait a moment for restart
sleep 5

echo ""
echo "🎯 OpenVPN certificate fix completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Access OpenVPN admin interface: https://vpn.ploscope.com:943"
echo "   2. Check the 'Web Server Configuration' page"
echo "   3. You should now see the Let's Encrypt certificate"
echo ""
echo "🔗 If you still see the self-signed certificate, try:"
echo "   docker-compose restart openvpn" 