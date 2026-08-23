# StudioBook Docker Setup

Complete Docker development environment for StudioBook.

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) 20.10+
- [Docker Compose](https://docs.docker.com/compose/install/) 2.0+

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/your-repo/studio-book.git
cd studio-book

# Run setup script
./backend/setup.sh

# Or using Make
cd backend
make setup
```

## 🐳 Services

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| **Web** | 80 | http://localhost | React frontend |
| **API** | 8000 | http://localhost:8000 | Laravel backend |
| **phpMyAdmin** | 8080 | http://localhost:8080 | Database admin |
| **Mailhog** | 8025 | http://localhost:8025 | Email testing |
| **MySQL** | 3306 | localhost:3306 | Database |
| **Redis** | 6379 | localhost:6379 | Cache/Queue |

## 📁 Project Structure

```
studio-book/
├── backend/              # Laravel API
│   ├── Dockerfile        # PHP-FPM image
│   ├── docker-compose.yml # Backend services
│   └── ...
├── web/                  # React Frontend
│   ├── Dockerfile        # Nginx + Static build
│   ├── nginx.conf        # Nginx configuration
│   └── ...
├── mobile/               # Flutter App
├── docker-compose.yml    # Root compose (all services)
└── Makefile              # Development commands
```

## 🛠️ Available Commands

### Using Make (Recommended)

```bash
cd backend

# Setup
make setup              # Initial setup
make start              # Start all containers
make stop               # Stop all containers
make restart            # Restart all containers

# Development
make shell              # Access API container
make shell-web          # Access Web container
make shell-mysql        # Access MySQL shell

# Database
make migrate            # Run migrations
make migrate-fresh      # Fresh migration
make seed               # Seed database
make migrate-seed       # Fresh migration + seed

# Testing
make test               # Run all tests
make test-unit          # Run unit tests
make test-feature       # Run feature tests
make test-api           # Run API tests
make test-quick         # Run quick API test

# Performance
make perf-test          # Run performance tests
make load-test          # Run load tests
make stress-test        # Run stress tests
make db-perf-test       # Run database performance tests

# Build
make build              # Build Docker images
make build-no-cache     # Build without cache

# Clean
make clean              # Remove containers and volumes
make clean-all          # Remove everything

# Status
make status             # Show container status
make stats              # Show resource usage
```

### Using Docker Compose Directly

```bash
cd studio-book

# Start all services
docker compose up -d

# Start specific service
docker compose up -d api
docker compose up -d web
docker compose up -d mysql

# View logs
docker compose logs -f
docker compose logs -f api
docker compose logs -f web

# Access container
docker compose exec api bash
docker compose exec web sh

# Run commands
docker compose exec api php artisan migrate
docker compose exec api php artisan db:seed
docker compose exec api php artisan test
```

## 🔧 Configuration

### Environment Variables

Backend environment is configured in `backend/.env`:

```env
APP_NAME=StudioBook
APP_ENV=local
APP_KEY=base64:...
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=studiobook
DB_USERNAME=studiobook
DB_PASSWORD=secret

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
REDIS_HOST=redis
```

### Nginx Configuration

Web frontend uses custom Nginx config (`web/nginx.conf`):

- Gzip compression enabled
- Static asset caching (1 year)
- HTML no-cache headers
- Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- API proxy to backend service

## 🧪 Testing

### Run Tests in Docker

```bash
# All tests
make test

# Unit tests only
make test-unit

# Feature tests only
make test-feature

# API tests (starts server and runs curl tests)
make test-api

# Quick smoke test
make test-quick
```

### Run Tests Locally (without Docker)

```bash
# Backend tests
cd backend
php artisan test

# API tests
./tests/api_test.sh http://localhost:8000/api/v1

# Performance tests
./tests/performance_test.sh http://localhost:8000/api/v1
```

## 📊 Monitoring

### Container Status

```bash
make status              # Container status
make stats               # Resource usage
docker compose ps        # List containers
docker compose top       # Container processes
```

### Logs

```bash
make logs                # All logs
make logs-api            # API logs
make logs-web            # Web logs
docker compose logs -f --tail=100  # Last 100 lines
```

## 🐛 Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs api
docker compose logs nginx

# Rebuild container
docker compose build --no-cache api
docker compose up -d api
```

### Database connection refused

```bash
# Check MySQL is running
docker compose ps mysql

# Check MySQL logs
docker compose logs mysql

# Restart MySQL
docker compose restart mysql
```

### Port already in use

```bash
# Find process using port
lsof -i :80
lsof -i :8000
lsof -i :3306

# Stop conflicting service
sudo systemctl stop apache2
sudo systemctl stop mysql
```

### Permission issues

```bash
# Fix storage permissions
docker compose exec api chmod -R 775 storage bootstrap/cache
docker compose exec api chown -R www-data:www-data storage bootstrap/cache
```

## 🚀 Production Deployment

### Build Production Images

```bash
# Build optimized images
docker compose -f docker-compose.prod.yml build

# Or use CI/CD pipeline
# The GitHub Actions workflow handles this automatically
```

### Deploy to Server

```bash
# Pull images
docker compose pull

# Deploy
docker compose up -d --remove-orphans

# Run migrations
docker compose exec api php artisan migrate --force

# Cache configs
docker compose exec api php artisan config:cache
docker compose exec api php artisan route:cache
docker compose exec api php artisan view:cache
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Laravel Docker](https://laravel.com/docs/deployment#docker)
- [React Docker](https://create-react-app.com/docs/deployment)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Test with Docker: `make test`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
