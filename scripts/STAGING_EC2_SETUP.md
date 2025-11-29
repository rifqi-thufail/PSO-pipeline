# PSO Pipeline - Staging EC2 Configuration Files

## 1. Nginx Staging Configuration
**File: `/etc/nginx/sites-available/staging`**

```nginx
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
```

## 2. Enable Nginx Site Command
```bash
# Create symlink to enable the staging site
sudo ln -sf /etc/nginx/sites-available/staging /etc/nginx/sites-enabled/staging

# Remove default site (optional)
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

## 3. Directory Structure on EC2
```
/home/ubuntu/pso-pipeline-staging/     # Application code
├── backend/
│   ├── server.js
│   ├── .env.staging → .env
│   └── package.json
└── frontend/
    └── build/                         # Built React app

/var/www/html/staging/                 # Nginx serves from here
├── index.html
├── static/
└── [React build files]
```

## 4. Database Configuration
```sql
-- Database: material_management_staging
-- User: staging_user
-- Password: staging_password_2024
```

## 5. PM2 Process
```bash
# Process name: pso-staging-backend
# Command: pm2 start server.js --name pso-staging-backend
# Working directory: /home/ubuntu/pso-pipeline-staging/backend
```

## 6. Firewall Rules (UFW)
```bash
sudo ufw allow ssh      # Port 22
sudo ufw allow http     # Port 80
sudo ufw allow https    # Port 443
sudo ufw --force enable
```

## 7. GitHub Secrets Required
Add these to your GitHub repository secrets:

- **STAGING_EC2_HOST**: Your EC2 instance public IP or domain
- **STAGING_EC2_USER**: `ubuntu` (default Ubuntu AMI user)
- **STAGING_SSH_PRIVATE_KEY**: Your EC2 instance private SSH key content

## 8. Verification Commands
```bash
# Check all services
sudo systemctl status nginx
pm2 status
curl http://localhost:5001/health

# Check logs
pm2 logs pso-staging-backend
sudo tail -f /var/log/nginx/error.log
```

## 9. Workflow Alignment
This configuration matches the `staging-deploy.yml` workflow:
- ✅ Application path: `/opt/pso-staging` → Updated to `/home/ubuntu/pso-pipeline-staging`
- ✅ Frontend path: `/var/www/pso-staging` → Updated to `/var/www/html/staging`
- ✅ Backend port: 5001
- ✅ PM2 process name: `pso-staging-backend`
- ✅ Database: `material_management_staging`
- ✅ Environment file: `.env.staging`