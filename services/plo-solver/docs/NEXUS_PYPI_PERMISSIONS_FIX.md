# Nexus PyPI Permissions Fix

## Problem

The `scripts/setup/setup-nexus-pypi.sh` and `scripts/setup/setup-nexus-staging.sh` scripts were not properly setting up permissions for the `pypi-publisher` user, resulting in 403 Forbidden errors when trying to pull and push packages to the PyPI repository.

### Error Message
```
ERROR    HTTPError: 403 Forbidden from
         https://nexus.ploscope.com/re
         pository/pypi-internal/      
         Forbidden
```

## Root Cause

The original scripts were using wildcard roles that don't work properly in Nexus:
- `"nx-repository-view-pypi-*-*"`
- `"nx-repository-admin-pypi-*-*"`

These wildcard roles are not properly configured in Nexus and don't grant the necessary permissions.

## Solution

### 1. Fixed Setup Scripts

Both setup scripts have been updated to:

1. **Create a custom role** with specific permissions:
   - `nx-repository-admin-pypi-pypi-internal-*` (admin access to internal repository)
   - `nx-repository-view-pypi-pypi-internal-read` (read access to internal repository)
   - `nx-repository-view-pypi-*-*` (read access to all PyPI repositories)

2. **Assign the custom role** to the `pypi-publisher` user instead of the problematic wildcard roles

3. **Add permission testing** to verify that the setup works correctly

4. **Handle existing users** by updating them with the new role if they already exist

### 2. New Fix Script

A dedicated fix script has been created for existing installations:
- `scripts/setup/fix-nexus-permissions.sh`

### 3. Test Script

A comprehensive test script has been created:
- `scripts/setup/test-nexus-permissions.sh`

## How to Fix Existing Installations

### Option 1: Use the Fix Script (Recommended)

```bash
# Set the required environment variables
export NEXUS_URL="https://nexus.ploscope.com"
export NEXUS_ADMIN_PASSWORD="your-admin-password"
export NEXUS_PYPI_PASSWORD="your-pypi-password"

# Run the fix script
./scripts/setup/fix-nexus-permissions.sh
```

### Option 2: Re-run the Setup Script

```bash
# For staging environment
./scripts/setup/setup-nexus-staging.sh

# For local environment
./scripts/setup/setup-nexus-pypi.sh
```

### Option 3: Manual Fix via Nexus Web Interface

1. Log into Nexus at `https://nexus.ploscope.com`
2. Go to **Security** → **Roles**
3. Create a new role called `pypi-publisher-with-read` with these privileges:
   - `nx-repository-admin-pypi-pypi-internal-*`
   - `nx-repository-view-pypi-pypi-internal-read`
   - `nx-repository-view-pypi-*-*`
4. Go to **Security** → **Users**
5. Edit the `pypi-publisher` user and assign the `pypi-publisher-with-read` role

## Testing the Fix

### Run the Test Script

```bash
# Set environment variables
export NEXUS_URL="https://nexus.ploscope.com"
export NEXUS_PYPI_PASSWORD="your-pypi-password"

# Run the test
./scripts/setup/test-nexus-permissions.sh
```

### Manual Testing

```bash
# Test read access
curl -u "pypi-publisher:your-password" \
  "https://nexus.ploscope.com/repository/pypi-internal/simple/"

# Test write access (should return 400, not 403)
curl -u "pypi-publisher:your-password" \
  -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary "test" \
  "https://nexus.ploscope.com/repository/pypi-internal/test/"
```

## Expected Results

After applying the fix:

1. **Read access** should work for both hosted and group repositories
2. **Write access** should work for the hosted repository
3. **403 Forbidden errors** should be resolved
4. **Package uploads** should succeed

## Troubleshooting

### If you still get 403 errors:

1. **Check Nexus logs** for detailed error messages
2. **Verify the role exists** in Nexus web interface
3. **Verify the user has the correct role** assigned
4. **Check repository configuration** to ensure it's properly set up
5. **Restart Nexus** if necessary

### Common Issues:

1. **Role not created**: The role creation might fail if Nexus is not fully ready
2. **User not updated**: The user update might fail if the user doesn't exist
3. **Repository not accessible**: The repository might not be properly configured

### Debug Commands:

```bash
# Check if Nexus is accessible
curl -k "https://nexus.ploscope.com/service/rest/v1/status"

# Check if user can authenticate
curl -k -u "pypi-publisher:password" \
  "https://nexus.ploscope.com/service/rest/v1/status"

# Check repository access
curl -k -u "pypi-publisher:password" \
  "https://nexus.ploscope.com/repository/pypi-internal/"
```

## Files Modified

1. `scripts/setup/setup-nexus-pypi.sh` - Updated with proper role creation and user management
2. `scripts/setup/setup-nexus-staging.sh` - Updated with proper role creation and user management
3. `scripts/setup/fix-nexus-permissions.sh` - New script for fixing existing installations
4. `scripts/setup/test-nexus-permissions.sh` - New script for testing permissions

## Environment Variables

Required environment variables for the scripts:

- `NEXUS_URL` - Nexus repository URL (default: `https://nexus.ploscope.com`)
- `NEXUS_ADMIN_USER` - Admin username (default: `admin`)
- `NEXUS_ADMIN_PASSWORD` - Admin password
- `NEXUS_PYPI_PASSWORD` - PyPI publisher password
- `REPOSITORY_NAME` - Hosted repository name (default: `pypi-internal`)
- `REPOSITORY_GROUP_NAME` - Group repository name (default: `pypi-all`)

