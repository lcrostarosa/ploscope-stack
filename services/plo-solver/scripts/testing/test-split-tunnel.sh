#!/bin/bash

# Test script for split tunnel VPN configuration
# This script verifies that ploscope domains route through VPN while other traffic uses client's internet

echo "=== Split Tunnel VPN Configuration Test ==="
echo "This script will test that:"
echo "1. ploscope.com domains route through VPN"
echo "2. Other internet traffic uses client's internet connection"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the PLOSolver root directory"
    exit 1
fi

echo "✅ Found docker-compose.yml"

# Function to test DNS resolution
test_dns_resolution() {
    local domain=$1
    local expected_description=$2
    
    echo "Testing DNS resolution for $domain..."
    if nslookup $domain > /dev/null 2>&1; then
        local resolved_ip=$(nslookup $domain | grep "Address:" | tail -1 | awk '{print $2}')
        echo "  ✅ $domain resolves to: $resolved_ip ($expected_description)"
        return 0
    else
        echo "  ❌ DNS resolution failed for $domain"
        return 1
    fi
}

# Function to test HTTP connectivity
test_http_connectivity() {
    local url=$1
    local expected_description=$2
    
    echo "Testing HTTP connectivity to $url..."
    if curl -f -s -m 10 --connect-timeout 5 "$url" > /dev/null 2>&1; then
        echo "  ✅ HTTP connectivity to $url: OK ($expected_description)"
        return 0
    else
        echo "  ❌ HTTP connectivity to $url: FAILED"
        return 1
    fi
}

# Function to check routing
check_routing() {
    local destination=$1
    local expected_route=$2
    
    echo "Checking routing for $destination..."
    if command -v ip >/dev/null 2>&1; then
        route_info=$(ip route get $destination 2>/dev/null | head -1)
        echo "  📍 Route to $destination: $route_info"
        
        if echo "$route_info" | grep -q "$expected_route"; then
            echo "  ✅ Routing through expected interface: $expected_route"
            return 0
        else
            echo "  ⚠️  Routing may not be through expected interface"
            return 1
        fi
    else
        echo "  ⚠️  'ip' command not available, skipping route check"
        return 1
    fi
}

echo ""
echo "🔍 Testing ploscope.com domains (should route through VPN)..."
echo "================================================="

# Test ploscope domains
ploscope_domains=(
    "ploscope.com"
    "kibana.ploscope.com"
    "portainer.ploscope.com"
    "rabbitmq.ploscope.com"
    "traefik.ploscope.com"
    "vpn.ploscope.com"
)

ploscope_success=0
ploscope_total=${#ploscope_domains[@]}

for domain in "${ploscope_domains[@]}"; do
    if test_dns_resolution "$domain" "ploscope service"; then
        ((ploscope_success++))
    fi
done

echo ""
echo "🌐 Testing external domains (should use client's internet)..."
echo "========================================================="

# Test external domains
external_domains=(
    "google.com"
    "github.com"
    "stackoverflow.com"
)

external_success=0
external_total=${#external_domains[@]}

for domain in "${external_domains[@]}"; do
    if test_dns_resolution "$domain" "external service"; then
        ((external_success++))
    fi
done

echo ""
echo "🔗 Testing HTTP connectivity..."
echo "=============================="

# Test HTTP connectivity to ploscope services
echo "Testing ploscope services (through VPN):"
ploscope_urls=(
    "https://ploscope.com"
    "https://kibana.ploscope.com"
    "https://portainer.ploscope.com"
    "https://rabbitmq.ploscope.com"
)

ploscope_http_success=0
ploscope_http_total=${#ploscope_urls[@]}

for url in "${ploscope_urls[@]}"; do
    if test_http_connectivity "$url" "ploscope service"; then
        ((ploscope_http_success++))
    fi
done

echo ""
echo "Testing external services (through client's internet):"
external_urls=(
    "https://google.com"
    "https://github.com"
    "https://httpbin.org/ip"
)

external_http_success=0
external_http_total=${#external_urls[@]}

for url in "${external_urls[@]}"; do
    if test_http_connectivity "$url" "external service"; then
        ((external_http_success++))
    fi
done

echo ""
echo "📋 Split Tunnel Configuration Test Results:"
echo "==========================================="
echo "✅ Ploscope DNS resolution: $ploscope_success/$ploscope_total"
echo "✅ External DNS resolution: $external_success/$external_total"
echo "✅ Ploscope HTTP connectivity: $ploscope_http_success/$ploscope_http_total"
echo "✅ External HTTP connectivity: $external_http_success/$external_http_total"

total_success=$((ploscope_success + external_success + ploscope_http_success + external_http_success))
total_tests=$((ploscope_total + external_total + ploscope_http_total + external_http_total))

echo ""
echo "📊 Overall Test Results: $total_success/$total_tests tests passed"

if [ $total_success -eq $total_tests ]; then
    echo "🎉 Split tunnel configuration is working correctly!"
    echo ""
    echo "✅ Configuration Summary:"
    echo "  - ploscope.com domains route through VPN"
    echo "  - External domains use client's internet connection"
    echo "  - DNS resolution works for both types of domains"
    echo "  - HTTP connectivity works for both types of services"
    exit 0
else
    echo "⚠️  Some tests failed. Please check the configuration."
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "1. Ensure you're connected to the VPN"
    echo "2. Check OpenVPN logs: docker logs plosolver-openvpn-staging"
    echo "3. Verify DNS configuration on your client"
    echo "4. Test routing with: ip route"
    echo "5. Check firewall rules if connectivity issues persist"
    exit 1
fi