# SSL Certificate Setup with Let's Encrypt and Traefik

This guide explains how to set up automatic SSL certificate generation using Let's Encrypt and Traefik for the PLOSolver application.

## Overview

PLOSolver uses **Traefik v2.10** with built-in **Let's Encrypt** support for automatic SSL certificate generation. This provides:

- ✅ **Automatic HTTPS** for all domains
- ✅ **Free SSL certificates** from Let's Encrypt
- ✅ **Automatic renewal** every 60 days
- ✅ **HTTP to HTTPS redirect**
- ✅ **Multiple domain support**
- ✅ **Zero downtime** certificate updates

## Quick Start

### 1. Configure Environment

```bash
# Copy environment file
cp env.example .env

# Edit the environment file
nano .env
```

Set these required variables:
```bash
# Domain configuration
FRONTEND_DOMAIN=yourdomain.com
TRAEFIK_DOMAIN=yourdomain.com

# Let's Encrypt configuration
ACME_EMAIL=your-email@yourdomain.com
```

### 2. Set Up SSL

```bash
# Run the SSL setup script
./scripts/setup/setup-ssl.sh setup .env
```

### 3. Verify SSL

```bash
# Check SSL status
./scripts/setup/setup-ssl.sh status yourdomain.com

# Test SSL certificate
./scripts/setup/setup-ssl.sh test yourdomain.com
```

## Configuration Details

### Environment Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `FRONTEND_DOMAIN` | Your domain name | Yes | `plosolver.com` |
| `TRAEFIK_DOMAIN` | Domain for Traefik | Yes | `plosolver.com` |
| `ACME_EMAIL` | Email for Let's Encrypt | Yes | `admin@plosolver.com` |
| `TRAEFIK_LOG_LEVEL` | Traefik log level | No | `INFO` |

### DNS Configuration

Before setting up SSL, ensure your domain points to your server:

```bash
# Check if DNS is configured correctly
./scripts/setup/setup-ssl.sh setup .env
```

The script will verify:
- Domain resolves to your server's IP
- Ports 80 and 443 are accessible
- Let's Encrypt can reach your server

### Certificate Storage

Certificates are stored in:
- **Container path**: `/etc/certs/acme.json`
- **Host path**: `./ssl/acme.json` (mounted volume)
- **Docker volume**: `traefik_letsencrypt` (persistent)

## SSL Script Commands

### Setup SSL Configuration
```bash
./scripts/setup/setup-ssl.sh setup [ENV_FILE]
```

**Features:**
- Validates environment configuration
- Checks DNS configuration
- Creates SSL directories
- Starts services with SSL enabled

### Test SSL Certificate
```bash
./scripts/setup/setup-ssl.sh test [DOMAIN]
```

**Features:**
- Tests HTTPS connectivity
- Validates certificate chain
- Checks certificate expiration

### Show SSL Status
```bash
./scripts/setup/setup-ssl.sh status [DOMAIN]
```

**Features:**
- Shows certificate information
- Displays expiration dates
- Shows certificate file size
- Validates HTTPS access

### Force Certificate Renewal
```bash
./scripts/setup/setup-ssl.sh renew [DOMAIN]
```

**Features:**
- Removes existing certificate
- Triggers new certificate generation
- Restarts Traefik service

### View SSL Logs
```bash
./scripts/setup/setup-ssl.sh logs
```

**Features:**
- Shows Traefik SSL logs
- Filters for certificate-related messages
- Displays recent certificate activity

## Traefik SSL Configuration

### Let's Encrypt Integration

The `docker-compose.yml` includes these SSL-specific configurations:

```yaml
traefik:
  command:
    # Let's Encrypt Configuration
    - "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}"
    - "--certificatesresolvers.letsencrypt.acme.storage=/etc/certs/acme.json"
    - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    - "--certificatesresolvers.letsencrypt.acme.server=https://acme-v02.api.letsencrypt.org/directory"
    
    # HTTP to HTTPS redirect
    - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
    - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
    - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
```

### Service Labels

Services automatically use SSL when configured:

```yaml
frontend:
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.frontend.rule=Host(`${FRONTEND_DOMAIN}`)"
    - "traefik.http.routers.frontend.entrypoints=websecure"
    - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
```

## Deployment Scenarios

### Development Environment

For local development, SSL is optional:

```bash
# Development setup (no SSL)
FRONTEND_DOMAIN=localhost
ACME_EMAIL=

# Start services
docker compose up -d
```

### Staging Environment

For staging with SSL:

```bash
# Staging setup
FRONTEND_DOMAIN=staging.plosolver.com
ACME_EMAIL=admin@plosolver.com

# Set up SSL
./scripts/setup/setup-ssl.sh setup env.staging
```

### Production Environment

For production with full SSL:

```bash
# Production setup
FRONTEND_DOMAIN=plosolver.com
ACME_EMAIL=admin@plosolver.com

# Set up SSL
./scripts/setup/setup-ssl.sh setup env.production
```

## Troubleshooting

### Common Issues

#### 1. Certificate Not Generated

**Symptoms:**
- HTTPS returns connection refused
- No certificate file in `/etc/certs/acme.json`

**Solutions:**
```bash
# Check Traefik logs
./scripts/setup/setup-ssl.sh logs

# Verify DNS configuration
nslookup yourdomain.com

# Force certificate renewal
./scripts/setup/setup-ssl.sh renew yourdomain.com
```

