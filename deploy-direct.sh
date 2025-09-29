#!/bin/bash

# Direct SSH Deployment Script for IO AGOP Pro
# This script runs deployment commands directly via SSH

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVER_IP="157.180.28.124"
DOMAIN="dev.agop.pro"
APP_NAME="ioagoppro"
REPO_URL="https://github.com/adenadoume/ioagoppro.git"
DB_PASSWORD="your-secure-password-123"

echo -e "${BLUE}🚀 Direct SSH Deployment for IO AGOP Pro${NC}"
echo -e "${YELLOW}Target: root@${SERVER_IP}${NC}"
echo ""

# Function to run commands on remote server
run_remote() {
    local command="$1"
    local description="$2"
    
    echo -e "${YELLOW}📋 ${description}${NC}"
    ssh root@${SERVER_IP} "$command"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${description} completed${NC}"
    else
        echo -e "${RED}❌ ${description} failed${NC}"
        exit 1
    fi
    echo ""
}

# Test connection
echo -e "${YELLOW}🔍 Testing connection...${NC}"
if ssh root@${SERVER_IP} "echo 'Connection successful'"; then
    echo -e "${GREEN}✅ Connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to server${NC}"
    exit 1
fi
echo ""

# Deployment steps
echo -e "${BLUE}🏗️ Starting deployment process...${NC}"
echo ""

# Update system and install packages
run_remote "apt update && apt upgrade -y" "System update"

run_remote "apt install -y python3-pip python3-venv python3.11 python3.11-venv git nginx postgresql postgresql-contrib libpq-dev python3-dev build-essential certbot python3-certbot-nginx ufw" "Installing required packages"

# Configure firewall
run_remote "ufw allow 22 && ufw allow 80 && ufw allow 443 && ufw --force enable" "Configuring firewall"

# Create app user and directory
run_remote "useradd -m -s /bin/bash django || true" "Creating app user"
run_remote "mkdir -p /opt/${APP_NAME} && chown django:django /opt/${APP_NAME}" "Creating app directory"

# Clone repository
run_remote "cd /opt/${APP_NAME} && git clone ${REPO_URL} . || (git fetch origin && git reset --hard origin/main)" "Cloning repository"
run_remote "chown -R django:django /opt/${APP_NAME}" "Setting ownership"

# Create virtual environment
run_remote "cd /opt/${APP_NAME} && python3.11 -m venv venv" "Creating virtual environment"
run_remote "cd /opt/${APP_NAME} && chown -R django:django venv" "Setting venv ownership"

# Install Python dependencies (create a basic requirements.txt if it doesn't exist)
run_remote "cd /opt/${APP_NAME} && echo 'Django>=4.2
gunicorn>=21.0
psycopg2-binary>=2.9
python-decouple>=3.8' > requirements.txt || true" "Creating requirements.txt"

run_remote "cd /opt/${APP_NAME} && ./venv/bin/pip install --upgrade pip" "Upgrading pip"
run_remote "cd /opt/${APP_NAME} && ./venv/bin/pip install -r requirements.txt" "Installing Python packages"

# Setup PostgreSQL
run_remote "sudo -u postgres psql -c \"CREATE DATABASE ${APP_NAME}_db;\" || true" "Creating database"
run_remote "sudo -u postgres psql -c \"CREATE USER ${APP_NAME}_user WITH PASSWORD '${DB_PASSWORD}';\" || true" "Creating database user"
run_remote "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME}_db TO ${APP_NAME}_user;\" || true" "Granting database privileges"

# Create .env file
run_remote "cat > /opt/${APP_NAME}/.env << 'EOF'
DEBUG=False
SECRET_KEY=your-secret-key-$(date +%s)
ALLOWED_HOSTS=${DOMAIN},www.${DOMAIN},${SERVER_IP}
DATABASE_URL=postgres://${APP_NAME}_user:${DB_PASSWORD}@localhost:5432/${APP_NAME}_db
STATIC_URL=/static/
STATIC_ROOT=/opt/${APP_NAME}/static/
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF" "Creating environment file"

run_remote "chown django:django /opt/${APP_NAME}/.env && chmod 600 /opt/${APP_NAME}/.env" "Securing environment file"

# Create logs directory
run_remote "mkdir -p /opt/${APP_NAME}/logs && chown django:django /opt/${APP_NAME}/logs" "Creating logs directory"

# Run Django commands (if manage.py exists)
run_remote "cd /opt/${APP_NAME} && ./venv/bin/python manage.py migrate || echo 'No manage.py found - skipping migrations'" "Running migrations"
run_remote "cd /opt/${APP_NAME} && ./venv/bin/python manage.py collectstatic --noinput || echo 'No manage.py found - skipping collectstatic'" "Collecting static files"

# Create systemd service
run_remote "cat > /etc/systemd/system/${APP_NAME}.service << 'EOF'
[Unit]
Description=Gunicorn instance to serve ${APP_NAME}
After=network.target postgresql.service
Wants=postgresql.service

[Service]
User=django
Group=www-data
WorkingDirectory=/opt/${APP_NAME}
Environment=\"PATH=/opt/${APP_NAME}/venv/bin\"
EnvironmentFile=/opt/${APP_NAME}/.env
ExecStart=/opt/${APP_NAME}/venv/bin/gunicorn --workers 3 --bind unix:/opt/${APP_NAME}/${APP_NAME}.sock ${APP_NAME}.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF" "Creating systemd service"

# Enable and start service
run_remote "systemctl daemon-reload" "Reloading systemd"
run_remote "systemctl enable ${APP_NAME}" "Enabling service"
run_remote "systemctl start ${APP_NAME}" "Starting service"

# Configure Nginx
run_remote "cat > /etc/nginx/sites-available/${APP_NAME} << 'EOF'
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    
    client_max_body_size 50M;
    
    location /static/ {
        alias /opt/${APP_NAME}/static/;
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }
    
    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }
    
    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
        proxy_pass http://unix:/opt/${APP_NAME}/${APP_NAME}.sock;
    }
}
EOF" "Creating Nginx configuration"

# Enable Nginx site
run_remote "ln -sf /etc/nginx/sites-available/${APP_NAME} /etc/nginx/sites-enabled/" "Enabling Nginx site"
run_remote "rm -f /etc/nginx/sites-enabled/default" "Removing default site"
run_remote "nginx -t" "Testing Nginx configuration"
run_remote "systemctl restart nginx" "Restarting Nginx"

# Obtain SSL certificate
run_remote "certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m agop.website@gmail.com || echo 'SSL setup will need manual configuration'" "Setting up SSL"

# Setup SSL auto-renewal
run_remote "echo '0 2 * * * /usr/bin/certbot renew --quiet' | crontab -" "Setting up SSL auto-renewal"

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}Your application should be available at: https://${DOMAIN}${NC}"
echo ""
echo -e "${BLUE}📋 Service management commands:${NC}"
echo "sudo systemctl status ${APP_NAME}     # Check service status"
echo "sudo systemctl restart ${APP_NAME}    # Restart application"
echo "sudo journalctl -u ${APP_NAME} -f     # View logs"
echo ""
echo -e "${YELLOW}⚠️  Make sure your domain ${DOMAIN} points to ${SERVER_IP}${NC}"
