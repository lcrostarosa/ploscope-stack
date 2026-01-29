#!/bin/bash
set -e

# Environment variables with defaults
DOMAIN="${CERT_DOMAIN:-example.com}"
ACME_FILE="${ACME_FILE:-/etc/traefik-certs/acme.json}"
CERT_FILE="${CERT_FILE:-/certs/server.crt}"
KEY_FILE="${KEY_FILE:-/certs/server.key}"
SERVICE_NAME="${SERVICE_NAME:-service}"
RESTART_COMMAND="${RESTART_COMMAND:-}"
LOCK_FILE="/tmp/cert-monitor-${SERVICE_NAME}.lock"

# Special handling for different services
case "$SERVICE_NAME" in
    "openvpn")
        # OpenVPN expects certificates in its config directory
        OPENVPN_CERT_DIR="/openvpn/etc/web-ssl"
        if [ ! -d "$OPENVPN_CERT_DIR" ]; then
            mkdir -p "$OPENVPN_CERT_DIR"
        fi
        # Update paths for OpenVPN
        CERT_FILE="$OPENVPN_CERT_DIR/server.crt"
        KEY_FILE="$OPENVPN_CERT_DIR/server.key"
        ;;
    "rabbitmq")
        # RabbitMQ expects certificates in its certs directory
        RABBITMQ_CERT_DIR="/etc/rabbitmq/certs"
        if [ ! -d "$RABBITMQ_CERT_DIR" ]; then
            mkdir -p "$RABBITMQ_CERT_DIR"
        fi
        # Update paths for RabbitMQ
        CERT_FILE="$RABBITMQ_CERT_DIR/rabbitmq.crt"
        KEY_FILE="$RABBITMQ_CERT_DIR/rabbitmq.key"
        ;;
    "portainer")
        # Portainer expects certificates in its data directory
        PORTAINER_CERT_DIR="/data/certs"
        if [ ! -d "$PORTAINER_CERT_DIR" ]; then
            mkdir -p "$PORTAINER_CERT_DIR"
        fi
        # Update paths for Portainer
        CERT_FILE="$PORTAINER_CERT_DIR/portainer.crt"
        KEY_FILE="$PORTAINER_CERT_DIR/portainer.key"
        ;;
    "kibana")
        # Kibana expects certificates in its config directory
        KIBANA_CERT_DIR="/usr/share/kibana/config/certs"
        if [ ! -d "$KIBANA_CERT_DIR" ]; then
            mkdir -p "$KIBANA_CERT_DIR"
        fi
        # Update paths for Kibana
        CERT_FILE="$KIBANA_CERT_DIR/kibana.crt"
        KEY_FILE="$KIBANA_CERT_DIR/kibana.key"
        ;;
esac

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${SERVICE_NAME^^}-CERT-MONITOR: $1"
}

# Check if another instance is running
if [ -f "$LOCK_FILE" ] && kill -0 $(cat "$LOCK_FILE") 2>/dev/null; then
    log "Another instance is running, exiting"
    exit 0
fi

# Create lock file
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# Extract certificate hash from acme.json using Python
get_acme_cert_hash() {
    if [ ! -f "$ACME_FILE" ]; then
        log "ACME file not found: $ACME_FILE"
        echo "NOTFOUND"
        return 1
    fi

    python3 -c "
import json
import base64
import hashlib

try:
    with open('$ACME_FILE', 'r') as f:
        data = json.load(f)

    for cert in data.get('letsencrypt', {}).get('Certificates', []):
        if cert['domain']['main'] == '$DOMAIN':
            cert_data = base64.b64decode(cert['certificate'])
            print(hashlib.sha256(cert_data).hexdigest())
            exit(0)

    print('NOTFOUND')
except:
    print('NOTFOUND')
" 2>/dev/null
}

# Extract certificate hash from existing file
get_current_cert_hash() {
    if [ ! -f "$CERT_FILE" ]; then
        echo "NOTFOUND"
        return
    fi

    sha256sum "$CERT_FILE" | cut -d' ' -f1
}

