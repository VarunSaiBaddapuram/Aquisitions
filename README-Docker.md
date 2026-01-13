# Docker Deployment Guide

This guide explains how to run the Acquisitions API in both development and production environments using Docker with Neon Database integration.

## Overview

The application supports two distinct deployment modes:

- **Development**: Uses Neon Local proxy for ephemeral database branches
- **Production**: Connects directly to Neon Cloud database

## Prerequisites

- Docker and Docker Compose installed
- Neon account with a project created
- Neon API key (get it from [Neon Console](https://console.neon.tech/app/settings/api-keys))

## Quick Start with Setup Scripts

For the fastest setup experience, use the provided setup scripts:

### Windows (PowerShell)
```powershell
# Development environment
.\setup-docker.ps1 dev

# Production environment
.\setup-docker.ps1 prod

# Show help
.\setup-docker.ps1 help
```

### Linux/macOS (Bash)
```bash
# Development environment
./setup-docker.sh dev

# Production environment
./setup-docker.sh prod

# Show help
./setup-docker.sh help
```

The setup scripts will:
- ✅ Check Docker dependencies
- ✅ Create environment files from templates
- ✅ Guide you through configuration
- ✅ Create necessary directories
- ✅ Start the Docker environment
- ✅ Provide helpful next steps

**For manual setup or more control, continue reading the sections below.**

## Development Environment

The development setup uses **Neon Local**, which creates ephemeral database branches that are automatically created when containers start and deleted when they stop.

### Setup

1. **Configure Environment Variables**
   
   Copy and configure the development environment file:
   ```bash
   cp .env.development.example .env.development
   ```

   Update `.env.development` with your Neon credentials:
   ```env
   # Required Neon configuration
   NEON_API_KEY=your_neon_api_key_here
   NEON_PROJECT_ID=your_neon_project_id_here
   PARENT_BRANCH_ID=your_parent_branch_id_here
   
   # Optional: Your Arcjet key for security features
   ARCJET_KEY=your_arcjet_key_here
   ```

2. **Start Development Environment**
   
   ```bash
   # Using npm script (recommended)
   npm run docker:dev
   
   # Or using docker-compose directly
   docker-compose -f docker-compose-dev.yml --env-file .env.development up --build
   ```

3. **Access the Application**
   
   - Application: http://localhost:3000
   - Health check: http://localhost:3000/health
   - Neon Local Database: localhost:5432

### Development Commands

```bash
# Start development environment with logs
npm run docker:dev

# Stop development environment
npm run docker:dev:down

# View logs
npm run docker:dev:logs

# Build development image only
npm run docker:build:dev
```

### How Neon Local Works in Development

- **Ephemeral Branches**: Each time you start the containers, Neon Local creates a fresh database branch
- **Automatic Cleanup**: When containers stop, the ephemeral branch is automatically deleted
- **No Manual Cleanup**: No need to manage database state between development sessions
- **Fresh Start**: Every development session begins with a clean database state

## Production Environment

The production setup connects directly to your Neon Cloud database without using Neon Local.

### Setup

1. **Configure Environment Variables**
   
   Create `.env.production` or set environment variables directly in your deployment system:
   ```env
   # Production database URL from Neon Cloud
   DATABASE_URL=postgres://username:password@ep-xxx-xxx.region.aws.neon.tech/dbname?sslmode=require
   
   # Strong JWT secret (generate a secure random string)
   JWT_SECRET=your-super-secure-jwt-secret-here
   
   # Arcjet key for security features
   ARCJET_KEY=your_arcjet_key_here
   ```

2. **Start Production Environment**
   
   ```bash
   # Using npm script (recommended)
   npm run docker:prod
   
   # Or using docker-compose directly
   docker-compose -f docker-compose-prod.yml --env-file .env.production up -d --build
   ```

### Production Commands

```bash
# Start production environment (detached)
npm run docker:prod

# Stop production environment
npm run docker:prod:down

# View production logs
npm run docker:prod:logs

# Build production image only
npm run docker:build:prod
```

### Production Features

- **Optimized Image**: Multi-stage build with only production dependencies
- **Security Hardening**: Non-root user, dropped capabilities, resource limits
- **Health Checks**: Automatic container health monitoring
- **Logging**: Structured JSON logs with rotation
- **Resource Limits**: CPU and memory constraints for stability
- **Restart Policy**: Automatic restart on failure

## Database Migrations

Run database migrations in both environments:

```bash
# Development
docker-compose -f docker-compose-dev.yml exec app npm run db:generate
docker-compose -f docker-compose-dev.yml exec app npm run db:migrate

# Production  
docker-compose -f docker-compose-prod.yml exec app npm run db:generate
docker-compose -f docker-compose-prod.yml exec app npm run db:migrate
```

## Environment Variables Reference

### Development (.env.development)

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `NODE_ENV` | Environment mode | Yes | `development` |
| `PORT` | Application port | Yes | `3000` |
| `LOG_LEVEL` | Logging level | Yes | `debug` |
| `DATABASE_URL` | Neon Local connection string | Yes | Auto-configured |
| `NEON_API_KEY` | Your Neon API key | Yes | - |
| `NEON_PROJECT_ID` | Your Neon project ID | Yes | - |
| `PARENT_BRANCH_ID` | Parent branch for ephemeral branches | Yes | - |
| `JWT_SECRET` | JWT signing secret | Yes | `dev-secret-...` |
| `ARCJET_KEY` | Arcjet security key | No | - |

### Production (.env.production)

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `NODE_ENV` | Environment mode | Yes | `production` |
| `PORT` | Application port | Yes | `3000` |
| `LOG_LEVEL` | Logging level | Yes | `info` |
| `DATABASE_URL` | Neon Cloud connection string | Yes | `postgres://user:pass@ep-xxx.neon.tech/db` |
| `JWT_SECRET` | Strong JWT secret | Yes | `your-secure-secret` |
| `ARCJET_KEY` | Arcjet security key | Yes | `ajkey_...` |

## Troubleshooting

### Common Issues

1. **Neon Local Connection Failed**
   ```
   Error: connect ECONNREFUSED 127.0.0.1:5432
   ```
   - Ensure `NEON_API_KEY` and `NEON_PROJECT_ID` are correct
   - Check that the Neon Local container is healthy: `docker-compose ps`

2. **Database Migration Errors**
   ```
   Error: relation "users" does not exist
   ```
   - Run migrations: `docker-compose exec app npm run db:migrate`
   - For fresh start: `docker-compose down && docker-compose up --build`

3. **Permission Denied in Production**
   ```
   Error: EACCES: permission denied, mkdir '/app/logs'
   ```
   - This is handled by the Dockerfile, but ensure logs directory exists locally

### Debug Commands

```bash
# Check container status
docker-compose -f docker-compose-dev.yml ps

# Access app container shell
docker-compose -f docker-compose-dev.yml exec app sh

# Check Neon Local logs
docker-compose -f docker-compose-dev.yml logs neon-local

# Test database connection
docker-compose -f docker-compose-dev.yml exec app node -e "
import { db } from '#config/database.js';
console.log('Testing DB connection...');
await db.select().from('users').limit(1);
console.log('Connection successful!');
"
```

## Deployment Strategies

### Local Development
```bash
# Quick start for development
npm run docker:dev
```

### Staging Environment
```bash
# Use production compose with staging environment
docker-compose -f docker-compose-prod.yml --env-file .env.staging up -d
```

### Production Deployment
```bash
# Using environment variables from CI/CD
export DATABASE_URL="postgres://..."
export JWT_SECRET="..."
export ARCJET_KEY="..."

docker-compose -f docker-compose-prod.yml up -d --build
```

## Next Steps

- Set up monitoring and alerting for production
- Implement backup strategies for your Neon database
- Configure SSL certificates for HTTPS in production
- Set up log aggregation for production monitoring
- Consider using Docker Swarm or Kubernetes for orchestration