# Monitoring Services Authentication

## Overview

Authentication for monitoring services (Prometheus, Loki, Grafana) is managed in the **Traefik repository**, not in the monitoring stack. This ensures centralized security management and clean separation of concerns.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Traefik (Reverse Proxy)                 │
│  - SSL/TLS Termination                                      │
│  - Basic Auth Middleware                                     │
│  - Routing Rules                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌──────────────┬──────────────┬──────────────┐
        │              │              │              │
   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
   │Prometheus│   │  Loki   │   │ Grafana │   │  Alloy  │
   │(no auth) │   │(no auth)│   │(has auth)│  │(no auth)│
   └──────────┘   └─────────┘   └─────────┘   └─────────┘
```

## Authentication Configuration

### Where Authentication is Configured

**✅ Traefik Repository (`/traefik/staging/dynamic.docker.yml` and `/traefik/production/dynamic.docker.yml`)**

```yaml
middlewares:
  # Basic authentication for Prometheus
  prometheus-auth:
    basicAuth:
      users:
        - "prometheususer:$apr1$8K8v9rX2$5Y7v8w9x0y1z2a3b4c5d6e"
  
  # Basic authentication for Loki
  loki-auth:
    basicAuth:
      users:
        - "lokiuser:$apr1$9L9w0sY3$6Z8x9y0z1a2b3c4d5e6f7g"

http:
  routers:
    prometheus-https:
      rule: "Host(`prometheus.ploscope.com`)"
      service: prometheus
      middlewares:
        - prometheus-auth  # ← Authentication applied here
        - cors-headers
      
    loki-https:
      rule: "Host(`loki.ploscope.com`)"
      service: loki
      middlewares:
        - loki-auth  # ← Authentication applied here
        - cors-headers
```

**❌ NOT in Monitoring Repository**
- No Traefik labels in `docker-compose.yml`
- No `PROMETHEUS_BASIC_AUTH` or `LOKI_BASIC_AUTH` environment variables
- Services expose ports internally only, no authentication at service level

## Services and Authentication

| Service | Public URL | Authentication | Managed In |
|---------|------------|----------------|------------|
| **Prometheus** | `prometheus.ploscope.com` | ✅ Basic Auth | Traefik repo |
| **Loki** | `loki.ploscope.com` | ✅ Basic Auth | Traefik repo |
| **Grafana** | `grafana.ploscope.com` | ✅ Built-in Auth | Grafana config |
| **Alloy** | Internal only | ❌ No public access | N/A |
| **cAdvisor** | Internal only | ❌ No public access | N/A |

## Credentials

### Production

**Prometheus:**
- Username: `prometheususer`
- Password: Contact DevOps for credentials
- Access: https://prometheus-prod.ploscope.com

**Loki:**
- Username: `lokiuser`
- Password: Contact DevOps for credentials
- Access: https://loki.grafana-prod.ploscope.com

**Grafana:**
- Username: `admin`
- Password: Set via `GRAFANA_ADMIN_PASSWORD` environment variable
- Access: https://grafana-prod.ploscope.com

### Staging

**Prometheus:**
- Username: `prometheususer`
- Password: Contact DevOps for credentials
- Access: https://prometheus.ploscope.com

**Loki:**
- Username: `lokiuser`
- Password: Contact DevOps for credentials
- Access: https://loki.ploscope.com

**Grafana:**
- Username: `admin`
- Password: `admin-staging-123` (configured in `env.staging`)
- Access: https://grafana.ploscope.com

## How to Update Credentials

### 1. Generate New Hashed Password

Use `htpasswd` to generate bcrypt hashed passwords:

```bash
# Install apache2-utils if needed
sudo apt-get install apache2-utils

# Generate hashed password
htpasswd -nbB prometheususer "your-secure-password"
```

Output will be:
```
prometheususer:$2y$05$...hashed...password...
```

### 2. Update Traefik Configuration

**For Staging (`/traefik/staging/dynamic.docker.yml`):**

```yaml
middlewares:
  prometheus-auth:
    basicAuth:
      users:
        - "prometheususer:$2y$05$...new-hashed-password..."
