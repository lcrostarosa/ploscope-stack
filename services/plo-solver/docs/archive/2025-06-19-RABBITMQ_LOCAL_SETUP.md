# RabbitMQ Setup Guide

PLOSolver uses RabbitMQ as its message queue system for asynchronous job processing. This guide covers local development setup and production deployment.

## Overview

RabbitMQ handles all background job processing for:
- Spot simulations (equity calculations)
- Solver analysis (GTO strategy calculations)  
- Hand history analysis
- Long-running computations

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Frontend      │───▶│   Backend    │───▶│   RabbitMQ      │
│   (React)       │    │   (Flask)    │    │   (Message      │
│                 │    │              │    │    Queue)       │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                     │
                                                     ▼
                                            ┌─────────────────┐
                                            │   Job Worker    │
                                            │   (Background   │
                                            │   Processing)   │
                                            └─────────────────┘
```

## Local Development Setup

### Option 1: Using run_with_traefik.sh (Recommended)

The easiest way to get started is using our integrated startup script:

```bash
# Start PLOSolver with RabbitMQ
./run_with_traefik.sh

# With forum integration
./run_with_traefik.sh --forum

# With ngrok support
./run_with_traefik.sh --ngrok https://your-url.ngrok-free.app
```

The script automatically:
- Detects if RabbitMQ is installed locally
- Falls back to Docker if not available
- Sets up all required environment variables
- Creates necessary queues and exchanges

### Option 2: Manual RabbitMQ Setup

#### Install RabbitMQ

**macOS (with Homebrew):**
```bash
brew install rabbitmq
brew services start rabbitmq
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server
```

**Docker:**
```bash
docker run -d \
  --name plosolver-rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=plosolver \
  -e RABBITMQ_DEFAULT_PASS=dev_password_2024 \
  -e RABBITMQ_DEFAULT_VHOST=/plosolver \
  rabbitmq:3.13-management
```

#### Enable Management Plugin

```bash
# For local installation
sudo rabbitmq-plugins enable rabbitmq_management

# Access management UI at http://localhost:15672
# Default credentials: guest/guest (or plosolver/dev_password_2024 for Docker)
```

## Environment Configuration

Create or update your environment file with RabbitMQ settings:

```bash
# RabbitMQ Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=plosolver
RABBITMQ_PASSWORD=dev_password_2024
RABBITMQ_VHOST=/plosolver

# Queue Names
RABBITMQ_SPOT_QUEUE=spot-processing
RABBITMQ_SOLVER_QUEUE=solver-processing
RABBITMQ_SPOT_DLQ=spot-processing-dlq
RABBITMQ_SOLVER_DLQ=solver-processing-dlq
```

## Queue Structure

PLOSolver uses the following queue structure:

### Main Queues
- **spot-processing**: Handles spot simulation jobs
- **solver-processing**: Handles GTO solver analysis jobs

### Dead Letter Queues (DLQ)
- **spot-processing-dlq**: Failed spot simulation jobs
- **solver-processing-dlq**: Failed solver analysis jobs

### Delayed Queues (Auto-created)
- **spot-processing-delay-{seconds}**: Temporary delay queues
- **solver-processing-delay-{seconds}**: Temporary delay queues

## Running the System

### Start Job Worker

The job worker processes messages from RabbitMQ queues:

```bash
cd backend
python job_worker.py
```

### Start Backend Server

```bash
cd backend
python equity_server.py
```

### Start Frontend

```bash
npm start
```

## Monitoring and Management

### RabbitMQ Management UI

Access the management interface at http://localhost:15672

**Default credentials:**
- Username: `plosolver`
- Password: `dev_password_2024`

**Key features:**
- Queue monitoring and statistics
- Message inspection
- Connection and channel management
- User and permission management

### Queue Monitoring

Monitor queue health via API:

```bash
# Check queue status
curl http://localhost:5001/api/jobs/health

# View queue attributes
curl http://localhost:5001/api/jobs/stats
```

### Logs

Monitor RabbitMQ logs:

```bash
# Local installation (macOS)
tail -f /opt/homebrew/var/log/rabbitmq/rabbit@localhost.log

# Docker
docker logs -f plosolver-rabbitmq

# Job worker logs
tail -f backend/job_worker.log
```

## Production Deployment

### Docker Compose

The included `docker compose.yml` supports RabbitMQ:

```bash
# Start with RabbitMQ
docker compose --profile app up -d
```

### Environment Variables

Production environment variables:

```bash
# Production RabbitMQ (if using managed service)
RABBITMQ_HOST=your-rabbitmq-host.com
RABBITMQ_PORT=5672
RABBITMQ_USERNAME=prod_user
RABBITMQ_PASSWORD=secure_password_here
RABBITMQ_VHOST=/plosolver-prod

