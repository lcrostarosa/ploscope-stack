#!/bin/bash

# Fix VPN routing configuration
# This script updates the OpenVPN configuration to enable full tunnel routing

echo "=== VPN Routing Fix ==="
echo "This script will fix VPN routing to enable internet access and service connectivity"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the PLOSolver root directory"
    exit 1
fi

echo "✅ Found docker-compose.yml"

# Show the changes made to the OpenVPN config
echo ""
echo "📝 OpenVPN Configuration Changes:"
echo "  - Enabled full tunnel routing (reroute_gw=true)"
echo "  - Enabled DNS routing through VPN (reroute_dns=true)"
echo "  - Added Google DNS servers (8.8.8.8, 8.8.4.4)"
echo ""

# Check if the config file was updated
if grep -q "reroute_gw=true" server/openvpn/as.conf; then
    echo "✅ OpenVPN configuration has been updated"
else
    echo "❌ OpenVPN configuration update failed"
    exit 1
fi

echo ""
echo "🚀 Deploying to staging environment..."

# Deploy to staging
if [ -f "scripts/deployment/deploy-staging.sh" ]; then
    echo "Running staging deployment..."
    ./scripts/deployment/deploy-staging.sh
else
    echo "⚠️  Staging deployment script not found"
    echo "Please deploy manually to staging:"
    echo "1. Copy the updated server/openvpn/as.conf to staging"
    echo "2. Restart the OpenVPN container on staging"
fi

echo ""
echo "📋 After deployment, test the VPN:"
echo "1. Connect to the VPN from a client"
echo "2. Test internet access: ping google.com"
echo "3. Test service access: curl https://kibana.ploscope.com"
echo "4. Check if you can access other internet sites"
echo ""
echo "🔧 If issues persist:"
echo "- Check OpenVPN logs: docker logs plosolver-openvpn-staging"
echo "- Verify DNS resolution: nslookup kibana.ploscope.com"
echo "- Test direct IP access if DNS fails" 