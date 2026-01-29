#!/bin/bash
# Start monitoring stack with proper environment variable substitution
# This script prepares datasource files and starts the monitoring stack

set -e

ENVIRONMENT=${ENVIRONMENT:-staging}

echo "=========================================="
echo "🚀 Starting Monitoring Stack (${ENVIRONMENT})"
echo "=========================================="
echo ""

# 1. Load environment variables
if [ ! -f "env.${ENVIRONMENT}" ]; then
    echo "❌ Error: env.${ENVIRONMENT} file not found!"
    exit 1
fi

echo "1️⃣  Loading environment variables..."
set -a
source "env.${ENVIRONMENT}"
set +a
export ENVIRONMENT

echo "✅ Environment variables loaded"
echo "   Environment: ${ENVIRONMENT}"
echo "   Production Prometheus URL: ${PRODUCTION_PROMETHEUS_URL}"
echo "   Production Loki URL: ${PRODUCTION_LOKI_URL}"
echo ""

# 2. Prepare Grafana datasource files
echo "2️⃣  Preparing Grafana datasource files..."
if [ -f "./prepare-grafana-datasources.sh" ]; then
    ./prepare-grafana-datasources.sh
else
    echo "⚠️  Warning: prepare-grafana-datasources.sh not found, skipping datasource preparation"
fi
echo ""

# 3. Start docker-compose
echo "3️⃣  Starting Docker Compose..."
docker-compose --env-file "env.${ENVIRONMENT}" up -d

echo ""
echo "✅ Monitoring stack started!"
echo ""
echo "📊 Services:"
echo "   - Grafana: http://localhost:3001 (admin/${GRAFANA_ADMIN_PASSWORD})"
echo "   - Prometheus: http://localhost:9090"
echo "   - Loki: http://localhost:3100"
echo ""
echo "🔍 Check status:"
echo "   docker-compose ps"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f"
echo ""

