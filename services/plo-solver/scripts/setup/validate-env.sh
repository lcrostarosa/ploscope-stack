#!/bin/bash

# ===========================================
# Environment Validation Script
# ===========================================
#
# This script validates that environment variables are properly set up
# Run this script to check your environment configuration
#
# Usage:
# ./scripts/setup/validate-env.sh [environment]
#
# Examples:
# ./scripts/setup/validate-env.sh production
# ./scripts/setup/validate-env.sh development

set -e

ENV_FILE=""
ENV_NAME=""

if [ $# -eq 0 ]; then
    echo "Usage: $0 [environment]"
    echo "Environments: production, development, staging, test"
    exit 1
fi

case $1 in
    production)
        ENV_FILE="env.production"
        ENV_NAME="Production"
        ;;
    development)
        ENV_FILE="env.development"
        ENV_NAME="Development"
        ;;
    staging)
        ENV_FILE="env.staging"
        ENV_NAME="Staging"
        ;;
    test)
        ENV_FILE="env.test"
        ENV_NAME="Test"
        ;;
    *)
        echo "Unknown environment: $1"
        echo "Valid environments: production, development, staging, test"
        exit 1
        ;;
esac

echo "==========================================="
echo "PLO Solver - $ENV_NAME Environment Validation"
echo "==========================================="
echo ""

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: $ENV_FILE not found"
    echo ""
    if [ "$1" = "production" ]; then
        echo "To create production environment:"
        echo "1. cp env.production.template env.production"
        echo "2. ./scripts/setup/generate-production-secrets.sh"
        echo "3. Edit env.production with your values"
    elif [ "$1" = "staging" ]; then
        echo "To create staging environment:"
        echo "1. cp env.staging.template env.staging"
        echo "2. Edit env.staging with your values"
    fi
    exit 1
fi

echo "✅ $ENV_FILE found"
echo ""

# Load environment variables
set -a
source "$ENV_FILE"
set +a

# Check required variables
echo "Checking required variables..."
echo ""

# Database variables
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "❌ POSTGRES_PASSWORD not set"
else
    echo "✅ POSTGRES_PASSWORD is set (${#POSTGRES_PASSWORD} characters)"
fi

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set"
else
    echo "✅ DATABASE_URL is set"
fi

# Security variables
if [ -z "$SECRET_KEY" ]; then
    echo "❌ SECRET_KEY not set"
else
    echo "✅ SECRET_KEY is set (${#SECRET_KEY} characters)"
fi

if [ -z "$JWT_SECRET_KEY" ]; then
    echo "❌ JWT_SECRET_KEY not set"
else
    echo "✅ JWT_SECRET_KEY is set (${#JWT_SECRET_KEY} characters)"
fi

# RabbitMQ variables
if [ -z "$RABBITMQ_DEFAULT_PASS" ]; then
    echo "❌ RABBITMQ_DEFAULT_PASS not set"
else
    echo "✅ RABBITMQ_DEFAULT_PASS is set (${#RABBITMQ_DEFAULT_PASS} characters)"
fi

echo ""

# Check if this is a production environment and validate security
if [ "$1" = "production" ]; then
    echo "Production Security Checks:"
    echo ""
    
    # Check for placeholder values
    if [[ "$POSTGRES_PASSWORD" == *"your-secure"* ]] || [[ "$POSTGRES_PASSWORD" == *"placeholder"* ]]; then
        echo "❌ WARNING: POSTGRES_PASSWORD contains placeholder value"
    fi
    
    if [[ "$SECRET_KEY" == *"your-secure"* ]] || [[ "$SECRET_KEY" == *"placeholder"* ]]; then
        echo "❌ WARNING: SECRET_KEY contains placeholder value"
    fi
    
    if [[ "$JWT_SECRET_KEY" == *"your-secure"* ]] || [[ "$JWT_SECRET_KEY" == *"placeholder"* ]]; then
        echo "❌ WARNING: JWT_SECRET_KEY contains placeholder value"
    fi
    
    # Check domain configuration
    if [[ "$FRONTEND_DOMAIN" == *"your-production-domain"* ]]; then
        echo "❌ WARNING: FRONTEND_DOMAIN contains placeholder value"
    else
        echo "✅ FRONTEND_DOMAIN is configured: $FRONTEND_DOMAIN"
    fi
    
    # Check email configuration
    if [[ "$ACME_EMAIL" == *"your-email"* ]]; then
        echo "❌ WARNING: ACME_EMAIL contains placeholder value"
    else
        echo "✅ ACME_EMAIL is configured: $ACME_EMAIL"
    fi
    
    echo ""
    echo "Security Recommendations:"
    echo "1. Use the secrets generator: ./scripts/setup/generate-production-secrets.sh"
    echo "2. Replace all placeholder values with real values"
    echo "3. Ensure secrets are at least 32 characters long"
    echo "4. Use different secrets for each environment"
fi

echo ""
echo "==========================================="
echo "Validation complete for $ENV_NAME environment"
echo "===========================================" 