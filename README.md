# IO AGOP Pro - Portfolio Deployment

A professional Django application deployment setup for Hetzner VPS with automated GitHub CI/CD integration.

## 🚀 Features

- **Automated Deployment**: One-click deployment with Ansible
- **CI/CD Pipeline**: GitHub Actions for continuous integration and deployment
- **Production Ready**: Nginx, Gunicorn, PostgreSQL with SSL certificates
- **Security**: UFW firewall, SSL/TLS encryption, security headers
- **Performance**: Optimized Nginx configuration with gzip compression
- **Monitoring**: Systemd service management with auto-restart

## 📋 Prerequisites

- Hetzner VPS (or any Ubuntu/Debian server)
- Domain name pointed to your server IP
- SSH access to your server
- Ansible installed locally (or use GitHub Actions)

## 🛠️ Local Deployment

### 1. Setup Server Access

Copy the inventory example and configure your server:
```bash
cp inventory.ini.example inventory.ini
```

Edit `inventory.ini` with your server details:
```ini
[server]
YOUR_SERVER_IP ansible_user=root
```

### 2. Configure Variables

Edit `site.yml` and update the variables section:
```yaml
vars:
  domain: your-domain.com
  db_password: your-secure-password
  repo_url: https://github.com/yourusername/your-repo.git
```

### 3. Deploy

Run the deployment script:
```bash
./deploy.sh
```

Or run Ansible directly:
```bash
ansible-playbook -i inventory.ini site.yml
```

## 🔄 GitHub Actions CI/CD

### Setup GitHub Secrets

In your GitHub repository, go to Settings > Secrets and Variables > Actions, and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SERVER_IP` | Your server IP address | `123.456.789.10` |
| `SERVER_USER` | SSH username | `root` |
| `SSH_PRIVATE_KEY` | Your SSH private key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DOMAIN` | Your domain name | `example.com` |
| `DB_PASSWORD` | Database password | `your-secure-password` |
| `EMAIL` | Email for SSL certificates | `you@example.com` |

### Automatic Deployment

Once configured, every push to the `main` branch will:
1. Run tests and linting
2. Deploy to your server automatically
3. Update SSL certificates if needed

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│   Hetzner VPS   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │      Nginx      │
                                              │   (Reverse      │
                                              │    Proxy)       │
                                              └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │    Gunicorn     │
                                              │  (Django App)   │
                                              └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │   PostgreSQL    │
                                              │   (Database)    │
                                              └─────────────────┘
```

## 📁 Project Structure

```
io_agop/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD
├── templates/
│   ├── env.j2                  # Environment variables template
│   ├── nginx.j2                # Nginx configuration template
│   └── systemd.j2              # Systemd service template
├── deploy.sh                   # Local deployment script
├── inventory.ini.example       # Ansible inventory example
├── site.yml                    # Main Ansible playbook
└── README.md                   # This file
```

## 🔧 Configuration

### Environment Variables

The deployment creates a `.env` file with these settings:
- `DEBUG=False` - Production mode
- `SECRET_KEY` - Auto-generated secure key
- `ALLOWED_HOSTS` - Your domain and server IP
- `DATABASE_URL` - PostgreSQL connection string
- Security settings for HTTPS

### Services Installed

- **Nginx**: Web server and reverse proxy
- **Gunicorn**: WSGI server for Django
- **PostgreSQL**: Database server
- **Certbot**: SSL certificate management
- **UFW**: Firewall configuration

## 🔒 Security Features

- **UFW Firewall**: Only allows SSH, HTTP, and HTTPS
- **SSL/TLS**: Automatic Let's Encrypt certificates
- **Security Headers**: XSS protection, content type sniffing prevention
- **Secure Cookies**: HTTPS-only session and CSRF cookies
- **Database Security**: Isolated database user with limited privileges

## 🚨 Troubleshooting

### Check Service Status
```bash
sudo systemctl status ioagoppro
sudo systemctl status nginx
sudo systemctl status postgresql
```

### View Logs
```bash
sudo journalctl -u ioagoppro -f
sudo tail -f /opt/ioagoppro/logs/error.log
sudo tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
sudo systemctl restart ioagoppro
sudo systemctl restart nginx
```

## 📊 Monitoring

The deployment includes:
- Systemd service management with auto-restart
- Nginx access and error logging
- Application logging to `/opt/ioagoppro/logs/`
- SSL certificate auto-renewal via cron

## 🎯 Portfolio Features

This setup is perfect for showcasing your DevOps and full-stack development skills:

- **Modern CI/CD**: GitHub Actions workflow
- **Infrastructure as Code**: Ansible playbooks
- **Production Architecture**: Load balancer, app server, database
- **Security Best Practices**: SSL, firewall, secure headers
- **Automated Monitoring**: Service health checks and logging

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For questions or issues, please open a GitHub issue or contact [your-email@example.com].

---

**Built with ❤️ for portfolio demonstration**
