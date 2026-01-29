#!/bin/bash

# Setup Docker Log Rotation
# This script configures Docker daemon to automatically rotate logs every 7 days

set -e

echo "🔧 Setting up Docker log rotation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Docker Log Rotation Setup${NC}"
echo "=================================="

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root or with sudo${NC}"
   echo "Usage: sudo ./scripts/setup-docker-log-rotation.sh"
   exit 1
fi

# Backup existing Docker daemon configuration
if [ -f /etc/docker/daemon.json ]; then
    echo -e "${YELLOW}📋 Backing up existing Docker daemon configuration...${NC}"
    cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create or update Docker daemon configuration
echo -e "${BLUE}🔧 Configuring Docker daemon for log rotation...${NC}"

# Check if daemon.json exists and read existing config
if [ -f /etc/docker/daemon.json ]; then
    # Read existing config and merge with log rotation settings
    cat > /tmp/daemon_temp.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "7"
  }
}
EOF
    
    # Merge with existing config (simple merge - assumes no conflicts)
    if command -v jq &> /dev/null; then
        echo -e "${YELLOW}📋 Merging with existing Docker daemon configuration...${NC}"
        jq -s '.[0] * .[1]' /etc/docker/daemon.json /tmp/daemon_temp.json > /etc/docker/daemon.json.new
        mv /etc/docker/daemon.json.new /etc/docker/daemon.json
    else
        echo -e "${YELLOW}⚠️  jq not found, creating new daemon.json with log rotation${NC}"
        cat /tmp/daemon_temp.json > /etc/docker/daemon.json
    fi
else
    # Create new daemon.json with log rotation settings
    echo -e "${BLUE}📋 Creating new Docker daemon configuration...${NC}"
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "7"
  }
}
EOF
fi

# Set proper permissions
chmod 644 /etc/docker/daemon.json

echo -e "${GREEN}✅ Docker daemon configuration updated${NC}"

# Create logrotate configuration for Docker logs
echo -e "${BLUE}📋 Creating logrotate configuration for Docker logs...${NC}"

cat > /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /usr/bin/systemctl reload docker > /dev/null 2>&1 || true
    endscript
}
EOF

# Set proper permissions for logrotate config
chmod 644 /etc/logrotate.d/docker

echo -e "${GREEN}✅ Logrotate configuration created${NC}"

# Test logrotate configuration
echo -e "${BLUE}🧪 Testing logrotate configuration...${NC}"
if logrotate -d /etc/logrotate.d/docker > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Logrotate configuration is valid${NC}"
else
    echo -e "${YELLOW}⚠️  Logrotate configuration test failed (this may be normal if no logs exist yet)${NC}"
fi

# Restart Docker daemon to apply new configuration
echo -e "${BLUE}🔄 Restarting Docker daemon to apply new configuration...${NC}"
systemctl restart docker

# Wait for Docker to be ready
echo -e "${YELLOW}⏳ Waiting for Docker to be ready...${NC}"
sleep 10

# Verify Docker is running
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon failed to start${NC}"
    echo "Check logs with: journalctl -u docker"
    exit 1
fi

# Verify log rotation configuration
echo -e "${BLUE}🔍 Verifying log rotation configuration...${NC}"
if docker info | grep -q "Logging Driver: json-file"; then
    echo -e "${GREEN}✅ Docker is using json-file logging driver${NC}"
else
    echo -e "${YELLOW}⚠️  Docker logging driver verification failed${NC}"
fi

echo ""
echo -e "${BLUE}📊 Log Rotation Configuration${NC}"
echo "=================================="
echo "• Log Driver: json-file"
echo "• Max File Size: 10MB per log file"
echo "• Max Files: 7 files per container"
echo "• Rotation: Daily via logrotate"
echo "• Retention: 7 days"
echo "• Compression: Enabled"
echo ""

echo -e "${BLUE}🛡️  Security Features${NC}"
echo "========================"
echo "• Log files are owned by root:root"
echo "• Permissions set to 644"
echo "• Automatic compression of old logs"
echo "• Secure log rotation process"
echo ""

echo -e "${BLUE}📈 Benefits${NC}"
echo "================"
echo "• Prevents disk space exhaustion"
echo "• Maintains log history for 7 days"
echo "• Automatic cleanup of old logs"
echo "• Compressed storage for efficiency"
echo "• No manual intervention required"
echo ""

echo -e "${GREEN}✅ Docker log rotation setup complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Monitoring Commands:${NC}"
echo "• Check Docker logs: docker logs <container>"
echo "• View log files: ls -la /var/lib/docker/containers/*/*.log"
echo "• Test logrotate: sudo logrotate -f /etc/logrotate.d/docker"
echo "• Check disk usage: du -sh /var/lib/docker/containers/*/"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Monitor log growth with: du -sh /var/lib/docker/containers/*/"
echo "2. Test log rotation by creating some test logs"
echo "3. Verify compression is working"
echo "4. Check that old logs are automatically removed" 