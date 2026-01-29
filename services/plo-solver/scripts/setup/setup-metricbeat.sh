#!/bin/bash

# Setup Metricbeat for PLOSolver
# This script configures metricbeat for system and Docker monitoring

set -e

echo "🔧 Setting up Metricbeat for PLOSolver..."
echo "=========================================="

# Check if metricbeat directory exists
if [ ! -d "./server/metricbeat" ]; then
    echo "❌ Metricbeat directory not found. Please run this script from the project root."
    exit 1
fi

echo "📁 Checking metricbeat configuration..."

# Check if metricbeat.yml exists
if [ ! -f "./server/metricbeat/metricbeat.yml" ]; then
    echo "❌ metricbeat.yml not found. Please ensure the configuration file exists."
    exit 1
fi

# Check if modules.d directory exists
if [ ! -d "./server/metricbeat/modules.d" ]; then
    echo "📁 Creating modules.d directory..."
    mkdir -p ./server/metricbeat/modules.d
fi

echo "✅ Metricbeat configuration files found"

# Test metricbeat configuration
echo "🔍 Testing metricbeat configuration..."
if docker run --rm \
    -v "$(pwd)/server/metricbeat/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml:ro" \
    -v "$(pwd)/server/metricbeat/modules.d:/usr/share/metricbeat/modules.d:ro" \
    docker.elastic.co/beats/metricbeat:8.12.0 \
    metricbeat test config; then
    echo "✅ Metricbeat configuration is valid"
else
    echo "❌ Metricbeat configuration is invalid"
    exit 1
fi

echo ""
echo "🎯 Metricbeat setup complete!"
echo ""
echo "📋 Usage:"
echo "   # Start all services including metricbeat:"
echo "   docker-compose up -d"
echo ""
echo "   # View metricbeat logs:"
echo "   docker-compose logs metricbeat"
echo ""
echo "   # Access Kibana to view metrics:"
echo "   http://localhost:5601"
echo ""
echo "   # Check metricbeat health:"
echo "   curl http://localhost:5067/api/status"
echo ""
echo "📊 Available metrics:"
echo "   - System CPU, memory, and network usage"
echo "   - Docker container metrics"
echo "   - Process monitoring"
echo "   - Filesystem statistics"
echo ""
echo "🔗 Kibana dashboards will be automatically created" 