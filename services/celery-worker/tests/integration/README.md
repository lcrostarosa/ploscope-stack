# Integration Tests

This directory contains integration tests that require external services to be running.

## Prerequisites

Before running integration tests, ensure the following services are running:

### Required Services

1. **Redis** - For Celery result backend
   ```bash
   redis-server
   ```

2. **PostgreSQL Database** - For data persistence
   ```bash
   # Using Docker
   docker run --name postgres-test -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=plosolver -p 5432:5432 -d postgres:13

   # Or using local installation
   # Make sure PostgreSQL is running and accessible
   ```

3. **RabbitMQ** - For Celery message broker
   ```bash
   # Using Docker
   docker run --name rabbitmq-test -e RABBITMQ_DEFAULT_USER=guest -e RABBITMQ_DEFAULT_PASS=guest -p 5672:5672 -p 15672:15672 -d rabbitmq:3-management

   # Or using local installation
   # Make sure RabbitMQ is running and accessible
   ```

## Environment Variables

Set the following environment variables for integration tests:

```bash
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/plosolver"
export CELERY_BROKER_URL="amqp://guest:guest@localhost:5672//"
export CELERY_RESULT_BACKEND="redis://localhost:6379/0"
```

## Running Integration Tests

### Using Make

```bash
# Run all integration tests
make test-integration

# Run specific integration test file
poetry run pytest tests/integration/test_database.py -v

# Run with specific markers
poetry run pytest tests/integration/ -m "integration" -v
```

### Using pytest directly

```bash
# Run all integration tests
poetry run pytest tests/integration/ -m "integration" -v

# Run specific test file
poetry run pytest tests/integration/test_database.py -v

# Run with coverage
poetry run pytest tests/integration/ -m "integration" --cov=src --cov-report=html
```

## Test Files

- `test_database.py` - Database connection and session management tests
- `test_database_health_check.py` - Database health check functionality
- `test_redis_health_check.py` - Redis health check functionality
- `test_rabbitmq_health_check.py` - RabbitMQ health check functionality

## Notes

- Integration tests are marked with `@pytest.mark.integration`
- These tests require actual external services and may take longer to run
- Some tests may fail if services are not properly configured or running
- Integration tests are excluded from the default `make test` command to ensure fast unit test execution