# SSL Configuration (if needed)
RABBITMQ_USE_SSL=true
RABBITMQ_SSL_CERT_PATH=/path/to/cert.pem
RABBITMQ_SSL_KEY_PATH=/path/to/key.pem
```

### High Availability

For production, consider:

1. **RabbitMQ Cluster**: Multiple RabbitMQ nodes for redundancy
2. **Message Persistence**: All queues are durable by default
3. **Dead Letter Queues**: Failed messages are preserved for analysis
4. **Monitoring**: Use Prometheus + Grafana for metrics

## Performance Tuning

### Queue Configuration

Optimize for your workload:

```python
# In rabbitmq_service.py, queues are configured with:
# - Durable: Messages survive server restarts
# - Dead letter routing: Failed messages go to DLQ
# - TTL support: Delayed message processing
```

### Worker Scaling

Scale job workers based on load:

```bash
# Run multiple worker processes
python job_worker.py --workers 4
python job_worker.py --queue spot-processing --workers 2
python job_worker.py --queue solver-processing --workers 2
```

### Memory and Disk

Configure RabbitMQ limits:

```bash
# In rabbitmq.conf
vm_memory_high_watermark.relative = 0.6
disk_free_limit.relative = 1.0
```

## Troubleshooting

### Common Issues

**Connection Refused:**
```bash
# Check if RabbitMQ is running
sudo systemctl status rabbitmq-server
# or
brew services list | grep rabbitmq
```

**Permission Denied:**
```bash
# Create user and permissions
sudo rabbitmqctl add_user plosolver dev_password_2024
sudo rabbitmqctl set_user_tags plosolver administrator
sudo rabbitmqctl set_permissions -p /plosolver plosolver ".*" ".*" ".*"
```

**Queue Not Found:**
```bash
# Queues are auto-created, but you can create manually:
sudo rabbitmqctl declare queue spot-processing durable=true
```

### Debug Mode

Enable debug logging:

```bash
export RABBITMQ_LOG_LEVEL=debug
export FLASK_ENV=development
python job_worker.py --debug
```

### Health Checks

Verify system health:

```bash
# RabbitMQ health
curl http://localhost:15672/api/healthchecks/node

# PLOSolver health
curl http://localhost:5001/api/health

# Queue statistics
curl http://localhost:5001/api/jobs/stats
```

## Testing

Run the test suite:

```bash
# Unit tests
cd backend
pytest tests/unit/test_rabbitmq_service.py -v

# Integration tests (requires RabbitMQ)
pytest tests/integration/test_rabbitmq_integration.py -v

# Full workflow tests
pytest tests/integration/test_job_workflow.py -v

# Performance tests
pytest tests/integration/test_rabbitmq_integration.py::TestRabbitMQIntegration::test_message_throughput --run-slow
```

## Migration from SQS

PLOSolver previously supported AWS SQS but now uses RabbitMQ exclusively for:
- **Cost efficiency**: No per-message charges
- **Local development**: No AWS credentials needed
- **Feature completeness**: Better delayed message support
- **Monitoring**: Built-in management UI

Existing deployments should:
1. Set up RabbitMQ infrastructure
2. Update environment variables
3. Remove AWS SQS configurations
4. Test message flow end-to-end

## Security

### Authentication

RabbitMQ supports multiple authentication mechanisms:

```bash
# Username/password (default)
RABBITMQ_USERNAME=plosolver
RABBITMQ_PASSWORD=secure_password

# TLS certificates (production)
RABBITMQ_USE_SSL=true
RABBITMQ_SSL_CERT_PATH=/path/to/cert.pem
```

### Network Security

Secure RabbitMQ in production:

```bash
# Firewall rules (only allow backend servers)
sudo ufw allow from 10.0.0.0/8 to any port 5672

# TLS encryption
sudo rabbitmq-plugins enable rabbitmq_auth_mechanism_ssl
```

### Access Control

Implement least-privilege access:

```bash
# Create dedicated user for PLOSolver
sudo rabbitmqctl add_user plo_worker worker_password
sudo rabbitmqctl set_permissions -p /plosolver plo_worker "spot-.*|solver-.*" "spot-.*|solver-.*" "spot-.*|solver-.*"
```

This setup provides a robust, scalable message queue system for PLOSolver with excellent local development experience and production-ready features. 