#### 2. DNS Configuration Issues

**Symptoms:**
- Let's Encrypt validation fails
- Certificate generation times out

**Solutions:**
```bash
# Check DNS propagation
dig yourdomain.com

# Verify server IP
curl ifconfig.me

# Wait for DNS propagation (up to 48 hours)
```

#### 3. Port 80/443 Not Accessible

**Symptoms:**
- Let's Encrypt HTTP challenge fails
- Certificate validation errors

**Solutions:**
```bash
# Check if ports are open
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Check firewall rules
sudo ufw status

# Ensure Traefik is running
docker compose ps traefik
```

#### 4. Certificate Expiration

**Symptoms:**
- Browser shows certificate warnings
- HTTPS connection fails

**Solutions:**
```bash
# Check certificate status
./scripts/setup/setup-ssl.sh status yourdomain.com

# Force renewal
./scripts/setup/setup-ssl.sh renew yourdomain.com

# Check renewal logs
./scripts/setup/setup-ssl.sh logs
```

### Debug Commands

#### Check Certificate Details
```bash
# View certificate information
openssl s_client -servername yourdomain.com -connect yourdomain.com:443 < /dev/null | openssl x509 -noout -text

# Check certificate expiration
openssl s_client -servername yourdomain.com -connect yourdomain.com:443 < /dev/null | openssl x509 -noout -dates
```

#### Monitor Certificate Generation
```bash
# Watch Traefik logs in real-time
docker compose logs -f traefik | grep -i "acme\|certificate"

# Check certificate file
docker compose exec traefik ls -la /etc/certs/
```

#### Test HTTP Challenge
```bash
# Test if Let's Encrypt can reach your server
curl -I http://yourdomain.com/.well-known/acme-challenge/test
```

## Security Best Practices

### 1. Email Configuration

Use a real email address for Let's Encrypt notifications:
```bash
ACME_EMAIL=admin@yourdomain.com
```

### 2. Certificate Storage

Certificates are automatically backed up in Docker volumes:
```bash
# Backup certificates
docker compose exec traefik cp /etc/certs/acme.json /backup/

# Restore certificates
docker compose exec traefik cp /backup/acme.json /etc/certs/
```

### 3. Rate Limiting

Let's Encrypt has rate limits:
- **50 certificates per registered domain per week**
- **300 new orders per account per 3 hours**
- **5 duplicate certificates per week**

### 4. Monitoring

Set up monitoring for certificate expiration:
```bash
# Check certificate expiration
./scripts/setup/setup-ssl.sh status yourdomain.com | grep "Not After"
```

## Advanced Configuration

### Multiple Domains

Support multiple domains with the same certificate:

```yaml
# In docker-compose.yml
labels:
  - "traefik.http.routers.frontend.rule=Host(`domain1.com`) || Host(`domain2.com`)"
  - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
```

### Custom SSL Certificates

For custom certificates (not recommended for production):

```yaml
# Mount custom certificates
volumes:
  - ./ssl/cert.pem:/etc/certs/cert.pem:ro
  - ./ssl/key.pem:/etc/certs/key.pem:ro

# Configure in server/traefik/dynamic.docker.yml
tls:
  certificates:
    - certFile: /etc/certs/cert.pem
      keyFile: /etc/certs/key.pem
```

### Staging Environment

Use Let's Encrypt staging for testing:

```yaml
# In docker-compose.yml
command:
  - "--certificatesresolvers.letsencrypt-staging.acme.server=https://acme-staging-v02.api.letsencrypt.org/directory"
```

## Monitoring and Maintenance

### Certificate Monitoring

Set up automated monitoring:

```bash
#!/bin/bash
# check-ssl.sh
DOMAIN="yourdomain.com"
EXPIRY=$(./scripts/setup/setup-ssl.sh status $DOMAIN | grep "Not After" | cut -d'=' -f2)

if [ -n "$EXPIRY" ]; then
    echo "Certificate expires: $EXPIRY"
    # Add notification logic here
fi
```

### Automated Renewal

Traefik automatically renews certificates, but you can monitor the process:

```bash
# Add to crontab for daily checks
0 2 * * * /path/to/PLOSolver/scripts/setup/setup-ssl.sh status yourdomain.com >> /var/log/ssl-check.log
```

### Backup Strategy

Backup certificates regularly:

```bash
#!/bin/bash
# backup-ssl.sh
DATE=$(date +%Y%m%d)
docker compose exec traefik cp /etc/certs/acme.json /backup/acme-$DATE.json
```

## Performance Considerations

### Certificate Caching

Traefik caches certificates in memory for performance:
- **Fast certificate lookup**
- **Reduced disk I/O**
- **Automatic cache invalidation**

### HTTP/2 Support

SSL enables HTTP/2 by default:
- **Better performance**
- **Reduced latency**
- **Improved user experience**

### OCSP Stapling

Traefik automatically handles OCSP stapling:
- **Faster certificate validation**
- **Reduced client-server communication**
- **Better privacy**

## Conclusion

The PLOSolver SSL setup provides:

1. **Automatic certificate generation** with Let's Encrypt
2. **Zero-configuration HTTPS** for all domains
3. **Automatic renewal** every 60 days
4. **HTTP to HTTPS redirect** for security
5. **Comprehensive monitoring** and troubleshooting tools

The setup is production-ready and follows security best practices for SSL certificate management. 