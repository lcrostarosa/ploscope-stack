#!/bin/bash

echo "🔍 Quick PLO Solver Service Test"
echo "================================="

# Test Docker
echo "🐳 Testing Docker..."
if docker ps >/dev/null 2>&1; then
    echo "✅ Docker is running"
    echo "📊 Active containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep plosolver || echo "   No PLO Solver containers running"
else
    echo "❌ Docker is not running"
    exit 1
fi

echo ""
echo "🌐 Testing Endpoints..."

# Test main frontend
echo "📱 Frontend (http://localhost):"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost --connect-timeout 5 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend is accessible"
elif [ "$FRONTEND_STATUS" = "000" ]; then
    echo "❌ Frontend not reachable (connection failed)"
else
    echo "⚠️ Frontend returned HTTP $FRONTEND_STATUS"
fi

# Test API health
echo "🔧 API Health (http://localhost/api/health):"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health --connect-timeout 5 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo "✅ API health endpoint is working"
elif [ "$API_STATUS" = "000" ]; then
    echo "❌ API not reachable (connection failed)"
else
    echo "⚠️ API health returned HTTP $API_STATUS"
fi

# Test login endpoint
echo "🔐 Login Endpoint (http://localhost/api/auth/login):"
LOGIN_TEST=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"testpass"}' \
    http://localhost/api/auth/login --connect-timeout 5 2>/dev/null || echo "FAILED")

if [ "$LOGIN_TEST" = "FAILED" ]; then
    echo "❌ Login endpoint not reachable"
else
    LOGIN_STATUS=$(echo "$LOGIN_TEST" | grep -o '"error"' >/dev/null && echo "ERROR" || echo "OK")
    if [ "$LOGIN_STATUS" = "ERROR" ]; then
        echo "✅ Login endpoint is working (returned expected error for test credentials)"
    else
        echo "⚠️ Login endpoint returned unexpected response"
    fi
fi

# Test Traefik dashboard
echo "📊 Traefik Dashboard (http://localhost:8080):"
TRAEFIK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --connect-timeout 5 2>/dev/null || echo "000")
if [ "$TRAEFIK_STATUS" = "200" ]; then
    echo "✅ Traefik dashboard is accessible"
elif [ "$TRAEFIK_STATUS" = "000" ]; then
    echo "❌ Traefik dashboard not reachable"
else
    echo "⚠️ Traefik dashboard returned HTTP $TRAEFIK_STATUS"
fi

echo ""
echo "🔗 If services are running, you can access:"
echo "• Frontend: http://localhost"
echo "• API: http://localhost/api"
echo "• Traefik Dashboard: http://localhost:8080"

echo ""
echo "🔧 To start services: ./scripts/development/run_with_traefik.sh"
echo "🛑 To stop services: docker compose --env-file=env.development down" 