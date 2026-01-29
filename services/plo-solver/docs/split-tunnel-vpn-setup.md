# Split Tunnel VPN Configuration

## Overview

This document describes the split tunnel VPN configuration that allows:
- **ploscope.com domains** to route through the VPN tunnel
- **All other internet traffic** to use the client's direct internet connection

## Configuration Changes

### Server Configuration

The OpenVPN Access Server has been configured with the following split tunnel settings:

#### VPN Routing Settings (`server/openvpn/as.conf`)
```
# Client routing settings - Split tunnel configuration
vpn.client.routing.reroute_dns=false
vpn.client.routing.reroute_gw=false

# Internet routing - Split tunnel configuration
vpn.server.routing.gateway_access=false

# Push routes only for ploscope domains
vpn.server.routing.push_route.0=172.18.0.0/16
```

#### DNS Configuration
```
# DNS servers - Split DNS for ploscope domains
vpn.server.dhcp_option.dns.0=172.18.0.1
vpn.server.dhcp_option.dns.1=8.8.8.8
vpn.server.dhcp_option.dns.2=1.1.1.1

# Domain configuration for ploscope services
vpn.server.dhcp_option.domain=ploscope.com
vpn.server.dhcp_option.search_domain=ploscope.com
```

### Client Behavior

When connected to the VPN:

#### Routes Through VPN Tunnel:
- `ploscope.com` (main frontend)
- `kibana.ploscope.com` (Kibana dashboard)
- `portainer.ploscope.com` (Portainer management)
- `rabbitmq.ploscope.com` (RabbitMQ management)
- `traefik.ploscope.com` (Traefik dashboard)
- `vpn.ploscope.com` (VPN management)
- Internal Docker network: `172.18.0.0/16`

#### Routes Through Client's Internet:
- All other domains (google.com, github.com, etc.)
- Regular internet browsing
- Software updates
- Non-ploscope services

## Testing Split Tunnel Configuration

### Automated Testing

Run the split tunnel test script:
```bash
./scripts/test-split-tunnel.sh
```

This script will verify:
1. DNS resolution for ploscope domains
2. DNS resolution for external domains
3. HTTP connectivity to ploscope services
4. HTTP connectivity to external services
5. Routing configuration

### Manual Testing

#### 1. Test DNS Resolution
```bash
# Should resolve through VPN
nslookup kibana.ploscope.com

# Should resolve through client's DNS
nslookup google.com
```

#### 2. Test HTTP Connectivity
```bash
# Should work through VPN
curl -I https://kibana.ploscope.com

# Should work through client's internet
curl -I https://google.com
```

#### 3. Check Routing
```bash
# Check current routes
ip route

# Check route to ploscope services
ip route get 172.18.0.1

# Check route to external services
ip route get 8.8.8.8
```

#### 4. Test IP Address
```bash
# Check your external IP (should be client's real IP, not VPN IP)
curl https://httpbin.org/ip

# Check if you can access ploscope services
curl https://ploscope.com
```

## Client Configuration

### Desktop Clients

1. **Download Configuration**: Visit https://vpn.ploscope.com and download the client configuration
2. **Import Configuration**: Import the configuration into your OpenVPN client
3. **Connect**: Connect to the VPN
4. **Verify**: Run the test script to verify split tunnel functionality

### Mobile Clients

1. **Download OpenVPN Connect**: Install from App Store or Google Play
2. **Import Configuration**: Visit https://vpn.ploscope.com/connect/ and import the configuration
3. **Connect**: Connect to the VPN
4. **Verify**: Test access to ploscope services and external internet

## Expected Behavior

### ✅ Working Correctly
- You can access ploscope services (kibana.ploscope.com, portainer.ploscope.com, etc.)
- You can browse the internet normally (google.com, github.com, etc.)
- Your external IP address is your client's real IP (not VPN IP)
- DNS resolution works for both ploscope and external domains

### ❌ Issues to Watch For
- Cannot access ploscope services → Check VPN connection and DNS
- Cannot access external internet → Check client's internet connection
- DNS resolution fails → Check DNS configuration
- External IP shows VPN IP → Configuration may have reverted to full tunnel

## Troubleshooting

### Common Issues

1. **Cannot access ploscope services**:
   ```bash
   # Check VPN connection
   ip route | grep 172.18.0.0
   
   # Check DNS resolution
   nslookup kibana.ploscope.com
   ```

2. **Cannot access external internet**:
   ```bash
   # Check client's internet connection
   ping google.com
   
   # Check if full tunnel is accidentally enabled
   ip route | grep "0.0.0.0/0"
   ```

3. **DNS resolution issues**:
   ```bash
   # Check DNS servers
   cat /etc/resolv.conf
   
   # Test DNS resolution
   nslookup ploscope.com
   nslookup google.com
   ```

### Log Analysis

Check OpenVPN logs:
```bash
docker logs plosolver-openvpn-staging
```

Look for:
- Split tunnel configuration messages
- DNS configuration messages
- Client connection logs
- Routing table updates

### Reset Configuration

If the split tunnel configuration gets corrupted:

1. **Stop OpenVPN**:
   ```bash
   docker-compose stop openvpn
   ```

2. **Remove configuration volume**:
   ```bash
   docker volume rm plosolver_openvpn_data
   ```

3. **Restart OpenVPN**:
   ```bash
   docker-compose up -d openvpn
   ```

4. **Wait for reconfiguration** (the entrypoint script will automatically apply split tunnel settings)

## Security Considerations

### Benefits of Split Tunneling
- **Performance**: Only security-critical traffic goes through VPN
- **Bandwidth**: Reduces VPN server load
- **Speed**: Internet browsing uses direct connection
- **Compatibility**: Reduces issues with geo-blocked content

### Security Implications
- **ploscope services**: Fully protected through VPN tunnel
- **Internet traffic**: Uses client's direct connection (normal security risk)
- **DNS**: ploscope domains resolve through VPN, others through client's DNS

## Deployment

### Staging Deployment
```bash
# Deploy the split tunnel configuration
./scripts/deployment/deploy-staging.sh
```

### Production Deployment
```bash
# Deploy to production (when ready)
./scripts/deployment/deploy-production.sh
```

### Verification After Deployment
```bash
# Run the test script
./scripts/test-split-tunnel.sh

# Check service status
docker-compose ps

# Check logs
docker-compose logs openvpn
```

## Support

For issues with split tunnel configuration:
1. Run the test script: `./scripts/test-split-tunnel.sh`
2. Check OpenVPN logs: `docker logs plosolver-openvpn-staging`
3. Verify network connectivity and DNS resolution
4. Review this documentation for troubleshooting steps