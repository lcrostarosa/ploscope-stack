#!/bin/bash

# Setup admin policy for Vault
# This script creates an admin policy and token for managing plo-solver secrets

set -e

echo "Setting up admin policy for Vault..."

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until vault status > /dev/null 2>&1; do
  echo "Vault not ready, waiting..."
  sleep 2
done

# Create the admin policy
echo "Creating admin policy..."
vault policy write admin-policy /vault/policies/admin-policy.hcl

# Create an admin token with the policy
echo "Creating admin token..."
ADMIN_TOKEN=$(vault token create -policy=admin-policy -ttl=8760h -format=json | jq -r '.auth.client_token')

echo "Admin token created: $ADMIN_TOKEN"
echo "This token allows full CRUD operations on plo-solver secrets only"
echo "Save this token securely - it has admin privileges!"

# Save token to file for easy access
echo "$ADMIN_TOKEN" > /vault/scripts/admin-token.txt
echo "Token saved to /vault/scripts/admin-token.txt"

# Create some example secrets using the admin token
echo "Creating example secrets with admin token..."
export VAULT_TOKEN=$ADMIN_TOKEN

# Create example secrets
vault kv put secret/plo-solver/database-password password="admin-created-password" 2>/dev/null || echo "Secret already exists"
vault kv put secret/plo-solver/api-key key="admin-created-api-key" 2>/dev/null || echo "Secret already exists"
vault kv put secret/plo-solver/redis-password password="admin-created-redis-password" 2>/dev/null || echo "Secret already exists"

echo "Example secrets created successfully!"
echo ""
echo "Admin setup complete. Use the admin token for managing plo-solver secrets." 