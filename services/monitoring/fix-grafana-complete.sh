#!/bin/bash
# Complete fix for Grafana environment and authentication issues

set -e

echo "=========================================="
echo "🔧 Complete Grafana Fix"
echo "=========================================="
echo ""

# 1. Check current state
echo "1️⃣  Checking current state..."
echo "----------------------------------------"
echo "Environment file:"
grep PRODUCTION_PROMETHEUS_URL env.staging

echo ""
echo "Grafana container environment:"
docker exec grafana-staging printenv | grep PRODUCTION_PROMETHEUS_URL || echo "NOT SET"

echo ""
echo "Grafana admin password:"
docker exec grafana-staging printenv | grep GF_SECURITY_ADMIN || echo "NOT SET"

echo ""

# 2. Stop and remove current Grafana
echo "2️⃣  Stopping current Grafana..."
echo "----------------------------------------"
docker stop grafana-staging || echo "Already stopped"
docker rm grafana-staging || echo "Already removed"

echo ""

# 3. Load environment variables
echo "3️⃣  Loading environment variables..."
echo "----------------------------------------"
set -a
source env.staging
set +a

echo "PRODUCTION_PROMETHEUS_URL: $PRODUCTION_PROMETHEUS_URL"
echo "PRODUCTION_LOKI_URL: $PRODUCTION_LOKI_URL"
echo "GRAFANA_ADMIN_PASSWORD: $GRAFANA_ADMIN_PASSWORD"

echo ""

# 4. Start Grafana with correct environment
echo "4️⃣  Starting Grafana with correct environment..."
echo "----------------------------------------"

# Create a temporary env file with all variables
cat > grafana.env << EOF
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
GF_SERVER_HTTP_PORT=3000
GF_SERVER_DOMAIN=${GRAFANA_DOMAIN}
GF_LOG_LEVEL=${LOG_LEVEL}
ENVIRONMENT=${ENVIRONMENT}
RESTART_POLICY=${RESTART_POLICY:-unless-stopped}
VOLUME_MODE=${VOLUME_MODE:-rw}
PRODUCTION_PROMETHEUS_URL=${PRODUCTION_PROMETHEUS_URL}
PRODUCTION_PROMETHEUS_USER=${PRODUCTION_PROMETHEUS_USER}
PRODUCTION_PROMETHEUS_PASSWORD=${PRODUCTION_PROMETHEUS_PASSWORD}
PRODUCTION_LOKI_URL=${PRODUCTION_LOKI_URL}
PRODUCTION_LOKI_USER=${PRODUCTION_LOKI_USER}
PRODUCTION_LOKI_PASSWORD=${PRODUCTION_LOKI_PASSWORD}
EOF

echo "Created grafana.env file with:"
cat grafana.env | grep PRODUCTION_PROMETHEUS_URL

# Start Grafana
docker run -d \
  --name grafana-staging \
  --network plo-network-cloud \
  --env-file grafana.env \
  -p 3001:3000 \
  -v grafana_data:/var/lib/grafana \
  -v $(pwd)/grafana-config/grafana-dashboards-provisioning:/etc/grafana/provisioning/dashboards:ro \
  -v $(pwd)/grafana-config/grafana-dashboards:/etc/grafana/dashboards:ro \
  -v $(pwd)/grafana-config/grafana-alerting-provisioning:/etc/grafana/provisioning/alerting:ro \
  -v $(pwd)/grafana-config/grafana-datasources-provisioning/datasources.staging.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro \
  grafana/grafana:latest

echo "✅ Grafana started with correct environment"

echo ""

# 5. Wait for Grafana to start
echo "5️⃣  Waiting for Grafana to start..."
echo "----------------------------------------"
echo "Waiting 30 seconds for Grafana to fully initialize..."
sleep 30

# Check if Grafana is responding
for i in {1..10}; do
    if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
        echo "✅ Grafana is responding"
        break
    else
        echo "⏳ Waiting for Grafana... (attempt $i/10)"
        sleep 5
    fi
done

echo ""

