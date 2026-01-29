#!/bin/bash

# Elasticsearch Health Check Script for Staging (SSL enabled)
# This script reads the password from environment variables for health checks

set -e

ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-localhost:9200}

# Check if Elasticsearch is responding with SSL
if curl -f -k -u elastic:${ELASTIC_PASSWORD} "https://${ELASTICSEARCH_HOST}/_cluster/health" > /dev/null 2>&1; then
    echo "Elasticsearch is healthy (SSL)"
    exit 0
else
    echo "Elasticsearch health check failed (SSL)"
    exit 1
fi 