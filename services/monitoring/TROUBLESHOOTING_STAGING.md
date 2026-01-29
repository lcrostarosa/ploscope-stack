# Staging Monitoring Troubleshooting Guide

## Quick Diagnosis

Run these commands on your staging server to check what's working:

```bash
# 1. Check if monitoring containers are running
docker ps | grep -E "(prometheus|grafana|loki|alloy|cadvisor)"

# 2. Check Prometheus targets status
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'

# 3. Check if Loki is receiving logs
curl -s http://localhost:3100/loki/api/v1/label/container_name/values | jq '.'

# 4. Check Alloy status
curl -s http://localhost:12345/metrics | grep alloy

# 5. View container logs
docker logs alloy-staging --tail 50
docker logs prometheus-staging --tail 50
docker logs loki-staging --tail 50
```

## Expected Data Sources

Your staging Prometheus is configured to scrape:

### Working Targets (should have data):
- ✅ **prometheus** (localhost:9090) - Self-monitoring
- ✅ **alloy** (alloy:12345) - Log collector metrics
- ✅ **cadvisor** (cadvisor:8080) - Container metrics
- ⚠️ **traefik** (traefik:8082) - Only if Traefik is running on staging

### Application Targets (require apps to be running):
- ❌ **frontend** (frontend:3000/metrics)
- ❌ **backend** (backend:8000/metrics)
- ❌ **celeryworker** (celeryworker:8001/metrics)
- ❌ **db** (db:5432/metrics)
- ❌ **rabbitmq** (rabbitmq:15692/metrics)
- ❌ **nexus** (nexus:8081/metrics)

## Common Issues & Fixes

### Issue 1: No Application Services Running

**Symptom**: Only prometheus, alloy, and cadvisor show data

**Fix**: Your application services need to be running on the same server and Docker network

```bash
# Check what's on the plo-network-cloud network
docker network inspect plo-network-cloud | jq '.[].Containers'

# You should see: prometheus, grafana, loki, alloy, cadvisor, AND your app services
```

**Solution**: Deploy your application stack to staging:
```bash
# Navigate to your app directory and deploy
cd ~/ploscope/backend  # or wherever your app is
docker compose up -d
```

### Issue 2: Applications Don't Expose /metrics Endpoint

**Symptom**: Prometheus shows targets as "down" even though containers are running

**Check**:
```bash
# Test if metrics endpoints are accessible
docker exec -it prometheus-staging curl -s http://frontend:3000/metrics
docker exec -it prometheus-staging curl -s http://backend:8000/metrics
```

**Fix**: Your applications need to expose Prometheus metrics. You need to:

1. **For Python (FastAPI/Django)**:
   ```python
   # Install prometheus-client
   pip install prometheus-client
   
   # Add to your app
   from prometheus_client import make_asgi_app, Counter, Histogram
   
   # Expose /metrics endpoint
   metrics_app = make_asgi_app()
   app.mount("/metrics", metrics_app)
   ```

2. **For Node.js/React**:
   ```javascript
   // Install prom-client
   npm install prom-client
   
   // Add metrics endpoint
   const client = require('prom-client');
   const register = new client.Registry();
   client.collectDefaultMetrics({ register });
   
   app.get('/metrics', (req, res) => {
     res.set('Content-Type', register.contentType);
     res.end(register.metrics());
   });
   ```

### Issue 3: Docker Network Isolation

**Symptom**: Containers can't reach each other

**Check**:
```bash
# Test connectivity from prometheus container
docker exec -it prometheus-staging ping -c 2 frontend
docker exec -it prometheus-staging ping -c 2 backend
docker exec -it prometheus-staging ping -c 2 cadvisor
```

**Fix**: Ensure all services are on the `plo-network-cloud` network

```yaml
# In your application's docker-compose.yml
networks:
  default:
    name: plo-network-cloud
    external: true
```

### Issue 4: No Logs in Loki

**Symptom**: Grafana Explore shows no logs when querying Loki

**Check**:
```bash
# Check if Alloy is collecting logs
docker logs alloy-staging 2>&1 | grep -i error

# Check if Docker log files exist
sudo ls -lh /var/lib/docker/containers/*/*.log | head -10

# Test Loki directly
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={environment="staging"}' | jq '.'
```

**Fix Options**:

1. **Permission issue**:
   ```bash
   # Alloy needs permission to read Docker logs
   sudo chmod 644 /var/lib/docker/containers/*/*.log
   ```

2. **Alloy not running properly**:
   ```bash
   docker restart alloy-staging
   docker logs alloy-staging --follow
   ```

### Issue 5: Federation from Production Not Working

**Symptom**: Can't see production metrics in staging Grafana

**Check**:
```bash
# Test production Prometheus connectivity
curl -u "prometheususer:securepassword123" \
  https://prometheus.ploscope.com/api/v1/targets
```

**Fix**: Ensure production Prometheus credentials are correct in `env.staging`:
```bash
PRODUCTION_PROMETHEUS_URL=https://prometheus.ploscope.com
PRODUCTION_PROMETHEUS_USER=prometheususer
PRODUCTION_PROMETHEUS_PASSWORD=securepassword123
```

## What Should Be Working Right Now

Even without application services, you should see:

### In Prometheus (http://localhost:9090/targets):
- ✅ prometheus job (1/1 up)
- ✅ alloy job (1/1 up)
- ✅ cadvisor job (1/1 up)
- ❌ traefik job (0/1 up) - OK if Traefik not deployed
- ❌ frontend, backend, etc. (0/1 up) - Expected if apps not deployed

### In Grafana Dashboards:
- ✅ Container metrics from cAdvisor (CPU, memory, network)
- ✅ Prometheus metrics (queries, storage, etc.)
- ✅ Docker container logs in Explore → Loki

### In Loki (Grafana Explore):
Try these queries:
```logql
# All logs
{environment="staging"}

# Logs from specific container
{container_name="prometheus-staging"}

# Logs from monitoring stack
{container_name=~"prometheus-staging|loki-staging|alloy-staging"}
```

## Quick Test Queries in Grafana

Go to Grafana → Explore → Select "Prometheus (Staging)"

```promql
# Check if Prometheus is scraping itself
up{job="prometheus"}

# Check container metrics
rate(container_cpu_usage_seconds_total[5m])

# Check available containers
count by (container_name) (container_last_seen)

# Check Alloy metrics
alloy_component_controller_evaluating
```

## Step-by-Step Verification

1. **Check containers are running**:
   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
   ```

2. **Access Grafana**:
   ```bash
   # Staging: http://grafana.staging.ploscope.com
   # Or via port: http://localhost:3001
   # Login: admin / admin-staging-123
   ```

3. **Check Prometheus targets**:
   ```bash
   # Via UI: http://prometheus.staging.ploscope.com/targets
   # Or: http://localhost:9090/targets
   ```

4. **Query Loki logs**:
   - Grafana → Explore
   - Select "Loki (Staging)"
   - Query: `{environment="staging"}`
   - Click "Run query"

5. **Check container metrics**:
   - Grafana → Dashboards
   - Open "Docker Monitoring Dashboard"
   - You should see metrics from all running containers

## Next Steps

1. **If monitoring stack is working but no app data**:
   - Deploy your application services to staging
   - Ensure they're on the `plo-network-cloud` network
   - Add `/metrics` endpoints to your applications

2. **If monitoring stack itself has issues**:
   - Check container logs
   - Verify Docker network exists
   - Restart services: `docker compose restart`

3. **If you need to see production data**:
   - Verify production endpoints are accessible
   - Check credentials in `env.staging`
   - Look at "Prometheus (Production)" datasource in Grafana


