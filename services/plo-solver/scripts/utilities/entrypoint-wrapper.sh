#!/bin/sh
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ENTRYPOINT-WRAPPER: $1"
}

# Install Python3 if needed for certificate monitoring
if [ -f "/scripts/cert-monitor.sh" ] && [ -n "$CERT_DOMAIN" ] && [ "$SERVICE_NAME" = "kibana" ]; then
    if ! command -v python3 >/dev/null 2>&1; then
        log "Installing Python3 for certificate monitoring"
        apt-get update -qq && apt-get install -y -qq python3 python3-minimal >/dev/null 2>&1 || log "Failed to install Python3, continuing"
    fi
fi

# Run certificate monitor if script exists and domain is configured
if [ -f "/scripts/cert-monitor.sh" ] && [ -n "$CERT_DOMAIN" ]; then
    log "Running certificate monitor for $CERT_DOMAIN"
    /scripts/cert-monitor.sh || log "Certificate monitor failed, continuing startup"
else
    log "Certificate monitoring not configured or script not found"
fi

# Run the original entrypoint
log "Starting original entrypoint: $@"

# Start OpenVPN in background to allow post-initialization configuration
if [[ "$*" == *"openvpnas"* ]]; then
    log "Starting OpenVPN with custom configuration"
    
    # Start the original entrypoint in background
    "$@" &
    OPENVPN_PID=$!
    
    # Wait for OpenVPN to be ready (up to 3 minutes)
    log "Waiting for OpenVPN to initialize..."
    for i in {1..36}; do
        sleep 5
        if /usr/local/openvpn_as/scripts/sacli --key host.name --value "$VPN_DOMAIN" ConfigPut 2>/dev/null; then
            log "Successfully configured hostname: $VPN_DOMAIN"
            
            # Configure VPN routing for split tunneling
            log "Configuring VPN routing for split tunneling..."
            /usr/local/openvpn_as/scripts/sacli --key vpn.client.routing.reroute_gw --value false ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.client.routing.reroute_dns --value false ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.routing.nat_gateway --value true ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.routing.gateway_access --value false ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.client.routing.inter_client --value true ConfigPut
            
            # Configure DNS servers - Split DNS for ploscope domains
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.dhcp_option.dns.0 --value "172.18.0.1" ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.dhcp_option.dns.1 --value "8.8.8.8" ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.dhcp_option.dns.2 --value "1.1.1.1" ConfigPut
            
            # Domain configuration for ploscope services
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.dhcp_option.domain --value "ploscope.com" ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.dhcp_option.search_domain --value "ploscope.com" ConfigPut
            
            # Push routes only for ploscope domains - Split tunnel configuration
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.routing.push_route.0 --value "172.18.0.0/16" ConfigPut
            /usr/local/openvpn_as/scripts/sacli --key vpn.server.routing.push_route.1 --value "" ConfigPut
            
            # Enable IP forwarding and NAT for split tunneling
            echo 1 > /proc/sys/net/ipv4/ip_forward
            
            # NAT rules for VPN client access to internal services
            iptables -t nat -A POSTROUTING -s 172.27.224.0/20 -d 172.18.0.0/16 -j MASQUERADE 2>/dev/null || true
            
            # Forward rules for VPN client access to internal Docker networks
            iptables -A FORWARD -s 172.27.224.0/20 -d 172.18.0.0/16 -j ACCEPT 2>/dev/null || true
            iptables -A FORWARD -s 172.18.0.0/16 -d 172.27.224.0/20 -j ACCEPT 2>/dev/null || true
            
            log "VPN routing configuration completed"
            break
        fi
        if [ $i -eq 36 ]; then
            log "Timeout waiting for OpenVPN to be ready"
        fi
    done
    
    # Wait for the OpenVPN process
    wait $OPENVPN_PID
else
    exec "$@"
fi