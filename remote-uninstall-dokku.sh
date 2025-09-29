#!/bin/bash

# Remote Dokku Uninstallation Script
# This script uploads and runs the uninstall script on your VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Remote Dokku Uninstallation${NC}"

# Check if inventory.ini exists
if [ ! -f "inventory.ini" ]; then
    echo -e "${RED}❌ inventory.ini not found.${NC}"
    echo "Please create inventory.ini with your server details:"
    echo ""
    echo "[server]"
    echo "YOUR_SERVER_IP ansible_user=root"
    echo ""
    exit 1
fi

# Extract server IP from inventory.ini
SERVER_IP=$(grep -v '^\[' inventory.ini | grep -v '^#' | grep -v '^$' | head -1 | awk '{print $1}')
SERVER_USER=$(grep -v '^\[' inventory.ini | grep -v '^#' | grep -v '^$' | head -1 | grep -o 'ansible_user=[^ ]*' | cut -d'=' -f2 || echo "root")

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}❌ Could not extract server IP from inventory.ini${NC}"
    exit 1
fi

echo -e "${YELLOW}🎯 Target server: ${SERVER_USER}@${SERVER_IP}${NC}"

# Test connection
echo -e "${YELLOW}🔍 Testing connection to server...${NC}"
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "echo 'Connection successful'"; then
    echo -e "${GREEN}✅ Connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to server. Please check:${NC}"
    echo "1. Server IP address is correct"
    echo "2. SSH key is configured"
    echo "3. Server is running"
    exit 1
fi

# Upload uninstall script
echo -e "${YELLOW}📤 Uploading uninstall script to server...${NC}"
scp -o StrictHostKeyChecking=no uninstall-dokku.sh ${SERVER_USER}@${SERVER_IP}:/tmp/

# Make script executable and run it
echo -e "${YELLOW}🗑️  Running Dokku uninstall script on server...${NC}"
ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "
    chmod +x /tmp/uninstall-dokku.sh
    /tmp/uninstall-dokku.sh
"

echo -e "${GREEN}🎉 Dokku uninstallation completed!${NC}"
echo -e "${BLUE}💡 Your server is now ready for the new deployment.${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update site.yml with your domain and repository URL"
echo "2. Run: ./deploy.sh"
