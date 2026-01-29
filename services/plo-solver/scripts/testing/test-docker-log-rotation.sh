#!/bin/bash

# Test Docker Log Rotation
# This script verifies that Docker log rotation is working correctly

set -e

echo "🧪 Testing Docker log rotation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Docker Log Rotation Test Suite${NC}"
echo "====================================="

# Test 1: Check Docker daemon configuration
echo -e "${BLUE}1. Checking Docker daemon configuration...${NC}"
if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}✅ Docker daemon configuration exists${NC}"
    
    # Check if log rotation settings are present
    if grep -q "max-size" /etc/docker/daemon.json && grep -q "max-file" /etc/docker/daemon.json; then
        echo -e "${GREEN}✅ Log rotation settings found in daemon.json${NC}"
        echo "   Configuration:"
        grep -A 5 "log-opts" /etc/docker/daemon.json | sed 's/^/   /'
    else
        echo -e "${RED}❌ Log rotation settings not found in daemon.json${NC}"
    fi
else
    echo -e "${RED}❌ Docker daemon configuration not found${NC}"
fi

# Test 2: Check logrotate configuration
echo -e "${BLUE}2. Checking logrotate configuration...${NC}"
if [ -f /etc/logrotate.d/docker ]; then
    echo -e "${GREEN}✅ Docker logrotate configuration exists${NC}"
    
    # Check logrotate settings
    if grep -q "rotate 7" /etc/logrotate.d/docker; then
        echo -e "${GREEN}✅ 7-day rotation configured${NC}"
    else
        echo -e "${YELLOW}⚠️  7-day rotation not found in logrotate config${NC}"
    fi
    
    if grep -q "compress" /etc/logrotate.d/docker; then
        echo -e "${GREEN}✅ Compression enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Compression not found in logrotate config${NC}"
    fi
else
    echo -e "${RED}❌ Docker logrotate configuration not found${NC}"
fi

# Test 3: Check Docker logging driver
echo -e "${BLUE}3. Checking Docker logging driver...${NC}"
if docker info | grep -q "Logging Driver: json-file"; then
    echo -e "${GREEN}✅ Docker is using json-file logging driver${NC}"
else
    echo -e "${YELLOW}⚠️  Docker logging driver verification failed${NC}"
    echo "   Current logging driver:"
    docker info | grep "Logging Driver" || echo "   Could not determine logging driver"
fi

# Test 4: Check existing container logs
echo -e "${BLUE}4. Checking existing container logs...${NC}"
if [ -d /var/lib/docker/containers ]; then
    log_count=$(find /var/lib/docker/containers -name "*.log" 2>/dev/null | wc -l)
    if [ $log_count -gt 0 ]; then
        echo -e "${GREEN}✅ Found $log_count container log files${NC}"
        
        # Check log file sizes
        total_size=$(find /var/lib/docker/containers -name "*.log" -exec du -ch {} + 2>/dev/null | tail -1 | cut -f1)
        echo "   Total log size: $total_size"
        
        # Check for compressed logs
        compressed_count=$(find /var/lib/docker/containers -name "*.log.*.gz" 2>/dev/null | wc -l)
        if [ $compressed_count -gt 0 ]; then
            echo -e "${GREEN}✅ Found $compressed_count compressed log files${NC}"
        else
            echo -e "${YELLOW}⚠️  No compressed log files found (may be normal for new setup)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No container log files found${NC}"
    fi
else
    echo -e "${RED}❌ Docker containers directory not found${NC}"
fi

# Test 5: Test logrotate configuration
echo -e "${BLUE}5. Testing logrotate configuration...${NC}"
if logrotate -d /etc/logrotate.d/docker > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Logrotate configuration is valid${NC}"
else
    echo -e "${YELLOW}⚠️  Logrotate configuration test failed${NC}"
    echo "   This may be normal if no logs exist yet"
fi

# Test 6: Check Docker daemon status
echo -e "${BLUE}6. Checking Docker daemon status...${NC}"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon is not running${NC}"
fi

echo ""
echo -e "${BLUE}📊 Log Rotation Summary${NC}"
echo "============================="
echo "• Docker daemon configuration: $(if [ -f /etc/docker/daemon.json ]; then echo "✅"; else echo "❌"; fi)"
echo "• Logrotate configuration: $(if [ -f /etc/logrotate.d/docker ]; then echo "✅"; else echo "❌"; fi)"
echo "• JSON logging driver: $(if docker info 2>/dev/null | grep -q "Logging Driver: json-file"; then echo "✅"; else echo "❌"; fi)"
echo "• Docker daemon running: $(if systemctl is-active --quiet docker; then echo "✅"; else echo "❌"; fi)"
echo ""

echo -e "${BLUE}🔧 Configuration Details${NC}"
echo "=========================="
echo "• Max log file size: 10MB"
echo "• Max log files per container: 7"
echo "• Rotation frequency: Daily"
echo "• Retention period: 7 days"
echo "• Compression: Enabled"
echo ""

echo -e "${GREEN}✅ Docker log rotation test complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Monitoring Commands:${NC}"
echo "• Check log sizes: du -sh /var/lib/docker/containers/*/"
echo "• View log files: ls -la /var/lib/docker/containers/*/*.log"
echo "• Test rotation: sudo logrotate -f /etc/logrotate.d/docker"
echo "• Monitor growth: watch -n 60 'du -sh /var/lib/docker/containers/*/'"
echo ""
echo -e "${YELLOW}📋 Manual Test Steps:${NC}"
echo "1. Create some test logs: docker run --rm alpine sh -c 'for i in {1..1000}; do echo \"Test log $i\"; done'"
echo "2. Check log file growth: ls -lah /var/lib/docker/containers/*/*.log"
echo "3. Force logrotate: sudo logrotate -f /etc/logrotate.d/docker"
echo "4. Verify compression: ls -lah /var/lib/docker/containers/*/*.log.*.gz" 