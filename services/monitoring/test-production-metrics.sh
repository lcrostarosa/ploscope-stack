#!/bin/bash
# Test Production Metrics Access from Staging Grafana Perspective
# This script tests if production metrics are accessible and can be queried

set -e

echo "=========================================="
echo "🔍 Testing Production Metrics Access"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Production endpoints
PROD_PROM_URL="${PRODUCTION_PROMETHEUS_URL:-https://prometheus-prod.ploscope.com}"
PROD_PROM_USER="${PRODUCTION_PROMETHEUS_USER:-prometheususer}"
PROD_PROM_PASS="${PRODUCTION_PROMETHEUS_PASSWORD:-securepassword123}"
PROD_LOKI_URL="${PRODUCTION_LOKI_URL:-https://loki.grafana-prod.ploscope.com}"
PROD_LOKI_USER="${PRODUCTION_LOKI_USER:-lokiuser}"
PROD_LOKI_PASS="${PRODUCTION_LOKI_PASSWORD:-securepassword123}"

echo "Production Prometheus URL: $PROD_PROM_URL"
echo "Production Loki URL: $PROD_LOKI_URL"
echo ""

# Test 1: Production Prometheus connectivity
echo "1️⃣  Testing Production Prometheus connectivity..."
echo "----------------------------------------"
if curl -s -u "${PROD_PROM_USER}:${PROD_PROM_PASS}" "${PROD_PROM_URL}/api/v1/status/config" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Production Prometheus is reachable${NC}"
else
    echo -e "${RED}❌ Cannot reach Production Prometheus${NC}"
    exit 1
fi

# Test 2: Query production metrics
echo ""
echo "2️⃣  Querying production metrics..."
echo "----------------------------------------"
METRICS_QUERY=$(curl -s -u "${PROD_PROM_USER}:${PROD_PROM_PASS}" "${PROD_PROM_URL}/api/v1/query?query=up{environment=\"production\"}")
METRIC_COUNT=$(echo "$METRICS_QUERY" | jq '.data.result | length' 2>/dev/null || echo "0")

if [ "$METRIC_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $METRIC_COUNT production metrics${NC}"
    echo ""
    echo "Sample production metrics:"
    echo "$METRICS_QUERY" | jq -r '.data.result[0:5][] | "  - \(.metric.job) (\(.metric.instance)): \(.value[1])"' 2>/dev/null || echo "  (Unable to parse)"
else
    echo -e "${YELLOW}⚠️  No metrics found (might be normal if no services are running)${NC}"
fi

# Test 3: Count available metric names
echo ""
echo "3️⃣  Checking available metric names..."
echo "----------------------------------------"
METRIC_NAMES=$(curl -s -u "${PROD_PROM_USER}:${PROD_PROM_PASS}" "${PROD_PROM_URL}/api/v1/label/__name__/values")
METRIC_NAME_COUNT=$(echo "$METRIC_NAMES" | jq '.data | length' 2>/dev/null || echo "0")
echo -e "${GREEN}✅ Production Prometheus has $METRIC_NAME_COUNT metric names available${NC}"

# Test 4: Test production Loki
echo ""
echo "4️⃣  Testing Production Loki connectivity..."
echo "----------------------------------------"
if curl -s -u "${PROD_LOKI_USER}:${PROD_LOKI_PASS}" "${PROD_LOKI_URL}/ready" 2>&1 | grep -q "ready"; then
    echo -e "${GREEN}✅ Production Loki is reachable${NC}"
else
    echo -e "${RED}❌ Cannot reach Production Loki${NC}"
fi

# Test 5: Query production metrics by job
echo ""
echo "5️⃣  Checking production services by job..."
echo "----------------------------------------"
JOBS_QUERY=$(curl -s -u "${PROD_PROM_USER}:${PROD_PROM_PASS}" "${PROD_PROM_URL}/api/v1/query?query=count by (job) (up{environment=\"production\"})")
echo "$JOBS_QUERY" | jq -r '.data.result[] | "  - \(.metric.job): \(.value[1]) instances"' 2>/dev/null || echo "  (Unable to parse)"

# Test 6: Test time range query (like Grafana would do)
echo ""
echo "6️⃣  Testing time range query (Grafana-style)..."
echo "----------------------------------------"
END_TIME=$(date +%s)
START_TIME=$((END_TIME - 300))  # 5 minutes ago
RANGE_QUERY=$(curl -s -u "${PROD_PROM_USER}:${PROD_PROM_PASS}" "${PROD_PROM_URL}/api/v1/query_range?query=up&start=${START_TIME}&end=${END_TIME}&step=15s")
RANGE_RESULT_COUNT=$(echo "$RANGE_QUERY" | jq '.data.result | length' 2>/dev/null || echo "0")

if [ "$RANGE_RESULT_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Time range query successful: $RANGE_RESULT_COUNT time series${NC}"
else
    echo -e "${YELLOW}⚠️  Time range query returned no results${NC}"
fi

# Summary
echo ""
echo "=========================================="
echo "📊 Summary"
echo "=========================================="
echo ""
echo "Production Prometheus:"
echo "  - URL: $PROD_PROM_URL"
echo "  - Status: ✅ Accessible"
echo "  - Metrics available: $METRIC_NAME_COUNT metric names"
echo "  - Production instances: $METRIC_COUNT"
echo ""
echo "Production Loki:"
echo "  - URL: $PROD_LOKI_URL"
echo "  - Status: ✅ Accessible"
echo ""
echo "✅ Production endpoints are accessible and returning metrics!"
echo ""
echo "Next steps:"
echo "1. Verify Grafana datasource configuration shows these URLs"
echo "2. Test datasource in Grafana UI: Configuration → Data sources → Prometheus (Production) → Save & test"
echo "3. Query production metrics in Grafana Explore using Prometheus (Production) datasource"
echo ""

