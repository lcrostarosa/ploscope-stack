#!/bin/bash

echo "🔍 Traefik Health Check"
echo "======================="

# Check if Traefik container is running
echo "🐳 Checking Traefik container..."
if docker ps --filter "name=plosolver-traefik" --format "table {{.Names}}\t{{.Status}}" | grep -q "Up"; then
    echo "✅ Traefik container is running"
    
    # Check Traefik health
    echo "🏥 Checking Traefik health endpoint..."
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ping --connect-timeout 5 2>/dev/null || echo "000")
    if [ "$HEALTH_STATUS" = "200" ]; then
        echo "✅ Traefik health check passed"
    else
        echo "❌ Traefik health check failed (HTTP $HEALTH_STATUS)"
    fi
    
    # Check Traefik dashboard
    echo "📊 Checking Traefik dashboard..."
    DASHBOARD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --connect-timeout 5 2>/dev/null || echo "000")
    if [ "$DASHBOARD_STATUS" = "200" ]; then
        echo "✅ Traefik dashboard is accessible"
    else
        echo "❌ Traefik dashboard failed (HTTP $DASHBOARD_STATUS)"
    fi
    
    # Show Traefik routes
    echo "🛣️ Traefik Routes (via API):"
    curl -s http://localhost:8080/api/http/routers 2>/dev/null | \
        python3 -m json.tool 2>/dev/null | \
        grep -E '"name"|"rule"|"status"' | \
        head -20 || echo "   Could not fetch routes"
    
    # Show recent Traefik logs
    echo "📋 Recent Traefik logs (last 10 lines):"
    docker logs plosolver-traefik-1 --tail 10 2>/dev/null || echo "   Could not fetch logs"
    
else
    echo "❌ Traefik container is not running"
    
    # Check if it exists but stopped
    if docker ps -a --filter "name=plosolver-traefik" --format "table {{.Names}}\t{{.Status}}" | grep -q "plosolver-traefik"; then
        echo "📋 Traefik container status:"
        docker ps -a --filter "name=plosolver-traefik" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo "📋 Traefik logs (last 20 lines):"
        docker logs plosolver-traefik-1 --tail 20 2>/dev/null || echo "   Could not fetch logs"
    else
        echo "❌ Traefik container does not exist"
    fi
fi

echo ""
echo "🔧 Quick Actions:"
echo "• Start Traefik: docker compose --env-file=env.development --profile=traefik up -d"
echo "• View Traefik logs: docker logs plosolver-traefik-1 -f"
echo "• Restart Traefik: docker compose --env-file=env.development restart traefik"
echo "• Traefik Dashboard: http://localhost:8080" 