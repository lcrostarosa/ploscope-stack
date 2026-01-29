#!/bin/bash

# ===========================================
# Generate Production Secrets Script
# ===========================================
#
# This script generates secure random secrets for production environment variables
# Run this script to generate new secrets for your production environment
#
# Usage:
# ./scripts/setup/generate-production-secrets.sh
#
# This will output the secrets that you can copy into your env.production file

set -e

echo "==========================================="
echo "PLO Solver - Production Secrets Generator"
echo "==========================================="
echo ""
echo "Generating secure random secrets for production..."
echo ""

# Generate a secure secret key (64 characters)
SECRET_KEY=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-64)
echo "SECRET_KEY=$SECRET_KEY"
echo ""

# Generate a secure JWT secret key (64 characters)
JWT_SECRET_KEY=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-64)
echo "JWT_SECRET_KEY=$JWT_SECRET_KEY"
echo ""

# Generate a secure database password (32 characters)
DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
echo "POSTGRES_PASSWORD=$DB_PASSWORD"
echo ""

# Generate a secure RabbitMQ password (32 characters)
RABBITMQ_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
echo "RABBITMQ_DEFAULT_PASS=$RABBITMQ_PASSWORD"
echo "RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD"
echo ""

# Generate a secure Discourse SSO secret (32 characters)
DISCOURSE_SSO_SECRET=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
echo "DISCOURSE_SSO_SECRET=$DISCOURSE_SSO_SECRET"
echo ""

# Generate a secure Discourse webhook secret (32 characters)
DISCOURSE_WEBHOOK_SECRET=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
echo "DISCOURSE_WEBHOOK_SECRET=$DISCOURSE_WEBHOOK_SECRET"
echo ""

# Generate a secure Discourse database password (32 characters)
DISCOURSE_DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
echo "DISCOURSE_DB_PASSWORD=$DISCOURSE_DB_PASSWORD"
echo ""

echo "==========================================="
echo "Copy these values into your env.production file"
echo "==========================================="
echo ""
echo "Also update your DATABASE_URL to use the new POSTGRES_PASSWORD:"
echo "DATABASE_URL=postgresql://postgres:$DB_PASSWORD@db:5432/plosolver"
echo ""
echo "Remember to:"
echo "1. Never commit env.production to git"
echo "2. Keep these secrets secure"
echo "3. Rotate secrets regularly in production"
echo "4. Use different secrets for each environment" 