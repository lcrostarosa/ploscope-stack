#!/bin/bash

# Generate Test Certificate Script
# This script helps generate a test certificate in Traefik to see the ACME storage structure

set -e

echo "🔧 Generating test certificate in Traefik..."
echo "==========================================="

# Check if Traefik container is running
if ! docker ps | grep -q "plosolver-traefik"; then
    echo "❌ Traefik container is not running"
    exit 1
fi

echo "✅ Traefik container is running"

# Check if we have a domain configured
if [ -z "$ACME_EMAIL" ]; then
    echo "⚠️  ACME_EMAIL not set. Please set it in your environment:"
    echo "   export ACME_EMAIL=your-email@example.com"
    exit 1
fi

echo "📧 ACME Email: $ACME_EMAIL"

# Check if we have a test domain
TEST_DOMAIN="${TEST_DOMAIN:-test.ploscope.com}"
echo "🌐 Test Domain: $TEST_DOMAIN"

echo ""
echo "📋 To generate a test certificate:"
echo "   1. Make sure $TEST_DOMAIN points to your server"
echo "   2. Run: docker-compose restart traefik"
echo "   3. Check the certificate generation:"
echo "      docker-compose logs traefik | grep -i cert"
echo ""
echo "🔍 After certificate generation, check the structure:"
echo "   ./scripts/operations/check-acme-storage.sh"
echo ""
echo "🎯 This will help us see the proper ca_bundle structure" 