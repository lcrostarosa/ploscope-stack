# OpenVPN Access Server Setup

## Overview

PLOSolver uses OpenVPN Access Server to provide secure access to management interfaces like Kibana, Portainer, and RabbitMQ Management. This setup replaces the community OpenVPN server with a more user-friendly web-based management interface.

## Architecture

- **OpenVPN Access Server**: Web-based VPN management
- **Port 1194/UDP**: OpenVPN client connections
- **Port 943/TCP**: Web management interface
- **Port 443/TCP**: Client download portal
- **Domain**: `vpn.ploscope.com`

## Quick Start

1. **Start the services**:
   ```bash
   docker-compose up -d openvpn
   ```

2. **Wait for initialization** (2-3 minutes):
   ```bash
   docker-compose logs -f openvpn
   ```

3. **Access the web interface**:
   - URL: https://vpn.ploscope.com
   - Username: `admin`
   - Password: `admin123`

4. **Configure VPN**:
   - Change admin password
   - Configure VPN settings
   - Download client configurations

## Client Setup

### Desktop Clients

1. **Download client configuration**:
   - Visit https://vpn.ploscope.com
   - Log in with admin credentials
   - Download the appropriate client configuration

2. **Install OpenVPN client**:
   - **macOS**: Download from https://openvpn.net/community-downloads/
   - **Windows**: Download from https://openvpn.net/community-downloads/
   - **Linux**: `sudo apt-get install openvpn`

3. **Import and connect**:
   - Import the downloaded configuration
   - Connect to the VPN

### Mobile Clients

1. **Download OpenVPN Connect app**:
   - **iOS**: App Store
   - **Android**: Google Play Store

2. **Import configuration**:
   - Visit https://vpn.ploscope.com/connect/
   - Scan QR code or download configuration
   - Import into OpenVPN Connect app

## Management Interfaces

Once connected to the VPN, you can access:

- **Kibana**: https://kibana.ploscope.com
- **Portainer**: https://portainer.ploscope.com
- **RabbitMQ Management**: https://rabbitmq.ploscope.com
- **Traefik Dashboard**: https://traefik.ploscope.com

## Configuration

### Environment Variables

Add these to your `.env` file:

```bash
# OpenVPN Access Server
VPN_USERNAME=admin
VPN_PASSWORD=your-secure-password
```

### Docker Compose Configuration

The OpenVPN service is configured in `docker-compose.yml`:

```yaml
openvpn:
  image: openvpn/openvpn-as:latest
  ports:
    - "1194:1194/udp"  # OpenVPN UDP port
    - "443:443/tcp"     # Web interface
    - "943:943/tcp"     # Admin interface
  volumes:
    - openvpn_data:/usr/local/openvpn_as
  cap_add:
    - NET_ADMIN
```

### Traefik Configuration

The VPN service is routed through Traefik in `server/traefik/dynamic.docker.yml`:

```yaml
openvpn-https:
  rule: "Host(`vpn.ploscope.com`)"
  service: openvpn
  entrypoints:
    - websecure
  tls:
    certResolver: letsencrypt
```

## Troubleshooting

### Common Issues

1. **Can't access web interface**:
   ```bash
   # Check if container is running
   docker-compose ps openvpn
   
   # Check logs
   docker-compose logs openvpn
   ```

2. **VPN connection fails**:
   - Verify port 1194/UDP is open on your firewall
   - Check that the domain resolves correctly
   - Ensure client configuration is correct

3. **Management interfaces not accessible**:
   - Verify you're connected to the VPN
   - Check that the VPN IP range is allowed in Traefik configuration
   - Ensure DNS resolution works for management domains

### Logs

```bash
# View OpenVPN logs
docker-compose logs openvpn

# View Traefik logs
docker-compose logs traefik

# Check VPN connectivity
ping 10.8.0.1
```

### Reset Configuration

To reset the OpenVPN Access Server configuration:

```bash
# Stop the service
docker-compose stop openvpn

# Remove the volume
docker volume rm plosolver_openvpn_data

# Restart the service
docker-compose up -d openvpn
```

## Security Considerations

1. **Change default password**: Always change the admin password after first login
2. **Use strong passwords**: For both admin and user accounts
3. **Regular updates**: Keep the OpenVPN Access Server image updated
4. **Certificate management**: Monitor certificate expiration dates
5. **Access control**: Limit VPN access to authorized users only

## Backup and Restore

### Backup Configuration

```bash
# Backup OpenVPN data
docker run --rm -v plosolver_openvpn_data:/data -v $(pwd):/backup alpine tar czf /backup/openvpn-backup.tar.gz -C /data .
```

### Restore Configuration

```bash
# Restore OpenVPN data
docker run --rm -v plosolver_openvpn_data:/data -v $(pwd):/backup alpine tar xzf /backup/openvpn-backup.tar.gz -C /data
```

## Performance Tuning

### Recommended Settings

- **Max clients**: 50-100 concurrent connections
- **Connection timeout**: 120 seconds
- **Keepalive**: 10 seconds
- **MTU**: 1500 (adjust if needed)

### Monitoring

Monitor VPN usage through:
- OpenVPN Access Server web interface
- Docker logs
- System resource usage

## Support

For issues with OpenVPN Access Server:
1. Check the official documentation: https://openvpn.net/access-server-manager/
2. Review logs: `docker-compose logs openvpn`
3. Verify network connectivity and firewall rules 