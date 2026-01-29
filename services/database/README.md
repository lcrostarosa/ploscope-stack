# Database Initialization System

This directory contains the database initialization and migration system for PLOScope, a Flask-based application using Alembic for database schema management.

## Overview

The database initialization system provides:
- **Database migrations** using Alembic
- **Docker containerization** for consistent deployment
- **Poetry-based dependency management** for reliable builds
- **Automated schema management** for PostgreSQL databases
- **Pre-commit hooks** for code quality and migration validation
- **Static code analysis** for security and SQL quality
- **Development and production scripts** for Celery workers

## Directory Structure

```
database/
├── alembic.ini              # Alembic configuration file
├── Dockerfile               # Container for running migrations
├── env.py                   # Alembic environment configuration
├── Makefile                 # Development and deployment commands
├── pyproject.toml           # Poetry dependency management
├── poetry.lock              # Locked dependencies
├── script.py.mako           # Migration file template
├── scripts/                 # Utility scripts
│   ├── alembic-check.sh     # Pre-commit database validation
│   ├── run-celery-dev.sh    # Development Celery runner
│   └── run-celery-only.sh   # Production Celery runner
├── .pre-commit-config.yaml  # Pre-commit hooks configuration
├── .yamllint                # YAML linting configuration
└── versions/                # Database migration files
    ├── 001_create_users_table.py
    ├── 002_add_async_job_system.py
    ├── 003_bridge_migration.py
    ├── 004_create_spots_table.py
    ├── 005_create_hand_histories_table.py
    ├── 006_create_parsed_hands_table.py
    ├── 007_create_solver_solutions_table.py
    ├── 008_add_beta_user_field.py
    └── 009_create_user_sessions_table.py
```

## Database Schema

The system manages the following core tables:

### Core Tables
- **users** - User authentication and profile data
- **spots** - Poker game scenarios and positions
- **hand_histories** - Raw poker hand data
- **parsed_hands** - Processed hand information
- **solver_solutions** - Calculated poker solutions
- **user_sessions** - User session tracking

### Job System
- **async_jobs** - Background task management
- **job_results** - Task execution results

## Quick Start

### Prerequisites
- Python 3.11+
- Poetry (for dependency management)
- Docker and Docker Compose (for local database)
- Git

### Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd database

# Install dependencies with Poetry
poetry install

# Set up pre-commit hooks
poetry run pre-commit install

# Start local database for development
docker compose -f docker-compose-local-services.yml up -d db
```

## Usage

### Running Migrations

#### Using Docker (Recommended for Production)
```bash
# Run migrations in a container
docker run --rm \
  -e DATABASE_URL="postgresql://user:pass@host:port/db" \
  ploscope/db-init:latest
```

#### Local Development with Poetry
```bash
# Run migrations
poetry run alembic -c alembic.ini upgrade head

# Create a new migration
poetry run alembic -c alembic.ini revision --autogenerate -m "description"

# Downgrade to a specific version
poetry run alembic -c alembic.ini downgrade <revision_id>

# Check migration status
poetry run alembic -c alembic.ini current
poetry run alembic -c alembic.ini history
```

### Development Commands

The Makefile provides convenient commands for development:

```bash
# Install dependencies
make deps

# Run database migrations test with Poetry
make test-poetry

# Run static code analysis (security + SQL)
make static-analysis

# Format code
make format

# Lint code
make lint

# Set up pre-commit hooks
make pre-commit-setup

# Run pre-commit on all files
make pre-commit-run

# Run Celery worker in development mode (with hot reloading)
make run-celery-dev

# Run Celery worker with Docker infrastructure
make run-celery-only

# Scale Celery workers
make scale-celery ENV=production WORKERS=4

# Monitor Celery performance
make monitor-celery ENV=production DURATION=300
```

## Code Quality and Pre-commit Hooks

The repository includes comprehensive pre-commit hooks for code quality:

### Automated Checks
- **Database Migration Validation** - Starts local database and validates migrations
- **Python Code Formatting** - Black formatter with 120 character line length
- **Import Sorting** - isort with Black profile compatibility
- **Security Analysis** - Bandit for Python security vulnerabilities
- **SQL Linting** - SQLFluff for SQL code quality
- **YAML Linting** - yamllint for configuration file validation
- **General File Checks** - Trailing whitespace, file endings, merge conflicts

### Running Pre-commit Hooks
```bash
# Install pre-commit hooks
poetry run pre-commit install

# Run on staged files (automatic on commit)
git add .
git commit -m "Your commit message"

# Run on all files
poetry run pre-commit run --all-files

# Run specific hook
poetry run pre-commit run black --all-files
```

### Static Analysis

The system includes automated static analysis:

```bash
# Run security analysis with Bandit
poetry run bandit -r env.py versions/ -f txt -o bandit-report.txt

# Run SQL analysis with SQLFluff
poetry run sqlfluff lint versions/ --format human > sqlfluff-report.txt

