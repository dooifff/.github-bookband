# StudioBook Deployment Guide

Complete guide for deploying StudioBook to production servers.

## 📋 Prerequisites

### Server Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Storage | 40 GB | 80 GB SSD |
| OS | Ubuntu 20.04 | Ubuntu 22.04 LTS |

### Software Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git
- SSL certificates (Let's Encrypt or purchased)

## 🚀 Quick Deployment

### 1. Clone Repository

```bash
git clone https://github.com/your-repo/studio-book.git
cd studio-book
```

### 2. Configure Environment

```bash
# Copy environment file
cp .env.production .env.production.local

# Edit configuration
nano .env.production.local
```

### 3. Generate Application Key

```bash
# You can use any Laravel installation to generate the key
php artisan key:generate --show
# Copy the output and set it in .env.production.local as APP_KEY
```

### 4. Setup SSL Certificates

```bash
# Create SSL directory
mkdir -p backend/docker/nginx/ssl

# Option A: Use Let's Encrypt (recommended)
# Install certbot on host
sudo apt install certbot

# Get certificates
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem backend/docker/nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem backend/docker/nginx/ssl/
sudo chown $USER:$USER backend/docker/nginx/ssl/*

# Option B: Use purchased certificates
cp /path/to/fullchain.pem backend/docker/nginx/ssl/
cp /path/to/privkey.pem backend/docker/nginx/ssl/
```

### 5. Deploy

```bash
# Run deployment script
./scripts/deploy.sh production
```

## 🔧 Detailed Configuration

### Environment Variables

Edit `.env.production.local`:

```env
# Required Changes
APP_URL=https://yourdomain.com
DB_PASSWORD=your-strong-password
DB_ROOT_PASSWORD=your-strong-root-password
REDIS_PASSWORD=your-redis-password
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password

# Optional
SENTRY_DSN=https://your-sentry-dsn
```

### DNS Configuration

| Type | Name | Value |
|------|------|-------|
| A | @ | your-server-ip |
| A | www | your-server-ip |
| CNAME | api | yourdomain.com |

### Firewall Rules

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow SSH
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable
```

## 📦 Deployment Scripts

### Main Deployment

```bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
```

### Backup

```bash
# Create backup
./scripts/backup.sh production

# List backups
ls -la backups/

# Restore backup
./scripts/restore.sh studiobook_backup_2024-01-15_10-30-00
```

### Rollback

```bash
# Interactive rollback
./scripts/rollback.sh
```

## 🐳 Docker Commands

### Production Management

```bash
# Start all services
docker compose -f docker-compose.prod.yml up -d

# Stop all services
docker compose -f docker-compose.prod.yml down

# View logs
docker compose -f docker-compose.prod.yml logs -f

# View specific service logs
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f nginx

# Restart services
docker compose -f docker-compose.prod.yml restart

# Pull updates
docker compose -f docker-compose.prod.yml pull

# Build images
docker compose -f docker-compose.prod.yml build
```

### Maintenance Commands

```bash
# Access container shell
docker compose -f docker-compose.prod.yml exec api bash
docker compose -f docker-compose.prod.yml exec web sh

# Run Laravel commands
docker compose -f docker-compose.prod.yml exec api php artisan migrate
docker compose -f docker-compose.prod.yml exec api php artisan db:seed
docker compose -f docker-compose.prod.yml exec api php artisan cache:clear

# View container stats
docker compose -f docker-compose.prod.yml stats
```

## 🔒 Security Checklist

### Pre-Deployment

- [ ] Strong database passwords set
- [ ] APP_DEBUG=false in production
- [ ] SSL certificates installed
- [ ] Firewall configured
- [ ] SSH key authentication enabled
- [ ] Root login disabled

### Post-Deployment

- [ ] API health check passes
- [ ] HTTPS working correctly
- [ ] HSTS headers present
- [ ] Security headers configured
- [ ] Rate limiting active
- [ ] Error logging working

### Regular Maintenance

- [ ] Monitor server resources
- [ ] Review application logs
- [ ] Update Docker images monthly
- [ ] Rotate secrets quarterly
- [ ] Test backups monthly

## 📊 Monitoring

### Health Checks

```bash
# API health
curl -f https://yourdomain.com/api/health

# Web health
curl -f https://yourdomain.com

# Database health
docker compose -f docker-compose.prod.yml exec mysql mysqladmin ping
```

### Logs Location

| Service | Log Location |
|---------|--------------|
| Nginx | `/var/log/nginx/` |
| API | `backend/storage/logs/` |
| MySQL | Docker logs |
| Redis | Docker logs |

### Resource Monitoring

```bash
# Container stats
docker compose -f docker-compose.prod.yml stats

# System resources
htop
df -h
free -m
```

## 🔄 CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Tests** - Runs all tests on push/PR
2. **Build** - Creates Docker images
3. **Scan** - Security vulnerability scanning
4. **Deploy** - Deploys to staging/production

### Required Secrets

Add these to GitHub repository secrets:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `STAGING_SSH_PRIVATE_KEY` | SSH key for staging |
| `STAGING_HOST` | Staging server hostname |
| `STAGING_USER` | Staging SSH user |
| `PRODUCTION_SSH_PRIVATE_KEY` | SSH key for production |
| `PRODUCTION_HOST` | Production server hostname |
| `PRODUCTION_USER` | Production SSH user |

## 🆘 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose -f docker-compose.prod.yml logs api

# Rebuild
docker compose -f docker-compose.prod.yml build --no-cache api
docker compose -f docker-compose.prod.yml up -d api
```

### Database Connection Issues

```bash
# Check MySQL status
docker compose -f docker-compose.prod.yml exec mysql mysqladmin ping

# Check environment
docker compose -f docker-compose.prod.yml exec api env | grep DB_

# Restart MySQL
docker compose -f docker-compose.prod.yml restart mysql
```

### SSL Certificate Issues

```bash
# Verify certificates
openssl x509 -in backend/docker/nginx/ssl/fullchain.pem -text -noout

# Test SSL
openssl s_client -connect yourdomain.com:443
```

### Memory Issues

```bash
# Check memory usage
docker stats

# Increase PHP memory limit
# Edit backend/docker/php/php.ini
memory_limit = 512M

# Restart API
docker compose -f docker-compose.prod.yml restart api
```

### Performance Issues

```bash
# Enable OPcache
# Verify opcache.ini is loaded

# Check Redis connection
docker compose -f docker-compose.prod.yml exec redis redis-cli ping

# Monitor slow queries
docker compose -f docker-compose.prod.yml exec mysql mysql -e "SHOW PROCESSLIST;"
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Laravel Deployment](https://laravel.com/docs/deployment)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

## 🤝 Support

For deployment issues:

1. Check this documentation
2. Review container logs
3. Check GitHub Issues
4. Contact support team

---

**Last Updated:** January 2024
