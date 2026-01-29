#!/bin/bash

# Test VPN whitelist configuration
# This script shows the current IP ranges allowed for VPN-only services

echo "=== VPN Whitelist Test ==="
echo ""

# Show current IP ranges in the whitelist
echo "Current IP ranges allowed for VPN-only services:"
echo ""

# Extract IP ranges from the dynamic.yml file
grep -A 10 "vpn-only:" server/traefik/dynamic.docker.yml | grep "sourceRange:" -A 10 | grep "^-" | while read line; do
    ip_range=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*"//' | sed 's/".*//')
    comment=$(echo "$line" | sed 's/.*#//')
    echo "  ✅ $ip_range - $comment"
done

echo ""
echo "Testing connectivity to VPN-only services:"
echo ""

# Test each service
services=("kibana.ploscope.com" "portainer.ploscope.com" "rabbitmq.ploscope.com")

for service in "${services[@]}"; do
    echo "Testing $service..."
    
    # Try to get the service (this will show if it's accessible)
    response=$(curl -s -o /dev/null -w "%{http_code}" "https://$service" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "  ✅ $service is accessible (HTTP $response)"
    elif [ "$response" = "403" ]; then
        echo "  ❌ $service returns 403 Forbidden (IP not in whitelist)"
    elif [ "$response" = "000" ]; then
        echo "  ⚠️  $service is not reachable (connection failed)"
    else
        echo "  ⚠️  $service returned HTTP $response"
    fi
done

echo ""
echo "To test from a VPN client:"
echo "1. Connect to your VPN"
echo "2. Try accessing: https://kibana.ploscope.com"
echo "3. If you get 403 Forbidden, your client IP is not in the whitelist"
echo "4. Check the Traefik logs to see the actual client IP"
echo ""
echo "To add a new IP range:"
echo "1. Edit server/traefik/dynamic.docker.yml"
echo "2. Add the IP range to the vpn-only middleware sourceRange list"
echo "3. Restart Traefik: docker-compose restart traefik" 