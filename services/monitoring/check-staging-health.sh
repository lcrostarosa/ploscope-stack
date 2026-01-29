#!/bin/bash
# Staging Monitoring Health Check Script
# Run this on your staging server to diagnose monitoring issues

set -e

ENVIRONMENT=${ENVIRONMENT:-staging}

echo "=========================================="
echo "🔍 Staging Monitoring Health Check"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check Docker containers
echo "1️⃣  Checking Docker containers..."
echo "----------------------------------------"
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(prometheus|grafana|loki|alloy|cadvisor)"; then
    echo -e "${GREEN}✅ Monitoring containers are running${NC}"
else
    echo -e "${RED}❌ Some monitoring containers are missing${NC}"
fi
echo ""

# 2. Check Docker network
echo "2️⃣  Checking Docker network..."
echo "----------------------------------------"
if docker network inspect plo-network-cloud >/dev/null 2>&1; then
    CONTAINER_COUNT=$(docker network inspect plo-network-cloud | jq '.[0].Containers | length')
    echo -e "${GREEN}✅ plo-network-cloud exists with $CONTAINER_COUNT containers${NC}"
    docker network inspect plo-network-cloud | jq '.[0].Containers | to_entries[] | {name: .value.Name, ip: .value.IPv4Address}'
else
    echo -e "${RED}❌ plo-network-cloud network does not exist${NC}"
fi
echo ""

# 3. Check Prometheus health
echo "3️⃣  Checking Prometheus..."
echo "----------------------------------------"
if curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo -e "${GREEN}✅ Prometheus is healthy${NC}"
    
    # Check targets
    echo "📊 Prometheus targets:"
    curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health) \(if .lastError then "- " + .lastError else "" end)"' | while IFS= read -r line; do
        if echo "$line" | grep -q "up"; then
            echo -e "  ${GREEN}✅ $line${NC}"
        else
            echo -e "  ${RED}❌ $line${NC}"
        fi
    done
else
    echo -e "${RED}❌ Prometheus is not responding${NC}"
fi
echo ""

# 4. Check Loki health
echo "4️⃣  Checking Loki..."
echo "----------------------------------------"
if curl -s http://localhost:3100/ready > /dev/null; then
    echo -e "${GREEN}✅ Loki is healthy${NC}"
    
    # Check for logs
    LOG_COUNT=$(curl -s http://localhost:3100/loki/api/v1/label/container_name/values | jq '.data | length')
    if [ "$LOG_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Loki has logs from $LOG_COUNT containers${NC}"
        echo "📝 Containers with logs:"
        curl -s http://localhost:3100/loki/api/v1/label/container_name/values | jq -r '.data[]' | sed 's/^/  - /'
    else
        echo -e "${YELLOW}⚠️  Loki has no logs yet${NC}"
    fi
else
    echo -e "${RED}❌ Loki is not responding${NC}"
fi
echo ""

# 5. Check Alloy health
echo "5️⃣  Checking Alloy..."
echo "----------------------------------------"
if docker exec alloy-${ENVIRONMENT} timeout 2 bash -c "echo > /dev/tcp/localhost/12345" 2>/dev/null; then
    echo -e "${GREEN}✅ Alloy is running${NC}"
    
    # Check for errors in logs
    ERROR_COUNT=$(docker logs alloy-${ENVIRONMENT} 2>&1 | grep -i error | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $ERROR_COUNT errors in Alloy logs (recent 5):${NC}"
        docker logs alloy-${ENVIRONMENT} 2>&1 | grep -i error | tail -5 | sed 's/^/  /'
    else
        echo -e "${GREEN}✅ No errors in Alloy logs${NC}"
    fi
else
    echo -e "${RED}❌ Alloy is not responding${NC}"
fi
echo ""

# 6. Check Grafana health
echo "6️⃣  Checking Grafana..."
echo "----------------------------------------"
if curl -s http://localhost:3001/api/health | jq -e '.database == "ok"' > /dev/null; then
    echo -e "${GREEN}✅ Grafana is healthy${NC}"
    
    # Check datasources
    echo "📊 Datasources:"
    DATASOURCES=$(curl -s -u "admin:admin-${ENVIRONMENT}-123" http://localhost:3001/api/datasources)
    echo "$DATASOURCES" | jq -r '.[] | "  - \(.name) (\(.type)): \(if .isDefault then "default" else "" end)"'
else
    echo -e "${RED}❌ Grafana is not responding${NC}"
fi
echo ""

# 7. Check application services
echo "7️⃣  Checking application services..."
echo "----------------------------------------"
APP_SERVICES=("frontend:3000" "backend:8000" "celeryworker:8001" "db:5432" "rabbitmq:15692" "nexus:8081")
FOUND=0

for service in "${APP_SERVICES[@]}"; do
    SERVICE_NAME=$(echo $service | cut -d: -f1)
    if docker ps --format '{{.Names}}' | grep -q "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ $SERVICE_NAME is running${NC}"
        FOUND=$((FOUND + 1))
    fi
done

if [ "$FOUND" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No application services found${NC}"
    echo "   This is expected if you haven't deployed your application yet."
    echo "   Monitoring will still work, but you'll only see monitoring container metrics."
fi
echo ""

# 8. Test metrics endpoints
echo "8️⃣  Testing /metrics endpoints..."
echo "----------------------------------------"
ENDPOINTS=("localhost:9090/metrics" "localhost:12345/metrics")

for endpoint in "${ENDPOINTS[@]}"; do
    if curl -s "http://$endpoint" | head -5 > /dev/null; then
        echo -e "${GREEN}✅ $endpoint responding${NC}"
    else
        echo -e "${RED}❌ $endpoint not responding${NC}"
    fi
done
echo ""

# 9. Summary
echo "=========================================="
echo "📊 Summary"
echo "=========================================="
echo ""

# Count healthy services
HEALTHY=$(curl -s http://localhost:9090/api/v1/targets | jq '[.data.activeTargets[] | select(.health == "up")] | length')
TOTAL=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length')
echo "Prometheus targets: $HEALTHY/$TOTAL up"

# Check if basic monitoring is working
if [ "$HEALTHY" -ge 3 ]; then
    echo -e "${GREEN}✅ Basic monitoring is operational${NC}"
    echo ""
    echo "🎯 Next steps:"
    echo "  1. Access Grafana: http://localhost:3001 (admin/admin-${ENVIRONMENT}-123)"
    echo "  2. Check dashboards: Docker Monitoring, Container Logs"
    echo "  3. Explore logs: Grafana → Explore → Loki (Staging) → {environment=\"staging\"}"
    echo ""
    if [ "$FOUND" -eq 0 ]; then
        echo "💡 To monitor your applications:"
        echo "  1. Deploy your app services to the plo-network-cloud network"
        echo "  2. Ensure they expose /metrics endpoints"
        echo "  3. See TROUBLESHOOTING_STAGING.md for details"
    fi
else
    echo -e "${RED}⚠️  Monitoring has issues${NC}"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  1. Check container logs: docker logs <container-name>"
    echo "  2. Restart services: docker compose restart"
    echo "  3. See TROUBLESHOOTING_STAGING.md for detailed help"
fi

echo ""
echo "=========================================="


