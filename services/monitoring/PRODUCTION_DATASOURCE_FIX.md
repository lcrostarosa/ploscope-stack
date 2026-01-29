# Production Datasource Fix

## Issues Found and Fixed

### 1. **URL Mismatch** ❌ → ✅
**Problem:** 
- Traefik routes: `prometheus-prod.ploscope.com` and `loki.grafana-prod.ploscope.com`
- Env files used: `prometheus.ploscope.com` and `loki.ploscope.com`

**Fix:**
- ✅ Updated `env.staging` with correct production URLs
- ✅ Updated `prometheus.staging.yml` federation config

### 2. **Missing Environment Variables in Grafana** ❌ → ✅
**Problem:** 
- Grafana datasources use `${PRODUCTION_PROMETHEUS_URL}` variable substitution
- But these variables weren't passed to the Grafana container
- Result: datasource URLs were literally `${PRODUCTION_PROMETHEUS_URL}` instead of actual URLs

**Fix:**
- ✅ Added `PRODUCTION_*` environment variables to Grafana service in `docker-compose.yml`
- ✅ Updated deployment workflow to export these variables

### 3. **GitHub Actions Missing Variables** ❌ → ✅
**Problem:** 
- Production credentials weren't configured in GitHub Actions

**Fix:**
- ✅ Updated workflow to export production endpoint variables

## What You Need to Do Now

### Step 1: Configure GitHub Actions Secrets/Variables

**Go to:** GitHub → monitoring repository → Settings → Secrets and variables → Actions

#### Add Variables (not secrets):
```
PRODUCTION_PROMETHEUS_URL=https://prometheus-prod.ploscope.com
PRODUCTION_PROMETHEUS_USER=prometheususer
PRODUCTION_LOKI_URL=https://loki.grafana-prod.ploscope.com
PRODUCTION_LOKI_USER=lokiuser
```

#### Add Secrets:
```
PRODUCTION_PROMETHEUS_PASSWORD=securepassword123
PRODUCTION_LOKI_PASSWORD=securepassword123
```

### Step 2: Verify Production is Running

On your **production server**, check:

```bash
# Check production monitoring services are running
docker ps | grep -E "(prometheus|loki)-production"

# Should see:
# - prometheus-production
# - loki-production
# - alloy-production
# - cadvisor-production
```

### Step 3: Test Production URLs

```bash
# Test Prometheus (with basic auth)
curl -u prometheususer:securepassword123 \
  https://prometheus-prod.ploscope.com/api/v1/query?query=up

# Test Loki (with basic auth)
curl -u lokiuser:securepassword123 \
  https://loki.grafana-prod.ploscope.com/ready
```

If these fail:
- ✅ Verify production monitoring is deployed
- ✅ Check Traefik is running and configured
- ✅ Verify DNS records point to production server
- ✅ Check Basic Auth credentials match Traefik config

### Step 4: Deploy Staging with New Configuration

```bash
# Via GitHub Actions
# Go to: Actions → Deploy → Run workflow
# Select: staging environment
# Click: Run workflow

# Or manually on staging server:
cd ~/ploscope/monitoring
git pull origin master
docker-compose down
docker-compose up -d
```

### Step 5: Diagnose Datasources

**On staging server**, run the diagnostic script:

```bash
cd ~/ploscope/monitoring
./diagnose-datasources.sh
```

This will check:
- ✅ Grafana is running
- ✅ Environment variables are set correctly
- ✅ Datasources are configured
- ✅ Production endpoints are reachable
- ✅ Basic auth is working

### Step 6: Verify in Grafana

1. **Login to Grafana:**
   - URL: http://grafana.staging.ploscope.com (or http://localhost:3001)
   - User: `admin`
   - Pass: `admin-staging-123`

2. **Check Datasources:**
   - Go to: Configuration → Data sources
   - You should see:
     - ✅ Prometheus (Staging) - Default
     - ✅ Prometheus (Production) - with URL `https://prometheus-prod.ploscope.com`
     - ✅ Loki (Staging)
     - ✅ Loki (Production) - with URL `https://loki.grafana-prod.ploscope.com`

3. **Test Connection:**
   - Click on "Prometheus (Production)"
   - Scroll down and click "Save & test"
   - Should show: ✅ "Data source is working"

4. **Query Production Data:**
   - Go to: Explore
   - Select: "Prometheus (Production)" from dropdown
   - Query: `up{environment="production"}`
   - Click "Run query"
   - You should see production metrics!

## Architecture After Fix

