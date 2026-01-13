# Docker Setup Script for Windows (PowerShell)
# This script helps you set up the Docker environment for the Acquisitions API

param(
    [Parameter(Position=0)]
    [ValidateSet("dev", "prod", "help")]
    [string]$Environment = "help"
)

# Colors for output
$Red = [System.ConsoleColor]::Red
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue
$White = [System.ConsoleColor]::White

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Show-Help {
    Write-ColorOutput $Blue @"

🐳 Docker Setup Script for Acquisitions API
==========================================

Usage: .\setup-docker.ps1 [dev|prod]

Commands:
  dev   - Set up development environment with Neon Local
  prod  - Set up production environment with Neon Cloud
  help  - Show this help message

Examples:
  .\setup-docker.ps1 dev   # Setup development environment
  .\setup-docker.ps1 prod  # Setup production environment

"@
}

function Test-Dependencies {
    Write-ColorOutput $Blue "🔍 Checking dependencies..."
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>$null
        Write-ColorOutput $Green "✅ Docker found: $dockerVersion"
    } catch {
        Write-ColorOutput $Red "❌ Docker not found. Please install Docker Desktop."
        exit 1
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        Write-ColorOutput $Green "✅ Docker Compose found: $composeVersion"
    } catch {
        Write-ColorOutput $Red "❌ Docker Compose not found. Please install Docker Desktop with Compose."
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info 2>$null | Out-Null
        Write-ColorOutput $Green "✅ Docker daemon is running"
    } catch {
        Write-ColorOutput $Red "❌ Docker daemon is not running. Please start Docker Desktop."
        exit 1
    }
}

function Setup-DevEnvironment {
    Write-ColorOutput $Blue @"

🛠️ Setting up Development Environment
====================================

This will set up:
- Neon Local proxy for ephemeral database branches
- Development container with hot reload
- Debug logging enabled

"@
    
    # Check if .env.development exists
    if (-not (Test-Path ".env.development")) {
        Write-ColorOutput $Yellow "⚠️ .env.development not found. Creating from template..."
        
        $envContent = @"
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
"@
        $envContent | Out-File -FilePath ".env.development" -Encoding UTF8
        Write-ColorOutput $Green "✅ Created .env.development template"
    }
    
    # Prompt for Neon credentials
    Write-ColorOutput $Yellow @"

📝 Please update .env.development with your Neon credentials:

1. NEON_API_KEY - Get from https://console.neon.tech/app/settings/api-keys
2. NEON_PROJECT_ID - Found in your Neon project settings
3. PARENT_BRANCH_ID - Your main branch ID (usually 'main' or 'br-xxx')

"@
    
    $continue = Read-Host "Have you updated .env.development? (y/n)"
    if ($continue.ToLower() -ne "y") {
        Write-ColorOutput $Red "Please update .env.development and run the script again."
        exit 1
    }
    
    # Create logs directory
    if (-not (Test-Path "logs")) {
        New-Item -ItemType Directory -Name "logs" | Out-Null
        Write-ColorOutput $Green "✅ Created logs directory"
    }
    
    # Build and start development environment
    Write-ColorOutput $Blue "🚀 Starting development environment..."
    Write-ColorOutput $Yellow "This may take a few minutes on first run..."
    
    try {
        docker-compose -f docker-compose-dev.yml --env-file .env.development up --build -d
        
        Write-ColorOutput $Green @"

🎉 Development environment started successfully!

Access points:
- Application: http://localhost:3000
- Health check: http://localhost:3000/health
- API endpoint: http://localhost:3000/api

Useful commands:
- View logs: docker-compose -f docker-compose-dev.yml logs -f
- Stop: docker-compose -f docker-compose-dev.yml down
- Restart: docker-compose -f docker-compose-dev.yml restart

"@
    } catch {
        Write-ColorOutput $Red "❌ Failed to start development environment. Check the logs above."
        exit 1
    }
}

function Setup-ProdEnvironment {
    Write-ColorOutput $Blue @"

🏭 Setting up Production Environment
===================================

This will set up:
- Production-optimized container
- Direct connection to Neon Cloud
- Security hardening enabled

"@
    
    # Check if .env.production exists
    if (-not (Test-Path ".env.production")) {
        Write-ColorOutput $Yellow "⚠️ .env.production not found. Creating from template..."
        
        $envContent = @"
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
"@
        $envContent | Out-File -FilePath ".env.production" -Encoding UTF8
        Write-ColorOutput $Green "✅ Created .env.production template"
    }
    
    Write-ColorOutput $Yellow @"

📝 Please update .env.production with your production credentials:

1. DATABASE_URL - Your Neon Cloud connection string
2. JWT_SECRET - A strong, secure JWT secret
3. ARCJET_KEY - Your Arcjet API key

⚠️ SECURITY WARNING: Never commit .env.production to version control!

"@
    
    $continue = Read-Host "Have you updated .env.production? (y/n)"
    if ($continue.ToLower() -ne "y") {
        Write-ColorOutput $Red "Please update .env.production and run the script again."
        exit 1
    }
    
    # Create logs directory
    if (-not (Test-Path "logs")) {
        New-Item -ItemType Directory -Name "logs" | Out-Null
        Write-ColorOutput $Green "✅ Created logs directory"
    }
    
    # Build and start production environment
    Write-ColorOutput $Blue "🚀 Starting production environment..."
    Write-ColorOutput $Yellow "This may take a few minutes on first run..."
    
    try {
        docker-compose -f docker-compose-prod.yml --env-file .env.production up --build -d
        
        Write-ColorOutput $Green @"

🎉 Production environment started successfully!

Access points:
- Application: http://localhost:3000
- Health check: http://localhost:3000/health

Useful commands:
- View logs: docker-compose -f docker-compose-prod.yml logs -f
- Stop: docker-compose -f docker-compose-prod.yml down
- Restart: docker-compose -f docker-compose-prod.yml restart

📊 Monitor your application and check logs regularly in production!

"@
    } catch {
        Write-ColorOutput $Red "❌ Failed to start production environment. Check the logs above."
        exit 1
    }
}

# Main script logic
switch ($Environment) {
    "help" { 
        Show-Help 
    }
    "dev" { 
        Test-Dependencies
        Setup-DevEnvironment 
    }
    "prod" { 
        Test-Dependencies
        Setup-ProdEnvironment 
    }
    default { 
        Show-Help 
    }
}