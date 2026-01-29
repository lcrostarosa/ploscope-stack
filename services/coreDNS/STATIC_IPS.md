# Static IP Address Assignments

This document outlines the static IP address assignments for all Docker containers in the PLOSolver infrastructure.

## Network Configuration

- **Network**: `plo-network`
- **Subnet**: `172.18.0.0/16`
- **Gateway**: `172.18.0.1`

## Container IP Assignments

### Core Application Services
- **Frontend**: `172.18.1.19` (Port 3000)
- **Backend**: `172.18.1.20` (Port 5001)
- **Database**: `172.18.1.21` (Port 5432)

### Infrastructure Services
- **Traefik (Reverse Proxy)**: `172.18.1.18` (Ports 80, 443, 8080)
- **RabbitMQ**: `172.18.1.10` (Ports 5672, 15672)
- **OpenVPN**: `172.18.1.17` (Ports 1194/UDP, 443/TCP, 943/TCP)

### Monitoring & Management
- **Portainer**: `172.18.1.11` (Port 9000)
- **Elasticsearch**: `172.18.1.12` (Port 9200)
- **Logstash**: `172.18.1.13` (Port 9600)
- **Kibana**: `172.18.1.14` (Port 5601)
- **Filebeat**: `172.18.1.15` (Port 5066)
- **Metricbeat**: `172.18.1.16` (Port 5067)

## VPN Client Configuration

VPN clients are assigned IPs from the `172.27.224.0/20` subnet and can access:
- All services in the `172.18.0.0/16` network
- Split tunnel configuration routes only ploscope.com traffic through VPN

## Benefits of Static IPs

1. **Predictable Networking**: Services can reference each other by IP instead of relying on DNS resolution
2. **Security**: Firewall rules can be more precise with known IP ranges
3. **Troubleshooting**: Easier to trace network issues with fixed addresses
4. **VPN Access**: VPN clients can reliably access internal services
5. **Load Balancing**: Traefik can route traffic more efficiently with static endpoints

## Configuration Files Updated

- `docker-compose.yml`: Added static IP assignments for all containers
- `server/traefik/dynamic.docker.yml`: Updated Traefik service URLs to use static IPs
- `server/openvpn/as.conf`: Updated DNS and routing configuration

## Usage Examples

### From VPN Client
```bash
# Access Kibana
curl https://kibana.ploscope.com

# Access Portainer
curl https://portainer.ploscope.com

# Direct IP access (if needed)
curl http://172.18.1.14:5601
```

### From Backend Container
```bash
# Connect to database
psql postgresql://postgres:password@172.18.1.21:5432/plosolver

# Connect to RabbitMQ
amqp://plosolver:password@172.18.1.10:5672
```

### From Frontend Container
```bash
# API calls to backend
curl http://172.18.1.20:5001/api/health
``` 