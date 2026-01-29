#!/bin/bash

# Test script to verify favicon is working in staging environment
echo "Testing favicon in staging environment..."

# Get the staging domain from env file
STAGING_DOMAIN=$(grep "FRONTEND_DOMAIN" env.staging | cut -d'=' -f2)

if [ -z "$STAGING_DOMAIN" ]; then
    echo "Error: Could not find FRONTEND_DOMAIN in env.staging"
    exit 1
fi

echo "Testing favicon at: https://$STAGING_DOMAIN/favicon.svg"

# Test favicon with curl
echo "Testing favicon response..."
curl -I "https://$STAGING_DOMAIN/favicon.svg" 2>/dev/null | head -10

# Test if favicon returns 200 status
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$STAGING_DOMAIN/favicon.svg")
if [ "$STATUS" = "200" ]; then
    echo "✅ Favicon is working correctly (HTTP 200)"
else
    echo "❌ Favicon is not working (HTTP $STATUS)"
fi

# Test content type
CONTENT_TYPE=$(curl -s -I "https://$STAGING_DOMAIN/favicon.svg" | grep -i "content-type" | head -1)
echo "Content-Type: $CONTENT_TYPE"

echo "Testing main page..."
curl -I "https://$STAGING_DOMAIN/" 2>/dev/null | head -5 