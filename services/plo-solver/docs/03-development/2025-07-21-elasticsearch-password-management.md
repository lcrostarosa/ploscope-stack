# Elasticsearch Password Management and SSL Configuration

## Overview

This document covers how to manage passwords for Elasticsearch users and configure SSL for production environments.

## Password Management

### Current User Setup

The ELK stack uses the following users:

- **`elastic`** - Superuser/admin account (password: `changeme` by default)
- **`kibana_system`** - Kibana system user (password: `changeme` by default)
- **`logstash_writer`** - Logstash user (password: `changeme` by default)
- **`beats_writer`** - Filebeat/Metricbeat user (password: `changeme` by default)

### Changing Passwords

#### Using the Password Manager Script

```bash
# Change password for any user
./scripts/operations/elasticsearch-password-manager.sh change-password <username> <new_password>

# Examples:
./scripts/operations/elasticsearch-password-manager.sh change-password elastic my_secure_password
./scripts/operations/elasticsearch-password-manager.sh change-password kibana_system kibana_secure_2024
```

#### Manual Password Change

```bash
# Using curl directly
curl -X POST -u elastic:current_password \
  "http://localhost:9200/_security/user/username/_password" \
  -H "Content-Type: application/json" \
  -d '{"password":"new_password"}'
```

### Health Check Configuration

The health checks now use environment variables instead of hardcoded passwords:

```yaml
# In docker-compose.yml
healthcheck:
  test: ["CMD-SHELL", "/scripts/elasticsearch-health-check.sh"]
  interval: 30s
  timeout: 10s
  retries: 5
```

The health check script reads `ELASTIC_PASSWORD` from environment variables.

### Environment Variables

Set these environment variables to manage passwords:

```bash
# Set the main Elasticsearch password
export ELASTIC_PASSWORD=your_secure_password

# Set Elasticsearch host (if different from default)
export ELASTICSEARCH_HOST=localhost:9200
```

## Production and Staging SSL Configuration

### Development vs Staging vs Production

| Configuration | Development | Staging | Production |
|---------------|-------------|---------|------------|
| SSL | Disabled | Enabled | Enabled |
| Authentication | Enabled | Enabled | Enabled |
| Certificate | None | Self-signed | CA-signed |
| Health Checks | HTTP | HTTPS | HTTPS |
| Memory Settings | 512MB | 1GB | 2GB+ |

### Setting Up Production SSL

#### 1. Generate SSL Certificates

```bash
# Generate certificates for production
./scripts/setup/generate-elasticsearch-certs.sh
```

This creates:
- Certificate Authority (CA)
- Elasticsearch certificate
- Kibana certificate
- CA certificate for other services

#### 2. Deploy with Production Configuration

```bash
# Start with production SSL enabled
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

### Setting Up Staging SSL

#### 1. Generate SSL Certificates

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

#### 2. Deploy with Staging Configuration

```bash
# Set staging password
export ELASTIC_PASSWORD=your_staging_password

# Deploy with staging SSL configuration
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

#### 3. Update Environment Variables

```bash
# Set production password
export ELASTIC_PASSWORD=your_production_password

# Optional: Set CA password
export CA_PASSWORD=your_ca_password
```

### Production Configuration Files

#### Kibana Production Config (`server/kibana/kibana.production.yml`)

```yaml
# SSL Configuration for Production
server.ssl.enabled: true
server.ssl.certificate: /usr/share/kibana/config/certs/kibana.crt
server.ssl.key: /usr/share/kibana/config/certs/kibana.key

# Elasticsearch connection with SSL
elasticsearch.hosts: ["https://elasticsearch:9200"]
elasticsearch.ssl.verify: true
elasticsearch.ssl.certificateAuthorities: ["/usr/share/kibana/config/certs/elasticsearch-ca.crt"]
```

#### Production Docker Compose Override (`docker-compose.production.yml`)

```yaml
services:
  elasticsearch:
    environment:
      - xpack.security.http.ssl.enabled=true
      - xpack.security.transport.ssl.enabled=true
    volumes:
      - ./server/elasticsearch/certs:/usr/share/elasticsearch/config/certs:ro
```

