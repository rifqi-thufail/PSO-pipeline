# GitHub Actions Secrets Configuration

Untuk workflow CI/CD berjalan dengan baik, perlu setting secrets di GitHub repository.

## Required Secrets

Masuk ke repository settings → Secrets and variables → Actions → New repository secret:

### EC2_HOST
- **Value**: `13.212.157.243`
- **Description**: IP address EC2 Singapore server

### EC2_USER  
- **Value**: `ubuntu`
- **Description**: Username untuk SSH ke EC2

### EC2_SSH_KEY
- **Value**: Content dari file `pso-singapore.pem`
- **Description**: Private key untuk SSH authentication

## How to get EC2_SSH_KEY content:

1. Open `pso-singapore.pem` dengan text editor
2. Copy seluruh content termasuk:
   ```
   -----BEGIN RSA PRIVATE KEY-----
   [key content]
   -----END RSA PRIVATE KEY-----
   ```
3. Paste ke secret EC2_SSH_KEY

## Current Workflow Status:

- ✅ **frontend-deploy.yml**: Aktif - Deploy React build ke `/var/www/html/`
- ✅ **backend-deploy.yml**: Aktif - Deploy backend dan restart PM2 `pso-backend`
- ❌ **staging-deploy.yml**: Disabled (manual deployment)
- ❌ **deploy-production.yml**: Disabled (using manual PM2 instead of Docker)

## Manual Deployment (Current Working Method):

```bash
# Frontend
cd frontend
npm run build
scp -i pso-singapore.pem -r build/* ubuntu@13.212.157.243:/var/www/html/

# Backend
git push origin main
ssh -i pso-singapore.pem ubuntu@13.212.157.243
cd PSO-pipeline
git pull
cd backend
npm install
pm2 restart pso-backend
```

## Re-enable Workflows:

Untuk mengaktifkan kembali staging dan production workflows:
1. Set semua secrets di atas
2. Uncomment workflows di staging-deploy.yml dan deploy-production.yml
3. Sesuaikan path dan konfigurasi server jika perlu