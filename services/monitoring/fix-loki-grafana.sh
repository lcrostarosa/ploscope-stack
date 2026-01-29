#!/bin/bash
# Fix Loki and Grafana Datasource Issues

set -e

ENVIRONMENT=${ENVIRONMENT:-staging}

echo "=========================================="
echo "🔧 Fixing Loki and Grafana Issues"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Check Loki
echo "1️⃣  Diagnosing Loki..."
echo "----------------------------------------"
echo "Checking Loki logs for errors..."
LOKI_ERRORS=$(docker logs loki-${ENVIRONMENT} 2>&1 | grep -i "error\|fatal\|panic" | tail -10)
if [ -n "$LOKI_ERRORS" ]; then
    echo -e "${RED}Found errors in Loki logs:${NC}"
    echo "$LOKI_ERRORS"
else
    echo -e "${GREEN}No critical errors in Loki logs${NC}"
fi
echo ""

# Test Loki directly
echo "Testing Loki endpoint..."
if curl -s http://localhost:3100/ready > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Loki /ready endpoint is responding${NC}"
elif docker exec loki-${ENVIRONMENT} wget -qO- http://localhost:3100/ready > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Loki responds internally but not from host${NC}"
    echo "This might be a port mapping issue"
else
    echo -e "${RED}❌ Loki is not responding even internally${NC}"
    echo ""
    echo "Attempting to restart Loki..."
    docker restart loki-${ENVIRONMENT}
    echo "Waiting 10 seconds for Loki to start..."
    sleep 10
    
    if curl -s http://localhost:3100/ready > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Loki is now responding after restart${NC}"
    else
        echo -e "${RED}❌ Loki still not responding. Check logs:${NC}"
        echo "docker logs loki-${ENVIRONMENT}"
    fi
fi
echo ""

# 2. Fix Grafana Datasources
echo "2️⃣  Fixing Grafana Datasources..."
echo "----------------------------------------"

# Check if environment variables are set in Grafana
echo "Checking Grafana environment variables..."
PROD_PROM_URL=$(docker exec grafana-${ENVIRONMENT} printenv PRODUCTION_PROMETHEUS_URL || echo "NOT_SET")
echo "PRODUCTION_PROMETHEUS_URL: $PROD_PROM_URL"

if [ "$PROD_PROM_URL" = "NOT_SET" ] || [ -z "$PROD_PROM_URL" ]; then
    echo -e "${RED}❌ PRODUCTION_* variables not set in Grafana container${NC}"
    echo ""
    echo "This means the environment variables weren't passed correctly."
    echo "You need to:"
    echo "  1. Make sure env.staging has PRODUCTION_* variables"
    echo "  2. Restart Grafana to pick up the new environment variables"
    echo ""
    echo "Restarting Grafana..."
    docker restart grafana-${ENVIRONMENT}
    echo "Waiting 15 seconds for Grafana to start..."
    sleep 15
    
    PROD_PROM_URL=$(docker exec grafana-${ENVIRONMENT} printenv PRODUCTION_PROMETHEUS_URL || echo "STILL_NOT_SET")
    if [ "$PROD_PROM_URL" != "STILL_NOT_SET" ] && [ -n "$PROD_PROM_URL" ]; then
        echo -e "${GREEN}✅ Variables are now set after restart${NC}"
    else
        echo -e "${RED}❌ Variables still not set. Check docker-compose.yml${NC}"
    fi
else
    echo -e "${GREEN}✅ PRODUCTION_* variables are set in Grafana${NC}"
fi
echo ""

# 3. Check Grafana datasources
echo "3️⃣  Checking Grafana Datasources..."
echo "----------------------------------------"
GRAFANA_USER=${GRAFANA_ADMIN_USER:-admin}
GRAFANA_PASS=${GRAFANA_ADMIN_PASSWORD:-admin-staging-123}

echo "Waiting for Grafana API to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

DATASOURCES=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" http://localhost:3001/api/datasources 2>/dev/null)

if [ -z "$DATASOURCES" ] || [ "$DATASOURCES" = "null" ]; then
    echo -e "${RED}❌ Cannot get datasources from Grafana API${NC}"
    echo "Check Grafana logs: docker logs grafana-${ENVIRONMENT}"
else
    echo -e "${GREEN}✅ Grafana API is responding${NC}"
    echo ""
    echo "Configured datasources:"
    echo "$DATASOURCES" | jq -r '.[] | "  - \(.name) (\(.type)): \(.url)"' 2>/dev/null || echo "$DATASOURCES"
fi
echo ""

# 4. Test datasource connectivity
echo "4️⃣  Testing Datasource Connectivity..."
echo "----------------------------------------"

# Test staging Prometheus
echo -n "Testing Prometheus (Staging)... "
if docker exec grafana-${ENVIRONMENT} wget -qO- http://prometheus:9090/api/v1/query?query=up > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Reachable${NC}"
else
    echo -e "${RED}❌ Not reachable${NC}"
fi

# Test staging Loki
echo -n "Testing Loki (Staging)... "
if docker exec grafana-${ENVIRONMENT} wget -qO- http://loki:3100/ready > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Reachable${NC}"
else
    echo -e "${RED}❌ Not reachable${NC}"
fi

# Test production Prometheus
if [ "$PROD_PROM_URL" != "NOT_SET" ] && [ "$PROD_PROM_URL" != "STILL_NOT_SET" ] && [ -n "$PROD_PROM_URL" ]; then
    echo -n "Testing Prometheus (Production) at $PROD_PROM_URL... "
    if docker exec grafana-${ENVIRONMENT} wget -qO- "${PROD_PROM_URL}/api/v1/query?query=up" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Reachable${NC}"
    else
        echo -e "${RED}❌ Not reachable (may need auth)${NC}"
    fi
fi
echo ""

# 5. Fix old log timestamps (Alloy errors)
echo "5️⃣  Cleaning up old Docker logs..."
echo "----------------------------------------"
if [ -f "./cleanup-old-logs.sh" ]; then
    echo "Running cleanup script..."
    chmod +x ./cleanup-old-logs.sh
    sudo ./cleanup-old-logs.sh || echo -e "${YELLOW}⚠️  Cleanup script needs sudo${NC}"
    
    echo "Restarting Alloy to clear error state..."
    docker restart alloy-${ENVIRONMENT}
else
    echo -e "${YELLOW}⚠️  cleanup-old-logs.sh not found${NC}"
    echo "Old log errors in Alloy are not critical - they'll clear over time"
fi
echo ""

# Summary
echo "=========================================="
echo "📊 Summary"
echo "=========================================="
echo ""
echo "✅ Checks completed!"
echo ""
echo "Next steps:"
echo "  1. Check Grafana datasources: http://localhost:3001/datasources"
echo "  2. Test queries in Explore"
echo "  3. If production datasource doesn't work, verify:"
echo "     - Production monitoring is deployed"
echo "     - Production URLs are correct"
echo "     - Basic auth credentials match"
echo ""
echo "Run './check-staging-health.sh' again to verify fixes"
echo "=========================================="

