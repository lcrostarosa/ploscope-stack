# Elasticsearch Staging SSL Setup Guide

## Overview

This guide covers setting up SSL/TLS encryption for the ELK stack in the staging environment. Staging should mirror production security practices while maintaining appropriate settings for testing and development.

## Staging vs Production vs Development

| Environment | SSL | Authentication | Certificate Type | Health Checks | Memory Settings |
|-------------|-----|----------------|------------------|---------------|-----------------|
| **Development** | ❌ Disabled | ✅ Enabled | None | HTTP | 512MB |
| **Staging** | ✅ Enabled | ✅ Enabled | Self-signed | HTTPS | 1GB |
| **Production** | ✅ Enabled | ✅ Enabled | CA-signed | HTTPS | 2GB+ |

## Staging SSL Configuration

### 1. Generate SSL Certificates

```bash
# Generate certificates for staging (includes staging-specific certificates)
./scripts/setup/generate-elasticsearch-certs.sh
```

This creates:
- Certificate Authority (CA)
- Elasticsearch certificate
- Kibana certificate (production)
- **Kibana-staging certificate** (staging-specific)
- CA certificate for other services

### 2. Staging-Specific Certificates

The certificate generation script creates staging-specific certificates:

- **`kibana-staging.crt`** - Staging Kibana certificate
- **`kibana-staging.key`** - Staging Kibana private key

These certificates include:
- `kibana-staging.ploscope.com` in Subject Alternative Names
- Staging-specific Common Name (CN)

### 3. Deploy Staging with SSL

```bash
# Set staging password
export ELASTIC_PASSWORD=your_staging_password

# Deploy with staging SSL configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

## Staging Configuration Files

### Staging Docker Compose Override (`docker-compose.staging.yml`)

```yaml
services:
  elasticsearch:
    environment:
      - xpack.security.http.ssl.enabled=true
      - xpack.security.transport.ssl.enabled=true
      # Staging-specific settings
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    volumes:
      - ./server/elasticsearch/certs:/usr/share/elasticsearch/config/certs:ro
      - ./scripts/operations/elasticsearch-health-check-staging.sh:/scripts/elasticsearch-health-check.sh:ro
    healthcheck:
      test: ["CMD-SHELL", "/scripts/elasticsearch-health-check.sh"]
```

### Staging Kibana Config (`server/kibana/kibana.staging.yml`)

```yaml
# SSL Configuration for Staging
server.ssl.enabled: true
server.ssl.certificate: /usr/share/kibana/config/certs/kibana.crt
server.ssl.key: /usr/share/kibana/config/certs/kibana.key

# Elasticsearch connection with SSL
elasticsearch.hosts: ["https://elasticsearch:9200"]
elasticsearch.ssl.verify: true
elasticsearch.ssl.certificateAuthorities: ["/usr/share/kibana/config/certs/elasticsearch-ca.crt"]

# Staging-specific settings
xpack.security.session.idleTimeout: "30m"  # Shorter for testing
xpack.security.session.lifespan: "7d"      # Shorter for testing
logging.verbose: true                      # More verbose for debugging
xpack.dev.enabled: true                    # Enable dev features
```

## Staging-Specific Features

### 1. Enhanced Logging

Staging enables verbose logging for debugging:

```yaml
logging.verbose: true
logging.dest: stdout
```

### 2. Development Features

Staging enables development features for testing:

```yaml
xpack.dev.enabled: true
```

### 3. Shorter Session Timeouts

Staging uses shorter session timeouts for testing:

```yaml
xpack.security.session.idleTimeout: "30m"  # vs 1h in production
xpack.security.session.lifespan: "7d"      # vs 30d in production
```

### 4. Optimized Memory Settings

Staging uses moderate memory settings:

```yaml
# Elasticsearch
ES_JAVA_OPTS=-Xms1g -Xmx1g

# Kibana
NODE_OPTIONS=--max-old-space-size=1024

# Logstash
LS_JAVA_OPTS=-Xms512m -Xmx512m
```

### 5. SSL Health Checks

Staging uses HTTPS health checks:

```bash
# scripts/operations/elasticsearch-health-check-staging.sh
curl -f -k -u elastic:${ELASTIC_PASSWORD} "https://${ELASTICSEARCH_HOST}/_cluster/health"
```

## Staging Deployment Process

### 1. Pre-Deployment Checklist

- [ ] SSL certificates generated
- [ ] Staging password set (`ELASTIC_PASSWORD`)
- [ ] Certificate files in `./server/elasticsearch/certs/`
- [ ] Staging configuration files ready

### 2. Deploy Staging Environment

```bash
# Stop existing services
docker-compose down

# Deploy with staging configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d

# Check status
docker-compose -f docker-compose.yml -f docker-compose.staging.yml ps
```

### 3. Verify SSL Configuration

```bash
# Test Elasticsearch SSL
curl -k -u elastic:${ELASTIC_PASSWORD} https://localhost:9200/_cluster/health

# Test Kibana SSL
curl -k https://localhost:5601/api/status

