#!/bin/bash

# Local Ansible Deployment Script for IO AGOP Pro
# This script deploys using Ansible from your local machine

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Local Ansible Deployment for IO AGOP Pro${NC}"
echo -e "${YELLOW}Target: 157.180.28.124 (Hetzner VPS)${NC}"
echo ""

# Check if required files exist
if [ ! -f "inventory.ini" ]; then
    echo -e "${RED}❌ inventory.ini not found. Creating from example...${NC}"
    cp inventory.ini.example inventory.ini
    echo -e "${YELLOW}⚠️  Please edit inventory.ini with your server details before running again.${NC}"
    exit 1
fi

if [ ! -f "site.yml" ]; then
    echo -e "${RED}❌ site.yml not found.${NC}"
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ansible not found. Installing...${NC}"
    pip install ansible
fi

# Add Ansible to PATH if needed
export PATH="$PATH:/Users/nucintosh/Library/Python/3.11/bin"

# Test SSH connectivity
echo -e "${YELLOW}🔍 Testing SSH connectivity...${NC}"
echo -e "${BLUE}💡 You'll be prompted for your SSH key passphrase (ath7248420)${NC}"

if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@157.180.28.124 "echo 'SSH test successful'"; then
    echo -e "${GREEN}✅ SSH connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to server. Please check:${NC}"
    echo "1. Server IP address is correct"
    echo "2. SSH key passphrase is correct"
    echo "3. Server is running"
    exit 1
fi

echo ""
echo -e "${YELLOW}📦 Starting Ansible deployment...${NC}"
echo -e "${BLUE}💡 You may be prompted for your SSH key passphrase multiple times${NC}"
echo ""

# Run the Ansible playbook
ansible-playbook -i inventory.ini site.yml -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${GREEN}Your application should now be available at: https://dev.agop.pro${NC}"
    echo ""
    echo -e "${BLUE}📋 Service management commands (run on server):${NC}"
    echo "sudo systemctl status ioagoppro     # Check service status"
    echo "sudo systemctl restart ioagoppro    # Restart application"
    echo "sudo journalctl -u ioagoppro -f     # View logs"
    echo ""
    echo -e "${YELLOW}⚠️  Make sure your domain dev.agop.pro points to 157.180.28.124${NC}"
else
    echo -e "${RED}❌ Deployment failed. Check the error messages above.${NC}"
    exit 1
fi
