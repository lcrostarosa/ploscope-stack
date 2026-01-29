# PLOScope Monitoring Infrastructure

This directory contains the complete monitoring infrastructure for PLOScope, including Prometheus metrics collection, Grafana dashboards, and alerting configuration.

## Overview

The monitoring stack consists of:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and alerting
- **Traefik**: Reverse proxy with built-in metrics

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Traefik   │───▶│ Prometheus  │───▶│   Grafana   │
│   :8082     │    │   :9090     │    │   :3000     │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Components

### Prometheus (`prometheus.yml`)
- **Scrape Interval**: 15 seconds (global), 10 seconds for Traefik
- **Targets**:
  - Prometheus itself (`localhost:9090`)
  - Traefik reverse proxy (`traefik:8082`)
- **Metrics Path**: `/metrics` for Traefik
- **Environment Labels**: Applied to distinguish between environments

### Grafana Configuration

#### Data Sources (`grafana-provisioning.yml`)
- **Prometheus**: Primary data source at `http://prometheus:9090`
- **Access Mode**: Proxy (Grafana fetches data on behalf of users)
- **Default**: Set as the default data source

#### Dashboard Provisioning (`grafana-dashboards-provisioning.yml`)
- **Provider**: File-based dashboard provisioning
- **Path**: `/etc/grafana/provisioning/dashboards`
- **Features**:
  - Automatic folder structure from files
  - Editable dashboards
  - Deletion enabled

#### Available Dashboards
- **Traefik Dashboard** (`grafana-dashboards/traefik-dashboard.json`)
  - HTTP request rates and response codes
  - Backend health and performance metrics
  - SSL certificate monitoring

### Alerting (`grafana-alerting-provisioning/`)

#### Contact Points (`alerting.yml`)
- **Slack Integration**: Configured for team notifications
- **Webhook URL**: Set via `SLACK_ALERT_WEBHOOK_URL` environment variable
- **Recipient**: Configurable via `SLACK_ALERT_RECIPIENT` (defaults to `#alerts`)
- **Username**: "PLOSolver Alerts"

#### Alert Rules (`rules.yml`)
- Comprehensive alerting rules for:
  - High error rates
  - Service availability
  - Performance degradation
  - Resource utilization

## Usage

### Local Development
```bash
# Start monitoring stack
docker-compose up -d prometheus grafana

# Access Grafana
open http://localhost:3002

# Access Prometheus
open http://localhost:9091
```

### Default Credentials
- **Grafana**: `admin/admin` (configured in docker-compose)
- **Prometheus**: No authentication required

### Environment Variables
```bash
# Required for Slack alerts
SLACK_ALERT_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_ALERT_RECIPIENT=#alerts
```

## Adding New Services

### 1. Add Prometheus Target
Edit `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'your-service'
    static_configs:
      - targets: ['your-service:port']
        labels:
          environment: 'local'
    metrics_path: /metrics
```

### 2. Create Grafana Dashboard
1. Design dashboard in Grafana UI
2. Export as JSON
3. Save to `grafana-dashboards/your-service-dashboard.json`

### 3. Add Alert Rules
Edit `grafana-alerting-provisioning/rules.yml`:
```yaml
groups:
  - name: your-service
    rules:
      - alert: YourServiceDown
        expr: up{job="your-service"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Your service is down"
```

## Monitoring Best Practices

### Metrics to Monitor
- **Availability**: Service uptime and health checks
- **Performance**: Response times and throughput
- **Errors**: Error rates and types
- **Resources**: CPU, memory, disk usage
- **Business Metrics**: User activity, feature usage

### Alert Thresholds
- **Critical**: Immediate response required
- **Warning**: Investigate within 30 minutes
- **Info**: Monitor and trend analysis

### Dashboard Design
- Keep dashboards focused on specific services or concerns
- Use consistent naming conventions
- Include both current values and trends
- Group related metrics together

## Troubleshooting

### Common Issues

#### Prometheus Can't Scrape Targets
- Check target availability: `curl http://target:port/metrics`
- Verify network connectivity between containers
- Check firewall rules and port configurations

#### Grafana Can't Connect to Prometheus
- Verify Prometheus is running: `docker ps | grep prometheus`
- Check data source configuration in Grafana
- Ensure correct URL format: `http://prometheus:9090`

#### Alerts Not Firing
- Verify contact point configuration
- Check Slack webhook URL validity
- Review alert rule expressions
- Check Grafana alerting logs

### Useful Commands
```bash
# Check Prometheus targets
curl http://localhost:9091/api/v1/targets

# Check Grafana health
curl http://localhost:3002/api/health

# View Prometheus metrics
curl http://localhost:9091/metrics
```

## Security Considerations

- **Network Isolation**: Monitoring services run in isolated Docker networks
- **Authentication**: Grafana requires login (default: admin/admin)
- **TLS**: Production deployments should use HTTPS
- **Access Control**: Limit access to monitoring endpoints in production

## Contributing

When adding new monitoring components:

1. Update this README with new configuration details
2. Add appropriate alert rules for new services
3. Create dashboards for new metrics
4. Test configurations in local environment first
5. Document any new environment variables required

## License

This monitoring infrastructure is licensed under the same terms as the main PLOScope project. 