# Extract and install certificates using Python (since jq may not be available)
extract_certificates() {
    log "Extracting certificates for $DOMAIN"

    # Create certs directory if it doesn't exist
    mkdir -p "$(dirname "$CERT_FILE")"

    # Use Python to extract certificates (more reliable than jq)
    python3 -c "
import json
import base64
import sys

try:
    with open('$ACME_FILE', 'r') as f:
        data = json.load(f)

    for cert in data.get('letsencrypt', {}).get('Certificates', []):
        if cert['domain']['main'] == '$DOMAIN':
            # Extract and decode certificate
            cert_data = base64.b64decode(cert['certificate'])
            key_data = base64.b64decode(cert['key'])

            # Write certificate
            with open('$CERT_FILE', 'wb') as f:
                f.write(cert_data)

            # Write key
            with open('$KEY_FILE', 'wb') as f:
                f.write(key_data)

            print('SUCCESS')
            sys.exit(0)

    print('NOTFOUND')
    sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
" 2>/dev/null

    if [ $? -eq 0 ]; then
        log "Certificates extracted successfully"

        # Set proper permissions
        chmod 644 "$CERT_FILE"
        chmod 600 "$KEY_FILE"

        # Configure OpenVPN to use external certificates
        if [ "$SERVICE_NAME" = "openvpn" ]; then
            log "Configuring OpenVPN to use external certificates"

            # Wait a moment for OpenVPN to be ready
            sleep 5

            # Apply configuration from as.conf file
            log "Applying as.conf configuration"
            /usr/local/openvpn_as/scripts/sacli --key host.name --value $DOMAIN ConfigPut || true

            # Configure OpenVPN database with explicit settings
            /usr/local/openvpn_as/scripts/confdba --set --key web.server.cert --value /openvpn/etc/web-ssl/server.crt || true
            /usr/local/openvpn_as/scripts/confdba --set --key web.server.key --value /openvpn/etc/web-ssl/server.key || true
            /usr/local/openvpn_as/scripts/confdba --set --key web.server.cert.auto --value false || true
            /usr/local/openvpn_as/scripts/confdba --set --key host.name --value $DOMAIN || true
            /usr/local/openvpn_as/scripts/confdba --set --key cs.https.ip_address --value all || true
            /usr/local/openvpn_as/scripts/confdba --set --key cs.hostname --value $DOMAIN || true

            log "OpenVPN certificate and hostname configuration updated"

            # Restart OpenVPN to reload certificates
            log "Restarting OpenVPN to reload certificates"
            pkill -HUP openvpnas 2>/dev/null || true
        fi

        return 0
    else
        log "Failed to extract certificates for domain: $DOMAIN"
        return 1
    fi
}

# Restart service if command provided
restart_service() {
    if [ -n "$RESTART_COMMAND" ]; then
        log "Executing restart command: $RESTART_COMMAND"
        eval "$RESTART_COMMAND" || log "Restart command failed"
    else
        log "No restart command specified"
    fi
}

# Main monitoring logic
main() {
    log "Starting certificate monitoring for $DOMAIN"
    log "CERT_FILE: $CERT_FILE"
    log "KEY_FILE: $KEY_FILE"

    # Get certificate hashes
    acme_hash=$(get_acme_cert_hash)
    current_hash=$(get_current_cert_hash)

    log "ACME hash: $acme_hash"
    log "Current hash: $current_hash"

    # Check if extraction is needed
    needs_update=false

    if [ "$current_hash" = "NOTFOUND" ]; then
        log "No existing certificate found, extracting..."
        needs_update=true
    elif [ "$acme_hash" = "ERROR" ] || [ "$acme_hash" = "NOTFOUND" ]; then
        log "Cannot read ACME certificate, skipping update"
        exit 0
    elif [ "$acme_hash" != "$current_hash" ]; then
        log "Certificate has changed, updating..."
        needs_update=true
    else
        log "Certificate is up to date"
    fi

    if [ "$needs_update" = true ]; then
        if extract_certificates; then
            restart_service
            log "Certificate update completed successfully"
        else
            log "Certificate update failed"
            exit 1
        fi
    fi
}

# Run main function
main "$@"
