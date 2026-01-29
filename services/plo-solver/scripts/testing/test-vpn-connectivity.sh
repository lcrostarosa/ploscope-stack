#!/bin/bash

# Test VPN connectivity and routing
# This script helps verify that VPN clients can access services and internet

echo "=== VPN Connectivity Test ==="
echo ""

# Test internet connectivity
echo "🌐 Testing internet connectivity..."
if ping -c 1 google.com > /dev/null 2>&1; then
    echo "  ✅ Internet connectivity: OK"
else
    echo "  ❌ Internet connectivity: FAILED"
fi

# Test DNS resolution
echo ""
echo "🔍 Testing DNS resolution..."
if nslookup kibana.ploscope.com > /dev/null 2>&1; then
    echo "  ✅ DNS resolution for kibana.ploscope.com: OK"
    kibana_ip=$(nslookup kibana.ploscope.com | grep "Address:" | tail -1 | awk '{print $2}')
    echo "  📍 Resolved IP: $kibana_ip"
else
    echo "  ❌ DNS resolution for kibana.ploscope.com: FAILED"
fi

# Test service connectivity
echo ""
echo "🔗 Testing service connectivity..."

services=("kibana.ploscope.com" "portainer.ploscope.com" "rabbitmq.ploscope.com")

for service in "${services[@]}"; do
    echo "  Testing $service..."
    
    # Try HTTPS connection
    if curl -s -o /dev/null -w "%{http_code}" "https://$service" 2>/dev/null | grep -q "200\|403"; then
        echo "    ✅ HTTPS connection: OK"
    else
        echo "    ❌ HTTPS connection: FAILED"
    fi
    
    # Try HTTP connection (should redirect to HTTPS)
    if curl -s -o /dev/null -w "%{http_code}" "http://$service" 2>/dev/null | grep -q "301\|302\|200"; then
        echo "    ✅ HTTP connection: OK"
    else
        echo "    ❌ HTTP connection: FAILED"
    fi
done

echo ""
echo "📊 VPN Configuration Summary:"
echo "  - Full tunnel routing: ENABLED (reroute_gw=true)"
echo "  - DNS routing: ENABLED (reroute_dns=true)"
echo "  - DNS servers: 8.8.8.8, 8.8.4.4"
echo ""

echo "🔧 Troubleshooting steps if tests fail:"
echo "1. Check OpenVPN server logs: docker logs plosolver-openvpn-staging"
echo "2. Verify VPN client is connected and has correct IP"
echo "3. Test DNS manually: nslookup google.com"
echo "4. Check if VPN client can ping the server"
echo "5. Verify firewall rules allow VPN traffic" 