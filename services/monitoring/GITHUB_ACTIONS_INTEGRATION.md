# GitHub Actions Deployment Integration

## Overview

The staging Grafana deployment fix has been integrated into the GitHub Actions workflow to ensure datasource files are properly prepared before deployment.

## Changes Made

### 1. Updated GitHub Actions Workflow

**File:** `.github/workflows/deploy.yml`

Added a step to prepare Grafana datasource files before deploying:

```yaml
# Prepare Grafana datasource files with environment variable substitution
if [ "$ENVIRONMENT" != "production" ]; then
  echo "📝 Preparing Grafana datasource files..."
  
  # Ensure envsubst is available
  if ! command -v envsubst >/dev/null 2>&1; then
    # Install gettext-base/gettext package
  fi
  
  # Run prepare-grafana-datasources.sh
  ./prepare-grafana-datasources.sh
  
  # Verify processed file was created
  # ...
fi
```

### 2. Updated Docker Compose Commands

Made `--env-file` optional since environment variables are already exported in the SSH session:

```bash
# For staging
if [ -f "env.staging" ]; then
  docker compose -f docker-compose.yml --env-file env.staging up -d
else
  docker compose -f docker-compose.yml up -d  # Uses exported variables
fi
```

### 3. Updated prepare-grafana-datasources.sh

Made the script resilient to work in CI/CD environments where env files might not exist:

```bash
# In CI/CD, variables may already be exported
if [ -f "env.${ENVIRONMENT}" ]; then
  source "env.${ENVIRONMENT}"
else
  echo "Using environment variables already set in the environment."
fi
```

## How It Works in GitHub Actions

### Deployment Flow

1. **Checkout Code** - Clones/pulls the repository
2. **Setup SSH** - Connects to the deployment server
3. **Export Environment Variables** - Sets all required variables from GitHub Actions vars/secrets
4. **Prepare Datasource Files** (staging only):
   - Installs `envsubst` if needed
   - Runs `prepare-grafana-datasources.sh`
   - Verifies processed file was created
5. **Deploy Services** - Starts docker-compose with proper environment

### Environment Variables Required

The workflow exports these variables for staging Grafana:

```bash
# Production endpoints (for staging Grafana to access production)
export PRODUCTION_PROMETHEUS_URL=${{ vars.PRODUCTION_PROMETHEUS_URL }}
export PRODUCTION_PROMETHEUS_USER=${{ vars.PRODUCTION_PROMETHEUS_USER }}
export PRODUCTION_PROMETHEUS_PASSWORD=${{ secrets.PRODUCTION_PROMETHEUS_PASSWORD }}
export PRODUCTION_LOKI_URL=${{ vars.PRODUCTION_LOKI_URL }}
export PRODUCTION_LOKI_USER=${{ vars.PRODUCTION_LOKI_USER }}
export PRODUCTION_LOKI_PASSWORD=${{ secrets.PRODUCTION_LOKI_PASSWORD }}
```

## GitHub Actions Configuration

### Required Variables (Repository Settings → Variables)

Configure these in GitHub repository settings:

**For staging environment:**
- `PRODUCTION_PROMETHEUS_URL` - e.g., `https://prometheus-prod.ploscope.com`
- `PRODUCTION_PROMETHEUS_USER` - e.g., `prometheususer`
- `PRODUCTION_LOKI_URL` - e.g., `https://loki.grafana-prod.ploscope.com`
- `PRODUCTION_LOKI_USER` - e.g., `lokiuser`

### Required Secrets (Repository Settings → Secrets)

- `PRODUCTION_PROMETHEUS_PASSWORD` - Password for production Prometheus Basic Auth
- `PRODUCTION_LOKI_PASSWORD` - Password for production Loki Basic Auth

### How to Configure

1. Go to: GitHub → Repository → Settings → Secrets and variables → Actions
2. Add Variables (public):
   - `PRODUCTION_PROMETHEUS_URL`
   - `PRODUCTION_PROMETHEUS_USER`
   - `PRODUCTION_LOKI_URL`
   - `PRODUCTION_LOKI_USER`
3. Add Secrets (private):
   - `PRODUCTION_PROMETHEUS_PASSWORD`
   - `PRODUCTION_LOKI_PASSWORD`

## Deployment Steps

### Via GitHub Actions UI

1. Go to: Actions → Deployment workflow
2. Click: "Run workflow"
3. Select:
   - Branch: `master` (or your branch)
   - Environment: `staging` (or `production`)
4. Click: "Run workflow"

### What Happens During Deployment

1. ✅ Code is checked out
2. ✅ SSH connection established
3. ✅ Environment variables exported
4. ✅ Docker network created (if needed)
5. ✅ Repository cloned/updated
6. ✅ Docker volumes created
7. ✅ Old logs cleaned up
8. ✅ **Grafana datasource files prepared** (staging only)
9. ✅ Docker Compose services started
10. ✅ Health checks performed

## Verification After Deployment

### Check Deployment Logs

In GitHub Actions, check the deployment logs for:
- ✅ "Datasource file processed successfully"
- ✅ Preview of processed file URLs
- ✅ "grafana container is healthy"

### Verify on Server

```bash
# SSH to server
ssh user@server

# Check processed datasource file
cat ~/ploscope/monitoring/grafana-config/grafana-datasources-provisioning-processed/datasources.yml | grep url:

# Should show:
# url: https://prometheus-prod.ploscope.com
# NOT: ${PRODUCTION_PROMETHEUS_URL}
```

### Verify in Grafana UI

1. Access Grafana: http://grafana.staging.ploscope.com
2. Login: admin / (check GitHub vars for password)
3. Go to: Configuration → Data sources
4. Check "Prometheus (Production)":
   - URL should be: `https://prometheus-prod.ploscope.com`
   - Basic Auth: Enabled
   - Click "Save & test" - should show ✅

## Troubleshooting

### Issue: envsubst not found

**Fix:** The workflow automatically installs `gettext-base` (Debian/Ubuntu) or `gettext` (RHEL/CentOS) if needed.

### Issue: Processed file not created

**Possible causes:**
1. Script not executable - workflow makes it executable
2. envsubst not available - workflow installs it
3. Environment variables not set - check GitHub Actions vars/secrets

**Check logs:**
- Look for "Running prepare-grafana-datasources.sh"
- Check for "Processed datasource file not found" error

### Issue: Datasource still shows ${PRODUCTION_*}

**Possible causes:**
1. Script didn't run - check deployment logs
2. Variables not exported - verify GitHub Actions configuration
3. Wrong environment - ensure staging deployment (not production)

**Fix:**
```bash
# On server, manually run:
cd ~/ploscope/monitoring
export ENVIRONMENT=staging
source env.staging  # or ensure variables are exported
./prepare-grafana-datasources.sh
docker-compose restart grafana
```

## Production Deployment

Production deployments skip Grafana datasource preparation since:
- Production environment doesn't deploy Grafana
- Production only deploys: prometheus, loki, alloy, cadvisor
- Grafana is only in staging and accesses production data

## Summary

✅ **GitHub Actions integration complete**
- Datasource files are automatically prepared during deployment
- Works with existing GitHub Actions vars/secrets
- No manual intervention needed
- Handles missing env files gracefully
- Installs dependencies automatically

The fix is now fully automated and works seamlessly with your CI/CD pipeline!

