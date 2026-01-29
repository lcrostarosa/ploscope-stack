#!/bin/bash

# Debug VPN client IP addresses and connectivity
# This script helps identify what IP addresses VPN clients are using

echo "=== VPN Debug Script ==="
echo "This script will help identify VPN client IP addresses and test connectivity"
echo ""

# Check if Traefik is running
echo "1. Checking Traefik status..."
if docker ps | grep -q traefik; then
    echo "   ✓ Traefik is running"
else
    echo "   ✗ Traefik is not running"
    exit 1
fi

# Check OpenVPN container status
echo ""
echo "2. Checking OpenVPN container status..."
if docker ps | grep -q openvpn; then
    echo "   ✓ OpenVPN container is running"
    echo "   OpenVPN logs (last 10 lines):"
    docker logs plosolver-openvpn-development 2>&1 | tail -10
else
    echo "   ✗ OpenVPN container is not running"
    echo "   Attempting to start OpenVPN..."
    docker-compose up -d openvpn
fi

# Show current IP whitelist configuration
echo ""
echo "3. Current IP whitelist configuration in Traefik:"
echo "   The following IP ranges are allowed for VPN-only services:"
echo "   - 172.27.224.0/20 (OpenVPN Access Server default)"
echo "   - 172.18.0.0/16 (Docker network)"
echo "   - 10.8.0.0/24 (Alternative OpenVPN)"
echo "   - 192.168.255.0/24 (Common OpenVPN)"
echo "   - 174.201.20.0/24 (Observed in logs)"
echo "   - 10.0.0.0/8 (Common VPN subnets)"
echo "   - 172.16.0.0/12 (Additional VPN subnets)"
echo "   - 192.168.0.0/16 (Local network subnets)"

# Instructions for testing
echo ""
echo "4. Testing Instructions:"
echo "   a) Connect to your VPN from a client device"
echo "   b) Try to access: https://kibana.ploscope.com"
echo "   c) Check the browser's developer tools Network tab"
echo "   d) Look for the X-Real-IP and X-Forwarded-For headers"
echo "   e) Note the IP address being used"
echo ""
echo "   If you see a 403 Forbidden error, the client IP is not in the whitelist"
echo "   If you can access the service, the IP is correctly whitelisted"

# Show Traefik logs for recent requests
echo ""
echo "5. Recent Traefik access logs (last 20 lines):"
docker logs plosolver-traefik-development 2>&1 | grep -E "(kibana|portainer|rabbitmq)" | tail -20

echo ""
echo "6. To add a new IP range to the whitelist:"
echo "   Edit PLOSolver/server/traefik/dynamic.docker.yml"
echo "   Add the IP range to the vpn-only middleware sourceRange list"
echo "   Restart Traefik: docker-compose restart traefik"

echo ""
echo "=== Debug complete ===" 