# RabbitMQ Local Development

This directory contains a clean RabbitMQ setup for local development, testing, and pre-commit workflows.

## Quick Start

```bash
# Install hooks for commiting to this repo to run checks CI will run locally
make install-hooks
```

## Environment Variables

### Required Secrets (GitHub Secrets)
- `RABBITMQ_PASSWORD` - RabbitMQ password
- `RABBITMQ_USERNAME` - RabbitMQ username
- `APP_PATH` - Application path
- `SSH_HOST` - SSH host for deployment
- `SSH_PRIVATE_KEY` - SSH private key
- `SSH_USER` - SSH user

### Environment Variables
- `BUILD_ENV` - Build environment (development, test, production)
- `CONTAINER_ENV` - Container environment (docker, kubernetes)
- `ENVIRONMENT` - Environment name (local, staging, production)
- `LOG_LEVEL` - Logging level (DEBUG, INFO, WARNING, ERROR)
- `RABBITMQ_HOST` - RabbitMQ host
- `RABBITMQ_PORT` - RabbitMQ port
- `RABBITMQ_SOLVER_DLQ` - Solver dead letter queue
- `RABBITMQ_SOLVER_QUEUE` - Solver processing queue
- `RABBITMQ_SPOT_DLQ` - Spot dead letter queue
- `RABBITMQ_SPOT_QUEUE` - Spot processing queue
- `RABBITMQ_VHOST` - RabbitMQ virtual host
- `RESTART_POLICY` - Container restart policy
- `TESTING` - Testing mode flag
- `VOLUME_MODE` - Volume mount mode
- `DATABASE_URL` - PostgreSQL connection string
- `POSTGRES_DB` - PostgreSQL database name
- `POSTGRES_USER` - PostgreSQL username
- `POSTGRES_PASSWORD` - PostgreSQL password
- `POSTGRES_HOST` - PostgreSQL host
- `POSTGRES_MIGRATE_HOST` - PostgreSQL migration host
- `PGPASSWORD` - PostgreSQL password environment variable

## Security Notes

- Default development credentials are used for local development only
- Production credentials should be stored in GitHub Secrets
- SSH keys and sensitive data should never be committed to the repository
- Use environment-specific configuration files for different environments
