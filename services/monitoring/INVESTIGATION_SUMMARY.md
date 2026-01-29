# Investigation Summary: Staging Grafana Deployment Issues

## Issues Identified

### 1. **Grafana Not Substituting Environment Variables** ❌

**Root Cause:**
Grafana's datasource provisioning system does NOT support environment variable substitution in YAML files. When Grafana reads `datasources.staging.yml` with `${PRODUCTION_PROMETHEUS_URL}`, it sees this as a literal string, not as a variable to substitute.

**Evidence:**
- `docker-compose.yml` correctly passes `PRODUCTION_*` environment variables to Grafana container
- Grafana container has these variables available (verified via `docker exec grafana-staging env`)
- But Grafana's provisioning system reads YAML files directly without variable substitution
- Result: Datasource URLs show literal `${PRODUCTION_PROMETHEUS_URL}` instead of `https://prometheus-prod.ploscope.com`

**Why Grafana doesn't support this:**
- Grafana's provisioning system is designed to read static YAML files
- Variable substitution is only supported in dashboard templates (not datasource provisioning)
- This is a design limitation of Grafana's provisioning system

### 2. **Production Server Access** ❌

**Secondary Issue:**
Even if URLs were correct, staging Grafana needs:
- Network connectivity to production endpoints
- DNS resolution for `prometheus-prod.ploscope.com` and `loki.grafana-prod.ploscope.com`
- Basic Authentication credentials (`prometheususer` / `securepassword123`)
- Traefik routing configured on production server

## Solution Implemented

### ✅ Solution: Pre-process Datasource Files with `envsubst`

**Approach:**
1. Before starting Grafana, run a script that:
   - Loads environment variables from `env.staging`
   - Uses `envsubst` to substitute `${PRODUCTION_*}` variables in the datasource YAML
   - Creates a processed file with actual URLs
2. Mount the processed file to Grafana instead of the template file

**Files Created:**
- `prepare-grafana-datasources.sh` - Processes datasource files with envsubst
- `start-monitoring.sh` - Orchestrates the deployment process
- `STAGING_GRAFANA_FIX.md` - Detailed documentation

**Files Modified:**
- `docker-compose.yml` - Changed volume mount to use processed datasource file
- `.gitignore` - Added processed files directory
- `Makefile` - Updated deploy commands to run preparation script

**Files Generated (gitignored):**
- `grafana-config/grafana-datasources-provisioning-processed/datasources.yml` - Processed file with real URLs

## How It Works

```bash
# 1. Load environment variables
source env.staging
export ENVIRONMENT=staging

# 2. Process datasource file
./prepare-grafana-datasources.sh
# Reads: datasources.staging.yml (with ${PRODUCTION_PROMETHEUS_URL})
# Writes: datasources.yml (with https://prometheus-prod.ploscope.com)

# 3. Start Grafana
docker-compose --env-file env.staging up -d
# Grafana mounts processed datasources.yml with real URLs
```

## Verification Steps

### 1. Check Processed File

```bash
cat grafana-config/grafana-datasources-provisioning-processed/datasources.yml | grep -E "url:|basicAuthUser:"

# Should show:
# url: https://prometheus-prod.ploscope.com
# basicAuthUser: prometheususer
# NOT: ${PRODUCTION_PROMETHEUS_URL}
```

### 2. Check Grafana Datasources

1. Access Grafana: http://localhost:3001
2. Login: admin / admin-staging-123
3. Go to: Configuration → Data sources
4. Check "Prometheus (Production)":
   - URL should be: `https://prometheus-prod.ploscope.com`
   - Basic Auth: Enabled
   - User: `prometheususer`

### 3. Test Production Connectivity

```bash
# From staging server
curl -u prometheususer:securepassword123 \
  https://prometheus-prod.ploscope.com/api/v1/query?query=up

curl -u lokiuser:securepassword123 \
  https://loki.grafana-prod.ploscope.com/ready
```

## Deployment Instructions

### Quick Fix (Staging Server)

```bash
cd /path/to/monitoring

# 1. Prepare datasource files
export ENVIRONMENT=staging
./prepare-grafana-datasources.sh

# 2. Restart Grafana
docker-compose --env-file env.staging restart grafana

# 3. Verify
./diagnose-datasources.sh
```

### Using Makefile

```bash
make deploy-staging
```

This will:
1. Run `prepare-grafana-datasources.sh`
2. Start docker-compose with correct environment

## Expected Results

After applying the fix:

✅ Grafana datasources show correct production URLs  
✅ Production Prometheus datasource connects successfully  
✅ Production Loki datasource connects successfully  
✅ Can query production metrics from staging Grafana  
✅ Can view production logs from staging Grafana  

## Troubleshooting

### Issue: Processed file still has `${PRODUCTION_*}`

**Fix:**
```bash
# Ensure envsubst is installed
which envsubst || sudo apt-get install gettext-base

# Re-run preparation
source env.staging
export ENVIRONMENT=staging
./prepare-grafana-datasources.sh
```

### Issue: Cannot reach production endpoints

**Check:**
1. Production monitoring is deployed
2. DNS resolution works: `nslookup prometheus-prod.ploscope.com`
3. Network connectivity: `curl -I https://prometheus-prod.ploscope.com`
4. Basic auth credentials are correct
5. Traefik routing is configured

## Related Documentation

- `STAGING_GRAFANA_FIX.md` - Detailed technical documentation
- `TROUBLESHOOTING_STAGING.md` - General staging troubleshooting
- `PRODUCTION_DATASOURCE_FIX.md` - Previous fix attempts (partial)

## Summary

The staging Grafana deployment was failing because:
1. **Grafana doesn't substitute environment variables** in provisioning YAML files
2. **Solution:** Pre-process datasource files with `envsubst` before mounting to Grafana

This fix ensures that:
- Environment variables are properly substituted before Grafana reads the files
- Production datasources are correctly configured with real URLs
- Staging Grafana can access production monitoring endpoints

