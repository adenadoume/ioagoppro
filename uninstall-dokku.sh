#!/bin/bash

# Dokku Uninstallation Script for Hetzner VPS
# This script safely removes Dokku and prepares the server for new deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗑️  Dokku Uninstallation Script${NC}"
echo -e "${YELLOW}⚠️  This will completely remove Dokku and all its applications!${NC}"
echo ""

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Function to list Dokku apps
list_dokku_apps() {
    echo -e "${BLUE}📋 Current Dokku applications:${NC}"
    if command -v dokku >/dev/null 2>&1; then
        dokku apps:list 2>/dev/null || echo "No apps found or Dokku not responding"
    else
        echo "Dokku not found or not installed"
    fi
    echo ""
}

# Function to backup data (optional)
backup_data() {
    read -p "Do you want to backup any data before uninstalling? (y/N): " backup_choice
    if [[ $backup_choice =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}📦 Creating backup directory...${NC}"
        mkdir -p /root/dokku-backup-$(date +%Y%m%d)
        
        if command -v dokku >/dev/null 2>&1; then
            echo -e "${YELLOW}📦 Backing up Dokku apps data...${NC}"
            cp -r /home/dokku /root/dokku-backup-$(date +%Y%m%d)/ 2>/dev/null || true
            
            echo -e "${YELLOW}📦 Backing up Nginx configs...${NC}"
            cp -r /etc/nginx /root/dokku-backup-$(date +%Y%m%d)/ 2>/dev/null || true
        fi
        
        echo -e "${GREEN}✅ Backup created in /root/dokku-backup-$(date +%Y%m%d)${NC}"
    fi
}

# Function to stop all Dokku services
stop_dokku_services() {
    echo -e "${YELLOW}🛑 Stopping Dokku services...${NC}"
    
    # Stop all Dokku apps
    if command -v dokku >/dev/null 2>&1; then
        for app in $(dokku apps:list 2>/dev/null | tail -n +2); do
            echo "Stopping app: $app"
            dokku ps:stop "$app" 2>/dev/null || true
        done
    fi
    
    # Stop Docker containers
    echo -e "${YELLOW}🐳 Stopping Docker containers...${NC}"
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    # Stop services
    systemctl stop dokku-installer 2>/dev/null || true
    systemctl stop docker 2>/dev/null || true
}

# Function to remove Dokku packages
remove_dokku_packages() {
    echo -e "${YELLOW}📦 Removing Dokku packages...${NC}"
    
    # Remove Dokku
    apt-get remove --purge -y dokku 2>/dev/null || true
    apt-get remove --purge -y herokuish 2>/dev/null || true
    apt-get remove --purge -y plugn 2>/dev/null || true
    apt-get remove --purge -y sshcommand 2>/dev/null || true
    apt-get remove --purge -y dokku-* 2>/dev/null || true
    
    # Remove Docker (optional)
    read -p "Do you want to remove Docker as well? (y/N): " remove_docker
    if [[ $remove_docker =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🐳 Removing Docker...${NC}"
        apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || true
        apt-get remove --purge -y docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true
    fi
    
    # Clean up dependencies
    apt-get autoremove -y
    apt-get autoclean
}

# Function to remove Dokku files and directories
remove_dokku_files() {
    echo -e "${YELLOW}🗂️  Removing Dokku files and directories...${NC}"
    
    # Remove Dokku directories
    rm -rf /home/dokku
    rm -rf /var/lib/dokku
    rm -rf /etc/dokku
    rm -rf /var/log/dokku
    rm -rf /usr/share/dokku
    rm -rf /usr/bin/dokku
    
    # Remove Docker data (if Docker was removed)
    if [[ $remove_docker =~ ^[Yy]$ ]]; then
        rm -rf /var/lib/docker
        rm -rf /etc/docker
    fi
    
    # Remove systemd services
    rm -f /etc/systemd/system/dokku-*.service
    rm -f /lib/systemd/system/dokku-*.service
    systemctl daemon-reload
}

# Function to clean up Nginx
cleanup_nginx() {
    echo -e "${YELLOW}🌐 Cleaning up Nginx configuration...${NC}"
    
    # Remove Dokku Nginx configs
    rm -f /etc/nginx/sites-enabled/dokku-*
    rm -f /etc/nginx/sites-available/dokku-*
    rm -f /etc/nginx/conf.d/dokku-*
    rm -f /etc/nginx/conf.d/00-default-vhost.conf
    
    # Reset Nginx to default
    if [ -f "/etc/nginx/sites-available/default.orig" ]; then
        cp /etc/nginx/sites-available/default.orig /etc/nginx/sites-available/default
    fi
    
    # Test Nginx configuration
    nginx -t && systemctl restart nginx || echo "Nginx configuration needs manual fix"
}

# Function to clean up users and groups
cleanup_users() {
    echo -e "${YELLOW}👤 Cleaning up users and groups...${NC}"
    
    # Remove dokku user
    userdel -r dokku 2>/dev/null || true
    
    # Remove docker group if Docker was removed
    if [[ $remove_docker =~ ^[Yy]$ ]]; then
        groupdel docker 2>/dev/null || true
    fi
}

# Function to clean up repositories
cleanup_repositories() {
    echo -e "${YELLOW}📦 Cleaning up package repositories...${NC}"
    
    # Remove Dokku repository
    rm -f /etc/apt/sources.list.d/dokku.list
    
    # Remove Docker repository (if Docker was removed)
    if [[ $remove_docker =~ ^[Yy]$ ]]; then
        rm -f /etc/apt/sources.list.d/docker.list
    fi
    
    # Update package lists
    apt-get update
}

# Function to clean up iptables rules
cleanup_iptables() {
    echo -e "${YELLOW}🔥 Cleaning up firewall rules...${NC}"
    
    # Flush Docker iptables rules
    iptables -t nat -F DOCKER 2>/dev/null || true
    iptables -t nat -X DOCKER 2>/dev/null || true
    iptables -t filter -F DOCKER 2>/dev/null || true
    iptables -t filter -X DOCKER 2>/dev/null || true
    iptables -t filter -F DOCKER-ISOLATION-STAGE-1 2>/dev/null || true
    iptables -t filter -X DOCKER-ISOLATION-STAGE-1 2>/dev/null || true
    iptables -t filter -F DOCKER-ISOLATION-STAGE-2 2>/dev/null || true
    iptables -t filter -X DOCKER-ISOLATION-STAGE-2 2>/dev/null || true
    iptables -t filter -F DOCKER-USER 2>/dev/null || true
    iptables -t filter -X DOCKER-USER 2>/dev/null || true
    
    # Save iptables rules
    if command -v iptables-save >/dev/null 2>&1; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi
}

# Function to verify uninstallation
verify_uninstallation() {
    echo -e "${BLUE}🔍 Verifying uninstallation...${NC}"
    
    # Check if Dokku command exists
    if command -v dokku >/dev/null 2>&1; then
        echo -e "${RED}⚠️  Dokku command still exists${NC}"
    else
        echo -e "${GREEN}✅ Dokku command removed${NC}"
    fi
    
    # Check if Docker is running (if it should be removed)
    if [[ $remove_docker =~ ^[Yy]$ ]]; then
        if systemctl is-active --quiet docker; then
            echo -e "${RED}⚠️  Docker is still running${NC}"
        else
            echo -e "${GREEN}✅ Docker stopped/removed${NC}"
        fi
    fi
    
    # Check for remaining processes
    if pgrep -f dokku >/dev/null; then
        echo -e "${RED}⚠️  Dokku processes still running${NC}"
    else
        echo -e "${GREEN}✅ No Dokku processes found${NC}"
    fi
    
    # Show disk space freed
    echo -e "${GREEN}💾 Current disk usage:${NC}"
    df -h /
}

# Main execution
main() {
    check_root
    
    echo -e "${YELLOW}This script will:${NC}"
    echo "1. Stop all Dokku applications and services"
    echo "2. Remove Dokku packages and dependencies"
    echo "3. Clean up configuration files and directories"
    echo "4. Reset Nginx configuration"
    echo "5. Remove users and groups created by Dokku"
    echo "6. Clean up package repositories"
    echo "7. Reset firewall rules"
    echo ""
    
    list_dokku_apps
    
    read -p "Are you sure you want to continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Uninstallation cancelled${NC}"
        exit 0
    fi
    
    backup_data
    stop_dokku_services
    remove_dokku_packages
    remove_dokku_files
    cleanup_nginx
    cleanup_users
    cleanup_repositories
    cleanup_iptables
    verify_uninstallation
    
    echo ""
    echo -e "${GREEN}🎉 Dokku uninstallation completed!${NC}"
    echo -e "${GREEN}Your server is now clean and ready for new deployment.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Reboot the server: reboot"
    echo "2. Update your Ansible inventory.ini with the server IP"
    echo "3. Run the deployment: ./deploy.sh"
    echo ""
}

# Run main function
main "$@"
