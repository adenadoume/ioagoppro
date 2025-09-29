#!/usr/bin/env python3
"""
Django project setup script for ioagoppro
This script creates a minimal Django project structure if it doesn't exist
"""

import os
import sys
import subprocess

def create_django_project():
    """Create a basic Django project structure"""
    
    # Check if manage.py already exists
    if os.path.exists('manage.py'):
        print("✅ Django project already exists")
        return
    
    print("🚀 Creating Django project structure...")
    
    # Create Django project
    subprocess.run([sys.executable, '-m', 'django', 'startproject', 'ioagoppro', '.'], check=True)
    
    # Create basic settings for production
    settings_content = '''
import os
from pathlib import Path
from decouple import config

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-this-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'ioagoppro.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ioagoppro.wsgi.application'

# Database
import dj_database_url
DATABASES = {
    'default': dj_database_url.config(
        default=config('DATABASE_URL', default='sqlite:///db.sqlite3')
    )
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'static'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Security settings for production
if not DEBUG:
    SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=True, cast=bool)
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
'''
    
    # Write updated settings
    with open('ioagoppro/settings.py', 'w') as f:
        f.write(settings_content)
    
    # Create a simple view
    views_content = '''
from django.http import HttpResponse
from django.shortcuts import render

def home(request):
    return HttpResponse("""
    <!DOCTYPE html>
    <html>
    <head>
        <title>IO AGOP Pro - Portfolio</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; }
            .content { padding: 20px; background: #ecf0f1; margin-top: 20px; border-radius: 8px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 IO AGOP Pro</h1>
                <p>Professional Django Deployment Portfolio</p>
            </div>
            <div class="content">
                <h2>✅ Deployment Successful!</h2>
                <p>This Django application has been successfully deployed using:</p>
                <ul>
                    <li><strong>Ansible</strong> - Infrastructure as Code</li>
                    <li><strong>Nginx</strong> - Web Server & Reverse Proxy</li>
                    <li><strong>Gunicorn</strong> - WSGI Server</li>
                    <li><strong>PostgreSQL</strong> - Database</li>
                    <li><strong>SSL/TLS</strong> - Let's Encrypt Certificates</li>
                    <li><strong>GitHub Actions</strong> - CI/CD Pipeline</li>
                </ul>
                <p><strong>Server:</strong> Hetzner VPS</p>
                <p><strong>Domain:</strong> dev.agop.pro</p>
                <p><strong>Portfolio:</strong> <a href="https://github.com/adenadoume/ioagoppro">GitHub Repository</a></p>
            </div>
        </div>
    </body>
    </html>
    """)
'''
    
    with open('ioagoppro/views.py', 'w') as f:
        f.write(views_content)
    
    # Update URLs
    urls_content = '''
from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.home, name='home'),
]
'''
    
    with open('ioagoppro/urls.py', 'w') as f:
        f.write(urls_content)
    
    print("✅ Django project created successfully!")

if __name__ == '__main__':
    create_django_project()
