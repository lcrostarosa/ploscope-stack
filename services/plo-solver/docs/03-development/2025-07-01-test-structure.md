# PLOSolver Test Structure

## Overview

The PLOSolver backend has been restructured to separate unit tests from integration tests, providing better organization and faster feedback during development.

## Test Categories

### Unit Tests
- **Location**: `src/backend/tests/unit/`
- **Purpose**: Test individual components in isolation
- **Dependencies**: Mocked database responses, no external services
- **Speed**: Fast execution
- **Coverage**: Core business logic, utilities, and isolated components
- **Database**: Mocked PostgreSQL operations

### Integration Tests
- **Location**: `src/backend/tests/integration/`
- **Purpose**: Test component interactions and external service integration
- **Dependencies**: Real PostgreSQL (Docker), RabbitMQ, Docker containers
- **Speed**: Slower execution due to external dependencies
- **Coverage**: End-to-end workflows, service integration, Docker container testing
- **Database**: Real PostgreSQL database

## Available Test Commands

### Main Test Commands

```bash
# Run all tests (unit + integration)
make test

# Run unit tests only
make test-unit

# Run integration tests only
make test-integration

# Run backend tests only (unit + integration)
make test-backend

# Run frontend tests only
make test-frontend
```

### Comprehensive Test Commands

```bash
# Run all tests (frontend + backend)
make test

# Run all unit tests (frontend + backend)
make test-unit

# Run all integration tests (frontend + backend)
make test-integration

# Frontend tests
make test-frontend
make test-frontend-unit
make test-frontend-integration

# Backend tests
make test-backend
make test-backend-unit
make test-backend-integration
```

## Direct Script Usage

### Unit Test Runner

```bash
# From project root
cd scripts && ./run_unit_tests.sh

# Options
./run_unit_tests.sh --coverage    # Run with coverage
./run_unit_tests.sh --verbose     # Verbose output
./run_unit_tests.sh --fail-fast   # Stop on first failure
./run_unit_tests.sh --help        # Show help
```

### Integration Test Runner

```bash
# From project root
cd scripts && ./run_integration_tests.sh

# Options
./run_integration_tests.sh --coverage      # Run with coverage
./run_integration_tests.sh --verbose       # Verbose output
./run_integration_tests.sh --fail-fast     # Stop on first failure
./run_integration_tests.sh --docker-only   # Run only Docker tests
./run_integration_tests.sh --rabbitmq-only # Run only RabbitMQ tests
./run_integration_tests.sh --help          # Show help
```

## Test Organization

### Unit Tests (`tests/unit/`)

- **`test_auth_routes.py`** - Authentication endpoint testing
- **`test_auth_utils.py`** - Authentication utility functions
- **`test_discourse_routes.py`** - Discourse integration routes
- **`test_hand_history_parser.py`** - Hand history parsing logic
- **`test_job_routes.py`** - Job management endpoints
- **`test_models.py`** - Database model testing
- **`test_player_profiles.py`** - Player profile functionality
- **`test_rate_limiter.py`** - Rate limiting logic
- **`test_rabbitmq_service.py`** - RabbitMQ service unit tests
- **`test_solver_engine.py`** - Core solver logic
- **`test_solver_routes.py`** - Solver endpoint testing
- **`test_spot_routes.py`** - Spot management endpoints
- **`test_subscription_routes.py`** - Subscription management

### Integration Tests (`tests/integration/`)

- **`test_docker_job_workflow.py`** - Docker-based job processing
- **`test_docker_rabbitmq_integration.py`** - Docker + RabbitMQ integration
- **`test_docker_setup.py`** - Docker container setup and configuration
- **`test_job_workflow.py`** - End-to-end job processing workflows
- **`test_rabbitmq_integration.py`** - RabbitMQ service integration

## Development Workflow

### During Development