```
┌─────────────────────────────────────────────────────────────────┐
│                    Staging Environment                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Grafana (staging)                                        │  │
│  │ - Has PRODUCTION_* environment variables                 │  │
│  │ - Datasources configured with correct URLs              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                     │
│                           ├─────────────────┐                   │
│                           ▼                 ▼                   │
│  ┌───────────────────────────┐   ┌─────────────────────────┐  │
│  │ Prometheus (staging)      │   │ Loki (staging)          │  │
│  │ - Scrapes local services  │   │ - Collects local logs   │  │
│  │ - Federates from prod     │   └─────────────────────────┘  │
│  └───────────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS + Basic Auth
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Production Environment                        │
│                                                                 │
│  ┌──────────────────────┐          ┌──────────────────────┐    │
│  │ Traefik              │          │ Traefik              │    │
│  │ prometheus-prod.*    │          │ loki.grafana-prod.*  │    │
│  │ + Basic Auth         │          │ + Basic Auth         │    │
│  └──────────────────────┘          └──────────────────────┘    │
│           │                                  │                  │
│           ▼                                  ▼                  │
│  ┌──────────────────────┐          ┌──────────────────────┐    │
│  │ Prometheus (prod)    │          │ Loki (prod)          │    │
│  │ - No auth internally │          │ - No auth internally │    │
│  └──────────────────────┘          └──────────────────────┘    │
│                                                                 │
│  ⚠️  NOTE: No Grafana in production (by design)               │
│     All monitoring viewed through Staging Grafana              │
└─────────────────────────────────────────────────────────────────┘
```

## Expected Results

After following all steps, you should:

1. ✅ See "Prometheus (Production)" datasource as working in Grafana
2. ✅ Be able to query production metrics from Staging Grafana
3. ✅ See production logs in "Loki (Production)" datasource
4. ✅ Staging Prometheus automatically federating production metrics
5. ✅ All connections secured with Basic Authentication
6. ✅ Can compare staging vs production metrics side-by-side

## Troubleshooting

### Datasource Still Shows Error

**Check environment variables in Grafana:**
```bash
docker exec grafana-staging env | grep PRODUCTION
```

Should show:
```
PRODUCTION_PROMETHEUS_URL=https://prometheus-prod.ploscope.com
PRODUCTION_PROMETHEUS_USER=prometheususer
PRODUCTION_PROMETHEUS_PASSWORD=securepassword123
PRODUCTION_LOKI_URL=https://loki.grafana-prod.ploscope.com
PRODUCTION_LOKI_USER=lokiuser
PRODUCTION_LOKI_PASSWORD=securepassword123
```

If not, redeploy staging.

### Can't Reach Production URLs

**From staging server:**
```bash
# Test without auth (should fail with 401)
curl -I https://prometheus-prod.ploscope.com/api/v1/query

# Should return: HTTP/1.1 401 Unauthorized (this is good!)

# Test with auth (should succeed)
curl -u prometheususer:securepassword123 \
  https://prometheus-prod.ploscope.com/api/v1/query?query=up
```

If both fail:
- Check production monitoring is deployed
- Check Traefik is running
- Check DNS

### Authentication Fails

Verify credentials in Traefik config match:

**In `/traefik/production/dynamic.docker.yml`:**
```yaml
prometheus-auth:
  basicAuth:
    users:
      - "prometheususer:$apr1$8K8v9rX2$5Y7v8w9x0y1z2a3b4c5d6e"
```

Password should hash to `securepassword123` (or update to match your password).

## Related Files Changed

```
monitoring/
├── env.staging                     ← Updated production URLs
├── prometheus.staging.yml          ← Updated federation config
├── docker-compose.yml              ← Added PRODUCTION_* env vars to Grafana
├── .github/workflows/deploy.yml    ← Export PRODUCTION_* variables
├── diagnose-datasources.sh         ← New diagnostic script
└── PRODUCTION_DATASOURCE_FIX.md    ← This file

traefik/
├── staging/dynamic.docker.yml      ← Has Basic Auth for Prometheus/Loki
└── production/dynamic.docker.yml   ← Has Basic Auth for Prometheus/Loki
```

## Summary

The issue was a combination of:
1. **Wrong URLs** - Using staging URLs instead of production URLs
2. **Missing environment variables** - Grafana couldn't substitute datasource URLs
3. **Missing GitHub Actions configuration** - Variables not available during deployment

All are now fixed! Just need to:
1. Configure GitHub Actions secrets/variables
2. Verify production is running
3. Deploy staging with new config
4. Test datasources in Grafana

