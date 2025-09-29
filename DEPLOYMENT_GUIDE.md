# Complete Deployment Guide

## Step-by-Step Setup for Hetzner VPS

### 1. 🏗️ Hetzner VPS Setup

1. **Create a Hetzner VPS**:
   - Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
   - Create a new server (Ubuntu 22.04 LTS recommended)
   - Choose your server size (CX11 minimum for small apps)
   - Add your SSH key or use password authentication

2. **Configure DNS**:
   - Point your domain A record to your server IP
   - If using Cloudflare, set SSL/TLS to "Full"

### 2. 🔧 Local Setup

1. **Clone this repository**:
   ```bash
   git clone https://github.com/yourusername/io_agop.git
   cd io_agop
   ```

2. **Install Ansible** (if not using GitHub Actions):
   ```bash
   pip install ansible
   ```

3. **Configure inventory**:
   ```bash
   cp inventory.ini.example inventory.ini
   nano inventory.ini
   ```
   
   Update with your server IP:
   ```ini
   [server]
   123.456.789.10 ansible_user=root
   ```

4. **Update site.yml variables**:
   ```yaml
   vars:
     domain: yourdomain.com
     db_password: your-super-secure-password
     repo_url: https://github.com/yourusername/your-django-repo.git
   ```

### 3. 🚀 GitHub Actions Setup (Recommended)

1. **Fork this repository** to your GitHub account

2. **Add GitHub Secrets**:
   - Go to your repo Settings > Secrets and Variables > Actions
   - Add the following secrets:

   | Secret | Value | Notes |
   |--------|-------|-------|
   | `SERVER_IP` | `123.456.789.10` | Your Hetzner VPS IP |
   | `SERVER_USER` | `root` | SSH username |
   | `SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH...` | Your private SSH key |
   | `DOMAIN` | `yourdomain.com` | Your domain name |
   | `DB_PASSWORD` | `secure-password` | Database password |
   | `EMAIL` | `you@domain.com` | For SSL certificates |

3. **Get your SSH private key**:
   ```bash
   cat ~/.ssh/id_rsa
   ```
   Copy the entire output including the header and footer lines.

4. **Push to main branch**:
   ```bash
   git add .
   git commit -m "Initial deployment setup"
   git push origin main
   ```

   This will trigger the automatic deployment!

### 4. 🔧 Manual Deployment (Alternative)

If you prefer to deploy manually:

1. **Test connectivity**:
   ```bash
   ansible all -i inventory.ini -m ping
   ```

2. **Run deployment**:
   ```bash
   ./deploy.sh
   ```

3. **Monitor progress**:
   The script will show you each step and any errors.

### 5. 🔍 Verification

After deployment, verify everything is working:

1. **Check your website**: `https://yourdomain.com`
2. **Verify SSL certificate**: Should show a green lock
3. **Check services on server**:
   ```bash
   ssh root@your-server-ip
   sudo systemctl status ioagoppro
   sudo systemctl status nginx
   sudo systemctl status postgresql
   ```

### 6. 🎯 Django App Requirements

Your Django application needs these configurations:

1. **Settings for production** (`settings.py`):
   ```python
   import os
   from decouple import config
   
   DEBUG = config('DEBUG', default=False, cast=bool)
   SECRET_KEY = config('SECRET_KEY')
   ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')
   
   # Database
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.postgresql',
           'NAME': config('DB_NAME'),
           'USER': config('DB_USER'),
           'PASSWORD': config('DB_PASSWORD'),
           'HOST': 'localhost',
           'PORT': '5432',
       }
   }
   
   # Static files
   STATIC_URL = '/static/'
   STATIC_ROOT = os.path.join(BASE_DIR, 'static')
   
   # Security settings
   if not DEBUG:
       SECURE_SSL_REDIRECT = True
       SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
       SESSION_COOKIE_SECURE = True
       CSRF_COOKIE_SECURE = True
   ```

2. **Required packages** (`requirements.txt`):
   ```
   Django>=4.2
   gunicorn>=21.0
   psycopg2-binary>=2.9
   python-decouple>=3.8
   ```

3. **WSGI configuration** (`wsgi.py`):
   ```python
   import os
   from django.core.wsgi import get_wsgi_application
   
   os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')
   application = get_wsgi_application()
   ```

### 7. 🚨 Troubleshooting

**Common issues and solutions:**

1. **Connection refused**:
   - Check if SSH key is correct
   - Verify server IP address
   - Ensure port 22 is open

2. **SSL certificate errors**:
   - Verify domain points to server IP
   - Check DNS propagation: `dig yourdomain.com`
   - Wait for DNS to propagate (up to 24 hours)

3. **Application won't start**:
   ```bash
   # Check logs
   sudo journalctl -u ioagoppro -f
   
   # Check Django logs
   sudo tail -f /opt/ioagoppro/logs/error.log
   
   # Check if port is listening
   sudo netstat -tlnp | grep :8000
   ```

4. **Database connection errors**:
   ```bash
   # Check PostgreSQL status
   sudo systemctl status postgresql
   
   # Test database connection
   sudo -u postgres psql -c "\\l"
   ```

5. **Nginx errors**:
   ```bash
   # Test Nginx configuration
   sudo nginx -t
   
   # Check Nginx logs
   sudo tail -f /var/log/nginx/error.log
   ```

### 8. 🔄 Updates and Maintenance

**Updating your application**:

1. **Automatic updates** (GitHub Actions):
   - Just push to the main branch
   - GitHub Actions will handle the deployment

2. **Manual updates**:
   ```bash
   ssh root@your-server
   cd /opt/ioagoppro
   git pull origin main
   source venv/bin/activate
   pip install -r requirements.txt
   python manage.py migrate
   python manage.py collectstatic --noinput
   sudo systemctl restart ioagoppro
   ```

**SSL certificate renewal**:
- Automatic via cron job (set up by Ansible)
- Manual renewal: `sudo certbot renew`

**Database backups**:
```bash
# Create backup
sudo -u postgres pg_dump ioagoppro_db > backup_$(date +%Y%m%d).sql

# Restore backup
sudo -u postgres psql ioagoppro_db < backup_20231201.sql
```

### 9. 📊 Monitoring

**Check application health**:
```bash
# System resources
htop
df -h
free -h

# Application logs
sudo journalctl -u ioagoppro --since "1 hour ago"

# Nginx access logs
sudo tail -f /var/log/nginx/access.log
```

**Performance monitoring**:
- Set up monitoring tools like Grafana + Prometheus
- Use Django's built-in admin for basic monitoring
- Configure log aggregation with ELK stack

### 10. 🎯 Portfolio Points

This deployment demonstrates:

✅ **Infrastructure as Code** with Ansible
✅ **CI/CD Pipeline** with GitHub Actions  
✅ **Production Security** with SSL, firewall, secure headers
✅ **Scalable Architecture** with separate web/app/database layers
✅ **Automated Monitoring** with systemd and logging
✅ **Professional DevOps** practices and documentation

Perfect for showcasing in job interviews and portfolio presentations!

---

**Need help?** Open an issue on GitHub or contact [your-email@example.com]
