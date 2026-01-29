# PLOScope Development Guide

## Prerequisites

- Docker Engine 24.0+
- Docker Compose v2.20+
- GitHub CLI (`gh`) for cloning repositories
- Git
- (Optional) Make

## Initial Setup

### 1. Clone the Stack Repository

```bash
git clone https://github.com/PLOScope/ploscope-stack.git
cd ploscope-stack
```

### 2. Run Setup Wizard

```bash
./scripts/setup.sh
```

This will:
- Create `.env` with generated secure passwords
- Create Docker network
- Optionally clone all source repositories

### 3. Clone Source Repositories

If you skipped during setup:

```bash
./scripts/clone-repos.sh
```

This creates a `repos/` directory with all PLOScope repositories.

## Starting Development Environment

### Using the Dev Script

```bash
# Start all services
./scripts/dev.sh up

# Start specific services
./scripts/dev.sh up backend frontend

# View logs
./scripts/dev.sh logs

# Stop everything
./scripts/dev.sh down
```

### Using Make

```bash
make dev          # Start dev environment
make dev-logs     # Follow logs
make dev-down     # Stop dev environment
```

### Using Docker Compose Directly

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## Development URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | - |
| Backend API | http://localhost:5001/api | JWT |
| Traefik Dashboard | http://localhost:8080 | - |
| RabbitMQ Management | http://localhost:15672 | plosolver / (from .env) |
| Grafana | http://localhost:3001 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| PostgreSQL | localhost:5432 | postgres / (from .env) |

## Project Structure

```
ploscope-stack/
├── repos/                    # Cloned source repositories
│   ├── backend/             # Flask API
│   ├── frontend/            # React SPA
│   ├── celery-worker/       # Background workers
│   ├── core/                # Shared library
│   ├── monitoring/          # Grafana/Prometheus configs
│   └── ...
├── config/                   # Stack-level configs
└── scripts/                  # Helper scripts
```

## Working with Services

### Backend Development

```bash
# Enter backend container
./scripts/dev.sh shell backend

# Or
make shell-backend

# Run tests inside container
pytest tests/

# Apply database migrations
alembic upgrade head
```

Backend code is mounted at `/app/backend/src`, changes are picked up automatically (Flask debug mode).

### Frontend Development

```bash
# Enter frontend container
./scripts/dev.sh shell frontend

# Install a new npm package (inside container)
npm install <package>
```

Frontend code is mounted at `/app/src`, changes trigger hot reload.

### Celery Worker Development

```bash
# View worker logs
./scripts/dev.sh logs celery-worker

# Restart worker after code changes
docker compose restart celery-worker
```

## Database Operations

### Access PostgreSQL

```bash
# Using make
make db-shell

# Or directly
docker compose exec db psql -U postgres -d plosolver
```

### Create Migration

```bash
# Enter db-init container
docker compose run --rm db-init bash

# Generate migration
alembic revision --autogenerate -m "Description"

# Apply migration
alembic upgrade head
```

### Backup Database

```bash
make db-backup
# Creates backup in ./backups/
```

## Testing

### Backend Tests

```bash
# Run all tests
docker compose exec backend pytest

# Run specific test file
docker compose exec backend pytest tests/test_auth.py

# Run with coverage
docker compose exec backend pytest --cov=src
```

### Frontend Tests

```bash
docker compose exec frontend npm test
```

## Debugging

### View Logs

```bash
# All services
./scripts/dev.sh logs

# Specific service
./scripts/dev.sh logs backend

# Last 100 lines
docker compose logs --tail=100 backend
```

### Interactive Debugging (Backend)

1. Add breakpoint in code:
```python
import pdb; pdb.set_trace()
```

2. Attach to container:
```bash
docker attach ploscope-backend
```

3. Press Enter when breakpoint is hit

### Check Service Health

```bash
# Status of all services
make status

# Health endpoints
curl http://localhost:5001/api/health
curl http://localhost:3000
```

## Common Issues

### Port Conflicts

If ports are in use:

```bash
# Find what's using port 5432
lsof -i :5432

# Or change ports in .env
POSTGRES_PORT=5433
```

### Container Won't Start

```bash
# Check logs
docker compose logs <service>

# Recreate container
docker compose up -d --force-recreate <service>
```

### Database Connection Issues

```bash
# Verify database is running
docker compose ps db

# Check database logs
docker compose logs db

# Test connection
docker compose exec db pg_isready
```

### Nexus Authentication (Build Failures)

For building Python images, you need Nexus credentials:

```bash
# In .env
NEXUS_PYPI_USERNAME=your-username
NEXUS_PYPI_PASSWORD=your-password
```

### Clean Restart

```bash
# Remove all containers and volumes
make reset

# Start fresh
make setup
make dev
```

## Code Style

### Backend (Python)

- Follow PEP 8
- Use Black for formatting
- Run pre-commit hooks

```bash
cd repos/backend
pre-commit install
pre-commit run --all-files
```

### Frontend (TypeScript/React)

- ESLint + Prettier
- Run before committing:

```bash
cd repos/frontend
npm run lint
npm run format
```

## Workflow Tips

### Fast Iteration on Backend

1. Make code changes in `repos/backend/src/`
2. Changes apply immediately (Flask debug mode)
3. Check logs: `./scripts/dev.sh logs backend`

### Fast Iteration on Frontend

1. Make code changes in `repos/frontend/src/`
2. Browser auto-refreshes (hot module replacement)
3. Check browser console for errors

### Building Images Locally

```bash
# Build all images
./scripts/build-all.sh

# Build specific service
docker compose -f docker-compose.yml -f docker-compose.dev.yml build backend
```

## Git Workflow

Each repository has its own git history. The stack repo only contains orchestration files.

```bash
# Working on backend
cd repos/backend
git checkout -b feature/my-feature
# ... make changes ...
git commit -m "Add feature"
git push origin feature/my-feature

# Back to stack
cd ../..
```
