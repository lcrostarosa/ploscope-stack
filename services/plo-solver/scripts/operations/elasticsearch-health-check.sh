#!/bin/bash

# Elasticsearch Health Check Script
# This script reads the password from environment variables for health checks

set -e

ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-localhost:9200}

# Check if Elasticsearch is responding
if curl -f -u elastic:${ELASTIC_PASSWORD} "http://${ELASTICSEARCH_HOST}/_cluster/health" > /dev/null 2>&1; then
    echo "Elasticsearch is healthy"
    exit 0
else
    echo "Elasticsearch health check failed"
    exit 1
fi 