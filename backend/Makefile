.PHONY: help setup start stop restart shell migrate seed test logs clean

# Default target
help: ## Show this help message
	@echo "StudioBook Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup
setup: ## Initial project setup (Docker)
	@./setup.sh

# Docker commands
start: ## Start all containers
	docker compose up -d

stop: ## Stop all containers
	docker compose down

restart: ## Restart all containers
	docker compose restart

logs: ## View container logs
	docker compose logs -f

logs-api: ## View API logs
	docker compose logs -f api

logs-web: ## View Web logs
	docker compose logs -f web

logs-nginx: ## View Nginx logs
	docker compose logs -f nginx

# Shell access
shell: ## Access API container shell
	docker compose exec api bash

shell-web: ## Access Web container shell
	docker compose exec web sh

shell-mysql: ## Access MySQL shell
	docker compose exec mysql mysql -u studiobook -psecret studiobook

# Database commands
migrate: ## Run database migrations
	docker compose exec api php artisan migrate

migrate-fresh: ## Fresh migration (drop all tables)
	docker compose exec api php artisan migrate:fresh

seed: ## Seed database
	docker compose exec api php artisan db:seed

migrate-seed: ## Fresh migration + seed
	docker compose exec api php artisan migrate:fresh --seed

# Development commands
cache-clear: ## Clear all caches
	docker compose exec api php artisan cache:clear
	docker compose exec api php artisan config:clear
	docker compose exec api php artisan route:clear
	docker compose exec api php artisan view:clear

optimize: ## Optimize application
	docker compose exec api php artisan config:cache
	docker compose exec api php artisan route:cache
	docker compose exec api php artisan view:cache

# Testing
test: ## Run all tests
	docker compose exec api php artisan test

test-unit: ## Run unit tests
	docker compose exec api php artisan test --testsuite=Unit

test-feature: ## Run feature tests
	docker compose exec api php artisan test --testsuite=Feature

test-api: ## Run API tests
	docker compose exec api ./tests/api_test.sh http://localhost:8000/api/v1

test-quick: ## Run quick API test
	docker compose exec api ./tests/quick_test.sh http://localhost:8000/api/v1

# Performance testing
perf-test: ## Run performance tests
	docker compose exec api ./tests/performance_test.sh http://localhost:8000/api/v1

load-test: ## Run load tests
	docker compose exec api ./tests/load_test.sh http://localhost:8000/api/v1

stress-test: ## Run stress tests
	docker compose exec api ./tests/stress_test.sh http://localhost:8000/api/v1

db-perf-test: ## Run database performance tests
	docker compose exec api ./tests/db_performance_test.sh http://localhost:8000/api/v1

# Build commands
build: ## Build Docker images
	docker compose build

build-no-cache: ## Build without cache
	docker compose build --no-cache

# Clean commands
clean: ## Stop containers and remove volumes
	docker compose down -v

clean-all: ## Stop containers, remove volumes and images
	docker compose down -v --rmi all

# Production commands
deploy-staging: ## Deploy to staging server
	@echo "Deploying to staging..."
	@# Add deployment commands here

deploy-production: ## Deploy to production server
	@echo "Deploying to production..."
	@# Add deployment commands here

# Status
status: ## Show container status
	docker compose ps

stats: ## Show container resource usage
	docker compose stats
