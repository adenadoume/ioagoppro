# Manual Deployment Steps

Since we're having SSH automation issues, here's a step-by-step manual deployment that you can run directly on your server.

## 🚀 Step 1: Connect to Your Server

```bash
ssh root@157.180.28.124
```
(Enter your passphrase when prompted)

## 📦 Step 2: Update System and Install Packages

Once connected to your server, run these commands one by one:

```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y python3-pip python3-venv python3.11 python3.11-venv git nginx postgresql postgresql-contrib libpq-dev python3-dev build-essential certbot python3-certbot-nginx ufw

# Configure firewall
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable
```

## 👤 Step 3: Create App User and Directory

```bash
# Create django user
useradd -m -s /bin/bash django

# Create app directory
mkdir -p /opt/ioagoppro
chown django:django /opt/ioagoppro
```

## 📁 Step 4: Clone Repository and Setup

```bash
# Clone your repository (replace with your actual repo URL)
cd /opt/ioagoppro
git clone https://github.com/adenadoume/ioagoppro.git .

# Set ownership
chown -R django:django /opt/ioagoppro

# Create virtual environment
python3.11 -m venv venv
chown -R django:django venv
```

## 🐍 Step 5: Install Python Dependencies

```bash
# Create requirements.txt if it doesn't exist
cat > requirements.txt << 'EOF'
Django>=4.2
gunicorn>=21.0
psycopg2-binary>=2.9
python-decouple>=3.8
whitenoise>=6.5
EOF

# Install packages
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt
```

## 🗄️ Step 6: Setup PostgreSQL Database

```bash
# Create database and user
sudo -u postgres psql -c "CREATE DATABASE ioagoppro_db;"
sudo -u postgres psql -c "CREATE USER ioagoppro_user WITH PASSWORD 'your-secure-password-123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ioagoppro_db TO ioagoppro_user;"
```

## ⚙️ Step 7: Create Environment Configuration

```bash
# Create .env file
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=your-secret-key-$(date +%s)
ALLOWED_HOSTS=dev.agop.pro,www.dev.agop.pro,157.180.28.124
DATABASE_URL=postgres://ioagoppro_user:your-secure-password-123@localhost:5432/ioagoppro_db
STATIC_URL=/static/
STATIC_ROOT=/opt/ioagoppro/static/
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF

# Secure the file
chown django:django .env
chmod 600 .env

# Create logs directory
mkdir -p logs
chown django:django logs
```

## 🏗️ Step 8: Run Django Commands (if applicable)

```bash
# Run Django commands if manage.py exists
./venv/bin/python manage.py migrate || echo "No manage.py found - skipping migrations"
./venv/bin/python manage.py collectstatic --noinput || echo "No manage.py found - skipping collectstatic"
```

## 🔧 Step 9: Create Systemd Service

```bash
# Create systemd service file
cat > /etc/systemd/system/ioagoppro.service << 'EOF'
[Unit]
Description=Gunicorn instance to serve ioagoppro
After=network.target postgresql.service
Wants=postgresql.service

[Service]
User=django
Group=www-data
WorkingDirectory=/opt/ioagoppro
Environment="PATH=/opt/ioagoppro/venv/bin"
EnvironmentFile=/opt/ioagoppro/.env
ExecStart=/opt/ioagoppro/venv/bin/gunicorn --workers 3 --bind unix:/opt/ioagoppro/ioagoppro.sock ioagoppro.wsgi:application
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable ioagoppro
systemctl start ioagoppro

# Check service status
systemctl status ioagoppro
```

## 🌐 Step 10: Configure Nginx

```bash
# Create Nginx configuration
cat > /etc/nginx/sites-available/ioagoppro << 'EOF'
server {
    listen 80;
    server_name dev.agop.pro www.dev.agop.pro;
    
    client_max_body_size 50M;
    
    location /static/ {
        alias /opt/ioagoppro/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }
    
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://unix:/opt/ioagoppro/ioagoppro.sock;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/ioagoppro /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t
systemctl restart nginx
```

## 🔒 Step 11: Setup SSL Certificate

```bash
# Obtain Let's Encrypt SSL certificate
certbot --nginx -d dev.agop.pro --non-interactive --agree-tos -m agop.website@gmail.com

# Setup auto-renewal
echo '0 2 * * * /usr/bin/certbot renew --quiet' | crontab -
```

## ✅ Step 12: Verify Deployment

```bash
# Check service status
systemctl status ioagoppro
systemctl status nginx
systemctl status postgresql

# Check if socket file exists
ls -la /opt/ioagoppro/ioagoppro.sock

# Check logs if there are issues
journalctl -u ioagoppro -f
```

## 🎉 Final Notes

After completing these steps:

1. **Your application should be available at**: `https://dev.agop.pro`
2. **Make sure your domain points to**: `157.180.28.124`
3. **Service management commands**:
   - `systemctl status ioagoppro` - Check status
   - `systemctl restart ioagoppro` - Restart app
   - `journalctl -u ioagoppro -f` - View logs

## 🚨 Troubleshooting

If you encounter issues:

1. **Check service logs**: `journalctl -u ioagoppro -f`
2. **Check Nginx logs**: `tail -f /var/log/nginx/error.log`
3. **Verify socket file**: `ls -la /opt/ioagoppro/ioagoppro.sock`
4. **Test Nginx config**: `nginx -t`

---

**Once this is working, we can set up the GitHub Actions CI/CD for automatic deployments!**
