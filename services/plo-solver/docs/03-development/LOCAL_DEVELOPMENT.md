# PLOSolver Local Development Guide

This guide will help you get the PLOSolver application running locally for development.

## Prerequisites

- Docker and Docker Compose installed
- Git (to clone the repository)

## Quick Start

### 1. Start the Local Development Environment

```bash
# Using the Makefile (recommended)
make dev

# Or using the script directly
./scripts/development/start-localdev.sh
```

### 2. Access the Application

Once the services are running, you can access:

- **Frontend**: http://localhost
- **Backend API**: http://localhost:5001
- **Traefik Dashboard**: http://localhost:8080
- **RabbitMQ Management**: http://localhost:15672
- **Database**: localhost:5432

### 3. Stop the Environment

```bash
# Using the Makefile
make localdev-stop

# Or using Docker Compose directly
docker compose -f docker-compose-localdev.yml down
```

## Services Overview

The local development environment includes:

- **PostgreSQL Database**: Stores application data
- **RabbitMQ**: Message queue for job processing
- **Backend API**: Flask application running on port 5001
- **Frontend**: React application running on port 3000
- **Traefik**: Reverse proxy that routes requests to the appropriate services

## Development Workflow

### Viewing Logs

```bash
# View all service logs
docker compose -f docker-compose-localdev.yml logs -f

# View specific service logs
docker compose -f docker-compose-localdev.yml logs -f backend
docker compose -f docker-compose-localdev.yml logs -f frontend
```

### Making Changes

The application is set up with volume mounts, so changes to the source code will be reflected immediately:

- Backend changes: The Flask development server will auto-reload
- Frontend changes: The React development server will auto-reload

### Database Access

```bash
# Connect to the database
docker compose -f docker-compose-localdev.yml exec db psql -U postgres -d plosolver

# Run database migrations
make db-migrate
```

### Testing

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests
make test-integration
```

## Troubleshooting

### Services Not Starting

1. Check if Docker is running
2. Check available ports (80, 3000, 5001, 5432, 5672, 15672, 8080)
3. View logs: `docker compose -f docker-compose-localdev.yml logs`

### Health Check Failures

If you see health check warnings, the services may still be starting up. Wait a few moments and try again.

### Port Conflicts

If you get port conflicts, you can modify the ports in `docker-compose-localdev.yml`:

```yaml
ports:
  - "8080:80"  # Change 80 to 8080 for Traefik
  - "3001:3000"  # Change 3000 to 3001 for Frontend
  - "5002:5001"  # Change 5001 to 5002 for Backend
```

### Database Issues

If the database isn't working:

```bash
# Reset the database
make db-reset

# Or remove the data volume and restart
docker compose -f docker-compose-localdev.yml down
rm -rf data/postgres
docker compose -f docker-compose-localdev.yml up -d
```

## Environment Variables

The local development environment uses the following key environment variables:

- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: Flask secret key
- `JWT_SECRET_KEY`: JWT token secret
- `RABBITMQ_HOST`: RabbitMQ host
- `RABBITMQ_PORT`: RabbitMQ port
- `RABBITMQ_USERNAME`: RabbitMQ username
- `RABBITMQ_PASSWORD`: RabbitMQ password

These are configured in the `docker-compose-localdev.yml` file.

## API Endpoints

The backend API is available at `http://localhost:5001/api/` with the following main endpoints:

- `GET /api/health` - Health check
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/solver/*` - Solver endpoints
- `GET /api/spots/*` - Spot analysis endpoints

## Frontend Development

The frontend is a React application with the following features:

- Hot reloading for development
- API proxy configuration
- Dark mode support
- Responsive design

## Backend Development

The backend is a Flask application with:

- Auto-reloading in development mode
- SQLAlchemy ORM
- JWT authentication
- WebSocket support
- Job queue integration

## Next Steps

Once you have the local environment running:

1. Create a user account through the frontend
2. Explore the API endpoints
3. Check out the Traefik dashboard for request routing
4. Monitor RabbitMQ for job processing

For more detailed information, see the main documentation in the `docs/` directory. 