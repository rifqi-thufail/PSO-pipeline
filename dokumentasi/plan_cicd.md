# Plan: CI/CD Pipeline for Backend on AWS Free Tier EC2

Deploy your Node.js/Express backend to an AWS Free Tier EC2 instance via GitHub Actions. When you push changes to `backend/`, the pipeline automatically deploys to EC2, and users can access the app via the EC2 public IP in their browser.

## Cost: $0 (AWS Free Tier)

| Service | Free Tier Allowance | Our Usage |
|---------|---------------------|-----------|
| EC2 `t2.micro` | 750 hours/month (12 months) | ~720 hours/month ✅ |
| EBS Storage | 30 GB/month | ~8 GB ✅ |
| Data Transfer | 100 GB/month outbound | Minimal ✅ |
| Elastic IP | Free when attached to running instance | 1 IP ✅ |

---

## Architecture Overview

```
Developer → Push to GitHub → GitHub Actions → SSH to EC2 → Pull & Restart App
                                                              ↓
User Browser ←──────── http://<EC2-Public-IP>:5001 ←──── Node.js App (PM2)
                                                              ↓
                                                         PostgreSQL (on EC2)
```

---

## Step 1: Provision EC2 Instance (One-time Setup)

### 1.1 Launch EC2 Instance
- **AMI**: Amazon Linux 2023 or Ubuntu 22.04 LTS (both free tier eligible)
- **Instance Type**: `t2.micro` (free tier)
- **Storage**: 8 GB gp3 (free tier allows up to 30 GB)
- **Key Pair**: Create new or use existing (download `.pem` file - you'll need this!)

### 1.2 Configure Security Group
Create a security group with these inbound rules:

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | Your IP or 0.0.0.0/0 | SSH access for deployment |
| Custom TCP | 5001 | 0.0.0.0/0 | Backend API access |
| HTTP | 80 | 0.0.0.0/0 | (Optional) Redirect to app |

### 1.3 Allocate Elastic IP (Recommended)
- Elastic IPs are **free** when attached to a running instance
- Prevents IP change on instance restart
- Go to EC2 → Elastic IPs → Allocate → Associate with your instance

---

## Step 2: Setup EC2 Instance

SSH into your instance and run these commands:

### 2.1 Connect to EC2
```bash
ssh -i "your-key.pem" ec2-user@<EC2-Public-IP>
# Or for Ubuntu: ssh -i "your-key.pem" ubuntu@<EC2-Public-IP>
```

### 2.2 Install Node.js, PM2, and PostgreSQL
```bash
# Update system
sudo yum update -y  # Amazon Linux
# sudo apt update && sudo apt upgrade -y  # Ubuntu

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs  # Amazon Linux
# sudo apt install -y nodejs  # Ubuntu

# Install PM2 globally (process manager)
sudo npm install -g pm2

# Install PostgreSQL
sudo yum install -y postgresql15-server postgresql15  # Amazon Linux
# sudo apt install -y postgresql postgresql-contrib  # Ubuntu

# Initialize and start PostgreSQL
sudo postgresql-setup --initdb  # Amazon Linux only
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2.3 Setup PostgreSQL Database
```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL shell:
CREATE DATABASE material_management;
CREATE USER app_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE material_management TO app_user;
\q
```

### 2.4 Clone Repository and Setup App
```bash
# Create app directory
mkdir -p ~/app
cd ~/app

# Clone your repository
git clone https://github.com/akhtar2344/PSO_Final.git
cd PSO_Final/backend

# Install dependencies
npm ci --only=production

# Create .env file
cat > .env << EOF
PORT=5001
NODE_ENV=production
DATABASE_URL=postgresql://app_user:your_secure_password@localhost:5432/material_management
SESSION_SECRET=your_super_secret_session_key_here
EOF

# Initialize database schema
psql -U app_user -d material_management -f schema.sql

# Start app with PM2
pm2 start server.js --name "backend"
pm2 save
pm2 startup  # Follow the instructions it prints
```

### 2.5 Verify App is Running
```bash
# Check PM2 status
pm2 status

# Test locally
curl http://localhost:5001/api/auth/check
```

---

## Step 3: Access the App from Your Browser

Once the app is running on EC2:

1. Open your web browser
2. Navigate to: `http://<EC2-Public-IP>:5001`
3. You should see your API respond!

**Example URLs:**
- Health check: `http://54.123.45.67:5001/api/auth/check`
- Login: `http://54.123.45.67:5001/api/auth/login`

---

## Step 4: Configure GitHub Actions for Auto-Deploy

### 4.1 Add GitHub Secrets
Go to your repo → Settings → Secrets and variables → Actions → New repository secret

| Secret Name | Value |
|-------------|-------|
| `EC2_HOST` | Your EC2 Elastic IP (e.g., `54.123.45.67`) |
| `EC2_USER` | `ec2-user` (Amazon Linux) or `ubuntu` (Ubuntu) |
| `EC2_SSH_KEY` | Contents of your `.pem` file (entire private key) |

### 4.2 Update GitHub Actions Workflow
Replace `.github/workflows/backend-deploy.yml` with the workflow that:
1. Triggers on push to `main` when `backend/**` changes
2. SSHs into EC2
3. Pulls latest code
4. Installs dependencies
5. Restarts PM2

---

## Step 5: Workflow File

Create/update `.github/workflows/backend-deploy.yml`:

```yaml
name: Backend CI/CD to EC2

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'
  pull_request:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        working-directory: ./backend
        run: npm ci
      
      - name: Run linter (if configured)
        working-directory: ./backend
        run: npm run lint --if-present
      
      - name: Run tests (if configured)
        working-directory: ./backend
        run: npm test --if-present

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    
    steps:
      - name: Deploy to EC2
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd ~/app/PSO_Final
            git pull origin main
            cd backend
            npm ci --only=production
            pm2 restart backend || pm2 start server.js --name "backend"
            pm2 save
```

---

## Complete Workflow: Push → Deploy → Access

```
1. Make changes to backend code locally
2. Commit and push to GitHub:
   git add .
   git commit -m "Update backend"
   git push origin main

3. GitHub Actions automatically:
   - Runs tests
   - SSHs into EC2
   - Pulls latest code
   - Restarts the app

4. Users access the updated app at:
   http://<EC2-Public-IP>:5001
```

---

## Troubleshooting

### Can't access app in browser?
- Check security group allows port 5001 from 0.0.0.0/0
- Verify app is running: `pm2 status`
- Check logs: `pm2 logs backend`

### GitHub Actions deployment fails?
- Verify SSH key is correct (include full key with headers)
- Check EC2_HOST is the correct IP
- Ensure EC2 security group allows SSH from GitHub IPs

### Database connection issues?
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Verify pg_hba.conf allows local connections

---

## Free Tier Limits Reminder

⚠️ **Stay within free tier:**
- Keep EC2 running 24/7 = ~720 hours/month (within 750 limit)
- Don't launch additional instances
- Elastic IP must be attached to running instance (or you get charged)
- Free tier expires after 12 months from AWS account creation
