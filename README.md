# 🎸 StudioBook

**Music Studio Booking Platform**

A full-stack application for booking music studios, managing schedules, and processing payments.

![Laravel](https://img.shields.io/badge/Laravel-11-red)
![React](https://img.shields.io/badge/React-19-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.19-teal)
![PHP](https://img.shields.io/badge/PHP-8.2-purple)
![Node](https://img.shields.io/badge/Node.js-20-green)

---

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Docker Setup](#docker-setup)
- [Manual Setup](#manual-setup)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

---

## ✨ Features

### Customer Features
- 🔍 Browse and search music studios
- 📅 Book studio rooms with real-time availability
- 💳 Secure payment processing (Midtrans/Xendit)
- ⭐ Leave reviews and ratings
- 👥 Create and manage bands
- 🔔 Push notifications
- 🎁 Referral system
- 📱 Mobile app (Flutter)

### Owner Features
- 📊 Dashboard with analytics
- 🏠 Manage studios and rooms
- 📅 Schedule management
- 💰 Revenue reports and exports
- 💲 Dynamic pricing rules
- 📧 Email notifications

### Admin Features
- 📈 Platform-wide analytics
- 👥 User management
- 🏠 Studio verification
- 📅 Booking oversight
- ⚡ Performance monitoring
- 🔔 Real-time alerts
- 📊 Performance comparison reports
- 📧 Automated email reports

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| **Backend API** | Laravel 11, PHP 8.2 |
| **Frontend Web** | React 19, TypeScript, Tailwind CSS |
| **Mobile App** | Flutter 3.19, Dart |
| **Database** | MySQL 8.0 |
| **Cache/Queue** | Redis |
| **Authentication** | Laravel Sanctum |
| **Payment** | Midtrans, Xendit |
| **Push Notifications** | Firebase Cloud Messaging |
| **Containerization** | Docker, Docker Compose |
| **CI/CD** | GitHub Actions |

---

## 📁 Project Structure

```
studiobook/
├── backend/                 # Laravel API
│   ├── app/
│   │   ├── Console/        # Artisan commands
│   │   ├── Exceptions/     # Exception handlers
│   │   ├── Http/           # Controllers, Middleware, Requests
│   │   ├── Mail/           # Email templates
│   │   ├── Models/         # Eloquent models
│   │   ├── Notifications/  # Push notifications
│   │   └── Services/       # Business logic
│   ├── config/             # Configuration files
│   ├── database/           # Migrations, seeders, factories
│   ├── docker/             # Docker configurations
│   ├── public/             # Public assets
│   ├── resources/          # Views, email templates
│   ├── routes/             # API routes
│   ├── storage/            # Logs, cache, uploads
│   └── tests/              # Unit and feature tests
│
├── web/                    # React Frontend
│   ├── src/
│   │   ├── components/     # Reusable components
│   │   ├── hooks/          # Custom React hooks
│   │   ├── layouts/        # Layout components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API services
│   │   └── utils/          # Utility functions
│   └── public/             # Static assets
│
├── mobile/                 # Flutter App
│   ├── lib/
│   │   ├── core/           # Constants, theme, utils
│   │   ├── models/         # Data models
│   │   ├── providers/      # State management
│   │   ├── screens/        # App screens
│   │   ├── services/       # API services
│   │   └── widgets/        # Reusable widgets
│   └── assets/             # Images, icons
│
├── scripts/                # Deployment scripts
├── .github/                # CI/CD workflows
├── docker-compose.yml      # Docker configuration
└── README.md               # This file
```

---

## 📋 Prerequisites

### For Docker Setup (Recommended)
- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)

### For Manual Setup
- [PHP](https://www.php.net/) (8.2+)
- [Composer](https://getcomposer.org/)
- [Node.js](https://nodejs.org/) (20+)
- [MySQL](https://dev.mysql.com/) (8.0+)
- [Redis](https://redis.io/)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.19+)

---

## 🚀 Quick Start

### Option 1: Docker Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/your-username/studiobook.git
cd studiobook

# Run the interactive setup script
./start.sh

# Select option 1 for full setup
```

Or manually:

```bash
# Copy environment file
cp .env.example .env

# Start all services
docker compose up -d

# Wait for services to be ready, then:
docker compose exec api php artisan key:generate
docker compose exec api php artisan migrate --seed
```

### Option 2: Manual Setup

#### Backend (API)

```bash
cd backend

# Install dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate app key
php artisan key:generate

# Configure database in .env
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=studiobook
# DB_USERNAME=root
# DB_PASSWORD=

# Run migrations
php artisan migrate

# Seed database
php artisan db:seed

# Start server
php artisan serve
```

#### Frontend (Web)

```bash
cd web

# Install dependencies
npm install

# Start development server
npm run dev
```

#### Mobile (Flutter)

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

---

## 🐳 Docker Setup

### Services

| Service | Port | Description |
|---------|------|-------------|
| **Web** | 80 | React frontend |
| **API** | 8000 | Laravel backend |
| **MySQL** | 3306 | Database |
| **Redis** | 6379 | Cache & Queue |
| **phpMyAdmin** | 8080 | Database admin |
| **Mailhog** | 8025 | Email testing |

### Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Access API shell
docker compose exec api bash

# Run artisan commands
docker compose exec api php artisan <command>

# Stop all services
docker compose down

# Reset database
docker compose exec api php artisan migrate:fresh --seed
```

### Service URLs

- 🌐 **Web App:** http://localhost
- 🔌 **API:** http://localhost:8000/api/health
- 🗄️ **phpMyAdmin:** http://localhost:8080
- 📧 **Mailhog:** http://localhost:8025

---

## 📚 API Documentation

### Base URL

```
http://localhost:8000/api/v1
```

### Authentication

```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@studiobook.com","password":"password"}'

# Use token in requests
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Endpoints

| Category | Endpoint | Method | Auth |
|----------|----------|--------|------|
| **Auth** | `/auth/login` | POST | No |
| | `/auth/register` | POST | No |
| | `/auth/me` | GET | Yes |
| **Studios** | `/studios` | GET | No |
| | `/studios/{slug}` | GET | No |
| **Bookings** | `/bookings` | GET | Yes |
| | `/bookings` | POST | Yes |
| **Payments** | `/payments` | POST | Yes |
| **Performance** | `/admin/performance` | GET | Admin |
| | `/admin/performance/alerts` | GET | Admin |

For complete API documentation, see [backend/docs/api.md](backend/docs/api.md)

---

## 🧪 Testing

### Backend Tests

```bash
cd backend

# Run all tests
php artisan test

# Run with coverage
php artisan test --coverage

# Run specific test suite
php artisan test --testsuite=Unit
php artisan test --testsuite=Feature
```

### Frontend Tests

```bash
cd web

# Run lint
npm run lint

# Build for production
npm run build
```

### API Tests

```bash
cd backend

# Start server first
php artisan serve

# Run API test suite
./tests/api_test.sh http://localhost:8000/api/v1

# Run performance tests
./tests/performance_test.sh http://localhost:8000/api/v1
```

### Flutter Tests

```bash
cd mobile

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 🚢 Deployment

### Production Setup

1. **Server Requirements:**
   - Ubuntu 22.04 LTS
   - Docker & Docker Compose
   - Nginx (or use Docker)
   - SSL certificate

2. **Deploy:**

```bash
# Clone repository
git clone https://github.com/your-username/studiobook.git
cd studiobook

# Configure environment
cp .env.example .env.production
nano .env.production

# Start services
docker compose -f docker-compose.prod.yml up -d

# Run migrations
docker compose exec api php artisan migrate --force

# Cache configuration
docker compose exec api php artisan config:cache
docker compose exec api php artisan route:cache
docker compose exec api php artisan view:cache
```

### Environment Variables

See [.env.example](.env.example) for all configuration options.

Key variables:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE=studiobook
DB_USERNAME=studiobook
DB_PASSWORD=your-secure-password

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailgun.org
MAIL_PORT=587
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=your-password
```

---

## 🔧 Available Commands

### Artisan Commands

```bash
# Performance Reports
php artisan performance:send-reports --type=weekly
php artisan performance:weekly-report

# Database
php artisan migrate
php artisan db:seed
php artisan migrate:fresh --seed

# Cache
php artisan config:cache
php artisan route:cache
php artisan cache:clear
```

### NPM Scripts

```bash
npm run dev      # Start development server
npm run build    # Build for production
npm run lint     # Run linter
```

---

## 👥 Test Accounts

| Role | Email | Password |
|------|-------|----------|
| **Super Admin** | admin@studiobook.com | password |
| **Studio Owner** | owner@studiobook.com | password |
| **Customer** | customer@studiobook.com | password |

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- **PHP:** PSR-12 (Laravel Pint)
- **TypeScript:** ESLint
- **Flutter:** Flutter lints

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

- 📧 Email: support@studiobook.com
- 📖 Documentation: [docs.studiobook.com](https://docs.studiobook.com)
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/studiobook/issues)

---

## 🙏 Acknowledgments

- [Laravel](https://laravel.com/)
- [React](https://react.dev/)
- [Flutter](https://flutter.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Vite](https://vitejs.dev/)