# 6. Test authentication
echo "6️⃣  Testing authentication..."
echo "----------------------------------------"
echo "Testing with admin:${GRAFANA_ADMIN_PASSWORD}..."
if curl -s -u "admin:${GRAFANA_ADMIN_PASSWORD}" http://localhost:3001/api/health > /dev/null 2>&1; then
    echo "✅ Authentication successful"
else
    echo "❌ Authentication failed"
    echo "Trying with admin-staging-123..."
    if curl -s -u "admin:admin-staging-123" http://localhost:3001/api/health > /dev/null 2>&1; then
        echo "✅ Authentication successful with admin-staging-123"
        GRAFANA_PASS="admin-staging-123"
    else
        echo "❌ Authentication failed with both passwords"
        echo "Check Grafana logs: docker logs grafana-staging"
        exit 1
    fi
else
    GRAFANA_PASS="${GRAFANA_ADMIN_PASSWORD}"
fi

echo ""

# 7. Check datasources
echo "7️⃣  Checking datasources..."
echo "----------------------------------------"
echo "Getting datasources with password: $GRAFANA_PASS"
DATASOURCES=$(curl -s -u "admin:${GRAFANA_PASS}" http://localhost:3001/api/datasources)

if [ -n "$DATASOURCES" ] && [ "$DATASOURCES" != "null" ]; then
    echo "✅ Datasources retrieved successfully"
    echo ""
    echo "Configured datasources:"
    echo "$DATASOURCES" | jq -r '.[] | "  - \(.name) (\(.type)): \(.url)"' 2>/dev/null || echo "$DATASOURCES"
else
    echo "❌ Failed to get datasources"
    echo "Response: $DATASOURCES"
fi

echo ""

# 8. Check environment variables in container
echo "8️⃣  Verifying environment variables in container..."
echo "----------------------------------------"
echo "PRODUCTION_PROMETHEUS_URL in container:"
docker exec grafana-staging printenv PRODUCTION_PROMETHEUS_URL || echo "NOT SET"

echo "PRODUCTION_LOKI_URL in container:"
docker exec grafana-staging printenv PRODUCTION_LOKI_URL || echo "NOT SET"

echo ""

# 9. Test production connectivity
echo "9️⃣  Testing production connectivity..."
echo "----------------------------------------"
echo "Testing production Prometheus at $PRODUCTION_PROMETHEUS_URL..."
if curl -s --connect-timeout 5 "$PRODUCTION_PROMETHEUS_URL/api/v1/query?query=up" > /dev/null 2>&1; then
    echo "✅ Production Prometheus is reachable"
else
    echo "❌ Production Prometheus not reachable (may need auth or not deployed)"
fi

echo "Testing production Loki at $PRODUCTION_LOKI_URL..."
if curl -s --connect-timeout 5 "$PRODUCTION_LOKI_URL/ready" > /dev/null 2>&1; then
    echo "✅ Production Loki is reachable"
else
    echo "❌ Production Loki not reachable (may need auth or not deployed)"
fi

echo ""

# 10. Cleanup
echo "🔟  Cleaning up..."
echo "----------------------------------------"
rm -f grafana.env
echo "✅ Temporary files cleaned up"

echo ""

echo "=========================================="
echo "📊 Fix Complete!"
echo "=========================================="
echo ""
echo "Grafana should now be working with:"
echo "  - URL: http://localhost:3001"
echo "  - Username: admin"
echo "  - Password: $GRAFANA_PASS"
echo ""
echo "Next steps:"
echo "1. Open Grafana: http://localhost:3001"
echo "2. Login with admin / $GRAFANA_PASS"
echo "3. Go to Configuration → Data sources"
echo "4. Check if 'Prometheus (Production)' shows: $PRODUCTION_PROMETHEUS_URL"
echo "5. Test datasource connection"
echo "6. Run './check-staging-health.sh' to verify everything"
echo ""
echo "If production datasources don't work:"
echo "- Verify production monitoring is deployed"
echo "- Check production URLs are accessible"
echo "- Verify basic auth credentials match"
echo "=========================================="
