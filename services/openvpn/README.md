# OpenVPN Access Server Configuration

This directory contains the configuration for the OpenVPN Access Server used by PLOScope to provide secure VPN access to internal services and development environments.

## Overview

The OpenVPN Access Server provides secure remote access to PLOScope's internal network infrastructure, allowing authorized users to access development, staging, and production environments securely.

## Configuration Details

### Server Information
- **Hostname**: vpn.ploscope.com
- **Admin UI Port**: 943 (HTTPS)
- **VPN Port**: 443 (TCP/UDP with port sharing)
- **Client Subnet**: 172.27.224.0/20

### Key Features

#### Split Tunnel Configuration
The VPN is configured with split tunneling to optimize performance and security:
- **DNS Resolution**: Primary DNS points to CoreDNS (172.18.1.30) for ploscope.com domains
- **Domain Routing**: Only ploscope.com traffic is routed through the VPN
- **Internet Access**: Client internet traffic bypasses the VPN for better performance
- **Internal Access**: Full access to internal Docker networks (172.18.0.0/16)

#### Security Features
- **TLS Crypt**: Enhanced security with TLS crypt mode
- **Local Authentication**: Uses local user database for authentication
- **Certificate Management**: Automatic certificate generation and management
- **Port Sharing**: Web interface and VPN share the same port (443)

#### Network Configuration
- **Private Network Access**: NAT-based access to internal networks
- **Client Routing**: Inter-client communication enabled
- **Gateway Access**: Internet gateway access disabled for split tunnel
- **Custom Routes**: Domain-based routing for ploscope.com services

## File Structure

```
openvpn/
├── README.md          # This file
├── as.conf           # OpenVPN Access Server configuration
├── LICENSE.txt       # License information
└── .gitignore        # Git ignore rules
```

## Configuration Breakdown

### Core Settings (`as.conf`)

#### Server Configuration
- Hostname and port settings for admin interface
- Database configuration (SQLite-based)
- User and group settings for service accounts

#### VPN Daemon Settings
- TCP and UDP daemon configuration
- Port sharing between web interface and VPN
- Listen address and port configuration

#### DNS and Routing
- Split DNS configuration for ploscope.com domains
- Custom routing rules for internal networks
- NAT configuration for internet access

#### Security and Authentication
- Local authentication module
- TLS crypt security mode
- Certificate management and auto-generation

## Usage

### For Administrators

1. **Access Admin Interface**: Navigate to `https://vpn.ploscope.com:943`
2. **User Management**: Create and manage VPN user accounts
3. **Certificate Management**: Monitor and manage client certificates
4. **Configuration Updates**: Modify settings through the web interface

### For Users

1. **Client Download**: Download OpenVPN client from the admin interface
2. **Authentication**: Use provided credentials to connect
3. **Access Services**: Access internal PLOScope services through the VPN

## Network Architecture

```
Internet
    │
    ▼
┌─────────────────┐
│   OpenVPN AS    │ ← vpn.ploscope.com:443
│   (Port 443)    │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  Internal       │ ← 172.18.0.0/16 (Docker networks)
│  Services       │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│   CoreDNS       │ ← 172.18.1.30 (DNS resolution)
└─────────────────┘
```

## Security Considerations

- **Access Control**: Only authorized users can access the VPN
- **Split Tunneling**: Minimizes attack surface by routing only necessary traffic
- **Certificate Security**: TLS crypt mode provides enhanced security
- **Network Isolation**: Internal services are isolated from direct internet access

## Troubleshooting

### Common Issues

1. **Connection Problems**: Verify DNS resolution and network connectivity
2. **Certificate Issues**: Check certificate validity and renewal status
3. **Routing Issues**: Ensure split tunnel configuration is working correctly
4. **Performance**: Monitor bandwidth usage and adjust split tunnel settings

### Logs and Monitoring

- **Server Logs**: Check OpenVPN Access Server logs for connection issues
- **Client Logs**: Review client-side logs for authentication problems
- **Network Monitoring**: Monitor VPN traffic and performance metrics

## Maintenance

### Regular Tasks

1. **Certificate Renewal**: Monitor and renew certificates before expiration
2. **User Management**: Regularly review and update user access
3. **Security Updates**: Keep OpenVPN Access Server updated
4. **Backup Configuration**: Regularly backup configuration files

### Configuration Updates

When updating the configuration:
1. Backup the current `as.conf` file
2. Test changes in a staging environment
3. Apply changes during maintenance windows
4. Monitor for any issues after deployment

## License

This configuration is proprietary to PLOScope. See `LICENSE.txt` for full license terms.

## Support

For issues related to the OpenVPN configuration:
1. Check the troubleshooting section above
2. Review OpenVPN Access Server documentation
3. Contact the PLOScope infrastructure team
