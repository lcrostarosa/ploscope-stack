#!/bin/bash

# Check ACME Storage Script
# This script examines what certificate data is available in Traefik's ACME storage

set -e

echo "🔍 Checking Traefik ACME storage..."
echo "===================================="

# Check if Traefik container is running
if ! docker ps | grep -q "plosolver-traefik"; then
    echo "❌ Traefik container is not running"
    exit 1
fi

echo "✅ Traefik container is running"

# Check if ACME file exists
if docker exec plosolver-traefik test -f /etc/certs/acme.json; then
    echo "✅ ACME storage file exists"
else
    echo "❌ ACME storage file not found"
    exit 1
fi

# Get ACME file size
ACME_SIZE=$(docker exec plosolver-traefik stat -c%s /etc/certs/acme.json)
echo "📊 ACME file size: $ACME_SIZE bytes"

# Check if ACME file has content
if [ "$ACME_SIZE" -gt 0 ]; then
    echo "✅ ACME file has content"
else
    echo "❌ ACME file is empty"
    exit 1
fi

# Extract and display certificate information
echo "🔍 Certificate information from ACME storage:"
echo "=============================================="

# Use jq to extract certificate information
docker exec plosolver-traefik sh -c '
if [ ! -f /etc/certs/acme.json ]; then
    echo "❌ ACME file not found"
    exit 1
fi

# Count certificates
cert_count=$(jq ".letsencrypt.Certificates | length" /etc/certs/acme.json 2>/dev/null || echo "0")
echo "Found $cert_count certificates"

# Extract certificate details
jq -r ".letsencrypt.Certificates[]? | {
    domain: .domain.main,
    sans: (.domain.sans // []),
    fields: (keys | join(\", \")),
    has_certificate_chain: (.certificate_chain != null),
    has_issuer_certificate: (.issuer_certificate != null),
    has_ca_bundle: (.ca_bundle != null)
} | \"Certificate: \" + .domain + \"\\n  SANs: \" + (.sans | join(\", \")) + \"\\n  Available fields: \" + .fields + \"\\n  Has certificate_chain: \" + .has_certificate_chain + \"\\n  Has issuer_certificate: \" + .has_issuer_certificate + \"\\n  Has ca_bundle: \" + .has_ca_bundle + \"\\n\"" /etc/certs/acme.json 2>/dev/null || echo "No certificates found or error parsing JSON"
'

echo ""
echo "🎯 ACME storage check completed!" 