# Check certificates
openssl x509 -in server/elasticsearch/certs/kibana-staging.crt -text -noout | grep "Subject Alternative Name"
```

### 4. Setup Users and Passwords

```bash
# Setup default users with staging password
ELASTIC_PASSWORD=your_staging_password ./scripts/operations/elasticsearch-password-manager.sh setup-default-users

# Change passwords if needed
./scripts/operations/elasticsearch-password-manager.sh change-password elastic your_secure_staging_password
```

## Staging Security Considerations

### 1. Certificate Management

- **Self-signed certificates** are acceptable for staging
- **Certificate rotation** should follow production schedule
- **Certificate validation** is enabled for security

### 2. Password Security

- **Use strong passwords** even in staging
- **Different passwords** from production
- **Regular rotation** (90-day cycle)

### 3. Network Security

- **HTTPS for all communications**
- **Certificate validation** enabled
- **Proper firewall rules** for staging environment

### 4. Access Control

- **Role-based access** maintained
- **User authentication** required
- **Session management** with appropriate timeouts

## Troubleshooting Staging SSL

### Common Issues

#### 1. Certificate Validation Errors

```bash
# Check certificate validity
openssl x509 -in server/elasticsearch/certs/kibana-staging.crt -text -noout

# Verify certificate chain
openssl verify -CAfile server/elasticsearch/certs/ca.crt server/elasticsearch/certs/kibana-staging.crt
```

#### 2. SSL Connection Failures

```bash
# Test SSL connection
curl -v -k -u elastic:password https://localhost:9200/_cluster/health

# Check SSL configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml logs elasticsearch | grep -i ssl
```

#### 3. Health Check Failures

```bash
# Test health check script
./scripts/operations/elasticsearch-health-check-staging.sh

# Check health check logs
docker-compose -f docker-compose.yml -f docker-compose.staging.yml logs elasticsearch
```

### Debugging Commands

```bash
# Check SSL configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec elasticsearch curl -k -u elastic:password https://localhost:9200/_nodes/ssl

# Check certificate files
docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec elasticsearch ls -la /usr/share/elasticsearch/config/certs/

# Test Kibana SSL
docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec kibana curl -k https://localhost:5601/api/status
```

## Monitoring Staging

### 1. SSL Certificate Monitoring

```bash
# Check certificate expiration
openssl x509 -in server/elasticsearch/certs/kibana-staging.crt -noout -dates

# Monitor certificate validity
openssl x509 -in server/elasticsearch/certs/ca.crt -noout -checkend 86400
```

### 2. Performance Monitoring

```bash
# Check cluster health
curl -k -u elastic:password https://localhost:9200/_cluster/health

# Monitor resource usage
curl -k -u elastic:password https://localhost:9200/_nodes/stats

# Check Kibana status
curl -k https://localhost:5601/api/status
```

### 3. Security Monitoring

```bash
# Check user activity
curl -k -u elastic:password https://localhost:9200/_security/audit

# Monitor authentication
curl -k -u elastic:password https://localhost:9200/_security/_authenticate
```

## Migration from Development to Staging

### 1. Backup Development Data

```bash
# Export development data
curl -u elastic:password http://localhost:9200/_all > development_backup.json
```

### 2. Generate Staging Certificates

```bash
# Generate staging certificates
./scripts/setup/generate-elasticsearch-certs.sh
```

### 3. Update Configuration

```bash
# Update environment variables
export ELASTIC_PASSWORD=your_staging_password

# Deploy staging configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

### 4. Import Data (if needed)

```bash
# Import data to staging
curl -k -u elastic:password -X POST "https://localhost:9200/_bulk" -H "Content-Type: application/json" --data-binary @development_backup.json
```

## Best Practices for Staging

### 1. Security

- **Mirror production security** practices
- **Use strong passwords** and SSL
- **Regular security updates**
- **Access control** and monitoring

### 2. Performance

- **Optimize memory settings** for staging workload
- **Monitor resource usage**
- **Regular performance testing**
- **Load testing** before production deployment

### 3. Maintenance

- **Regular certificate rotation**
- **Password rotation** schedule
- **Log monitoring** and analysis
- **Backup and recovery** testing

### 4. Testing

- **SSL configuration** testing
- **Authentication** testing
- **Performance** testing
- **Security** testing

## Scripts Reference

### Staging Health Check

```bash
./scripts/operations/elasticsearch-health-check-staging.sh

Environment variables:
  ELASTIC_PASSWORD     - Elasticsearch admin password
  ELASTICSEARCH_HOST   - Elasticsearch host (default: localhost:9200)
```

### Certificate Generation

```bash
./scripts/setup/generate-elasticsearch-certs.sh

Creates staging-specific certificates:
  - kibana-staging.crt
  - kibana-staging.key
```

### Password Management

```bash
./scripts/operations/elasticsearch-password-manager.sh

Commands work for staging environment:
  - change-password <username> <new_password>
  - list-users
  - setup-default-users
```

## Environment Variables for Staging

```bash
# Required
export ELASTIC_PASSWORD=your_staging_password

# Optional
export ELASTICSEARCH_HOST=staging-elasticsearch.example.com:9200
export CA_PASSWORD=your_ca_password
``` 