# Run all static analysis
make static-analysis
```

## Configuration

### Environment Variables

The system uses the following environment variables:

- `DATABASE_URL` - PostgreSQL connection string
- `PYTHONPATH` - Python module path (set to `/app` in container)
- `PYTHONUNBUFFERED` - Disable Python output buffering
- `PYTHONDONTWRITEBYTECODE` - Don't write .pyc files

### Poetry Configuration

The `pyproject.toml` file manages:
- **Dependencies** - Core and development dependencies
- **Code Formatting** - Black configuration (120 char line length)
- **Import Sorting** - isort configuration with Black compatibility
- **Security Analysis** - Bandit configuration and exclusions
- **Tool Configurations** - Centralized settings for all development tools

### Alembic Configuration

The `alembic.ini` file configures:
- Migration script location (`.` - current directory)
- Logging levels for SQLAlchemy, Alembic, and Flask-Migrate
- Database connection settings

## Migration Management

### Creating New Migrations

1. **Auto-generate** (recommended for schema changes):
   ```bash
   poetry run alembic -c alembic.ini revision --autogenerate -m "Add new table"
   ```

2. **Manual creation** (for complex migrations):
   ```bash
   poetry run alembic -c alembic.ini revision -m "Custom migration"
   ```

### Migration Best Practices

- Always test migrations on a copy of production data
- Use descriptive migration names
- Include both `upgrade()` and `downgrade()` functions
- Test rollback scenarios
- Review auto-generated migrations before applying
- Run pre-commit hooks to validate migrations

### Migration History

The system maintains a sequential migration history:

1. **001** - Create users table with authentication fields
2. **002** - Add async job system for background tasks
3. **003** - Bridge migration for system compatibility
4. **004** - Create spots table for poker scenarios
5. **005** - Create hand histories table
6. **006** - Create parsed hands table
7. **007** - Create solver solutions table
8. **008** - Add beta user field to users table
9. **009** - Create user sessions table

## Docker Integration

The `Dockerfile` creates a lightweight container with:
- Python 3.11 slim base image
- Poetry for dependency management
- PostgreSQL client tools
- Alembic and SQLAlchemy dependencies
- Migration scripts pre-copied

### Building the Image
```bash
docker build -t ploscope/db-init:latest .
```

### Running in CI/CD
The container is designed for CI/CD pipelines and supports:
- Environment variable injection
- Non-interactive execution
- Proper exit codes for automation
- Poetry-based dependency management

## CI/CD Pipeline

The GitHub Actions workflow (`/.github/workflows/build-and-test.yml`) includes:

### Build and Test
- Poetry dependency installation and caching
- Database migration testing with Docker Compose
- Automated schema validation

### Static Analysis
- Security analysis with Bandit
- SQL code quality with SQLFluff
- Automated report generation and artifact upload

## Troubleshooting

### Common Issues

1. **Poetry Installation Issues**
   ```bash
   # Reinstall Poetry
   curl -sSL https://install.python-poetry.org | python3 -

   # Clear Poetry cache
   poetry cache clear --all pypi
   ```

2. **Pre-commit Hook Failures**
   ```bash
   # Update pre-commit hooks
   poetry run pre-commit autoupdate

   # Run specific hook to debug
   poetry run pre-commit run black --all-files
   ```

3. **Database Connection Errors**
   - Verify `DATABASE_URL` format
   - Check network connectivity
   - Ensure database is running
   - Use `docker compose -f docker-compose-local-services.yml ps` to check status

4. **Migration Conflicts**
   - Check for conflicting migration IDs
   - Verify migration dependencies
   - Review migration history
   - Run `poetry run alembic -c alembic.ini history` to see current state

5. **Static Analysis Issues**
   ```bash
   # View detailed reports
   cat bandit-report.txt
   cat sqlfluff-report.txt

   # Fix formatting issues
   make format
   make lint
   ```

### Debug Mode

Enable verbose logging by modifying `alembic.ini`:
```ini
[logger_alembic]
level = DEBUG
```

## Contributing

When adding new migrations or making changes:

1. **Follow the existing naming convention** (`00X_description.py`)
2. **Include comprehensive upgrade and downgrade logic**
3. **Test migrations on development database**
4. **Run pre-commit hooks** before committing
5. **Update this README** with new table descriptions
6. **Ensure backward compatibility**
7. **Follow code formatting standards** (120 char line length)

### Development Workflow
```bash
# 1. Install dependencies
poetry install

# 2. Set up pre-commit hooks
poetry run pre-commit install

# 3. Make your changes
# ... edit files ...

# 4. Run quality checks
make format
make lint
make static-analysis

# 5. Test migrations
make test-poetry

# 6. Commit (pre-commit hooks run automatically)
git add .
git commit -m "Your descriptive commit message"
```

## License

This project is licensed under the terms specified in `LICENSE.txt`.
