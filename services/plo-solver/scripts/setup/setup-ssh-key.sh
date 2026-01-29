#!/bin/bash

# Setup SSH Key for PLOSolver Monitoring
# This script helps generate and configure SSH keys for secure access

set -e

echo "🔑 Setting up SSH key for PLOSolver monitoring..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 SSH Key Setup${NC}"
echo "=================="

# Default SSH key path
DEFAULT_KEY_PATH="$HOME/.ssh/plosolver_key"
KEY_PATH=${1:-$DEFAULT_KEY_PATH}

echo -e "${BLUE}🔧 SSH Key Configuration${NC}"
echo "============================="
echo "Key Path: $KEY_PATH"
echo ""

# Check if key already exists
if [ -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}⚠️  SSH key already exists at: $KEY_PATH${NC}"
    echo ""
    echo "Options:"
    echo "1. Use existing key"
    echo "2. Generate new key (will overwrite existing)"
    echo "3. Use different key path"
    echo ""
    read -p "Choose option (1-3): " choice
    
    case $choice in
        1)
            echo -e "${GREEN}✅ Using existing SSH key${NC}"
            ;;
        2)
            echo -e "${BLUE}🔄 Generating new SSH key...${NC}"
            ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "plosolver-monitoring"
            echo -e "${GREEN}✅ New SSH key generated${NC}"
            ;;
        3)
            read -p "Enter new key path: " KEY_PATH
            if [ -f "$KEY_PATH" ]; then
                echo -e "${GREEN}✅ Using existing key at: $KEY_PATH${NC}"
            else
                echo -e "${BLUE}🔄 Generating new SSH key at: $KEY_PATH${NC}"
                ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "plosolver-monitoring"
                echo -e "${GREEN}✅ New SSH key generated${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${BLUE}🔄 Generating new SSH key...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "plosolver-monitoring"
    echo -e "${GREEN}✅ SSH key generated at: $KEY_PATH${NC}"
fi

# Set proper permissions
echo -e "${BLUE}🔐 Setting proper permissions...${NC}"
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"
echo -e "${GREEN}✅ Permissions set correctly${NC}"

# Display public key
echo ""
echo -e "${BLUE}📋 Public Key${NC}"
echo "============="
echo "Add this public key to your server's ~/.ssh/authorized_keys:"
echo ""
cat "$KEY_PATH.pub"
echo ""

# Instructions for adding to server
echo -e "${BLUE}📝 Server Setup Instructions${NC}"
echo "================================"
echo "1. Copy the public key above"
echo "2. SSH to your server: ssh user@your-server"
echo "3. Add to authorized_keys:"
echo "   mkdir -p ~/.ssh"
echo "   echo 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""

# Test connection (if server details provided)
if [ -n "$2" ] && [ -n "$3" ]; then
    SERVER_HOST=$2
    SERVER_USER=$3
    
    echo -e "${BLUE}🧪 Testing SSH connection...${NC}"
    if ssh -i "$KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes ${SERVER_USER}@${SERVER_HOST} exit 2>/dev/null; then
        echo -e "${GREEN}✅ SSH connection successful!${NC}"
    else
        echo -e "${YELLOW}⚠️  SSH connection failed${NC}"
        echo "   Make sure the public key is added to the server"
        echo "   and the server details are correct"
    fi
fi

# Update environment variables
echo -e "${BLUE}🔧 Environment Configuration${NC}"
echo "================================"
echo "Add these to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
echo ""
echo "export PLOSOLVER_SSH_KEY=\"$KEY_PATH\""
echo ""

# Create a test command
echo -e "${BLUE}🚀 Test Commands${NC}"
echo "================"
echo "Test SSH tunnel with key:"
echo "  ./scripts/ssh-tunnel-all.sh <server-ip> <username> $KEY_PATH"
echo ""
echo "Test SSH connection:"
echo "  ssh -i $KEY_PATH <username>@<server-ip>"
echo ""

echo -e "${GREEN}✅ SSH key setup complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Add the public key to your server"
echo "2. Test the SSH connection"
echo "3. Use the key with SSH tunnel scripts"
echo "4. Set the PLOSOLVER_SSH_KEY environment variable" 