# Celery Failed Jobs Retrigger Guide

This document explains how to manage and retrigger failed jobs in the PLOSolver Celery system.

## Overview

When Celery jobs fail, they are automatically moved to Dead Letter Queues (DLQs) in RabbitMQ. This system provides a way to:
- Monitor failed jobs
- Retrigger specific failed jobs
- Retrigger all failed jobs
- Clear failed jobs from DLQs

## Prerequisites

Before using the retrigger scripts, ensure:

1. **RabbitMQ is running** and accessible
2. **PostgreSQL database** is running and accessible
3. **Celery workers** are running
4. **Environment variables** are properly configured

## Quick Start

### 1. List Failed Jobs

To see all failed jobs in the DLQs:

```bash
# Using the shell script (recommended)
./scripts/testing/retrigger_failed_jobs.sh --list

# Or using the Python script directly
python3 scripts/testing/retrigger_failed_jobs.py --list
```

### 2. Retrigger All Failed Jobs

To retrigger all failed jobs at once:

```bash
# Using the shell script (recommended)
./scripts/testing/retrigger_failed_jobs.sh --retrigger-all

# Or using the Python script directly
python3 scripts/testing/retrigger_failed_jobs.py --retrigger-all
```

### 3. Retrigger a Specific Job

To retrigger a specific job by its ID:

```bash
# Using the shell script (recommended)
./scripts/testing/retrigger_failed_jobs.sh --retrigger-job <job_id>

# Or using the Python script directly
python3 scripts/testing/retrigger_failed_jobs.py --retrigger-job <job_id>
```

Example:
```bash
./scripts/testing/retrigger_failed_jobs.sh --retrigger-job abc123-def456-7890
```

### 4. Clear All DLQs (Dangerous!)

⚠️ **WARNING**: This will permanently delete all failed jobs from DLQs!

```bash
# Using the shell script (recommended)
./scripts/testing/retrigger_failed_jobs.sh --clear-all

# Or using the Python script directly
python3 scripts/testing/retrigger_failed_jobs.py --clear-all
```

The script will ask for confirmation before proceeding.

## Environment Configuration

The scripts use the following environment variables:

```bash
# RabbitMQ Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/

# Queue Names
RABBITMQ_SPOT_DLQ=spot-processing-dlq
RABBITMQ_SOLVER_DLQ=solver-processing-dlq

# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@db:5432/plosolver
```

These can be set in your environment file (`env.development`, `.env`, etc.) or as environment variables.

## How It Works

### 1. Job Failure Process

1. When a Celery job fails, it's automatically moved to the appropriate DLQ
2. The job status in the database is updated to `FAILED`
3. Error information is stored in the job record

### 2. Retrigger Process

1. **Job Lookup**: The script finds the job in the database by ID
2. **Status Reset**: Job status is reset to `QUEUED`
3. **Cleanup**: Error messages and timestamps are cleared
4. **Resubmission**: Job is resubmitted to Celery with a new task ID
5. **Database Update**: The new task ID is stored in the job record

### 3. DLQ Management

- **Listing**: Messages are read from DLQs without consuming them
- **Retriggering**: Jobs are resubmitted to Celery and removed from DLQs
- **Clearing**: All messages are permanently deleted from DLQs

## Troubleshooting

### Common Issues

#### 1. Connection Errors

**Error**: `Failed to connect to RabbitMQ`

**Solution**:
```bash
# Check if RabbitMQ is running
docker ps | grep rabbitmq

# Start RabbitMQ if needed
make setup  # or docker-compose up rabbitmq
```

#### 2. Database Connection Errors

**Error**: `Job not found in database`

**Solution**:
```bash
# Check database connection
docker ps | grep postgres

# Start database if needed
make setup  # or docker-compose up db
```

#### 3. Celery Worker Issues

**Error**: `Failed to submit job to Celery`

**Solution**:
```bash
# Check if Celery workers are running
ps aux | grep celery

# Start Celery workers
make run-local  # or start celery workers manually
```

#### 4. Permission Issues

**Error**: `Permission denied`

**Solution**:
```bash
# Make script executable
chmod +x scripts/testing/retrigger_failed_jobs.sh
```

### Debug Mode

To get more detailed output, use the `--verbose` flag:

```bash
./scripts/testing/retrigger_failed_jobs.sh --list --verbose
```

## Monitoring

### Check Job Status

You can monitor job status through:

1. **Database**: Check the `jobs` table
2. **Celery**: Use Celery monitoring tools
3. **RabbitMQ Management UI**: Access at `http://localhost:15672`

### Logs

Check the following logs for troubleshooting:

```bash
# Celery worker logs
docker logs <celery-container>

# RabbitMQ logs
docker logs <rabbitmq-container>

# Application logs
tail -f logs/app.log
```

## Best Practices

### 1. Regular Monitoring

- Check DLQs regularly for failed jobs
- Monitor job failure patterns
- Address root causes of failures

### 2. Selective Retriggering

- Retrigger specific jobs when possible
- Avoid bulk retriggering unless necessary
- Test fixes before retriggering

### 3. Documentation

- Document the cause of failures
- Keep track of retriggered jobs
- Update this guide as needed

### 4. Safety

- Always confirm before clearing DLQs
- Backup important data before operations
- Test in development environment first

## Integration with CI/CD

The retrigger scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Retrigger Failed Jobs
  run: |
    ./scripts/testing/retrigger_failed_jobs.sh --retrigger-all
  if: failure()
```

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review logs for detailed error messages
3. Consult the Celery and RabbitMQ documentation
4. Contact the development team

## Related Documentation

- [Celery Integration Guide](CELERY_INTEGRATION.md)
- [RabbitMQ Setup Guide](RABBITMQ_SETUP.md)
- [Job Processing Architecture](JOB_PROCESSING_ARCHITECTURE.md) 