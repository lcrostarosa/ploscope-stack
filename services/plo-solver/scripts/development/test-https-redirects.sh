#!/bin/bash

# Test HTTPS Redirects Script
# This script tests that HTTP requests are properly redirected to HTTPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing HTTPS Redirects...${NC}"

# Function to test redirect
test_redirect() {
    local url=$1
    local expected_redirect=$2
    local description=$3
    
    echo -n "Testing $description: "
    
    # Use curl to follow redirects and check the final URL
    response=$(curl -s -w "%{http_code}|%{redirect_url}" -o /dev/null "$url" 2>/dev/null || echo "000|")
    
    http_code=$(echo "$response" | cut -d'|' -f1)
    redirect_url=$(echo "$response" | cut -d'|' -f2)
    
    if [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        if [ "$redirect_url" = "$expected_redirect" ]; then
            echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code → $redirect_url)"
        else
            echo -e "${RED}✗ FAIL${NC} (Expected: $expected_redirect, Got: $redirect_url)"
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code, Expected: 301/302)"
    fi
}

# Test main domain redirects
echo -e "\n${YELLOW}Testing Main Domain Redirects:${NC}"
test_redirect "http://localhost" "https://localhost/" "Main site HTTP to HTTPS"
test_redirect "http://localhost/api/health" "https://localhost/api/health" "API endpoint HTTP to HTTPS"

# Test staging domain redirects (if configured)
if [ -n "$FRONTEND_DOMAIN" ] && [ "$FRONTEND_DOMAIN" != "localhost" ]; then
    echo -e "\n${YELLOW}Testing Staging Domain Redirects:${NC}"
    test_redirect "http://$FRONTEND_DOMAIN" "https://$FRONTEND_DOMAIN/" "Staging site HTTP to HTTPS"
    test_redirect "http://$FRONTEND_DOMAIN/api/health" "https://$FRONTEND_DOMAIN/api/health" "Staging API HTTP to HTTPS"
fi

# Test specific service redirects (if accessible)
echo -e "\n${YELLOW}Testing Service Redirects:${NC}"
test_redirect "http://vpn.ploscope.com" "https://vpn.ploscope.com/" "VPN service HTTP to HTTPS"
test_redirect "http://kibana.ploscope.com" "https://kibana.ploscope.com/" "Kibana service HTTP to HTTPS"
test_redirect "http://portainer.ploscope.com" "https://portainer.ploscope.com/" "Portainer service HTTP to HTTPS"
test_redirect "http://rabbitmq.ploscope.com" "https://rabbitmq.ploscope.com/" "RabbitMQ service HTTP to HTTPS"

# Test that ACME challenges are NOT redirected
echo -e "\n${YELLOW}Testing ACME Challenge Access (should NOT redirect):${NC}"
acme_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/.well-known/acme-challenge/test" 2>/dev/null || echo "000")
if [ "$acme_response" = "404" ]; then
    echo -e "${GREEN}✓ PASS${NC} (ACME challenge path accessible on HTTP)"
else
    echo -e "${YELLOW}⚠ WARNING${NC} (ACME challenge path returned HTTP $acme_response)"
fi

echo -e "\n${GREEN}HTTPS Redirect Testing Complete!${NC}"
echo -e "${YELLOW}Note: Some tests may fail if services are not running or domains are not configured.${NC}" 