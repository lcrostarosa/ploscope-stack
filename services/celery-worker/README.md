# Celery Worker for PLOSolver

## Purpose
This directory contains the Celery worker application for background job processing in PLOSolver. It is responsible for running asynchronous and long-running tasks such as solver simulations and analysis, which are offloaded from the main web application to improve reliability, scalability, and maintainability.

## Migration Status
✅ **COMPLETED**: The migration from the custom RabbitMQ-based job processing system to Celery is now complete. The system now uses Celery for all background job processing.

### What Changed
- **Job Processing**: All job processing now happens in Celery workers instead of custom thread-based processors
- **Task Submission**: Jobs are submitted to Celery using `send_task()` instead of direct RabbitMQ messages
- **Database Integration**: Celery tasks directly interact with the database to update job status and results
- **Error Handling**: Improved error handling and retry mechanisms through Celery's built-in features

### Benefits Achieved
- **Scalability**: Easy horizontal scaling by adding more Celery workers
- **Reliability**: Built-in retry mechanisms and better error handling
- **Monitoring**: Better task monitoring and health checks
- **Maintainability**: Cleaner separation of concerns and industry-standard solution

## How It Works
- The Celery worker connects to the same RabbitMQ broker and Postgres database as the main backend app.
- All job logic (e.g., spot simulation, solver analysis) is implemented as Celery tasks in `src/main/tasks.py`.
- The main backend submits jobs by calling these tasks asynchronously using the `celery_service.py`.
- Results and job status are stored in the database and communicated back to the user via the main app's API and WebSocket system.

## Architecture

### Task Routing
- `spot_simulation` queue: Handles spot simulation jobs
- `solver_analysis` queue: Handles solver analysis jobs

### Database Integration
- Tasks create their own database sessions using SQLAlchemy
- Job status updates are committed directly to the database
- Results are stored in the `result_data` field of the Job model

### Error Handling
- Failed tasks are marked with `FAILED` status in the database
- Error messages are stored in the `error_message` field
- Celery's built-in retry mechanisms can be configured if needed

## How to Build and Run

### Build the Docker Image
```sh
docker build -t plosolver-celery-worker -f src/celery/Dockerfile .
```

### Run Locally (with Docker Compose)
The main `docker-compose.yml` and related files include a `celeryworker` service. To start everything locally:
```sh
make run-local
```

Or manually:
```sh
docker compose up --build --scale celeryworker=2
```

### Run Manually (for development)
```sh
cd src/celery
pip install -r requirements.txt
python src/main/celery_app.py  # Starts health check server
celery -A src.main.celery_app.celery worker --loglevel=info --concurrency=2
```

## Testing
- Unit and integration tests for Celery tasks are in the `tests/` directory.
- Run tests with:
```sh
pytest tests/
```

- Test the migration with:
```sh
python src/celery/test_celery_migration.py
```

## Environment/Configuration
- The worker uses environment variables for RabbitMQ and Postgres connection info, shared with the main backend.
- See `.env` files and Docker Compose for details.

### Required Environment Variables
- `CELERY_BROKER_URL`: RabbitMQ connection URL (default: `amqp://rabbitmq:5672//`)
- `CELERY_RESULT_BACKEND`: Result backend URL (default: `rpc://`)
- `DATABASE_URL`: PostgreSQL connection URL

## Communication with Main App
- The worker reads/writes to the same database as the backend.
- Job status and results are updated in the DB and surfaced to users via the backend API and WebSocket notifications.
- The backend uses `celery_service.py` to submit tasks and check their status.

## Monitoring and Health Checks
- Health check endpoint: `http://localhost:5002/health`
- Celery monitoring: Use Flower or Celery's built-in monitoring tools
- Logs: Check container logs with `docker logs plosolver-celeryworker-*`

## Troubleshooting

### Common Issues
1. **Import Errors**: Ensure the backend source code is properly copied to the Celery container
2. **Database Connection**: Verify `DATABASE_URL` is correctly set
3. **RabbitMQ Connection**: Check that RabbitMQ is running and accessible
4. **Task Not Found**: Verify task routing configuration matches the actual task names

### Debug Commands
```sh
# Check Celery worker status
docker exec plosolver-celeryworker-* celery -A main.celery_app.celery inspect active

# Check task queues
docker exec plosolver-celeryworker-* celery -A main.celery_app.celery inspect stats

# Monitor tasks in real-time
docker exec plosolver-celeryworker-* celery -A main.celery_app.celery events
```

## Migration Rationale
This migration was necessary to replace a brittle, custom job system with a scalable, maintainable, and industry-standard solution. Celery is widely used for Python background processing and integrates seamlessly with Flask, RabbitMQ, and Postgres.
