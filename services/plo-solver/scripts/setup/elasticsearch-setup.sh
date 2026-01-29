#!/bin/bash

# Elasticsearch Setup Script for ELK Stack
# This script sets up users and roles for Kibana, Logstash, and Beats

set -e

ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-localhost:9200}

echo "Setting up Elasticsearch users and roles..."

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s -u elastic:${ELASTIC_PASSWORD} "http://${ELASTICSEARCH_HOST}/_cluster/health" > /dev/null 2>&1; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

echo "Elasticsearch is ready!"

# Create roles
echo "Creating roles..."

# Kibana system role
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  "http://${ELASTICSEARCH_HOST}/_security/role/kibana_system" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor", "manage_api_key"],
    "indices": [
      {
        "names": [".kibana*"],
        "privileges": ["all"]
      }
    ]
  }' || echo "Role kibana_system already exists"

# Logstash writer role
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  "http://${ELASTICSEARCH_HOST}/_security/role/logstash_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor"],
    "indices": [
      {
        "names": ["logstash-*", "plosolver-*"],
        "privileges": ["create_index", "write", "delete", "manage"]
      }
    ]
  }' || echo "Role logstash_writer already exists"

# Beats writer role
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  "http://${ELASTICSEARCH_HOST}/_security/role/beats_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor"],
    "indices": [
      {
        "names": ["filebeat-*", "metricbeat-*", "plosolver-*"],
        "privileges": ["create_index", "write", "delete", "manage"]
      }
    ]
  }' || echo "Role beats_writer already exists"

# Create users
echo "Creating users..."

# Kibana system user
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  "http://${ELASTICSEARCH_HOST}/_security/user/kibana_system" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "'${ELASTIC_PASSWORD}'",
    "roles": ["kibana_system"],
    "full_name": "Kibana System User"
  }' || echo "User kibana_system already exists"

# Logstash writer user
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  "http://${ELASTICSEARCH_HOST}/_security/user/logstash_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "'${ELASTIC_PASSWORD}'",
    "roles": ["logstash_writer"],
    "full_name": "Logstash Writer User"
  }' || echo "User logstash_writer already exists"

# Beats writer user
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  "http://${ELASTICSEARCH_HOST}/_security/user/beats_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "'${ELASTIC_PASSWORD}'",
    "roles": ["beats_writer"],
    "full_name": "Beats Writer User"
  }' || echo "User beats_writer already exists"

echo "Elasticsearch setup complete!"
echo "Users created:"
echo "  - elastic:${ELASTIC_PASSWORD} (admin)"
echo "  - kibana_system:${ELASTIC_PASSWORD}"
echo "  - logstash_writer:${ELASTIC_PASSWORD}"
echo "  - beats_writer:${ELASTIC_PASSWORD}" 