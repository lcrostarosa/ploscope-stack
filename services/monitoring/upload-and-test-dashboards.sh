#!/bin/bash
# Upload and test Grafana dashboards on staging server

set -e

GRAFANA_URL="https://grafana.ploscope.com"
GRAFANA_USER="admin"
GRAFANA_PASS="gjz-brm!APN0gar-kvq"

echo "=========================================="
echo "📊 Uploading and Testing Grafana Dashboards"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to upload dashboard
upload_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "$dashboard_file" .json)
    
    echo "📤 Uploading $dashboard_name..."
    
    # Upload dashboard via API
    RESPONSE=$(curl -s -X POST \
        "$GRAFANA_URL/api/dashboards/db" \
        --user "$GRAFANA_USER:$GRAFANA_PASS" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
  "dashboard": $(cat "$dashboard_file"),
  "overwrite": true,
  "folderId": null
}
EOF
    )
    
    if echo "$RESPONSE" | grep -q '"uid"'; then
        DASHBOARD_UID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['dashboard']['uid'])" 2>/dev/null || echo "")
        echo -e "${GREEN}✅ Dashboard uploaded successfully${NC}"
        echo "   UID: $DASHBOARD_UID"
        echo "   URL: $GRAFANA_URL/d/$DASHBOARD_UID"
        return 0
    else
        echo -e "${RED}❌ Failed to upload dashboard${NC}"
        echo "Response: $RESPONSE"
        return 1
    fi
}

# Function to test dashboard
test_dashboard() {
    local dashboard_uid=$1
    local dashboard_name=$2
    
    echo ""
    echo "🧪 Testing $dashboard_name..."
    
    # Get dashboard details
    DASHBOARD_DATA=$(curl -s \
        "$GRAFANA_URL/api/dashboards/uid/$dashboard_uid" \
        --user "$GRAFANA_USER:$GRAFANA_PASS")
    
    if echo "$DASHBOARD_DATA" | grep -q '"dashboard"'; then
        PANEL_COUNT=$(echo "$DASHBOARD_DATA" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['dashboard']['panels']))" 2>/dev/null || echo "0")
        echo -e "${GREEN}✅ Dashboard accessible${NC}"
        echo "   Panels: $PANEL_COUNT"
        
        # Check datasources
        DATASOURCES=$(echo "$DASHBOARD_DATA" | python3 -c "import sys, json; d=json.load(sys.stdin)['dashboard']; \
            prom_uids = set(); loki_uids = set(); \
            [prom_uids.add(p['datasource']['uid']) for p in d['panels'] if p.get('datasource', {}).get('type') == 'prometheus']; \
            [loki_uids.add(p['datasource']['uid']) for p in d['panels'] if p.get('datasource', {}).get('type') == 'loki']; \
            print(f\"Prometheus datasources: {prom_uids}\"); print(f\"Loki datasources: {loki_uids}\")" 2>/dev/null || echo "")
        echo "   $DATASOURCES"
        
        return 0
    else
        echo -e "${RED}❌ Dashboard not accessible${NC}"
        return 1
    fi
}

# Check if dashboard files exist
if [ ! -f "grafana-config/grafana-dashboards/production-logs-metrics-dashboard.json" ]; then
    echo -e "${RED}❌ Production dashboard file not found${NC}"
    exit 1
fi

if [ ! -f "grafana-config/grafana-dashboards/staging-logs-metrics-dashboard.json" ]; then
    echo -e "${RED}❌ Staging dashboard file not found${NC}"
    exit 1
fi

# Validate JSON files
echo "🔍 Validating dashboard JSON files..."
python3 -c "import json; json.load(open('grafana-config/grafana-dashboards/production-logs-metrics-dashboard.json'))" && echo -e "${GREEN}✅ Production dashboard JSON valid${NC}" || { echo -e "${RED}❌ Production dashboard JSON invalid${NC}"; exit 1; }
python3 -c "import json; json.load(open('grafana-config/grafana-dashboards/staging-logs-metrics-dashboard.json'))" && echo -e "${GREEN}✅ Staging dashboard JSON valid${NC}" || { echo -e "${RED}❌ Staging dashboard JSON invalid${NC}"; exit 1; }

echo ""

