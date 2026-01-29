#!/bin/bash

# Start ELK Stack
# This script starts the Elasticsearch, Logstash, and Kibana services

set -e

echo "Starting ELK Stack..."

# Create logs directory if it doesn't exist
mkdir -p logs

# Start ELK services
docker compose up -d elasticsearch logstash kibana

echo "Waiting for Elasticsearch to be ready..."
until curl -f http://localhost:9200/_cluster/health > /dev/null 2>&1; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

echo "Elasticsearch is ready!"

echo "Waiting for Kibana to be ready..."
until curl -f http://localhost:5601/api/status > /dev/null 2>&1; do
    echo "Waiting for Kibana..."
    sleep 5
done

echo "Kibana is ready!"

echo ""
echo "ELK Stack is running!"
echo "===================="
echo "Elasticsearch: http://localhost:9200"
echo "Kibana: http://localhost:5601"
echo ""
echo "To access via SSH tunnel:"
echo "  ssh -L 5601:localhost:5601 user@your-server"
echo "  ssh -L 9200:localhost:9200 user@your-server"
echo ""
echo "Check logs with:"
echo "  docker compose logs elasticsearch"
echo "  docker compose logs logstash"
echo "  docker compose logs kibana" 