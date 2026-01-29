# Staging Grafana Deployment Fix

## Root Cause Analysis

### Issue 1: Environment Variable Substitution Not Working ❌

**Problem:**
- Grafana datasource provisioning files (`datasources.staging.yml`) use environment variable syntax: `${PRODUCTION_PROMETHEUS_URL}`
- Grafana **does NOT automatically substitute** environment variables in YAML provisioning files
- Even though `docker-compose.yml` passes environment variables to the Grafana container, Grafana reads the YAML file as-is
- Result: Datasource URLs show literal `${PRODUCTION_PROMETHEUS_URL}` instead of actual URLs like `https://prometheus-prod.ploscope.com`

**Why this happens:**
- Grafana's provisioning system reads YAML files directly without variable substitution
- Environment variables passed to Docker containers are separate from Grafana's provisioning file parsing
- Grafana only supports variable substitution in certain contexts (dashboard variables, not datasource provisioning)

### Issue 2: Production Server Access ❌

**Problem:**
- Even if URLs were correct, staging Grafana needs to reach production endpoints
- Production endpoints require Basic Authentication
- Network connectivity and DNS resolution must be working

## Solution Implemented

### 1. Created Environment Variable Substitution Script ✅

**File:** `prepare-grafana-datasources.sh`

This script:
- Loads environment variables from `env.staging`
- Uses `envsubst` to substitute `${PRODUCTION_*}` variables in the datasource YAML file
- Creates a processed file in `grafana-config/grafana-datasources-provisioning-processed/datasources.yml`
- This processed file has actual URLs instead of variable placeholders

### 2. Updated Docker Compose Configuration ✅

**File:** `docker-compose.yml`

Changed Grafana volume mount from:
```yaml
- ./grafana-config/grafana-datasources-provisioning/datasources.${ENVIRONMENT:-staging}.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro
```

To:
```yaml
- ./grafana-config/grafana-datasources-provisioning-processed/datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro
```

### 3. Created Startup Script ✅

**File:** `start-monitoring.sh`

This script:
- Loads environment variables
- Runs `prepare-grafana-datasources.sh` to process datasource files
- Starts docker-compose with proper environment

### 4. Added Processed Files to .gitignore ✅

The processed datasource files are generated and should not be committed to git.

## How to Deploy the Fix

### Step 1: Prepare Datasource Files

```bash
cd /path/to/monitoring
export ENVIRONMENT=staging
./prepare-grafana-datasources.sh
```

This will create `grafana-config/grafana-datasources-provisioning-processed/datasources.yml` with substituted variables.

### Step 2: Restart Grafana

```bash
# Option A: Use the startup script
./start-monitoring.sh

# Option B: Manual docker-compose
docker-compose --env-file env.staging down grafana
docker-compose --env-file env.staging up -d grafana
```

### Step 3: Verify Configuration

```bash
# Check if datasource file was processed correctly
cat grafana-config/grafana-datasources-provisioning-processed/datasources.yml | grep -E "url:|basicAuthUser:"

# Should show:
# url: https://prometheus-prod.ploscope.com  (not ${PRODUCTION_PROMETHEUS_URL})
# basicAuthUser: prometheususer  (not ${PRODUCTION_PROMETHEUS_USER})
```

### Step 4: Test in Grafana

1. Access Grafana: http://localhost:3001 (or http://grafana.staging.ploscope.com)
2. Login: admin / admin-staging-123
3. Go to: Configuration → Data sources
4. Check "Prometheus (Production)" datasource:
   - URL should be: `https://prometheus-prod.ploscope.com`
   - Basic Auth should be enabled
   - Click "Save & test" - should show ✅ "Data source is working"

### Step 5: Test Production Connectivity

```bash
# From staging server, test production endpoints
curl -u prometheususer:securepassword123 \
  https://prometheus-prod.ploscope.com/api/v1/query?query=up

curl -u lokiuser:securepassword123 \
  https://loki.grafana-prod.ploscope.com/ready
```

## Troubleshooting

### Issue: Processed file still has `${PRODUCTION_*}` variables

**Cause:** Environment variables not loaded or `envsubst` not available

**Fix:**
```bash
# Ensure envsubst is installed
which envsubst || sudo apt-get install gettext-base  # Ubuntu/Debian
which envsubst || brew install gettext               # macOS

# Load environment variables explicitly
source env.staging
export ENVIRONMENT=staging
./prepare-grafana-datasources.sh
```

### Issue: Grafana shows "Data source not found"

**Cause:** Processed file not created or wrong path

**Fix:**
```bash
# Check if processed file exists
ls -la grafana-config/grafana-datasources-provisioning-processed/datasources.yml

# If missing, regenerate
./prepare-grafana-datasources.sh

# Restart Grafana
docker-compose restart grafana
```

### Issue: "Cannot reach production Prometheus"

**Possible causes:**
1. Production monitoring not deployed
2. DNS not resolving
3. Network firewall blocking
4. Wrong Basic Auth credentials
5. Traefik routing not configured

**Diagnosis:**
```bash
# Test DNS resolution
nslookup prometheus-prod.ploscope.com

# Test connectivity (should fail with 401, not timeout)
curl -I https://prometheus-prod.ploscope.com/api/v1/query

# Test with auth (should succeed)
curl -u prometheususer:securepassword123 \
  https://prometheus-prod.ploscope.com/api/v1/query?query=up
```

## Files Changed

```
monitoring/
├── prepare-grafana-datasources.sh          ← NEW: Processes datasource files
├── start-monitoring.sh                      ← NEW: Startup script
├── docker-compose.yml                       ← UPDATED: Uses processed datasource file
├── .gitignore                               ← UPDATED: Ignores processed files
└── grafana-config/
    └── grafana-datasources-provisioning-processed/  ← NEW: Generated files (gitignored)
        └── datasources.yml
```

## Architecture After Fix

```
┌─────────────────────────────────────────────────────────┐
│           Staging Deployment Process                    │
│                                                         │
│  1. Load env.staging                                    │
│  2. Run prepare-grafana-datasources.sh                 │
│     ├─ Reads: datasources.staging.yml                  │
│     └─ Writes: datasources.yml (with substituted vars) │
│  3. Start docker-compose                                │
│     └─ Grafana mounts processed datasources.yml        │
│                                                         │
│  Grafana Container:                                     │
│  ├─ Reads: /etc/grafana/provisioning/datasources/      │
│  │         datasources.yml (with real URLs)            │
│  └─ Connects to: Production Prometheus/Loki            │
│      via HTTPS + Basic Auth                             │
└─────────────────────────────────────────────────────────┘
```

## Next Steps

1. ✅ Deploy fix to staging server
2. ✅ Verify datasources work in Grafana UI
3. ✅ Test querying production metrics
4. ✅ Update deployment documentation
5. ✅ Consider automating datasource preparation in CI/CD

## Alternative Solutions Considered

### Option 1: Use Grafana API (Rejected)
- Would require API calls on container startup
- More complex error handling
- Harder to debug

### Option 2: Use ConfigMap/Secrets (Not applicable)
- Kubernetes-only solution
- This is Docker Compose

### Option 3: Template Engine (Rejected)
- More dependencies (Python/Node.js)
- `envsubst` is simpler and standard

### Option 4: Hardcode URLs (Rejected)
- Not flexible
- Requires code changes for different environments
- Security risk if committed

**Chosen Solution:** Pre-process YAML files with `envsubst` ✅
- Simple and standard
- No additional dependencies
- Works with Docker Compose
- Easy to debug

