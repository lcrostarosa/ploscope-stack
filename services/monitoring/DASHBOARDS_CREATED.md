# Production and Staging Logs & Metrics Dashboards

## ✅ Dashboards Created

### 1. Production Logs & Metrics Dashboard
**File:** `grafana-config/grafana-dashboards/production-logs-metrics-dashboard.json`
**UID:** `production-logs-metrics`

### 2. Staging Logs & Metrics Dashboard
**File:** `grafana-config/grafana-dashboards/staging-logs-metrics-dashboard.json`
**UID:** `staging-logs-metrics`

## 📊 Dashboard Panels

Both dashboards include the following panels:

### 1. Requests Per Second
- **Metric:** `sum(rate(traefik_entrypoint_requests_total{environment="..."}[1m])) by (entrypoint)`
- **Unit:** Requests per second (reqps)
- **Shows:** HTTP request rate by entrypoint

### 2. CPU Usage %
- **Metric:** `rate(container_cpu_usage_seconds_total{environment="...", container_name!="POD"}[5m]) * 100`
- **Unit:** Percentage (%)
- **Thresholds:** Green < 70%, Yellow 70-85%, Red > 85%
- **Shows:** CPU usage per container

### 3. Memory Usage %
- **Metric:** `100 * (container_memory_usage_bytes{environment="..."} / container_spec_memory_limit_bytes{environment="..."})`
- **Unit:** Percentage (%)
- **Thresholds:** Green < 80%, Yellow 80-90%, Red > 90%
- **Shows:** Memory usage percentage per container

### 4. IOPS (Reads + Writes)
- **Metric:** `rate(container_fs_reads_total{environment="..."}[5m]) + rate(container_fs_writes_total{environment="..."}[5m])`
- **Unit:** IOPS (Input/Output Operations Per Second)
- **Shows:** Combined read and write IOPS per container

### 5. RabbitMQ Queue Messages
- **Metrics:** 
  - `rabbitmq_queue_messages_ready{environment="..."}`
  - `rabbitmq_queue_messages_unacknowledged{environment="..."}`
- **Unit:** Messages (short)
- **Shows:** Queue depth and unacknowledged messages per queue

### 6. RabbitMQ Jobs Status
- **Metrics:**
  - `rabbitmq_up{environment="..."}` - Service status
  - `rabbitmq_queue_consumers{environment="..."}` - Consumers per queue
- **Type:** Table
- **Shows:** RabbitMQ health and consumer counts

### 7. Error Logs
- **LogQL:** `{environment="..."} |= "ERROR" or |= "FATAL" or |= "CRITICAL" or |= "Exception" or |= "error" or |= "failed"`
- **Type:** Logs panel
- **Shows:** All error-level logs from production/staging containers

### 8. Error Rate by Container
- **LogQL:** `sum(rate({environment="..."} |= "ERROR" or ... [1m])) by (container_name)`
- **Unit:** Errors per second
- **Thresholds:** Green < 1, Yellow 1-5, Red > 5
- **Shows:** Error rate trend per container

### 9. Log Rate by Container
- **LogQL:** `sum(rate({environment="..."}[1m])) by (container_name)`
- **Unit:** Logs per second
- **Shows:** Overall log volume per container

## 🔧 Configuration

### Datasources Used

**Production Dashboard:**
- Prometheus: `PA41442CB522D174D` (Prometheus (Production))
- Loki: `PAABE892D2EFEB273` (Loki (Production))

**Staging Dashboard:**
- Prometheus: `PDE721BD19156384A` (Prometheus (Staging))
- Loki: `P5CA6E0688B18D13B` (Loki (Staging))

### Template Variables

Both dashboards include:
- **Container:** Multi-select variable for filtering by container name
- **Source:** Loki label values query

### Refresh Rate

- **Default:** 10 seconds
- **Time Range:** Last 1 hour

## 🚀 Deployment

The dashboards will be automatically provisioned when:
1. Files are deployed to the server
2. Grafana reads the dashboard provisioning directory
3. Dashboard refresh occurs (automatic or manual)

## 📋 Verification

After deployment, verify dashboards:

1. **Access Grafana:** https://grafana.ploscope.com
2. **Navigate to Dashboards**
3. **Look for:**
   - "Production Logs & Metrics Dashboard"
   - "Staging Logs & Metrics Dashboard"
4. **Verify panels show data:**
   - Requests per second should show Traefik metrics
   - CPU/Memory should show container metrics
   - RabbitMQ panels should show queue status
   - Error logs should show any errors

## 🎯 Metrics Availability

### Required Metrics

These dashboards expect the following metrics to be available:

**From cAdvisor (via Prometheus):**
- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_spec_memory_limit_bytes`
- `container_fs_reads_total`
- `container_fs_writes_total`

**From Traefik:**
- `traefik_entrypoint_requests_total`

**From RabbitMQ:**
- `rabbitmq_up`
- `rabbitmq_queue_messages_ready`
- `rabbitmq_queue_messages_unacknowledged`
- `rabbitmq_queue_consumers`

**From Loki:**
- Logs with `environment="production"` or `environment="staging"` labels
- Container name labels

### If Metrics Are Missing

If panels show "No data":
1. Check if services are running
2. Verify Prometheus is scraping targets
3. Check metric names match your setup
4. Verify environment labels are applied

## 🔄 Customization

To customize dashboards:

1. **Edit JSON files** directly
2. **Or use Grafana UI:**
   - Open dashboard
   - Click "Edit"
   - Modify panels
   - Save changes

Changes made in Grafana UI will be saved to Grafana's database, not the JSON files.

## ✅ Summary

- ✅ Production dashboard created with all requested panels
- ✅ Staging dashboard created with all requested panels
- ✅ Both use correct datasource UIDs
- ✅ Panels include: Requests/sec, CPU, Memory, IOPS, RabbitMQ status, Errors
- ✅ Ready for deployment


