# PLOSolver Backend

The PLOSolver backend is a Flask-based API service for calculating poker equity in Pot Limit Omaha (PLO) bomb pots. This service uses Poetry for dependency management and packaging.

## Prerequisites

- Python 3.10 or higher
- Poetry (will be installed automatically if not present)
- PostgreSQL (for database)
- Redis (for caching and task queues)

## Quick Start - For Development

### Option 1: Complete Setup

```bash
# Complete development setup (dependencies + pre-commit hooks)
make setup
```

This will install Poetry, all dependencies, and set up pre-commit hooks in one command.

### Option 2: Step-by-Step Setup

#### 1. Install Poetry (if not already installed)

```bash
make install-poetry
```

This will automatically detect if Poetry is installed and install it if needed using the official installer, or fall back to pip if the official installer fails.

#### 2. Set Up Environment

Authenticate with nexus
```bash
poetry config http-basic.nexus-internal username assword
```

#### 3. Install Dependencies

```bash
# Install all dependencies (including development and build tools)
make deps

# Or install only production dependencies
make deps-prod
```

#### 4. Set Up Pre-commit Hooks (Optional but Recommended)

```bash
make pre-commit-install
```

#### 5. Generate Protos
```bash
make gen # generate protos
```


#### 6. Set Up Database

Make sure PostgreSQL is running, then run migrations:

```bash
make db-migrate
```

#### 7. Run the Application

```bash
# Run the unified server (REST API + gRPC)
make dev

# Or run directly with Poetry
poetry run python src/main.py
```

The backend will be available at:
- **REST API**: `http://localhost:5001`
- **gRPC API**: `localhost:50051`

## Development Commands

### Dependency Management

```bash
# Install Poetry if not present
make install-poetry

# Install all dependencies
make deps

# Install production dependencies only
make deps-prod

# Add a new dependency
make poetry-add

# Add a development dependency
make poetry-add-dev

# Update all dependencies
make poetry-update

# Lock dependencies (regenerate poetry.lock)
make poetry-lock
```

### Development

```bash
# Run the unified server (REST API + gRPC)
make dev

# Run in Docker development mode
make dev-docker
```

### Testing

```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run only integration tests
make test-integration

# Run tests with coverage report
make test-coverage
```

### Code Quality

```bash
# Run linting
make lint

# Auto-fix linting issues
make lint-fix

# Format code with Black
make format

# Run security checks
make security
```

### Pre-commit Hooks

