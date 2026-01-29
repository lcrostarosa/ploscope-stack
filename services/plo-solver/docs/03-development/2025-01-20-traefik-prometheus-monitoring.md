# Traefik Prometheus Monitoring Setup

This document describes the traffic tracing and monitoring setup using Traefik and Prometheus for the PLO Solver application.

## Overview

The monitoring stack consists of:
- **Traefik**: Reverse proxy with built-in metrics and tracing
- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization and dashboard platform

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Client    │───▶│   Traefik   │───▶│ Application │
│             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │ Prometheus  │
                   │             │
                   └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │   Grafana   │
                   │             │
                   └─────────────┘
```

## Configuration

### Traefik Configuration

All Traefik configurations include:

1. **Metrics Endpoint**: Exposed on port 8082
2. **Prometheus Metrics**: Enabled with detailed labels
3. **Tracing**: Enabled with 100% sample rate

#### Key Configuration Sections

```yaml
# Metrics endpoint
entryPoints:
  metrics:
    address: ":8082"

# Prometheus metrics configuration
metrics:
  prometheus:
    entryPoint: metrics
    addEntryPointsLabels: true
    addServicesLabels: true
    buckets:
      - 0.1
      - 0.3
      - 1.2
      - 5.0

# Tracing configuration
tracing:
  serviceName: plosolver-traefik
  sampleRate: 1.0
```

### Prometheus Configuration

Located at `server/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'traefik'
    static_configs:
      - targets: ['plosolver-traefik-production:8082']
        labels:
          environment: 'production'
      - targets: ['plosolver-traefik-staging:8082']
        labels:
          environment: 'staging'
      - targets: ['plosolver-traefik-localdev:8082']
        labels:
          environment: 'local'
    metrics_path: /metrics
    scrape_interval: 10s
    scrape_timeout: 5s
```

## Docker Compose Setup

### Production Environment

The production docker-compose includes:

```yaml
services:
  traefik:
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
      - "8082:8082"  # Metrics endpoint
    volumes:
      - ./server/traefik/production/traefik.yml:/etc/traefik/traefik.yml:ro

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9091:9090"
    volumes:
      - ./data/prometheus:/prometheus
      - ./server/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --web.enable-lifecycle

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3006:3000"
    volumes:
      - ./data/grafana:/var/lib/grafana
```

## Available Metrics

### Key Traefik Metrics

1. **Request Metrics**:
   - `traefik_http_requests_total`: Total number of HTTP requests
   - `traefik_http_request_duration_seconds`: Request duration histogram
   - `traefik_http_responses_total`: Total number of HTTP responses by status code

2. **Connection Metrics**:
   - `traefik_http_connections_total`: Total number of connections
   - `traefik_http_connection_duration_seconds`: Connection duration

3. **Service Metrics**:
   - `traefik_service_requests_total`: Requests per service
   - `traefik_service_request_duration_seconds`: Service response time

4. **Entry Point Metrics**:
   - `traefik_entrypoint_requests_total`: Requests per entry point
   - `traefik_entrypoint_request_duration_seconds`: Entry point response time

### Useful Prometheus Queries

```promql
# Request rate per minute
rate(traefik_http_requests_total[1m])

# 95th percentile response time
histogram_quantile(0.95, rate(traefik_http_request_duration_seconds_bucket[5m]))

# Error rate (4xx and 5xx responses)
rate(traefik_http_responses_total{code=~"4..|5.."}[5m])

# Top services by request count
topk(5, sum by (service) (traefik_service_requests_total))
```

## Accessing the Monitoring Stack

### Local Development
- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3006
- **Traefik Dashboard**: http://localhost:8080
- **Traefik Metrics**: http://localhost:8082/metrics

### Staging Environment
- **Prometheus**: http://staging.ploscope.com:9091
- **Grafana**: http://staging.ploscope.com:3006
- **Traefik Dashboard**: http://staging.ploscope.com:8080
- **Traefik Metrics**: http://staging.ploscope.com:8082/metrics

### Production Environment
- **Prometheus**: http://ploscope.com:9091
- **Grafana**: http://ploscope.com:3006
- **Traefik Dashboard**: http://ploscope.com:8080
- **Traefik Metrics**: http://ploscope.com:8082/metrics

## Verification

Use the verification script to ensure metrics are flowing properly:

```bash
# Verify local environment
./scripts/operations/verify-traefik-metrics.sh local

# Verify staging environment
./scripts/operations/verify-traefik-metrics.sh staging

# Verify production environment
./scripts/operations/verify-traefik-metrics.sh production
```

## Troubleshooting

### Common Issues

1. **Prometheus can't reach Traefik**:
   - Check if Traefik metrics port (8082) is exposed
   - Verify network connectivity between containers
   - Check Prometheus target status at `/api/v1/targets`

2. **No metrics in Prometheus**:
   - Verify Traefik metrics endpoint is accessible
   - Check Prometheus configuration file is mounted correctly
   - Restart Prometheus container to reload configuration

3. **High memory usage**:
   - Adjust Prometheus retention settings
   - Consider reducing scrape frequency
   - Monitor Prometheus resource usage

### Debug Commands

```bash
# Check Traefik metrics endpoint
curl http://localhost:8082/metrics

# Check Prometheus targets
curl http://localhost:9091/api/v1/targets

# Check specific metric
curl "http://localhost:9091/api/v1/query?query=traefik_http_requests_total"

# Check Prometheus configuration
curl http://localhost:9091/api/v1/status/config
```

## Security Considerations

1. **Access Control**: Prometheus and Grafana should be protected with authentication
2. **Network Security**: Metrics endpoints should not be publicly accessible
3. **Data Retention**: Configure appropriate retention policies for metrics data
4. **Resource Limits**: Set memory and CPU limits for monitoring containers

## Performance Optimization

1. **Scrape Intervals**: Adjust based on monitoring needs (10s for critical, 30s for general)
2. **Metric Filtering**: Only collect necessary metrics to reduce storage requirements
3. **Retention Policies**: Configure appropriate data retention periods
4. **Resource Allocation**: Monitor and adjust container resource limits

## Integration with CI/CD

The monitoring setup is integrated into the deployment pipeline:

1. **Health Checks**: Docker Compose includes health checks for all monitoring services
2. **Configuration Validation**: Prometheus configuration is validated during deployment
3. **Metrics Verification**: Automated verification scripts ensure metrics flow
4. **Alerting**: Grafana can be configured with alerting rules for critical metrics

## Next Steps

1. **Grafana Dashboards**: Create custom dashboards for application-specific metrics
2. **Alerting Rules**: Configure alerting for critical thresholds
3. **Log Integration**: Integrate with ELK stack for comprehensive observability
4. **Custom Metrics**: Add application-specific metrics to the monitoring stack 