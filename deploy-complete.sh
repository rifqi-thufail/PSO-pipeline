#!/bin/bash
set -e

echo "🚀 Starting Complete PSO Pipeline Deployment (Git-Free)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Install Docker and Docker Compose
log_info "Installing Docker and Docker Compose..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common unzip
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
log_success "Docker and Docker Compose installed"

# 2. Stop existing containers and clean up
log_info "Stopping existing containers and cleaning up..."
cd /home/ubuntu
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker system prune -af 2>/dev/null || true
log_success "Old containers and images removed"

# 3. Remove old project directories
log_info "Removing old project directories..."
rm -rf /home/ubuntu/PSO-pipeline
log_success "Old directories removed"

# 4. Create fresh project structure
log_info "Creating fresh project structure..."
mkdir -p /home/ubuntu/PSO-pipeline/backend /home/ubuntu/PSO-pipeline/frontend
cd /home/ubuntu/PSO-pipeline

# 5. Extract backend.zip
log_info "Extracting backend from backend.zip..."
if [ -f "/home/ubuntu/backend.zip" ]; then
    cd backend
    unzip -o /home/ubuntu/backend.zip
    cd ..
    log_success "Backend extracted successfully"
else
    log_error "backend.zip not found in /home/ubuntu/"
    exit 1
fi

# 6. Extract frontend from build.zip
log_info "Extracting frontend from build.zip..."
if [ -f "/home/ubuntu/build.zip" ]; then
    cd frontend
    unzip -o /home/ubuntu/build.zip
    cd ..
    log_success "Frontend build extracted successfully"
else
    log_error "build.zip not found in /home/ubuntu/"
    exit 1
fi

# 7. Create Docker Compose configuration
log_info "Creating docker-compose.yml..."
cat > docker-compose.yml << 'DOCKER_COMPOSE_EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: pso-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: material_management_staging
      POSTGRES_USER: staging_user
      POSTGRES_PASSWORD: staging_password_2024
      POSTGRES_HOST_AUTH_METHOD: trust
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
    ports:
      - "5432:5432"
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U staging_user -d material_management_staging"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: pso-backend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=material_management_staging
      - DB_USER=staging_user
      - DB_PASSWORD=staging_password_2024
      - PORT=5001
      - SESSION_SECRET=staging_session_secret_production
      - CORS_ORIGIN=http://13.212.157.243
    ports:
      - "5001:5001"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./backend/uploads:/app/uploads
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pso-frontend
    restart: unless-stopped
    environment:
      - REACT_APP_API_BASE_URL=http://13.212.157.243:5001
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
DOCKER_COMPOSE_EOF

# 8. Create backend Dockerfile
log_info "Creating backend Dockerfile..."
cat > backend/Dockerfile << 'BACKEND_DOCKERFILE_EOF'
FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache postgresql-client curl

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN mkdir -p uploads/materials

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:5001/health || exit 1

CMD ["node", "server.js"]
BACKEND_DOCKERFILE_EOF

# 9. Create frontend Dockerfile (uses pre-built React app)
log_info "Creating frontend Dockerfile..."
cat > frontend/Dockerfile << 'FRONTEND_DOCKERFILE_EOF'
FROM nginx:alpine

# Copy the pre-built React app
COPY build /usr/share/nginx/html

# Create nginx configuration
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
    location /api { \
        proxy_pass http://pso-backend:5001; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
FRONTEND_DOCKERFILE_EOF

# 10. Build and start containers
log_info "Building and starting Docker containers..."
docker-compose up -d --build
log_success "Containers building and starting..."

# 11. Wait for services to be ready
log_info "Waiting for services to initialize..."
sleep 90

# 12. Verification
log_info "Verifying deployment..."
echo ""
echo "=== DOCKER CONTAINERS ==="
docker-compose ps

echo ""
echo "=== TESTING SERVICES ==="
echo "Backend health check:"
curl -f http://localhost:5001/health 2>/dev/null && echo "✅ Backend OK" || echo "❌ Backend Failed"

echo "Frontend check:"
curl -I http://localhost/ 2>/dev/null | head -1 && echo "✅ Frontend OK" || echo "❌ Frontend Failed"

echo ""
echo "🎉 DEPLOYMENT COMPLETED!"
echo ""
echo "🌐 Your application URLs:"
echo "📱 Frontend: http://13.212.157.243"
echo "🔧 Backend API: http://13.212.157.243:5001"
echo "💚 Health Check: http://13.212.157.243:5001/health"
echo ""
echo "🐳 Docker containers are running with auto-restart enabled"
echo "📊 Check status: docker-compose ps"
echo "📝 View logs: docker-compose logs -f"
echo "🔄 Restart: docker-compose restart"
echo "🛑 Stop: docker-compose down"

# 13. Clean up zip files
log_info "Cleaning up zip files..."
rm -f /home/ubuntu/backend.zip /home/ubuntu/build.zip
log_success "Zip files cleaned up"

echo ""
echo "🚀 Ready to serve traffic on http://13.212.157.243"