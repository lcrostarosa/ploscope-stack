#!/bin/bash

set -e

echo "Starting database..."
docker compose up -d db

echo "Waiting for database to be healthy..."
# Wait for database to be ready (max 60 seconds)
for i in {1..30}; do
  if docker compose -f exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    echo "Database is healthy!"
    break
  fi
  echo "Waiting for database... ($i/30)"
  sleep 2
done

# Final check
if ! docker compose -f exec -T db pg_isready -U postgres >/dev/null 2>&1; then
  echo "ERROR: Database failed to become healthy within 60 seconds"
  exit 1
fi

echo "Running alembic validation..."
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/plosolver poetry run alembic -c alembic.ini current
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/plosolver poetry run alembic -c alembic.ini history

echo "Alembic validation completed successfully!"

echo "Shutting down database..."
docker compose -f down db

echo "Database shutdown completed!"
