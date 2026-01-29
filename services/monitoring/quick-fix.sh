#!/bin/bash
# Quick fix for staging monitoring issues

set -e

echo "=========================================="
echo "🔧 Quick Fix for Staging Monitoring"
echo "=========================================="
echo ""

# 1. Check current environment
echo "1️⃣  Checking current environment..."
echo "----------------------------------------"
echo "Environment file content:"
grep -E "PRODUCTION_.*URL" env.staging

echo ""
echo "Grafana container environment:"
docker exec grafana-staging printenv | grep PRODUCTION_PROMETHEUS_URL || echo "NOT SET"

echo ""

# 2. Fix environment variables
echo "2️⃣  Fixing environment variables..."
echo "----------------------------------------"

# Check if we're using the right env file
if [ -f "env.staging" ]; then
    echo "✅ Found env.staging file"
    echo "Loading environment variables..."
    set -a
    source env.staging
    set +a
    
    echo "PRODUCTION_PROMETHEUS_URL is now: $PRODUCTION_PROMETHEUS_URL"
    echo "PRODUCTION_LOKI_URL is now: $PRODUCTION_LOKI_URL"
else
    echo "❌ env.staging file not found"
    exit 1
fi

echo ""

# 3. Restart Grafana with correct environment
echo "3️⃣  Restarting Grafana with correct environment..."
echo "----------------------------------------"
echo "Stopping Grafana..."
docker stop grafana-staging

echo "Starting Grafana with environment file..."
docker run -d \
  --name grafana-staging-temp \
  --network plo-network-cloud \
  --env-file env.staging \
  -p 3001:3000 \
  -v grafana_data:/var/lib/grafana \
  -v $(pwd)/grafana-config/grafana-dashboards-provisioning:/etc/grafana/provisioning/dashboards:ro \
  -v $(pwd)/grafana-config/grafana-dashboards:/etc/grafana/dashboards:ro \
  -v $(pwd)/grafana-config/grafana-alerting-provisioning:/etc/grafana/provisioning/alerting:ro \
  -v $(pwd)/grafana-config/grafana-datasources-provisioning/datasources.staging.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro \
  grafana/grafana:latest

# Wait for Grafana to start
echo "Waiting for Grafana to start..."
sleep 15

# Remove old container
docker rm grafana-staging
docker rename grafana-staging-temp grafana-staging

echo "✅ Grafana restarted with correct environment"

echo ""

# 4. Test the fixes
echo "4️⃣  Testing fixes..."
echo "----------------------------------------"

# Wait a bit more for Grafana to fully start
sleep 10

echo "Testing Grafana API..."
if curl -s -u "admin:admin-staging-123" http://localhost:3001/api/health > /dev/null; then
    echo "✅ Grafana API is responding"
    
    echo ""
    echo "Checking datasources..."
    DATASOURCES=$(curl -s -u "admin:admin-staging-123" http://localhost:3001/api/datasources)
    echo "$DATASOURCES" | jq -r '.[] | "  - \(.name) (\(.type)): \(.url)"' 2>/dev/null || echo "Error parsing datasources"
    
    echo ""
    echo "Checking production URL in Grafana:"
    docker exec grafana-staging printenv PRODUCTION_PROMETHEUS_URL || echo "Still not set"
    
else
    echo "❌ Grafana API not responding yet, wait a moment and try again"
fi

echo ""

# 5. Test production connectivity
echo "5️⃣  Testing production connectivity..."
echo "----------------------------------------"

echo "Testing production Prometheus..."
if curl -s --connect-timeout 5 "https://prometheus-prod.ploscope.com/api/v1/query?query=up" > /dev/null; then
    echo "✅ Production Prometheus is reachable"
else
    echo "❌ Production Prometheus not reachable (may need auth or not deployed)"
fi

echo "Testing production Loki..."
if curl -s --connect-timeout 5 "https://loki.grafana-prod.ploscope.com/ready" > /dev/null; then
    echo "✅ Production Loki is reachable"
else
    echo "❌ Production Loki not reachable (may need auth or not deployed)"
fi

echo ""

echo "=========================================="
echo "📊 Fix Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check Grafana: http://localhost:3001 (admin/admin-staging-123)"
echo "2. Go to Configuration → Data sources"
echo "3. Verify 'Prometheus (Production)' shows correct URL"
echo "4. Test datasource connection"
echo "5. Run './check-staging-health.sh' to verify everything"
echo ""
echo "If production datasources still don't work:"
echo "- Verify production monitoring is deployed"
echo "- Check production URLs are accessible"
echo "- Verify basic auth credentials"
echo "=========================================="