```

**For Production (`/traefik/production/dynamic.docker.yml`):**

```yaml
middlewares:
  prometheus-auth:
    basicAuth:
      users:
        - "prometheususer:$2y$05$...new-hashed-password..."
```

### 3. Deploy Traefik

```bash
# Navigate to traefik repository
cd ~/ploscope/traefik

# Pull latest changes
git pull origin master

# Restart Traefik (it will auto-reload dynamic config)
docker restart traefik-production  # or traefik-staging
```

## Accessing Services

### Via Grafana (Recommended)

Access monitoring services through Grafana data sources:
1. Login to Grafana
2. Go to **Explore**
3. Select **Prometheus (Staging)** or **Loki (Staging)** from the dropdown
4. Credentials are automatically configured

### Direct Access

**Using curl with Basic Auth:**

```bash
# Prometheus
curl -u prometheususer:password https://prometheus.ploscope.com/api/v1/query?query=up

# Loki
curl -u lokiuser:password https://loki.ploscope.com/loki/api/v1/labels
```

**Using web browser:**
1. Navigate to service URL
2. Browser will prompt for username/password
3. Enter credentials

## Federation (Staging → Production)

Staging Grafana can access Production metrics for comparison:

**In `env.staging`:**
```bash
PRODUCTION_PROMETHEUS_URL=https://prometheus-prod.ploscope.com
PRODUCTION_PROMETHEUS_USER=prometheususer
PRODUCTION_PROMETHEUS_PASSWORD=securepassword123
```

**In Grafana datasources (`datasources.staging.yml`):**
```yaml
- name: Prometheus (Production)
  type: prometheus
  url: ${PRODUCTION_PROMETHEUS_URL}
  basicAuth: true
  basicAuthUser: ${PRODUCTION_PROMETHEUS_USER}
  secureJsonData:
    basicAuthPassword: ${PRODUCTION_PROMETHEUS_PASSWORD}
```

## Security Best Practices

1. **Rotate passwords regularly** - Update credentials every 90 days
2. **Use strong passwords** - Minimum 20 characters, mixed case, numbers, symbols
3. **Limit access** - Only expose services that need public access
4. **Use VPN for sensitive services** - Consider VPN-only access for production
5. **Monitor access logs** - Review Traefik logs for unauthorized attempts
6. **SSL/TLS only** - All public services use HTTPS (managed by Traefik)

## Troubleshooting

### Authentication Fails

**Problem:** Getting 401 Unauthorized when accessing Prometheus/Loki

**Solutions:**
1. Verify credentials are correct
2. Check Traefik middleware is applied to the route
3. Ensure Traefik has loaded the latest dynamic configuration:
   ```bash
   docker logs traefik-staging --tail 50 | grep "Configuration loaded"
   ```
4. Verify the hashed password format is correct (starts with `$apr1$` or `$2y$`)

### Can't Access Service at All

**Problem:** Service unreachable or 404 error

**Solutions:**
1. Verify service is running:
   ```bash
   docker ps | grep -E "(prometheus|loki)"
   ```
2. Check Traefik routing rules in dynamic config
3. Verify DNS points to correct server
4. Check Traefik logs for routing errors:
   ```bash
   docker logs traefik-staging --tail 100
   ```

### Grafana Can't Connect to Data Sources

**Problem:** Grafana shows data source as unreachable

**Solutions:**
1. **For Staging → Staging connections:**
   - Verify services are on same Docker network (`plo-network-cloud`)
   - Use internal URLs: `http://prometheus:9090`, `http://loki:3100`
   - No authentication needed for internal connections

2. **For Staging → Production connections:**
   - Verify credentials in `env.staging` are correct
   - Test connection manually:
     ```bash
     curl -u user:pass https://prometheus-prod.ploscope.com/api/v1/query?query=up
     ```
   - Check Grafana logs for connection errors

## Related Documentation

- [Traefik Configuration](../traefik/README.md)
- [Prometheus Configuration](prometheus.yml)
- [Grafana Data Sources](grafana-config/grafana-datasources-provisioning/)
- [Deployment Guide](README.md)

