#!/bin/bash

# Clean up existing containers and volumes
docker compose --profile localdev rm -f
docker volume rm postgres-data rabbitmq-data shared-logs || true
docker volume create postgres-data
docker volume create rabbitmq-data
docker volume create shared-logs

# Create the external network if it doesn't exist
docker network create plo-network-cloud --subnet=172.30.0.0/16 || true

# Set environment variables
export DB_INIT_TAG=staging
export BACKEND_TAG=staging
export NEXUS_PYPI_USERNAME=your-nexus-username
export NEXUS_PYPI_PASSWORD=your-nexus-password

# Database configuration - using plosolver as requested
export PGPASSWORD=postgres
export POSTGRES_HOST=db
export POSTGRES_MIGRATE_HOST=db
export SCHEMA_USER=postgres
export SCHEMA_PASSWORD=postgres
export POSTGRES_SCHEMA_USER=postgres
export POSTGRES_SCHEMA_PASSWORD=postgres
export DATABASE_URL=postgresql://postgres:postgres@db:5432/plosolver
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export POSTGRES_DB=plosolver
export POSTGRES_PORT=5432
export POSTGRES_DATA_PATH=./data/postgres
export POSTGRES_BACKUP_PATH=./backups

# RabbitMQ configuration
export RABBITMQ_DEFAULT_USER=plosolver
export RABBITMQ_DEFAULT_PASS=dev_password_2024
export RABBITMQ_SPOT_QUEUE=spot-processing
export RABBITMQ_SOLVER_QUEUE=solver-processing
export RABBITMQ_SPOT_DLQ=spot-processing-dlq
export RABBITMQ_SOLVER_DLQ=solver-processing-dlq
export RABBITMQ_VHOST=/plosolver
export RABBITMQ_USERNAME=plosolver
export RABBITMQ_PASSWORD=dev_password_2024
export RABBITMQ_HOST=rabbitmq
export RABBITMQ_PORT=5672

# Application configuration
export ENVIRONMENT=staging
export FLASK_ENV=production
export NODE_ENV=production
export FLASK_DEBUG=false
export LOG_LEVEL=DEBUG
export REACT_APP_API_URL=/api
export SECRET_KEY=dev-secret-key-change-in-production
export JWT_SECRET_KEY=your-jwt-secret-key-here

# OAuth and CORS
export GOOGLE_CLIENT_ID=your-google-client-id
export GOOGLE_CLIENT_SECRET=your-google-client-secret
export FRONTEND_URL=http://localhost:3001
export WEBSOCKET_CORS_ORIGINS=http://localhost:3001,http://127.0.0.1:3001,http://localhost,http://127.0.0.1,http://*.

# Stripe configuration
export STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
export STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key
export STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
export STRIPE_PRICE_PRO_MONTHLY=price_1234567890abcdef
export STRIPE_PRICE_PRO_YEARLY=price_1234567890abcdef
export STRIPE_PRICE_ELITE_MONTHLY=price_1234567890abcdef
export STRIPE_PRICE_ELITE_YEARLY=price_1234567890abcdef

# Discourse configuration
export DISCOURSE_URL=http://localhost:4080
export DISCOURSE_DOMAIN=forum.localhost
export DISCOURSE_SSO_SECRET=change-this-secret
export DISCOURSE_WEBHOOK_SECRET=your-discourse-webhook-secret-here
export DISCOURSE_DB_USER=discourse
export DISCOURSE_DB_PASSWORD=discourse_secure_password
export DISCOURSE_DB_NAME=discourse
export DISCOURSE_DEVELOPER_EMAILS=admin@plosolver.local

# New Relic
export NEW_RELIC_LICENSE_KEY=your-new-relic-license-key
export NEW_RELIC_ENVIRONMENT=development

# Docker configuration
export BUILD_ENV=development
export RESTART_POLICY=unless-stopped
export VOLUME_MODE=rw

# Container environment
export TESTING=false
export CONTAINER_ENV=production

# Start the routes_grpc
docker compose --profile localdev up
