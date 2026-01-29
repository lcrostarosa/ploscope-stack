#!/bin/bash

# OpenVPN Certificate Verification Script
# This script verifies the OpenVPN certificate and checks the certificate chain

set -e

echo "🔍 Verifying OpenVPN certificate..."
echo "==================================="

# Check if OpenVPN container is running
if ! docker ps | grep -q "plosolver-openvpn"; then
    echo "❌ OpenVPN container is not running"
    exit 1
fi

CONTAINER_NAME=$(docker ps --filter "name=plosolver-openvpn" --format "{{.Names}}")

echo "📦 Container: $CONTAINER_NAME"

# Check if certificate file exists
if docker exec "$CONTAINER_NAME" test -f /openvpn/etc/web-ssl/server.crt; then
    echo "✅ Certificate file exists"
else
    echo "❌ Certificate file not found"
    exit 1
fi

# Check certificate chain
echo "🔍 Checking certificate chain..."
CERT_COUNT=$(docker exec "$CONTAINER_NAME" grep -c "-----BEGIN CERTIFICATE-----" /openvpn/etc/web-ssl/server.crt)
echo "📊 Found $CERT_COUNT certificates in chain"

if [ "$CERT_COUNT" -ge 2 ]; then
    echo "✅ Full certificate chain detected"
else
    echo "⚠️  Incomplete certificate chain (should have 2+ certificates)"
fi

# Check certificate details
echo "🔍 Certificate details:"
docker exec "$CONTAINER_NAME" openssl x509 -in /openvpn/etc/web-ssl/server.crt -text -noout | grep -E "(Subject:|Issuer:|DNS:|Not After)" || echo "Could not read certificate details"

# Check if OpenVPN is using the certificate
echo "🔍 Checking OpenVPN configuration..."
CERT_PATH=$(docker exec "$CONTAINER_NAME" /usr/local/openvpn_as/scripts/confdba --get --key web.server.cert 2>/dev/null || echo "")
AUTO_CERT=$(docker exec "$CONTAINER_NAME" /usr/local/openvpn_as/scripts/confdba --get --key web.server.cert.auto 2>/dev/null || echo "")

echo "Certificate path: $CERT_PATH"
echo "Auto cert generation: $AUTO_CERT"

if [ "$AUTO_CERT" = "false" ]; then
    echo "✅ OpenVPN configured to use external certificates"
else
    echo "❌ OpenVPN still using auto-generated certificates"
fi

echo ""
echo "🎯 Certificate verification completed!" 