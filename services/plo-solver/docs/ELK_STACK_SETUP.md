# ELK Stack Setup for PLOSolver

This document describes the ELK (Elasticsearch, Logstash, Kibana) stack setup for PLOSolver, which replaces New Relic for log monitoring and analysis.

## Overview

The ELK stack provides comprehensive monitoring for:
- **Infrastructure**: CPU, memory, disk, network metrics
- **Containers**: All Docker container logs and resource usage
- **Frontend**: Application logs, errors, and performance
- **Backend**: Application logs, database queries, API calls
- **Traefik**: HTTP access logs, response times, status codes
- **System**: System logs, Docker daemon logs

Components:
- **Elasticsearch**: Search and analytics engine for all data
- **Logstash**: Log processing pipeline for structured data
- **Filebeat**: Infrastructure metrics and container log collection
- **Kibana**: Web interface for visualization and analysis
- **Portainer**: Docker container management interface
- **RabbitMQ**: Message queue management interface

## Architecture

```
Infrastructure Metrics → Filebeat → Elasticsearch → Kibana
Container Logs → Filebeat → Elasticsearch → Kibana
Application Logs → Logstash → Elasticsearch → Kibana
Traefik Logs → Logstash → Elasticsearch → Kibana
System Logs → Filebeat → Elasticsearch → Kibana
```

## Security

- **SSH-only access**: ELK services are not exposed to the internet
- **Internal network**: Services communicate only within the Docker network
- **Volume mounts**: Persistent data storage with proper permissions

## Setup

### 1. Setup Monitoring Infrastructure

```bash
# Setup comprehensive monitoring
./scripts/setup-monitoring.sh
```

### 2. Start the ELK Stack

```bash
# Start all ELK services
./scripts/start-elk.sh

# Or start manually
docker compose up -d elasticsearch logstash kibana filebeat
```

### 2. Setup Access Control

```bash
# Run the access control setup script
./scripts/setup-elk-access.sh
```

### 3. Access via SSH Tunnel

#### Individual Service Access

To access individual services, you must be SSH'd into the server:

```bash
# Access Kibana
ssh -L 5601:localhost:5601 user@your-server
# Then open: http://localhost:5601

# Access Elasticsearch
ssh -L 9200:localhost:9200 user@your-server
# Then open: http://localhost:9200

# Access Portainer
ssh -L 9000:localhost:9000 user@your-server
# Then open: http://localhost:9000

# Access RabbitMQ
ssh -L 15672:localhost:15672 user@your-server
# Then open: http://localhost:15672
```

#### All Services Access (Recommended)

Use the comprehensive SSH tunnel script to access all services at once:

```bash
# Open tunnels for all services
./scripts/ssh-tunnel-all.sh <server-ip> <username> [ssh-key-path]

# Test all tunnels
./scripts/test-ssh-tunnels.sh

# Show configuration
./scripts/ssh-tunnel-config.sh
```

#### SSH Key Authentication

You can specify an SSH key for secure authentication:

```bash
# With SSH key
./scripts/ssh-tunnel-all.sh 192.168.1.100 ubuntu ~/.ssh/id_rsa
./scripts/ssh-tunnel-all.sh plosolver.example.com admin ~/.ssh/plosolver_key

# Without SSH key (will prompt for password)
./scripts/ssh-tunnel-all.sh 192.168.1.100 ubuntu
```

#### Setup SSH Key

Generate and configure an SSH key for secure access:

```bash
# Generate new SSH key
./scripts/setup-ssh-key.sh

# Generate with custom path
./scripts/setup-ssh-key.sh ~/.ssh/plosolver_key

# Generate and test with server details
./scripts/setup-ssh-key.sh ~/.ssh/plosolver_key 192.168.1.100 ubuntu
```

#### Configuration

You can customize the SSH tunnel configuration:

```bash
# Set environment variables
export PLOSOLVER_SERVER="your-server-ip"
export PLOSOLVER_USER="your-username"
export PLOSOLVER_SSH_KEY="~/.ssh/id_rsa"

# Or modify the config file
./scripts/ssh-tunnel-config.sh
```

## Log Rotation

### Application Logs

Logs are automatically rotated every 7 days with the following configuration:

- **Rotation**: Daily
- **Retention**: 7 days
- **Compression**: Enabled
- **Location**: `/var/log/plosolver/`

### Docker Container Logs

Docker container logs are automatically rotated with the following configuration:

- **Max File Size**: 10MB per log file
- **Max Files**: 7 files per container
- **Retention**: 7 days
- **Compression**: Enabled
- **Rotation**: Daily via logrotate
- **Location**: `/var/lib/docker/containers/*/`

### Setup Docker Log Rotation

```bash
# Setup Docker log rotation (requires sudo)
sudo ./scripts/setup-docker-log-rotation.sh

# Test Docker log rotation
./scripts/test-docker-log-rotation.sh
```

## Configuration Files

### Logstash Configuration

- **Config**: `logstash/config/logstash.yml`
- **Pipeline**: `logstash/pipeline/logstash.conf`

### Log Rotation

- **Application Logs**: `logrotate.conf`
- **Docker Logs**: `/etc/logrotate.d/docker`
- **Docker Daemon**: `/etc/docker/daemon.json`

## Monitoring

