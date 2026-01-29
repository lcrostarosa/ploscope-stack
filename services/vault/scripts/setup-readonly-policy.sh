#!/bin/bash

# Setup read-only policy for containers
# This script should be run after Vault is initialized

set -e

echo "Setting up read-only policy for containers..."

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until vault status > /dev/null 2>&1; do
  echo "Vault not ready, waiting..."
  sleep 2
done

# Create the read-only policy
echo "Creating read-only policy..."
vault policy write container-readonly /vault/policies/read-only-policy.hcl

# Create a token for containers with read-only access
echo "Creating read-only token for containers..."
READONLY_TOKEN=$(vault token create -policy=container-readonly -ttl=8760h -format=json | jq -r '.auth.client_token')

echo "Read-only token created: $READONLY_TOKEN"
echo "This token should be provided to containers via environment variable VAULT_TOKEN"
echo "Containers will only have read access to secrets under secret/data/plo-solver/*"

# Save token to file for easy access
echo "$READONLY_TOKEN" > /vault/scripts/container-readonly-token.txt
echo "Token saved to /vault/scripts/container-readonly-token.txt" 