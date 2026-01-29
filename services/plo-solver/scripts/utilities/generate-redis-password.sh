#!/bin/bash

# Generate a secure Redis password
# This script creates a cryptographically secure password for Redis

set -e

echo "🔐 Generating secure Redis password..."

# Generate a secure password using openssl
PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

echo "✅ Generated secure Redis password:"
echo ""
echo "REDIS_PASSWORD=${PASSWORD}"
echo ""
echo "📋 To use this password:"
echo "1. Update your env.staging file with this password"
echo "2. Update your docker-compose.staging.yml to use \${REDIS_PASSWORD}"
echo "3. Set the REDIS_PASSWORD environment variable in your deployment"
echo ""
echo "🔒 Security notes:"
echo "- This password is 25 characters long"
echo "- Contains uppercase, lowercase, and numbers"
echo "- Generated using cryptographically secure random number generator"
echo "- Store this password securely and don't commit it to version control"
echo ""
echo "💡 For production environments:"
echo "- Use environment variables or secrets management"
echo "- Rotate passwords regularly"
echo "- Consider using Redis ACLs for more granular access control"
