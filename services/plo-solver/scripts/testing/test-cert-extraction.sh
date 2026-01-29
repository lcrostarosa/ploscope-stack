#!/bin/bash

# Test script to verify certificate extraction for all services
set -e

echo "🔍 Testing certificate extraction for all services..."

# Test data (simulated ACME certificate)
TEST_ACME_JSON='{
  "letsencrypt": {
    "Certificates": [
      {
        "domain": {
          "main": "vpn.ploscope.com"
        },
        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBZzhBTUlJQkNnS0NBZ0VBb1Q5d3FIT2RVRWo2KzV4VXgwa1QKbURzd09EL3J6c0Y1UEJ0NkdqT0xqSnVHMzFUTnVvN1R5V0t3QjVnM3JIT0xqSnVHMzFUTnVvN1R5V0t3QjVnMwo=",
        "key": "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBdGVWTjN5bFlPeUJ6WXIvMnM3TjFmblljK2hWZndxZ2VHc0J3czJZWFg0c2RrVmhKCk1xRnk3R0k2L3ZFeGROVzRrMGVmaDJuZVd5L1JzMm1iaG1kaXNyT2d3N3kzQm5uZnQ4WlhaN2RqYWVWWG5SeUoKNWpVMTI4V0Exc05vN1R5V0t3QjVnM3JIT0xqSnVHMzFUTnVvN1R5V0t3QjVnM3JIT0xqSnVHMzFUTnVvN1R5Vwo="
      }
    ]
  }
}'

# Create test directory
TEST_DIR="/tmp/cert-test"
mkdir -p "$TEST_DIR"

# Create test ACME file
echo "$TEST_ACME_JSON" > "$TEST_DIR/acme.json"

# Test each service
SERVICES=("openvpn" "rabbitmq" "portainer" "kibana")

for service in "${SERVICES[@]}"; do
    echo "Testing $service..."
    
    # Set environment variables
    export CERT_DOMAIN="vpn.ploscope.com"
    export ACME_FILE="$TEST_DIR/acme.json"
    export SERVICE_NAME="$service"
    export CERT_FILE="$TEST_DIR/${service}.crt"
    export KEY_FILE="$TEST_DIR/${service}.key"
    
    # Run certificate extraction
    if ./scripts/operations/cert-monitor.sh; then
        echo "✅ $service certificate extraction successful"
        
        # Check if files were created
        if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
            echo "✅ $service certificate files created"
        else
            echo "❌ $service certificate files missing"
        fi
    else
        echo "❌ $service certificate extraction failed"
    fi
    
    echo ""
done

# Cleanup
rm -rf "$TEST_DIR"

echo "🎯 Certificate extraction test completed!" 