1. **Quick Feedback**: Use `make test-unit` for fast feedback on code changes
2. **Full Validation**: Use `make test` before committing to ensure all tests pass
3. **Integration Testing**: Use `make test-integration` when working on service integration

### CI/CD Pipeline

```bash
# Unit tests (fast, no external dependencies)
make test-unit

# Integration tests (slower, requires Docker)
make test-integration

# Full test suite
make test
```

## Test Configuration

### Unit Test Configuration
- Uses mocked PostgreSQL database operations
- Mocked external services (RabbitMQ, etc.)
- Fast execution
- No Docker requirements
- No real database connections

### Integration Test Configuration
- Uses real PostgreSQL database (Docker container)
- Real RabbitMQ connections (Docker container)
- Database persistence and transactions
- Slower execution
- Requires Docker to be running

## Troubleshooting

### Common Issues

1. **404 Errors in Unit Tests**: Routes not registered properly in test app
2. **Mock Configuration Issues**: Database mocking not set up correctly
3. **Docker Not Running**: Required for integration tests
4. **PostgreSQL Connection Issues**: Database container not available for integration tests
5. **RabbitMQ Connection Issues**: Service not available for integration tests

### Solutions

1. **Unit Test Issues**: Check `conftest_unit.py` for proper mocking configuration
2. **Integration Test Issues**: Ensure Docker is running and PostgreSQL/RabbitMQ containers are available
3. **Database Issues**: Check PostgreSQL container setup and database migrations
4. **Mock Issues**: Verify that database operations are properly mocked in unit tests

## Best Practices

1. **Write Unit Tests First**: Focus on testing individual components with mocked database
2. **Use Integration Tests Sparingly**: Only for critical workflows that require real database
3. **Mock Database Operations**: Keep unit tests fast by mocking all database interactions
4. **Test Isolation**: Each test should be independent and not affect others
5. **Clear Test Names**: Use descriptive test method names
6. **Use Real PostgreSQL**: Integration tests should use the same database as production
7. **Mock External Services**: Unit tests should mock RabbitMQ, external APIs, etc.

## Coverage

- Unit tests focus on code coverage of individual functions
- Integration tests focus on workflow coverage
- Combined coverage provides confidence in system reliability

## PostgreSQL-Based Testing

### Why PostgreSQL Instead of SQLite?

1. **Production Parity**: Tests run against the same database type as production
2. **Feature Compatibility**: PostgreSQL-specific features are properly tested
3. **Data Types**: Proper testing of PostgreSQL data types and constraints
4. **Performance**: More accurate performance testing with real database
5. **Migrations**: Database migrations are tested against the correct database

### Unit Test Mocking Strategy

Unit tests use comprehensive mocking to avoid database dependencies:

```python
# Example: Mocking database operations
@pytest.fixture
def mock_user_query(mock_user):
    """Mock user database query."""
    mock_query = Mock()
    mock_query.filter = Mock(return_value=mock_query)
    mock_query.first = Mock(return_value=mock_user)
    return mock_query

def test_user_creation_mocked(mock_user, mock_db_query):
    """Test user creation with mocked database."""
    with patch('core.models.db.session') as mock_session:
        mock_session.query.return_value = mock_db_query
        # Test logic here...
```

### Integration Test Database Setup

Integration tests use real PostgreSQL containers:

```yaml
# docker compose.test.yml
test-postgres:
  image: postgres:15
  environment:
    POSTGRES_USER: test_user
    POSTGRES_PASSWORD: test_password
    POSTGRES_DB: test_plosolver
  ports:
    - "5433:5432"
```

## Future Improvements

1. **Parallel Test Execution**: Run unit tests in parallel for faster feedback
2. **Test Categories**: Add more granular test categories (e.g., slow, fast, critical)
3. **Performance Testing**: Add performance benchmarks
4. **Load Testing**: Add load testing for critical endpoints
5. **Database Seeding**: Improve database seeding for integration tests
6. **Connection Pooling**: Optimize database connection handling in tests 