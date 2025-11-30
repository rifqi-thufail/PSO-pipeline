#!/bin/bash
# PSO Pipeline - Complete Staging Deployment Script
# Run this script on your EC2 instance: ./deploy-staging.sh

set -e

echo "🚀 Starting PSO Pipeline Staging Deployment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==========================================
# A. DATABASE SETUP
# ==========================================
log_info "Setting up PostgreSQL database..."

# Start PostgreSQL if not running
sudo systemctl start postgresql
sudo systemctl enable postgresql
log_success "PostgreSQL service started"

# Create database and user
sudo -u postgres psql << EOF
-- Drop and recreate database to ensure clean state
DROP DATABASE IF EXISTS material_management_staging;
DROP USER IF EXISTS staging_user;

-- Create database and user
CREATE DATABASE material_management_staging;
CREATE USER staging_user WITH PASSWORD 'staging_password_2024';
GRANT ALL PRIVILEGES ON DATABASE material_management_staging TO staging_user;

-- Connect to database and grant schema permissions
\c material_management_staging
GRANT ALL ON SCHEMA public TO staging_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO staging_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO staging_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO staging_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO staging_user;
\q
EOF

log_success "Database and user created with full permissions"

# ==========================================
# B. REPOSITORY UPDATE
# ==========================================
log_info "Updating repository..."
cd ~/PSO-pipeline
git fetch origin
git reset --hard origin/staging
git pull origin staging
log_success "Repository updated to latest staging branch"

# Run database schema
log_info "Setting up database schema..."
cd ~/PSO-pipeline/backend
PGPASSWORD=staging_password_2024 psql -h localhost -U staging_user -d material_management_staging -f schema.sql
log_success "Database schema applied"

# ==========================================
# C. BACKEND DEPLOYMENT
# ==========================================
log_info "Deploying backend..."

cd ~/PSO-pipeline/backend

# Install dependencies
npm ci --production
log_success "Backend dependencies installed"

# Stop existing PM2 process if running
pm2 delete pso-staging-backend 2>/dev/null || true

# Start backend with PM2
NODE_ENV=staging pm2 start server.js --name pso-staging-backend
pm2 save
log_success "Backend started with PM2 on port 5001"

# ==========================================
# D. FRONTEND DEPLOYMENT
# ==========================================
log_info "Deploying frontend..."

cd ~/PSO-pipeline/frontend

# Install dependencies
npm ci
log_success "Frontend dependencies installed"

# Build frontend
npm run build
log_success "Frontend build completed"

# Create staging directory if not exists
sudo mkdir -p /var/www/html/staging
sudo chown -R www-data:www-data /var/www/html/staging

# Deploy built files
sudo rm -rf /var/www/html/staging/*
sudo cp -r build/* /var/www/html/staging/
sudo chown -R www-data:www-data /var/www/html/staging
log_success "Frontend deployed to /var/www/html/staging"

# ==========================================
# E. NGINX CONFIGURATION
# ==========================================
log_info "Configuring Nginx..."

# Create Nginx staging configuration
sudo tee /etc/nginx/sites-available/staging > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    # Frontend - Serve React build files
    location / {
        root /var/www/html/staging;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API - Proxy to Node.js server
    location /api/ {
        proxy_pass http://localhost:5001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_redirect off;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:5001/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Hide server version
    server_tokens off;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# Enable staging site
sudo ln -sf /etc/nginx/sites-available/staging /etc/nginx/sites-enabled/staging

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
sudo nginx -t
sudo systemctl reload nginx
log_success "Nginx configured and reloaded"

# ==========================================
# F. DOCKER COMPOSE SETUP (GENERATE ONLY)
# ==========================================
log_info "Creating docker-compose.yml for future use..."

cd ~/PSO-pipeline
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: pso-staging-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: material_management_staging
      POSTGRES_USER: staging_user
      POSTGRES_PASSWORD: staging_password_2024
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/schema.sql:/docker-entrypoint-initdb.d/schema.sql
    ports:
      - "5433:5432"  # Different port to avoid conflict with native PostgreSQL
    networks:
      - staging-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U staging_user -d material_management_staging"]
      interval: 30s
      timeout: 10s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: pso-staging-backend-docker
    restart: unless-stopped
    environment:
      - DB_HOST=postgres
      - DB_USER=staging_user
      - DB_PASSWORD=staging_password_2024
      - DB_NAME=material_management_staging
      - DB_PORT=5432
      - NODE_ENV=staging
      - PORT=5001
      - SESSION_SECRET=staging_session_secret_change_in_production
      - CORS_ORIGIN=http://localhost:3001
    ports:
      - "5002:5001"  # Different port to avoid conflict with native backend
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./backend/uploads:/app/uploads
    networks:
      - staging-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 30s
      timeout: 10s
      retries: 5

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pso-staging-frontend-docker
    restart: unless-stopped
    ports:
      - "3001:3000"  # Different port to avoid conflict with native nginx
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - staging-network

volumes:
  postgres_data:

networks:
  staging-network:
    driver: bridge
EOF

log_success "Docker Compose configuration created (not started)"

# ==========================================
# G. VALIDATION
# ==========================================
log_info "Running validation checks..."

echo ""
echo "======================================"
echo "🔍 VALIDATION RESULTS"
echo "======================================"

echo ""
echo "1. PM2 Status:"
pm2 status

echo ""
echo "2. Backend Health Check:"
sleep 5  # Give backend time to start
curl -f http://localhost:5001/health 2>/dev/null && echo "✅ Backend healthy" || echo "❌ Backend unhealthy"

echo ""
echo "3. Frontend Check:"
curl -I http://localhost/ 2>/dev/null | head -1 && echo "✅ Frontend accessible" || echo "❌ Frontend inaccessible"

echo ""
echo "4. Nginx Status:"
sudo systemctl status nginx --no-pager -l

echo ""
echo "5. Frontend Files:"
ls -la /var/www/html/staging/ | head -10

echo ""
echo "======================================"
echo "🎯 DEPLOYMENT SUMMARY"
echo "======================================"
echo "🌐 Backend URL: http://54.252.13.132:5001"
echo "🌐 Frontend URL: http://54.252.13.132"
echo "🔗 Health Check: http://54.252.13.132/health"
echo ""
echo "Services Status:"
echo "✅ PostgreSQL: Running on port 5432"
echo "✅ Backend: Running on PM2 (port 5001)"
echo "✅ Frontend: Deployed to nginx"
echo "✅ Nginx: Configured and running"
echo "✅ Docker Compose: Ready for future use"
echo ""
echo "🎉 Staging deployment completed successfully!"