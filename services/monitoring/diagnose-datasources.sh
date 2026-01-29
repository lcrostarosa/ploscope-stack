#!/bin/bash
# Diagnose Production Datasource Issues
# Run this on your staging server

set -e

ENVIRONMENT=${ENVIRONMENT:-staging}
GRAFANA_USER=${GRAFANA_ADMIN_USER:-admin}
GRAFANA_PASS=${GRAFANA_ADMIN_PASSWORD:-admin-staging-123}

echo "=========================================="
echo "🔍 Production Datasource Diagnosis"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Check if Grafana is running
echo "1️⃣  Checking Grafana container..."
echo "----------------------------------------"
if docker ps | grep -q "grafana-${ENVIRONMENT}"; then
    echo -e "${GREEN}✅ Grafana is running${NC}"
else
    echo -e "${RED}❌ Grafana is not running${NC}"
    exit 1
fi
echo ""

# 2. Check Grafana environment variables
echo "2️⃣  Checking Grafana environment variables..."
echo "----------------------------------------"
echo "Checking for PRODUCTION_* variables in Grafana container..."
docker exec grafana-${ENVIRONMENT} env | grep -E "(PRODUCTION_|ENVIRONMENT)" || echo -e "${YELLOW}⚠️  No PRODUCTION_* variables found${NC}"
echo ""

# 3. Check datasources in Grafana
echo "3️⃣  Checking Grafana datasources..."
echo "----------------------------------------"
DATASOURCES=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" http://localhost:3001/api/datasources)
echo "$DATASOURCES" | jq -r '.[] | "\(.name): \(.url) (Type: \(.type), Auth: \(.basicAuth))"'
echo ""

# 4. Test production Prometheus connectivity FROM GRAFANA CONTAINER
echo "4️⃣  Testing production Prometheus from Grafana container..."
echo "----------------------------------------"

# First, check what the datasource URL is configured as
PROD_PROM_URL=$(echo "$DATASOURCES" | jq -r '.[] | select(.name=="Prometheus (Production)") | .url')
echo "Configured URL: $PROD_PROM_URL"

if [ "$PROD_PROM_URL" = "null" ] || [ -z "$PROD_PROM_URL" ]; then
    echo -e "${RED}❌ Production Prometheus datasource not found or URL is empty${NC}"
    echo "This means environment variables weren't substituted properly"
else
    echo "Testing connection from Grafana container..."
    
    # Test with basicAuth
    PROD_USER=$(echo "$DATASOURCES" | jq -r '.[] | select(.name=="Prometheus (Production)") | .basicAuthUser')
    
    if docker exec grafana-${ENVIRONMENT} wget -q --tries=1 --timeout=5 -O- "$PROD_PROM_URL/api/v1/query?query=up" 2>&1; then
        echo -e "${GREEN}✅ Production Prometheus is reachable${NC}"
    else
        echo -e "${RED}❌ Cannot reach production Prometheus${NC}"
        echo "Trying with basic auth user: $PROD_USER"
        
        # Test from host instead
        echo ""
        echo "Testing from host machine..."
        if curl -s --connect-timeout 5 "$PROD_PROM_URL/api/v1/query?query=up" > /dev/null; then
            echo -e "${GREEN}✅ Host can reach production Prometheus${NC}"
            echo -e "${YELLOW}⚠️  Issue might be with Grafana container network or credentials${NC}"
        else
            echo -e "${RED}❌ Host cannot reach production Prometheus either${NC}"
            echo -e "${YELLOW}⚠️  Production Prometheus might not be deployed or URL is wrong${NC}"
        fi
    fi
fi
echo ""

# 5. Check production endpoints
echo "5️⃣  Checking production service availability..."
echo "----------------------------------------"
PROD_URLS=(
    "https://prometheus-prod.ploscope.com"
    "https://prometheus.ploscope.com"
    "https://loki.grafana-prod.ploscope.com"
    "https://loki.ploscope.com"
)

for url in "${PROD_URLS[@]}"; do
    echo -n "Testing $url ... "
    if curl -s --connect-timeout 3 "$url/api/v1/query?query=up" > /dev/null 2>&1 || \
       curl -s --connect-timeout 3 "$url/ready" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Reachable${NC}"
    else
        echo -e "${RED}❌ Not reachable${NC}"
    fi
done
echo ""

# 6. Check datasource health in Grafana
echo "6️⃣  Checking datasource health status..."
echo "----------------------------------------"
DS_HEALTH=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" http://localhost:3001/api/datasources)
echo "$DS_HEALTH" | jq -r '.[] | select(.name | contains("Production")) | "\(.name): UID=\(.uid), BasicAuth=\(.basicAuth), BasicAuthUser=\(.basicAuthUser)"'
echo ""

# 7. Test datasource by UID
echo "7️⃣  Testing production datasource health..."
echo "----------------------------------------"
PROD_PROM_UID=$(echo "$DS_HEALTH" | jq -r '.[] | select(.name=="Prometheus (Production)") | .uid')
if [ -n "$PROD_PROM_UID" ] && [ "$PROD_PROM_UID" != "null" ]; then
    echo "Testing datasource UID: $PROD_PROM_UID"
    DS_TEST=$(curl -s -u "${GRAFANA_USER}:${GRAFANA_PASS}" "http://localhost:3001/api/datasources/uid/$PROD_PROM_UID/health")
    echo "$DS_TEST" | jq '.'
else
    echo -e "${RED}❌ Cannot find Production Prometheus datasource${NC}"
fi
echo ""

# 8. Summary and recommendations
echo "=========================================="
echo "📊 Summary & Recommendations"
echo "=========================================="
echo ""

# Check if URL substitution worked
if [ "$PROD_PROM_URL" = "null" ] || [ -z "$PROD_PROM_URL" ] || [[ "$PROD_PROM_URL" == *'${'* ]]; then
    echo -e "${RED}❌ CRITICAL: Environment variables not substituted in datasources${NC}"
    echo ""
    echo "🔧 Fix: Add production variables to Grafana container environment"
    echo "   In docker-compose.yml, under grafana service, add:"
    echo "   environment:"
    echo "     - PRODUCTION_PROMETHEUS_URL=https://prometheus-prod.ploscope.com"
    echo "     - PRODUCTION_PROMETHEUS_USER=prometheususer"
    echo "     - PRODUCTION_PROMETHEUS_PASSWORD=your-password"
    echo "     - PRODUCTION_LOKI_URL=https://loki.grafana-prod.ploscope.com"
    echo "     - PRODUCTION_LOKI_USER=lokiuser"
    echo "     - PRODUCTION_LOKI_PASSWORD=your-password"
    echo ""
elif [[ "$PROD_PROM_URL" == *"prometheus.ploscope.com"* ]] && [[ ! "$PROD_PROM_URL" == *"prometheus-prod"* ]]; then
    echo -e "${YELLOW}⚠️  URL MISMATCH: Using 'prometheus.ploscope.com' but Traefik expects 'prometheus-prod.ploscope.com'${NC}"
    echo ""
    echo "🔧 Fix: Update env.staging:"
    echo "   PRODUCTION_PROMETHEUS_URL=https://prometheus-prod.ploscope.com"
    echo ""
else
    echo -e "${GREEN}✅ Configuration looks correct${NC}"
    echo ""
    echo "If datasource still doesn't work, check:"
    echo "  1. Production services are actually deployed"
    echo "  2. Basic auth credentials are correct"
    echo "  3. Network connectivity from staging to production"
    echo "  4. Traefik routing rules are applied"
fi

echo ""
echo "=========================================="

