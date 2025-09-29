#!/bin/bash

# Deployment script for IO AGOP Pro
# This script deploys the application to a Hetzner VPS using Ansible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment of IO AGOP Pro${NC}"

# Check if required files exist
if [ ! -f "inventory.ini" ]; then
    echo -e "${RED}❌ inventory.ini not found. Please create it with your server details.${NC}"
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

# Verify server connectivity
echo -e "${YELLOW}🔍 Testing server connectivity...${NC}"
SERVER_IP=$(grep -v '^\[' inventory.ini | grep -v '^#' | grep -v '^$' | head -1 | awk '{print $1}')
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@${SERVER_IP} "echo 'Connection successful'"; then
    echo -e "${GREEN}✅ Server is reachable${NC}"
else
    echo -e "${RED}❌ Cannot reach server. Please check your inventory.ini file.${NC}"
    exit 1
fi

# Run the playbook
echo -e "${YELLOW}📦 Running Ansible playbook...${NC}"
export PATH="$PATH:/Users/nucintosh/Library/Python/3.11/bin"
ansible-playbook -i inventory.ini site.yml --ask-pass -v

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}Your application should now be available at your configured domain.${NC}"
