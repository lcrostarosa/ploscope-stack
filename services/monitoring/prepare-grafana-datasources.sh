#!/bin/bash
# Prepare Grafana datasource files by substituting environment variables
# This script processes datasource YAML files using envsubst

set -e

ENVIRONMENT=${ENVIRONMENT:-staging}
SOURCE_DIR="./grafana-config/grafana-datasources-provisioning"
TARGET_DIR="./grafana-config/grafana-datasources-provisioning-processed"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Source file based on environment
SOURCE_FILE="${SOURCE_DIR}/datasources.${ENVIRONMENT}.yml"
TARGET_FILE="${TARGET_DIR}/datasources.yml"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file $SOURCE_FILE not found!"
    exit 1
fi

# Export all PRODUCTION_* variables if they're not already set
# In CI/CD environments, variables may already be exported, so we check first
if [ -f "env.${ENVIRONMENT}" ]; then
    echo "Loading environment variables from env.${ENVIRONMENT}..."
    set -a
    source "env.${ENVIRONMENT}"
    set +a
else
    echo "Note: env.${ENVIRONMENT} file not found. Using environment variables already set in the environment."
fi

# Check if required variables are set
if [ -z "$PRODUCTION_PROMETHEUS_URL" ]; then
    echo "Warning: PRODUCTION_PROMETHEUS_URL is not set. Datasource may not work correctly."
fi

if [ -z "$PRODUCTION_LOKI_URL" ]; then
    echo "Warning: PRODUCTION_LOKI_URL is not set. Datasource may not work correctly."
fi

# Use envsubst to substitute environment variables
# Only substitute variables that start with PRODUCTION_ to avoid unintended substitutions
echo "Processing datasource file: $SOURCE_FILE -> $TARGET_FILE"

# Create a list of variables to substitute for envsubst
# envsubst requires variables in format: $VAR1 $VAR2 or ${VAR1} ${VAR2}
VARS_TO_SUBST=""
for var in PRODUCTION_PROMETHEUS_URL PRODUCTION_PROMETHEUS_USER PRODUCTION_PROMETHEUS_PASSWORD \
           PRODUCTION_LOKI_URL PRODUCTION_LOKI_USER PRODUCTION_LOKI_PASSWORD; do
    if [ -n "${!var}" ]; then
        VARS_TO_SUBST="$VARS_TO_SUBST \${$var}"
    fi
done

# Export variables explicitly for envsubst
export PRODUCTION_PROMETHEUS_URL PRODUCTION_PROMETHEUS_USER PRODUCTION_PROMETHEUS_PASSWORD
export PRODUCTION_LOKI_URL PRODUCTION_LOKI_USER PRODUCTION_LOKI_PASSWORD

# Use envsubst - it will substitute all ${VAR} patterns found in the file
envsubst < "$SOURCE_FILE" > "$TARGET_FILE"

echo "✅ Datasource file processed successfully"
echo "   Variables substituted: $VARS_TO_SUBST"
echo "   Target file: $TARGET_FILE"

# Show a preview of the processed file (without sensitive data)
echo ""
echo "Preview of processed file (URLs only):"
grep -E "(url:|basicAuthUser:)" "$TARGET_FILE" | sed 's/password:.*/password: ***REDACTED***/'
