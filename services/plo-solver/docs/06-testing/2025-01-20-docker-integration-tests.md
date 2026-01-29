# Docker Integration Tests

This document describes the Docker-based integration testing setup for PLOSolver, which allows running integration tests against live Docker containers instead of requiring native installations of services like RabbitMQ and PostgreSQL.

## Overview

The Docker integration test system provides:

- **Isolated test environment**: Tests run against dedicated Docker containers
- **Real service testing**: Tests interact with actual RabbitMQ and PostgreSQL instances
- **Consistent environment**: Same test environment across different development machines
- **Easy setup**: No need to install and configure services locally
- **Clean isolation**: Test containers are automatically cleaned up after tests

## Architecture

### Test Services

The integration tests use the following Docker services:

1. **test-postgres**: PostgreSQL 15 database for test data
2. **test-rabbitmq**: RabbitMQ 3.13 with management interface
3. **test-backend**: Application container running the tests

### Network Isolation

All test services run on a dedicated Docker network (`plosolver-test-network`) to ensure isolation from the main application containers.

## Setup

### Prerequisites

1. **Docker**: Ensure Docker and docker compose are installed and running
2. **Python dependencies**: Install the Docker test requirements

```bash
cd src/backend
pip install -r requirements-docker-test.txt
```

### Configuration

The test environment uses the following configuration:

- **PostgreSQL**: 
  - Host: `localhost:5433` (mapped from container port 5432)
  - Database: `test_plosolver`
  - User: `test_user`
  - Password: `test_password`

- **RabbitMQ**:
  - Host: `localhost:5673` (mapped from container port 5672)
  - Management: `localhost:15673` (mapped from container port 15672)
  - User: `test_user`
  - Password: `test_password`
  - VHost: `/test`

## Running Tests

### Method 1: Using Makefile (Recommended)

```bash
# Run all integration tests (frontend + backend)
make test-integration

# Run backend integration tests only
make test-backend-integration
```

### Method 2: Using Script Directly

```bash
# Run the integration test script
./scripts/run-docker-integration-tests.sh
```

### Method 3: Using Docker Compose

```bash
# Start test services and run tests
docker compose -f docker-compose.yml --profile test up --build --abort-on-container-exit

# Start services only (for manual testing)
docker compose -f docker-compose.yml up -d test-postgres test-rabbitmq
```

### Method 4: Running Individual Test Files

```bash
cd src/backend

# Set environment variables for Docker containers
export RABBITMQ_HOST=localhost
export RABBITMQ_PORT=5673
export RABBITMQ_USERNAME=test_user
export RABBITMQ_PASSWORD=test_password
export RABBITMQ_VHOST=/test
export DATABASE_URL=postgresql://test_user:test_password@localhost:5433/test_plosolver

# Run specific test files
python -m pytest tests/integration/test_docker_rabbitmq_integration.py -v --docker-integration
python -m pytest tests/integration/test_docker_job_workflow.py -v --docker-integration
```

## Test Structure

### Test Files

1. **`test_docker_rabbitmq_integration.py`**: Tests RabbitMQ message queue functionality
2. **`test_docker_job_workflow.py`**: Tests job creation, processing, and workflow

### Test Fixtures

The tests use fixtures from `conftest_docker.py`:

- `docker_env`: Session-scoped Docker test environment
- `rabbitmq_container`: RabbitMQ container configuration
- `postgres_container`: PostgreSQL container configuration
- `docker_app`: Flask app configured for Docker containers
- `docker_client`: Test client for Docker-configured app
- `docker_user`: Test user for integration tests

### Test Markers

Tests are marked with specific pytest markers:

- `@pytest.mark.integration`: Integration test marker
- `@pytest.mark.docker`: Docker-specific test marker
- `@pytest.mark.slow`: Slow-running tests

## Test Categories

### RabbitMQ Integration Tests

- Service creation and health checks
- Message sending and receiving
- Queue management and attributes
- Connection recovery
- Message persistence
- Large message handling
- Throughput testing

### Job Workflow Tests

- Job creation and processing
- Queue integration
- Status updates
- Job retrieval and cancellation
- Error handling
- Service integration
- Data persistence

## Environment Variables

The following environment variables are used for Docker integration tests:

```bash
# RabbitMQ Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5673
RABBITMQ_USERNAME=test_user
RABBITMQ_PASSWORD=test_password
RABBITMQ_VHOST=/test

# Database Configuration
DATABASE_URL=postgresql://test_user:test_password@localhost:5433/test_plosolver

# Application Configuration
SECRET_KEY=test-secret-key
JWT_SECRET_KEY=test-jwt-secret-key
LOG_LEVEL=DEBUG
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 5433, 5673, and 15673 are not in use
2. **Docker not running**: Start Docker Desktop or Docker daemon
3. **Permission issues**: Ensure Docker commands can be run without sudo
4. **Network issues**: Clean up existing networks with `docker network prune`

### Debugging

1. **Check container status**:
   ```bash
   docker compose -f docker-compose.yml ps
   ```

2. **View container logs**:
   ```bash
   docker compose -f docker-compose.yml logs test-postgres
   docker compose -f docker-compose.yml logs test-rabbitmq
   ```

3. **Access container shell**:
   ```bash
   docker compose -f docker-compose.yml exec test-postgres bash
   docker compose -f docker-compose.yml exec test-rabbitmq bash
   ```

4. **Check network connectivity**:
   ```bash
   docker network ls
   docker network inspect plosolver-test-network
   ```

### Cleanup

To clean up test containers and volumes:

```bash
# Stop and remove containers
docker compose -f docker-compose.yml down --volumes --remove-orphans

# Remove test network
docker network rm plosolver-test-network

# Clean up all unused Docker resources
docker system prune -f
```

## Performance Considerations

### Test Execution Time

- **Fast tests**: Basic functionality tests (~1-5 seconds each)
- **Slow tests**: Throughput and performance tests (~10-30 seconds each)
- **Total suite**: Complete test suite (~2-5 minutes)

### Resource Usage

- **Memory**: ~500MB for PostgreSQL + ~200MB for RabbitMQ
- **CPU**: Minimal during idle, spikes during test execution
- **Disk**: ~100MB for container images + test data

### Optimization Tips

1. **Parallel execution**: Tests can be run in parallel using `pytest-xdist`
2. **Container reuse**: Use `--reuse-containers` flag to reuse containers between test runs
3. **Selective testing**: Use pytest markers to run specific test categories

## Integration with CI/CD

### GitHub Actions

The Docker integration tests can be integrated into CI/CD pipelines:

```yaml
- name: Run Integration Tests
  run: |
    make test-integration
```

### Local Development

For local development, you can run tests in watch mode:

```bash
# Install pytest-watch
pip install pytest-watch

# Run tests in watch mode
cd src/backend
ptw tests/integration/ -- --docker-integration
```

## Best Practices

1. **Always clean up**: Ensure containers are properly cleaned up after tests
2. **Use test data**: Use factories and fixtures for consistent test data
3. **Isolate tests**: Each test should be independent and not rely on others
4. **Handle timeouts**: Use appropriate timeouts for service health checks
5. **Log debugging**: Add logging for complex test scenarios
6. **Error handling**: Test both success and failure scenarios

## Future Enhancements

1. **Test parallelization**: Implement parallel test execution
2. **Performance benchmarks**: Add performance regression testing
3. **Load testing**: Add load testing scenarios
4. **Multi-service testing**: Test interactions with additional services
5. **Snapshot testing**: Add snapshot testing for complex data structures 