#### Staging Docker Compose Override (`docker-compose.staging.yml`)

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

## Security Best Practices

### Password Security

1. **Use Strong Passwords**: Minimum 12 characters with mixed case, numbers, and symbols
2. **Rotate Passwords Regularly**: Change passwords every 90 days
3. **Use Environment Variables**: Never hardcode passwords in configuration files
4. **Limit Access**: Use role-based access control (RBAC)

### SSL/TLS Security

1. **Use Valid Certificates**: In production, use certificates from a trusted CA
2. **Regular Certificate Rotation**: Renew certificates before expiration
3. **Secure Key Storage**: Store private keys securely with proper permissions
4. **Certificate Validation**: Enable certificate verification in all services

### Network Security

1. **Firewall Rules**: Restrict access to Elasticsearch ports (9200, 9300)
2. **VPN Access**: Use OpenVPN for secure remote access
3. **Network Segmentation**: Isolate ELK stack in separate network segment

## Troubleshooting

### Common Issues

#### Health Check Failures

```bash
# Check if Elasticsearch is running
curl -u elastic:password http://localhost:9200/_cluster/health

# Check health check script
./scripts/operations/elasticsearch-health-check.sh
```

#### SSL Certificate Issues

```bash
# Verify certificate validity
openssl x509 -in server/elasticsearch/certs/elasticsearch.crt -text -noout

# Check certificate chain
openssl verify -CAfile server/elasticsearch/certs/ca.crt server/elasticsearch/certs/elasticsearch.crt
```

#### Authentication Issues

```bash
# List all users
./scripts/operations/elasticsearch-password-manager.sh list-users

# Test user authentication
curl -u username:password http://localhost:9200/_security/_authenticate
```

### Log Analysis

```bash
# Check Elasticsearch logs
docker-compose logs elasticsearch

# Check Kibana logs
docker-compose logs kibana

# Check for SSL errors
docker-compose logs elasticsearch | grep -i ssl
```

## Migration Guide

### From Development to Production

1. **Backup Data**: Export existing data and configurations
2. **Generate Certificates**: Run the certificate generation script
3. **Update Passwords**: Change default passwords to secure ones
4. **Test Configuration**: Verify SSL and authentication work
5. **Deploy**: Use production docker-compose override
6. **Monitor**: Check logs and health status

### From HTTP to HTTPS

1. **Generate Certificates**: Create SSL certificates
2. **Update Configurations**: Modify service configurations for SSL
3. **Test Services**: Verify all services work with SSL
4. **Update Health Checks**: Ensure health checks use HTTPS
5. **Deploy**: Restart services with new configuration

## Scripts Reference

### Password Management Script

```bash
./scripts/operations/elasticsearch-password-manager.sh [command] [options]

Commands:
  change-password <username> <new_password>  - Change user password
  list-users                                 - List all users
  create-user <username> <password> <roles>  - Create new user
  delete-user <username>                     - Delete user
  setup-default-users                        - Setup default ELK users
```

### Certificate Generation Script

```bash
./scripts/setup/generate-elasticsearch-certs.sh

Environment variables:
  CA_PASSWORD       - CA private key password (default: auto-generated)
  ELASTIC_PASSWORD  - Elasticsearch admin password (default: changeme)
```

### Health Check Script

```bash
./scripts/operations/elasticsearch-health-check.sh

Environment variables:
  ELASTIC_PASSWORD     - Elasticsearch admin password (default: changeme)
  ELASTICSEARCH_HOST   - Elasticsearch host (default: localhost:9200)
```

## Monitoring and Maintenance

### Regular Tasks

1. **Password Rotation**: Change passwords every 90 days
2. **Certificate Renewal**: Renew certificates before expiration
3. **Log Review**: Monitor logs for security events
4. **Backup Verification**: Test backup and restore procedures
5. **Security Updates**: Keep ELK stack updated

### Monitoring Commands

```bash
# Check cluster health
curl -u elastic:password https://localhost:9200/_cluster/health

# Check user activity
curl -u elastic:password https://localhost:9200/_security/audit

# Monitor resource usage
curl -u elastic:password https://localhost:9200/_nodes/stats
``` 