# SSL Certificate Setup

This document describes how SSL certificates are automatically generated and distributed to services using Traefik and Let's Encrypt.

## Overview

The PLOSolver infrastructure uses Traefik as a reverse proxy with automatic SSL certificate generation via Let's Encrypt. Certificates are automatically extracted and distributed to services that require them.

## Architecture

### Certificate Flow

1. **Traefik** generates certificates via Let's Encrypt for configured domains
2. **Certificate Monitor** extracts certificates from Traefik's ACME storage
3. **Services** receive certificates in their expected locations
4. **Services** restart to load new certificates

### Services with SSL Support

| Service | Domain | Certificate Path | Restart Command |
|---------|--------|------------------|-----------------|
| OpenVPN | vpn.ploscope.com | `/openvpn/etc/web-ssl/` | `pkill -HUP openvpnas` |
| RabbitMQ | rabbitmq.ploscope.com | `/etc/rabbitmq/certs/` | `rabbitmqctl reload` |
| Portainer | portainer.ploscope.com | `/data/certs/` | `pkill -HUP portainer` |
| Kibana | kibana.ploscope.com | `/usr/share/kibana/config/certs/` | `pkill -HUP kibana` |

## Configuration

### Traefik Configuration

```yaml
# traefik.yml
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${ACME_EMAIL:-}
      storage: /etc/certs/acme.json
      httpChallenge:
        entryPoint: web
```

### Service Configuration

Each service with SSL support includes:

```yaml
environment:
  - CERT_DOMAIN=service.ploscope.com
  - CERT_FILE=/path/to/service.crt
  - KEY_FILE=/path/to/service.key
  - SERVICE_NAME=service_name
  - RESTART_COMMAND=restart_command
volumes:
  - traefik_certs:/etc/traefik-certs:ro
  - ./scripts/operations/cert-monitor.sh:/scripts/cert-monitor.sh:ro
  - ./scripts/utilities/entrypoint-wrapper.sh:/scripts/entrypoint-wrapper.sh:ro
entrypoint: ["/scripts/entrypoint-wrapper.sh"]
```

## Certificate Monitor Script

The `scripts/operations/cert-monitor.sh` script:

1. **Monitors** Traefik's ACME storage for certificate changes
2. **Extracts** certificates for the configured domain
3. **Distributes** certificates to service-specific locations
4. **Restarts** services to load new certificates

### Key Features

- **Automatic Detection**: Monitors certificate changes via hash comparison
- **Service-Specific Paths**: Each service gets certificates in its expected location
- **Proper Permissions**: Sets correct file permissions (644 for certs, 600 for keys)
- **Restart Integration**: Automatically restarts services when certificates change

## Testing

### Manual Testing

```bash
# Test certificate extraction
./scripts/testing/test-cert-extraction.sh

# Check certificate status
docker-compose logs openvpn | grep -i cert
docker-compose logs rabbitmq | grep -i cert
docker-compose logs portainer | grep -i cert
docker-compose logs kibana | grep -i cert
```

### Verification Commands

```bash
# Check if certificates exist
docker exec plosolver-openvpn ls -la /openvpn/etc/web-ssl/
docker exec plosolver-rabbitmq ls -la /etc/rabbitmq/certs/
docker exec plosolver-portainer ls -la /data/certs/
docker exec plosolver-kibana ls -la /usr/share/kibana/config/certs/

# Check certificate validity
docker exec plosolver-openvpn openssl x509 -in /openvpn/etc/web-ssl/server.crt -text -noout
```

## Troubleshooting

### Common Issues

1. **Certificates Not Generated**
   - Check Traefik logs: `docker-compose logs traefik`
   - Verify ACME email is set: `echo $ACME_EMAIL`
   - Check domain DNS resolution

2. **Certificates Not Distributed**
   - Check certificate monitor logs: `docker-compose logs openvpn | grep CERT-MONITOR`
   - Verify service environment variables
   - Check file permissions

3. **Services Not Restarting**
   - Check restart command syntax
   - Verify service-specific paths exist
   - Check service logs for errors

4. **OpenVPN Still Using Self-Signed Certificates**
   - Run the manual fix script: `./scripts/operations/fix-openvpn-certs.sh`
   - Check OpenVPN configuration: `docker exec plosolver-openvpn /usr/local/openvpn_as/scripts/confdba --get --key web.server.cert.auto`
   - Verify certificate paths: `docker exec plosolver-openvpn ls -la /openvpn/etc/web-ssl/`

### Debug Commands

```bash
# Check ACME storage
docker exec plosolver-traefik cat /etc/certs/acme.json | jq .

# Check certificate monitor
docker exec plosolver-openvpn /scripts/cert-monitor.sh

# Force certificate refresh
docker-compose restart openvpn
```

## Security Considerations

- **Private Keys**: Stored with 600 permissions (owner read/write only)
- **Certificates**: Stored with 644 permissions (owner read/write, group/other read)
- **ACME Storage**: Mounted read-only to services
- **Automatic Renewal**: Let's Encrypt certificates auto-renew before expiration

## Future Enhancements

- [ ] Add certificate expiration monitoring
- [ ] Implement certificate backup/restore
- [ ] Add certificate validation checks
- [ ] Support for custom certificate authorities 