This project uses the [pre-commit](https://pre-commit.com/) framework to automatically run code quality checks before each commit. The hooks include:

- **Black** - Code formatting
- **Flake8** - Linting and style checking
- **isort** - Import sorting
- **Bandit** - Security checks
- **Unit Tests** - Runs pytest on unit tests
- **General file checks** - YAML/JSON validation, merge conflicts, etc.

#### Setup

```bash
# Complete development setup (includes pre-commit hooks)
make setup

# Or install pre-commit hooks separately
make pre-commit-install
```

#### Usage

Pre-commit hooks will automatically run on every `git commit`:
1. **Code formatting** - Black and isort will format your code
2. **Linting** - Flake8 checks for style and potential issues
3. **Security** - Bandit scans for security vulnerabilities
4. **Unit Tests** - Runs all unit tests to ensure code quality
5. **File validation** - Checks for merge conflicts, valid YAML/JSON, etc.

If any check fails, the commit will be blocked until the issues are fixed. Most hooks will automatically fix issues when possible.

#### Skipping Pre-commit Hooks

In emergency situations, you can skip pre-commit hooks:

```bash
# Use --no-verify flag
git commit --no-verify -m "Emergency fix"
```

#### Management

```bash
# Run pre-commit hooks on all files
make pre-commit-run

# Run pre-commit hooks on changed files only
make pre-commit-run-changed

# Update pre-commit hooks to latest versions
make pre-commit-update

# Uninstall pre-commit hooks
make pre-commit-uninstall
```

**⚠️ Warning**: Skipping pre-commit hooks should be used sparingly. Always run the checks manually before pushing to ensure code quality.

### Building

```bash
# Build the package
make build

# Build Docker image
make build-docker

# Build Docker image without cache
make build-docker-no-cache
```

### Database

```bash
# Run database migrations
make db-migrate

# Create a new migration
make db-create-migration

# Reset database (drop and recreate)
make db-reset

# Stamp database with latest migration
make db-stamp
```

### CI/CD

```bash
# Run the full CI pipeline locally
make ci-pipeline

# Run quick CI pipeline (without security checks)
make ci-pipeline-quick
```

### Utilities

```bash
# Clean build artifacts
make clean

# Clean virtual environment
make clean-venv

# Generate protobuf files from .proto definitions
make gen

# Show Docker logs
make docker-logs

# Stop Docker containers
make docker-stop

# Restart Docker containers
make docker-restart
```

## Project Structure

```
backend/
├── src/                    # Source code
│   ├── main.py            # Unified server entry point (REST + gRPC)
│   ├── routes/            # API route handlers
│   ├── protos/           # Generated protobuf files
│   └── scripts/          # Utility scripts
├── protos/                # Protocol Buffer definitions
│   ├── common.proto      # Shared messages
│   ├── auth.proto        # Authentication service
│   ├── solver.proto      # Solver service
│   ├── job.proto         # Job management service
│   ├── subscription.proto # Subscription service
│   ├── hand_history.proto # Hand history service
│   └── core.proto        # Core service
├── tests/                 # Test files
│   ├── unit/             # Unit tests
│   └── integration/      # Integration tests
├── pyproject.toml        # Poetry configuration and dependencies
├── poetry.lock           # Lock file for reproducible builds
├── poetry.toml           # Poetry source configuration
├── Dockerfile            # Production Docker image
├── Dockerfile.dev        # Development Docker image
└── Makefile              # Development commands
```

## Protocol Buffers and gRPC Services

The backend includes a comprehensive gRPC API alongside the REST API. The Protocol Buffer definitions have been refactored into domain-specific modules for better maintainability:

### Proto File Structure

- **`common.proto`** - Shared messages (User, Error, Pagination)
- **`auth.proto`** - Authentication and user management services
- **`solver.proto`** - Game analysis and solver functionality
- **`job.proto`** - Job management and processing
- **`subscription.proto`** - Subscription and billing services
- **`hand_history.proto`** - Hand history file management
- **`core.proto`** - System health and core functionality

### Generating Protobuf Files

After modifying any `.proto` files, regenerate the Python files:

```bash
make gen
```

This command:
- Generates Python protobuf files from all `.proto` definitions
- Fixes import statements for proper module imports
- Updates the `src/protos/` directory with the latest generated code

### gRPC Services

The backend provides the following gRPC services:

- **AuthService** - User registration, login, profile management
- **SolverService** - Spot analysis, solver configuration, hand buckets
- **JobService** - Job creation, status tracking, management
- **CoreService** - Health checks, system status

### Running the Server

```bash
# Run unified server (both REST and gRPC)
poetry run python src/main.py

# Using Makefile
make dev
```

The servers run on:
- **REST API**: Port 5001 (configurable via `FLASK_PORT`)
- **gRPC API**: Port 50051 (configurable via `GRPC_PORT`)

## API Usage

### Calculate PLO Equity

**POST** `/api/equity/calculate`

Calculate equity for PLO bomb pot scenarios.

#### Request Body

```json
{
    "players": 8,
    "topBoard": ["7h", "4d", "Jd"],
    "bottomBoard": ["9s", "4c", "2s"],
    "players": [
        {
            "player_number": 1,
            "cards": ["Js", "7d", "As", "8d"]
        },
        {
            "player_number": 2,
            "cards": ["Qd", "8h", "6h", "Qs"]
        }
    ]
}
```

#### Response

```json
[
    {
        "player_number": 1,
        "cards": ["Js", "7d", "As", "8d"],
        "top_equity": 0.15,
        "bottom_equity": 0.23
    },
    {
        "player_number": 2,
        "cards": ["Qd", "8h", "6h", "Qs"],
        "top_equity": 0.18,
        "bottom_equity": 0.21
    }
]
```

## Environment Variables

Key environment variables (see `env.example` for full list):

- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `FLASK_ENV`: Environment (development, production)
- `SECRET_KEY`: Flask secret key
- `NEXUS_PYPI_PASSWORD`: Password for Nexus PyPI repository

## Docker Deployment

### Build Image

```bash
make build-docker
```

### Run with Docker Compose

```bash
# Development
docker-compose -f docker-compose-localdev.yml up

# Production
docker-compose -f docker-compose.production.yml up
```

## Troubleshooting

### Poetry Installation Issues

If the automatic Poetry installation fails:

```bash
# Try manual installation
curl -sSL https://install.python-poetry.org | python3 -

# Or install via pip
pip install poetry

# You may need to restart your terminal or update PATH
```

### Dependency Resolution Issues

```bash
# Clear Poetry cache and reinstall
poetry cache clear . --all
poetry install --with dev,build

# If lock file is corrupted
rm poetry.lock
poetry install --with dev,build
```

### Database Connection Issues

1. Ensure PostgreSQL is running
2. Check database credentials in `.env`
3. Verify database exists: `createdb <database_name>`

### Import Errors

Make sure you're using Poetry to run commands:

```bash
# Wrong
python src/main.py

# Correct
poetry run python src/main.py
# Or
make dev
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the CI pipeline: `make ci-pipeline`
5. Submit a pull request

## Migration from pip/requirements.txt

This project has been migrated from pip/requirements.txt to Poetry. See `POETRY_MIGRATION.md` for detailed migration information and rollback instructions.
