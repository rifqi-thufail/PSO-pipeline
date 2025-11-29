#!/bin/bash
# PSO Pipeline - Staging EC2 Setup Script
# Run this script on your Ubuntu EC2 instance to prepare staging environment
# Usage: curl -o setup-staging-ec2.sh [URL] && chmod +x setup-staging-ec2.sh && ./setup-staging-ec2.sh

set -e

echo "🚀 Starting PSO Pipeline Staging EC2 Setup..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
echo "📦 Installing Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
echo "✅ Node.js version: $(node --version)"
echo "✅ NPM version: $(npm --version)"

# Install PM2 globally
echo "📦 Installing PM2..."
sudo npm install -g pm2

# Install PostgreSQL
echo "📦 Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create staging database
echo "🗄️ Setting up staging database..."
sudo -u postgres psql << EOF
CREATE DATABASE material_management_staging;
CREATE USER staging_user WITH PASSWORD 'staging_password_2024';
GRANT ALL PRIVILEGES ON DATABASE material_management_staging TO staging_user;
\q
EOF

echo "✅ Database 'material_management_staging' created"

# Install Nginx
echo "📦 Installing Nginx..."
sudo apt install -y nginx

# Create staging directory structure
echo "📁 Creating staging directories..."
sudo mkdir -p /var/www/html/staging
sudo mkdir -p /home/ubuntu/pso-pipeline-staging

# Set proper permissions
sudo chown -R ubuntu:ubuntu /home/ubuntu/pso-pipeline-staging
sudo chown -R www-data:www-data /var/www/html/staging

# Create Nginx staging configuration
echo "⚙️ Creating Nginx staging configuration..."
sudo tee /etc/nginx/sites-available/staging > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;  # Replace with your staging domain if you have one
    
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
echo "🔗 Enabling Nginx staging site..."
sudo ln -sf /etc/nginx/sites-available/staging /etc/nginx/sites-enabled/staging

# Remove default Nginx site (optional, comment out if you want to keep it)
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure UFW firewall (optional but recommended)
echo "🔒 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# Clone the staging repository
echo "📦 Cloning staging repository..."
cd /home/ubuntu
git clone -b staging https://github.com/rifqi-thufail/PSO-pipeline.git pso-pipeline-staging
cd pso-pipeline-staging

# Create staging environment file
echo "⚙️ Creating staging environment file..."
cp backend/.env.staging backend/.env

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm ci --production

# Run database migrations/schema setup
echo "🗄️ Setting up database schema..."
PGPASSWORD=staging_password_2024 psql -h localhost -U staging_user -d material_management_staging -f schema.sql

# Install frontend dependencies and build
echo "📦 Building frontend..."
cd ../frontend
npm ci
npm run build

# Copy frontend build to nginx directory
echo "📁 Deploying frontend build..."
sudo cp -r build/* /var/www/html/staging/

# Start backend with PM2
echo "🚀 Starting backend with PM2..."
cd ../backend
pm2 start server.js --name pso-staging-backend
pm2 save
pm2 startup

# Restart services
echo "🔄 Restarting services..."
sudo systemctl restart nginx

# Health check
echo "🏥 Running health check..."
sleep 5
curl -f http://localhost:5001/health || echo "⚠️ Backend health check failed - check PM2 logs"

# Display status
echo ""
echo "🎉 STAGING EC2 SETUP COMPLETE!"
echo ""
echo "📊 Status Summary:"
echo "├─ Node.js: $(node --version)"
echo "├─ PM2: $(pm2 --version)"
echo "├─ PostgreSQL: Running"
echo "├─ Database: material_management_staging created"
echo "├─ Nginx: Running"
echo "├─ Frontend: Deployed to /var/www/html/staging"
echo "└─ Backend: Running on PM2 as 'pso-staging-backend'"
echo ""
echo "🔧 Useful commands:"
echo "├─ Check PM2 status: pm2 status"
echo "├─ Check PM2 logs: pm2 logs pso-staging-backend"
echo "├─ Restart backend: pm2 restart pso-staging-backend"
echo "├─ Check Nginx: sudo systemctl status nginx"
echo "├─ Check Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "└─ Test backend: curl http://localhost:5001/health"
echo ""
echo "🌐 Your staging application should be accessible via your EC2 public IP"
echo "📝 Don't forget to configure GitHub secrets for automated deployment!"