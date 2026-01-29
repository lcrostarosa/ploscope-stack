# HTTPS Redirects Implementation

This document describes the implementation of automatic HTTP to HTTPS redirects in the PLOSolver application.

## Overview

The PLOSolver application now automatically redirects all HTTP traffic to HTTPS, ensuring secure connections for all users. This implementation:

- ✅ **Redirects all HTTP traffic** to HTTPS automatically
- ✅ **Preserves ACME challenges** for Let's Encrypt certificate validation
- ✅ **Works across all environments** (development, staging, production)
- ✅ **Maintains backward compatibility** with existing configurations

## Implementation Details

### 1. Traefik Entrypoint Configuration

All Traefik configurations now include HTTP to HTTPS redirect at the entrypoint level:

```yaml
# server/traefik/staging/traefik.yml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"
```

### 2. Dynamic Router Configuration

The dynamic configuration includes specific routers to handle redirects while preserving ACME challenge access:

```yaml
# server/traefik/staging/dynamic.docker.yml
http:
  routers:
    # HTTP to HTTPS redirect for main domain (excluding ACME challenges)
    http-to-https:
      rule: "Host(`ploscope.com`) && !PathPrefix(`/.well-known/acme-challenge/`)"
      priority: 1000
      service: noop@internal
      entrypoints:
        - web
      middlewares:
        - redirect-to-https
    
    # ACME challenge handler (no redirect)
    acme-challenge:
      rule: "PathPrefix(`/.well-known/acme-challenge/`)"
      service: acme-challenge
      entrypoints:
        - web
      priority: 1001
      middlewares:
        - cors-headers
```

### 3. Middleware Configuration

The redirect middleware is configured for permanent redirects:

```yaml
middlewares:
  redirect-to-https:
    redirectScheme:
      scheme: https
      permanent: true
```

## Environment-Specific Configurations

### Staging Environment

- **File**: `server/traefik/staging/dynamic.docker.yml`
- **Domains**: `ploscope.com`, `vpn.ploscope.com`, `kibana.ploscope.com`, etc.
- **Features**: Full HTTPS redirects with ACME challenge support

### Local Development

- **File**: `server/traefik/localdev/dynamic.docker.yml`
- **Domain**: `localhost`
- **Features**: HTTPS redirects for local development

### Test Environment

- **File**: `server/traefik/test/dynamic.docker.yml`
- **Domain**: `localhost`
- **Features**: HTTPS redirects for testing

## Testing HTTPS Redirects

### Automated Testing

Use the provided test script to verify redirects:

```bash
# Test all redirects
./scripts/development/test-https-redirects.sh
```

### Manual Testing

Test specific endpoints manually:

```bash
# Test main site redirect
curl -I http://localhost
# Expected: 301/302 redirect to https://localhost

# Test API redirect
curl -I http://localhost/api/health
# Expected: 301/302 redirect to https://localhost/api/health

# Test ACME challenge (should NOT redirect)
curl -I http://localhost/.well-known/acme-challenge/test
# Expected: 404 (not a redirect)
```

### Testing Different Domains

```bash
# Staging domain
curl -I http://ploscope.com
# Expected: 301/302 redirect to https://ploscope.com

# VPN service
curl -I http://vpn.ploscope.com
# Expected: 301/302 redirect to https://vpn.ploscope.com

# Kibana service
curl -I http://kibana.ploscope.com
# Expected: 301/302 redirect to https://kibana.ploscope.com
```

## Security Considerations

### 1. ACME Challenge Preservation

ACME challenges for Let's Encrypt certificate validation are preserved:

- **Path**: `/.well-known/acme-challenge/`
- **Access**: HTTP only (no redirect)
- **Purpose**: Let's Encrypt validation

### 2. Permanent Redirects

All redirects are configured as permanent (HTTP 301):

- **SEO Benefits**: Search engines update their indexes
- **Performance**: Browsers cache redirects
- **Security**: Prevents protocol downgrade attacks

### 3. HSTS Headers

Consider adding HSTS headers for additional security:

```yaml
middlewares:
  security-headers:
    headers:
      customResponseHeaders:
        Strict-Transport-Security: "max-age=31536000; includeSubDomains"
```

## Troubleshooting

### Common Issues

#### 1. Redirect Loop

**Symptoms**: Infinite redirects between HTTP and HTTPS

**Solutions**:
```bash
# Check Traefik logs
docker compose logs traefik

# Verify router priorities
# ACME challenges should have higher priority than redirects
```

#### 2. ACME Challenges Failing

**Symptoms**: Let's Encrypt certificate renewal fails

**Solutions**:
```bash
# Test ACME challenge access
curl -I http://yourdomain.com/.well-known/acme-challenge/test

# Check router priorities
# ACME challenges should have priority 1001, redirects 1000
```

#### 3. Mixed Content Warnings

**Symptoms**: Browser shows mixed content warnings

**Solutions**:
```bash
# Ensure all resources use HTTPS
# Check for hardcoded HTTP URLs in frontend code
# Update API endpoints to use HTTPS
```

### Debug Commands

```bash
# Check Traefik configuration
docker compose exec traefik traefik version

# View router configuration
curl http://localhost:8080/api/http/routers

# Test specific router
curl -H "Host: localhost" http://localhost/api/health

# Check redirect middleware
curl -H "Host: localhost" -I http://localhost
```

## Migration Notes

### From Previous Configuration

The implementation replaces the previous approach:

**Before**: Manual redirect configuration in docker-compose labels
**After**: Centralized redirect configuration in Traefik dynamic files

### Benefits of New Approach

1. **Centralized Management**: All redirects in one place
2. **Environment Consistency**: Same behavior across environments
3. **ACME Support**: Proper handling of Let's Encrypt challenges
4. **Maintainability**: Easier to update and debug

## Performance Impact

### Redirect Performance

- **Minimal Overhead**: Single HTTP redirect per request
- **Browser Caching**: Permanent redirects are cached by browsers
- **CDN Friendly**: Works well with CDN caching

### Monitoring

Monitor redirect performance:

```bash
# Check redirect statistics
curl http://localhost:8080/api/http/routers/http-to-https

# Monitor access logs
docker compose logs -f traefik | grep "301\|302"
```

## Future Enhancements

### Potential Improvements

1. **HSTS Headers**: Add Strict-Transport-Security headers
2. **Preload Lists**: Submit domains to HSTS preload lists
3. **Redirect Analytics**: Track redirect performance and user behavior
4. **Custom Redirect Rules**: Support for path-specific redirects

### Configuration Examples

```yaml
# Example: Custom redirect rules
http:
  routers:
    custom-redirect:
      rule: "Host(`example.com`) && PathPrefix(`/old-path`)"
      priority: 100
      service: noop@internal
      entrypoints:
        - web
      middlewares:
        - redirect-to-new-path

  middlewares:
    redirect-to-new-path:
      redirectRegex:
        permanent: true
        regex: "^https://example.com/old-path(.*)"
        replacement: "https://example.com/new-path${1}"
```

## Summary

The HTTPS redirect implementation provides:

- **Automatic Security**: All HTTP traffic redirected to HTTPS
- **Let's Encrypt Compatibility**: ACME challenges work correctly
- **Environment Flexibility**: Works in development, staging, and production
- **Easy Testing**: Automated and manual testing tools provided
- **Maintainable**: Centralized configuration management

This ensures that users always access the application securely while maintaining compatibility with certificate renewal processes. 