### Check Service Status

```bash
# Check all ELK services
docker compose ps elasticsearch logstash kibana

# Check logs
docker compose logs elasticsearch
docker compose logs logstash
docker compose logs kibana
```

### Health Checks

```bash
# Elasticsearch health
curl http://localhost:9200/_cluster/health

# Kibana status
curl http://localhost:5601/api/status

# Portainer status
curl http://localhost:9000/api/status

# RabbitMQ status
curl http://localhost:15672/api/overview
```

## Log Structure

Application logs are structured as JSON with the following fields:

```json
{
  "timestamp": "2025-07-12T04:30:00.000Z",
  "level": "INFO",
  "logger": "plosolver",
  "message": "User login successful",
  "request_id": "abc12345",
  "ip": "192.168.1.100",
  "user_id": "user123",
  "user_agent": "Mozilla/5.0...",
  "referer": "https://ploscope.com/login"
}
```

## Kibana Dashboards

### Default Dashboards

1. **Infrastructure Overview**
   - CPU, memory, disk usage
   - Network traffic and bandwidth
   - System load and processes

2. **Container Health**
   - Docker container status
   - Container resource usage
   - Container logs and errors

3. **Application Performance**
   - Backend API response times
   - Frontend error rates
   - Database query performance
   - User activity and sessions

4. **Traefik Access Logs**
   - HTTP request patterns
   - Response time distribution
   - Status code analysis
   - Geographic traffic distribution

5. **Security Monitoring**
   - Failed login attempts
   - Suspicious access patterns
   - Error rate spikes
   - Unusual traffic patterns

6. **Portainer Container Management**
   - Docker container overview
   - Container resource monitoring
   - Container logs and console access
   - Volume and network management

7. **RabbitMQ Message Queue Management**
   - Queue monitoring and statistics
   - Message flow visualization
   - Connection and channel management
   - Exchange and binding configuration

### Creating Custom Dashboards

1. Open Kibana at `http://localhost:5601`
2. Go to **Discover** to explore log data
3. Create **Visualizations** for specific metrics
4. Combine visualizations into **Dashboards**

## Troubleshooting

### Common Issues

1. **Elasticsearch won't start**
   ```bash
   # Check memory usage
   docker stats elasticsearch
   
   # Check logs
   docker compose logs elasticsearch
   ```

2. **Logstash not processing logs**
   ```bash
   # Check pipeline status
   curl http://localhost:9600/_node/stats/pipeline
   
   # Check logs
   docker compose logs logstash
   ```

3. **Kibana not accessible**
   ```bash
   # Check if Kibana is running
   docker compose ps kibana
   
   # Check logs
   docker compose logs kibana
   ```

### Log Locations

- **Application logs**: `/app/logs/application.log`
- **Elasticsearch logs**: `/usr/share/elasticsearch/logs/`
- **Logstash logs**: `/var/log/logstash/`
- **Kibana logs**: `/usr/share/kibana/logs/`
- **Docker container logs**: `/var/lib/docker/containers/*/*.log`

## Performance Tuning

### Elasticsearch

- **Memory**: Set `ES_JAVA_OPTS=-Xms512m -Xmx512m` for small deployments
- **Index settings**: Configure index lifecycle management for log retention

### Logstash

- **Workers**: Adjust pipeline workers based on log volume
- **Batch size**: Optimize batch processing for throughput

## Backup and Recovery

### Backup Elasticsearch Data

```bash
# Create snapshot repository
curl -X PUT "localhost:9200/_snapshot/backup_repo" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/backup"
  }
}'

# Create snapshot
curl -X PUT "localhost:9200/_snapshot/backup_repo/snapshot_1"
```

### Restore Data

```bash
# Restore from snapshot
curl -X POST "localhost:9200/_snapshot/backup_repo/snapshot_1/_restore"
```

## Portainer Setup

### Initial Setup

Portainer is included in the monitoring stack and provides a web-based interface for managing Docker containers.

```bash
# Setup Portainer SSH access
./scripts/setup-portainer-ssh.sh

# Test Portainer functionality
./scripts/test-portainer.sh
```

### First Time Access

1. **Create SSH tunnel**:
   ```bash
   ssh -L 9000:localhost:9000 user@your-server
   ```

2. **Open Portainer**:
   - Navigate to `http://localhost:9000`
   - Create admin user account
   - Select "Local Docker Environment"
   - Connect to Docker socket

### Portainer Features

- **Container Management**: Start, stop, restart containers
- **Resource Monitoring**: CPU, memory, disk usage per container
- **Log Access**: View container logs in real-time
- **Console Access**: Execute commands in containers
- **Volume Management**: Manage Docker volumes
- **Network Management**: Configure Docker networks
- **Image Management**: Pull, push, remove Docker images

## Migration from New Relic

1. **Disable New Relic**: Remove New Relic configuration from environment
2. **Enable JSON logging**: Application now outputs structured JSON logs
3. **Update monitoring**: Replace New Relic dashboards with Kibana
4. **Verify data**: Ensure all logs are being captured in Elasticsearch

## Security Considerations

- **Network isolation**: ELK services are not exposed to the internet
- **SSH tunneling**: All access requires SSH authentication
- **Volume permissions**: Log files have restricted permissions
- **No external dependencies**: All services run locally 