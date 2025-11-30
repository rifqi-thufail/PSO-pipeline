#!/bin/bash
set -e

echo "🚀 Starting Simple PSO Pipeline Deployment (No Docker)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 1. Install Node.js if not present
log_info "Installing Node.js and dependencies..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || true
sudo apt install -y nodejs npm pm2 postgresql postgresql-contrib nginx unzip
log_success "System packages installed"

# 2. Setup PostgreSQL
log_info "Setting up PostgreSQL database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres psql << 'PSQL_EOF'
DROP DATABASE IF EXISTS material_management_staging;
DROP USER IF EXISTS staging_user;
CREATE DATABASE material_management_staging;
CREATE USER staging_user WITH PASSWORD 'staging_password_2024';
GRANT ALL PRIVILEGES ON DATABASE material_management_staging TO staging_user;
\q
PSQL_EOF
log_success "Database configured"

# 3. Clean up old deployment
log_info "Cleaning up old deployment..."
pm2 delete all 2>/dev/null || true
sudo rm -rf /var/www/html/* /home/ubuntu/PSO-pipeline
log_success "Old deployment cleaned"

# 4. Create project structure and extract files
log_info "Extracting application files..."
mkdir -p /home/ubuntu/PSO-pipeline/backend /home/ubuntu/PSO-pipeline/frontend
cd /home/ubuntu/PSO-pipeline

# Extract backend
if [ -f "/home/ubuntu/backend.zip" ]; then
    cd backend
    unzip -o /home/ubuntu/backend.zip
    cd ..
    log_success "Backend extracted"
else
    log_error "backend.zip not found!"
    exit 1
fi

# Extract frontend
if [ -f "/home/ubuntu/build.zip" ]; then
    cd frontend
    unzip -o /home/ubuntu/build.zip
    cd ..
    log_success "Frontend extracted"
else
    log_error "build.zip not found!"
    exit 1
fi

# 5. Setup database schema
log_info "Setting up database schema..."
cd backend
PGPASSWORD=staging_password_2024 psql -h localhost -U staging_user -d material_management_staging -f schema.sql
log_success "Database schema applied"

# 6. Install backend dependencies and start
log_info "Installing backend dependencies..."
npm install
log_success "Backend dependencies installed"

log_info "Starting backend with PM2..."
NODE_ENV=production pm2 start server.js --name pso-backend
pm2 save
pm2 startup
log_success "Backend started on PM2"

# 7. Deploy frontend to nginx
log_info "Deploying frontend..."
sudo mkdir -p /var/www/html
sudo cp -r ../frontend/build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
log_success "Frontend deployed"

# 8. Configure nginx
log_info "Configuring nginx..."
sudo tee /etc/nginx/sites-available/default > /dev/null << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html;
    server_name _;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:5001/health;
        proxy_set_header Host $host;
    }
}
NGINX_EOF

sudo systemctl restart nginx
sudo systemctl enable nginx
log_success "Nginx configured and started"

# 9. Final verification
log_info "Verifying deployment..."
echo ""
echo "=== SERVICE STATUS ==="
echo "PM2 processes:"
pm2 list
echo ""
echo "Nginx status:"
sudo systemctl is-active nginx && echo "✅ Nginx running" || echo "❌ Nginx failed"
echo ""
echo "Database connection:"
PGPASSWORD=staging_password_2024 psql -h localhost -U staging_user -d material_management_staging -c "SELECT current_database();" && echo "✅ Database OK" || echo "❌ Database failed"
echo ""
echo "=== ENDPOINT TESTS ==="
sleep 5
curl -f http://localhost:5001/health 2>/dev/null && echo "✅ Backend healthy" || echo "❌ Backend unhealthy"
curl -I http://localhost/ 2>/dev/null | head -1 && echo "✅ Frontend accessible" || echo "❌ Frontend inaccessible"

# 10. Cleanup
rm -f /home/ubuntu/backend.zip /home/ubuntu/build.zip

echo ""
echo "🎉 DEPLOYMENT COMPLETED!"
echo ""
echo "🌐 Your application URLs:"
echo "📱 Frontend: http://13.212.157.243"
echo "🔧 Backend API: http://13.212.157.243/api"
echo "💚 Health Check: http://13.212.157.243/health"
echo ""
echo "🔧 Management Commands:"
echo "  pm2 list           - View processes"
echo "  pm2 logs pso-backend - View backend logs"
echo "  pm2 restart pso-backend - Restart backend"
echo "  sudo systemctl restart nginx - Restart frontend"
echo ""
echo "🚀 Ready to serve traffic!"