# Upload Production Dashboard
echo "1️⃣  Uploading Production Dashboard..."
echo "----------------------------------------"
PROD_RESPONSE=$(curl -s -X POST \
    "$GRAFANA_URL/api/dashboards/db" \
    --user "$GRAFANA_USER:$GRAFANA_PASS" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "dashboard": $(cat grafana-config/grafana-dashboards/production-logs-metrics-dashboard.json),
  "overwrite": true,
  "folderId": null
}
EOF
)

if echo "$PROD_RESPONSE" | grep -q '"uid"'; then
    PROD_UID=$(echo "$PROD_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['dashboard']['uid'])" 2>/dev/null || echo "")
    echo -e "${GREEN}✅ Production dashboard uploaded${NC}"
    echo "   UID: $PROD_UID"
    echo "   URL: $GRAFANA_URL/d/$PROD_UID"
    PROD_SUCCESS=true
else
    echo -e "${RED}❌ Failed to upload production dashboard${NC}"
    echo "Response: $PROD_RESPONSE" | head -20
    PROD_SUCCESS=false
fi

echo ""

# Upload Staging Dashboard
echo "2️⃣  Uploading Staging Dashboard..."
echo "----------------------------------------"
STAGING_RESPONSE=$(curl -s -X POST \
    "$GRAFANA_URL/api/dashboards/db" \
    --user "$GRAFANA_USER:$GRAFANA_PASS" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "dashboard": $(cat grafana-config/grafana-dashboards/staging-logs-metrics-dashboard.json),
  "overwrite": true,
  "folderId": null
}
EOF
)

if echo "$STAGING_RESPONSE" | grep -q '"uid"'; then
    STAGING_UID=$(echo "$STAGING_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['dashboard']['uid'])" 2>/dev/null || echo "")
    echo -e "${GREEN}✅ Staging dashboard uploaded${NC}"
    echo "   UID: $STAGING_UID"
    echo "   URL: $GRAFANA_URL/d/$STAGING_UID"
    STAGING_SUCCESS=true
else
    echo -e "${RED}❌ Failed to upload staging dashboard${NC}"
    echo "Response: $STAGING_RESPONSE" | head -20
    STAGING_SUCCESS=false
fi

echo ""

# Test Production Dashboard
if [ "$PROD_SUCCESS" = true ] && [ -n "$PROD_UID" ]; then
    echo "3️⃣  Testing Production Dashboard..."
    echo "----------------------------------------"
    test_dashboard "$PROD_UID" "Production Dashboard"
fi

echo ""

# Test Staging Dashboard
if [ "$STAGING_SUCCESS" = true ] && [ -n "$STAGING_UID" ]; then
    echo "4️⃣  Testing Staging Dashboard..."
    echo "----------------------------------------"
    test_dashboard "$STAGING_UID" "Staging Dashboard"
fi

echo ""

# List all dashboards
echo "5️⃣  Listing Dashboards..."
echo "----------------------------------------"
curl -s "$GRAFANA_URL/api/search?type=dash-db" \
    --user "$GRAFANA_USER:$GRAFANA_PASS" | \
    python3 -c "import sys, json; dashboards = json.load(sys.stdin); \
    print(f\"Total dashboards: {len(dashboards)}\"); \
    [print(f\"  - {d['title']} (UID: {d['uid']})\") for d in dashboards if 'logs' in d['title'].lower() or 'metrics' in d['title'].lower()]"

echo ""

# Summary
echo "=========================================="
echo "📊 Summary"
echo "=========================================="
if [ "$PROD_SUCCESS" = true ] && [ "$STAGING_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ Both dashboards uploaded successfully!${NC}"
    echo ""
    echo "Access dashboards:"
    if [ -n "$PROD_UID" ]; then
        echo "  Production: $GRAFANA_URL/d/$PROD_UID"
    fi
    if [ -n "$STAGING_UID" ]; then
        echo "  Staging: $GRAFANA_URL/d/$STAGING_UID"
    fi
else
    echo -e "${YELLOW}⚠️  Some dashboards failed to upload${NC}"
    echo "Production: $([ \"$PROD_SUCCESS\" = true ] && echo '✅' || echo '❌')"
    echo "Staging: $([ \"$STAGING_SUCCESS\" = true ] && echo '✅' || echo '❌')"
fi
echo ""


