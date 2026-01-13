#!/bin/bash
# Docker Setup Script for Unix/Linux/macOS
# This script helps you set up the Docker environment for the Acquisitions API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_help() {
    echo -e "${BLUE}"
    cat << 'EOF'

🐳 Docker Setup Script for Acquisitions API
==========================================

Usage: ./setup-docker.sh [dev|prod]

Commands:
  dev   - Set up development environment with Neon Local
  prod  - Set up production environment with Neon Cloud
  help  - Show this help message

Examples:
  ./setup-docker.sh dev   # Setup development environment
  ./setup-docker.sh prod  # Setup production environment

EOF
    echo -e "${NC}"
}

check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo -e "${GREEN}✅ Docker found: $DOCKER_VERSION${NC}"
    else
        echo -e "${RED}❌ Docker not found. Please install Docker.${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        echo -e "${GREEN}✅ Docker Compose found: $COMPOSE_VERSION${NC}"
    else
        echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose.${NC}"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        echo -e "${GREEN}✅ Docker daemon is running${NC}"
    else
        echo -e "${RED}❌ Docker daemon is not running. Please start Docker.${NC}"
        exit 1
    fi
}

setup_dev_environment() {
    echo -e "${BLUE}"
    cat << 'EOF'

🛠️ Setting up Development Environment
====================================

This will set up:
- Neon Local proxy for ephemeral database branches
- Development container with hot reload
- Debug logging enabled

EOF
    echo -e "${NC}"
    
    # Check if .env.development exists
    if [ ! -f ".env.development" ]; then
        echo -e "${YELLOW}⚠️ .env.development not found. Creating from template...${NC}"
        
        cat > .env.development << 'EOF'
# Development Environment Configuration
# This file is used when running with docker-compose-dev.yml

# Application Configuration
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Database Configuration (Neon Local)
# This connects to the Neon Local proxy container
DATABASE_URL=postgres://neon:npg@neon-local:5432/neondb?sslmode=require

# Neon Local Configuration
# Replace these with your actual Neon credentials
NEON_API_KEY=your_neon_api_key_here
NEON_PROJECT_ID=your_neon_project_id_here
PARENT_BRANCH_ID=your_parent_branch_id_here

# JWT Configuration
JWT_SECRET=dev-secret-change-in-production-please

# Arcjet Configuration
ARCJET_KEY=your_arcjet_key_here
EOF
        echo -e "${GREEN}✅ Created .env.development template${NC}"
    fi
    
    # Prompt for Neon credentials
    echo -e "${YELLOW}"
    cat << 'EOF'

📝 Please update .env.development with your Neon credentials:

1. NEON_API_KEY - Get from https://console.neon.tech/app/settings/api-keys
2. NEON_PROJECT_ID - Found in your Neon project settings
3. PARENT_BRANCH_ID - Your main branch ID (usually 'main' or 'br-xxx')

EOF
    echo -e "${NC}"
    
    read -p "Have you updated .env.development? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Please update .env.development and run the script again.${NC}"
        exit 1
    fi
    
    # Create logs directory
    if [ ! -d "logs" ]; then
        mkdir -p logs
        echo -e "${GREEN}✅ Created logs directory${NC}"
    fi
    
    # Build and start development environment
    echo -e "${BLUE}🚀 Starting development environment...${NC}"
    echo -e "${YELLOW}This may take a few minutes on first run...${NC}"
    
    if docker-compose -f docker-compose-dev.yml --env-file .env.development up --build -d; then
        echo -e "${GREEN}"
        cat << 'EOF'

🎉 Development environment started successfully!

Access points:
- Application: http://localhost:3000
- Health check: http://localhost:3000/health
- API endpoint: http://localhost:3000/api

Useful commands:
- View logs: docker-compose -f docker-compose-dev.yml logs -f
- Stop: docker-compose -f docker-compose-dev.yml down
- Restart: docker-compose -f docker-compose-dev.yml restart

EOF
        echo -e "${NC}"
    else
        echo -e "${RED}❌ Failed to start development environment. Check the logs above.${NC}"
        exit 1
    fi
}

setup_prod_environment() {
    echo -e "${BLUE}"
    cat << 'EOF'

🏭 Setting up Production Environment
===================================

This will set up:
- Production-optimized container
- Direct connection to Neon Cloud
- Security hardening enabled

EOF
    echo -e "${NC}"
    
    # Check if .env.production exists
    if [ ! -f ".env.production" ]; then
        echo -e "${YELLOW}⚠️ .env.production not found. Creating from template...${NC}"
        
        cat > .env.production << 'EOF'
# Production Environment Configuration
# This file is used when running with docker-compose-prod.yml

# Application Configuration
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database Configuration (Neon Cloud)
# This should be your actual Neon Cloud database URL
# Format: postgres://username:password@ep-xxx-xxx.region.aws.neon.tech/dbname?sslmode=require
DATABASE_URL=your_neon_cloud_url_here

# JWT Configuration
# Use a strong secret in production
JWT_SECRET=your_super_secure_jwt_secret_here

# Arcjet Configuration
ARCJET_KEY=your_arcjet_key_here

# Additional Production Settings
# Add any other production-specific environment variables here
EOF
        echo -e "${GREEN}✅ Created .env.production template${NC}"
    fi
    
    echo -e "${YELLOW}"
    cat << 'EOF'

📝 Please update .env.production with your production credentials:

1. DATABASE_URL - Your Neon Cloud connection string
2. JWT_SECRET - A strong, secure JWT secret
3. ARCJET_KEY - Your Arcjet API key

⚠️ SECURITY WARNING: Never commit .env.production to version control!

EOF
    echo -e "${NC}"
    
    read -p "Have you updated .env.production? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Please update .env.production and run the script again.${NC}"
        exit 1
    fi
    
    # Create logs directory
    if [ ! -d "logs" ]; then
        mkdir -p logs
        echo -e "${GREEN}✅ Created logs directory${NC}"
    fi
    
    # Build and start production environment
    echo -e "${BLUE}🚀 Starting production environment...${NC}"
    echo -e "${YELLOW}This may take a few minutes on first run...${NC}"
    
    if docker-compose -f docker-compose-prod.yml --env-file .env.production up --build -d; then
        echo -e "${GREEN}"
        cat << 'EOF'

🎉 Production environment started successfully!

Access points:
- Application: http://localhost:3000
- Health check: http://localhost:3000/health

Useful commands:
- View logs: docker-compose -f docker-compose-prod.yml logs -f
- Stop: docker-compose -f docker-compose-prod.yml down
- Restart: docker-compose -f docker-compose-prod.yml restart

📊 Monitor your application and check logs regularly in production!

EOF
        echo -e "${NC}"
    else
        echo -e "${RED}❌ Failed to start production environment. Check the logs above.${NC}"
        exit 1
    fi
}

# Main script logic
case "${1:-help}" in
    "dev")
        check_dependencies
        setup_dev_environment
        ;;
    "prod")
        check_dependencies
        setup_prod_environment
        ;;
    "help"|*)
        print_help
        ;;
esac