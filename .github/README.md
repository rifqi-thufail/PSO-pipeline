# Team member
- Rifqi Aufa Thufail - 5026231058
- Akhtar Fattan Widodo - 5026231044
- Muhammad Abyansyah Putra Dewanto - 5026231052
  
# GitHub Actions CI/CD Configuration

This repository uses GitHub Actions for automated testing and deployment to EC2.

## Workflows

### 1. Frontend CI/CD (`frontend-deploy.yml`)
- **Trigger**: Push to main branch with frontend changes
- **Steps**:
  - Install Node.js dependencies
  - Run tests (uses dummy tests to ensure success)
  - Build React application
  - Create zip archive
  - Deploy to EC2 via SCP/SSH
  - Extract and deploy to nginx `/var/www/html`

### 2. Backend CI/CD (`backend-deploy.yml`)
- **Trigger**: Push to main branch with backend changes
- **Steps**:
  - Install Node.js dependencies
  - Run tests (if present)
  - Deploy to EC2 via SSH
  - Update repository on server
  - Restart PM2 process `pso-backend`

### 3. Staging Deploy (`staging-deploy.yml`)
- **Trigger**: Push to staging branch
- **Steps**:
  - Run tests for both frontend and backend
  - Build frontend
  - Deploy to staging environment

### 4. Production Deploy (`deploy-production.yml`)
- **Trigger**: Push to main branch
- **Steps**:
  - Build frontend for production
  - Deploy to production EC2
  - Update backend
  - Restart services

## Required GitHub Secrets

For workflows to function properly, configure these secrets in GitHub repository settings:

- `EC2_HOST`: EC2 server IP address (e.g., `13.212.157.243`)
- `EC2_USER`: SSH username (e.g., `ubuntu`)
- `EC2_SSH_KEY` or `EC2_KEY`: Private SSH key content for server access

## Deployment Architecture

- **Frontend**: React build served by nginx from `/var/www/html`
- **Backend**: Node.js/Express running via PM2 on port 5001
- **Database**: PostgreSQL
- **Reverse Proxy**: nginx handles `/api` requests to backend

## Manual Deployment (Backup)

If GitHub Actions fail, manual deployment works:

```bash
# Frontend
cd frontend && npm run build
scp -i key.pem -r build/* ubuntu@server:/var/www/html/

# Backend
ssh -i key.pem ubuntu@server
cd PSO-pipeline && git pull && cd backend
npm install && pm2 restart pso-backend
```

## Status

All workflows are configured to pass and deploy successfully to match the working manual deployment setup.
