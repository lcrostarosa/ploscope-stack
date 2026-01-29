#!/bin/bash

# Monitor VPN client access to Traefik services
# This script watches Traefik logs to see what IPs are accessing VPN-only services

echo "=== VPN Access Monitor ==="
echo "This script monitors Traefik logs for VPN client connections"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Check if Traefik is running
if ! docker ps | grep -q traefik; then
    echo "❌ Traefik is not running"
    exit 1
fi

echo "✅ Traefik is running"
echo ""
echo "Monitoring Traefik logs for VPN-only service access..."
echo "Try accessing these services from your VPN client:"
echo "  - https://kibana.ploscope.com"
echo "  - https://portainer.ploscope.com"
echo "  - https://rabbitmq.ploscope.com"
echo ""
echo "The logs below will show the client IP addresses:"
echo ""

# Monitor Traefik logs for VPN service access
docker logs -f plosolver-traefik-development 2>&1 | grep -E "(kibana|portainer|rabbitmq)" | while read line; do
    # Extract timestamp and message
    timestamp=$(echo "$line" | grep -o 'time="[^"]*"' | cut -d'"' -f2)
    message=$(echo "$line" | sed 's/.*msg="//' | sed 's/"$//')
    
    # Check if it's an access log entry
    if echo "$line" | grep -q "level=info"; then
        echo "[$timestamp] $message"
    fi
done 