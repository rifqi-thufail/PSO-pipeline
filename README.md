# Team member

- Rifqi Aufa Thufail - 5026231058
- Akhtar Fattan Widodo - 5026231044
- Muhammad Abyansyah Putra Dewanto - 5026231052

# 📦 Material Management System

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Node](https://img.shields.io/badge/node-v14%2B-brightgreen.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.5%2B-blue.svg)
![React](https://img.shields.io/badge/React-18-61DAFB.svg)

**A comprehensive full-stack Material Management System with CI/CD pipeline and cloud infrastructure.**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Deployment](#-deployment) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Features](#-features)
3. [Architecture](#-architecture)
4. [Technology Stack](#-technology-stack)
5. [Prerequisites](#-prerequisites)
6. [Quick Start](#-quick-start)
7. [Step-by-Step Installation](#-step-by-step-installation)
8. [Configuration](#-configuration)
9. [Running the Application](#-running-the-application)
10. [API Reference](#-api-reference)
11. [Project Structure](#-project-structure)
12. [Testing](#-testing)
13. [Deployment](#-deployment)
14. [CI/CD Pipeline](#-cicd-pipeline)
15. [Troubleshooting](#-troubleshooting)
16. [Security](#-security)
17. [Contributing](#-contributing)
18. [Team](#-team)
19. [License](#-license)

---

## 🔍 Overview

The **Material Management System** is an enterprise-grade web application designed to streamline material tracking, inventory management, and organizational workflows. Built with modern technologies including PostgreSQL, Express.js, React, and Node.js (PERN stack), it provides a robust, scalable, and secure platform for managing materials across divisions.

### Key Highlights

- 🔐 **Secure Authentication** - Session-based auth with bcrypt encryption
- 📁 **Material CRUD Operations** - Complete material lifecycle management
- 🖼️ **Image Upload Support** - Multi-image upload (up to 5 per material)
- 🔄 **Soft Delete System** - Non-destructive deletion with recovery options
- 🐳 **Docker Support** - Containerized deployment
- ☁️ **AWS Infrastructure** - Terraform-managed cloud deployment
- 🚀 **CI/CD Pipeline** - Automated testing and deployment via GitHub Actions

---

## ✨ Features

### 1. User Authentication & Registration

| Feature            | Description                                         |
| ------------------ | --------------------------------------------------- |
| User Registration  | Secure registration with email validation           |
| Session Management | 24-hour session persistence                         |
| Password Security  | bcrypt hashing with salt rounds                     |
| Custom UI          | Branded authentication pages with background images |

### 2. Material Management

| Feature          | Description                                                        |
| ---------------- | ------------------------------------------------------------------ |
| Create Materials | Add materials with name, number, division, placement, and function |
| Image Upload     | Upload up to 5 images per material (JPG, PNG, WEBP)                |
| Edit Materials   | Modify existing material details and images                        |
| Delete Materials | Soft delete with status toggle capability                          |
| Search & Filter  | Find materials by name, number, division, or placement             |

### 3. Dropdown Settings (Division & Placement)

| Feature          | Description                                     |
| ---------------- | ----------------------------------------------- |
| Manage Options   | Create, edit, and delete dropdown options       |
| Soft Delete      | Deactivate dropdowns without permanent deletion |
| Hidden System    | localStorage-based UI filtering                 |
| Persistent State | Settings persist across page refreshes          |

### 4. Dashboard Analytics

| Feature      | Description                                          |
| ------------ | ---------------------------------------------------- |
| Statistics   | Total materials, active count, divisions, placements |
| Grouping     | Materials organized by division                      |
| Recent Items | Quick view of recently added materials               |

---

## 🏗️ Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT BROWSER                                 │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                      React Frontend (Port 3000)                  │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────────┐│    │
│  │  │  Login   │ │Dashboard │ │Materials │ │   Dropdown Settings  ││    │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────────────┘│    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ HTTP/REST API
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        BACKEND SERVER (Port 5001)                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    Express.js + Node.js                          │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │    │
│  │  │ Auth Routes  │ │Material Routes│ │   Dropdown Routes        │ │    │
│  │  └──────────────┘ └──────────────┘ └──────────────────────────┘ │    │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐ │    │
│  │  │  Middleware  │ │    Models    │ │      File Uploads        │ │    │
│  │  └──────────────┘ └──────────────┘ └──────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  │ SQL Queries
                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      POSTGRESQL DATABASE (Port 5432)                     │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐            │
│  │   users    │ │  materials │ │  dropdowns │ │  sessions  │            │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘            │
└─────────────────────────────────────────────────────────────────────────┘
```

### AWS Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                   │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │                        CloudFront CDN                          │     │
│  │                    (React Frontend Delivery)                   │     │
│  └───────────────────────────────┬───────────────────────────────┘     │
│                                  │                                      │
│  ┌───────────────────────────────▼───────────────────────────────┐     │
│  │                          S3 Bucket                             │     │
│  │                    (Static Frontend Files)                     │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │                    Application Load Balancer                   │     │
│  └───────────────────────────────┬───────────────────────────────┘     │
│                                  │                                      │
│  ┌───────────────────────────────▼───────────────────────────────┐     │
│  │                        ECS Fargate                             │     │
│  │                   (Containerized Backend)                      │     │
│  └───────────────────────────────┬───────────────────────────────┘     │
│                                  │                                      │
│  ┌───────────────────────────────▼───────────────────────────────┐     │
│  │                    RDS PostgreSQL 17.2                         │     │
│  │                    (Managed Database)                          │     │
│  └───────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Backend Technologies

| Technology         | Version | Purpose                       |
| ------------------ | ------- | ----------------------------- |
| Node.js            | v14+    | JavaScript runtime            |
| Express.js         | v4.x    | Web framework                 |
| PostgreSQL         | v17.5+  | Relational database           |
| pg (node-postgres) | Latest  | PostgreSQL client             |
| express-session    | Latest  | Session management            |
| connect-pg-simple  | Latest  | PostgreSQL session store      |
| bcrypt             | Latest  | Password hashing              |
| multer             | Latest  | File upload handling          |
| cors               | Latest  | Cross-origin resource sharing |
| dotenv             | Latest  | Environment variables         |

### Frontend Technologies

| Technology   | Version | Purpose              |
| ------------ | ------- | -------------------- |
| React        | v18     | UI library           |
| React Router | v6      | Client-side routing  |
| Ant Design   | v5      | UI component library |
| Axios        | Latest  | HTTP client          |

### DevOps & Infrastructure

| Technology                     | Purpose                        |
| ------------------------------ | ------------------------------ |
| Docker                         | Containerization               |
| Docker Compose                 | Multi-container orchestration  |
| GitHub Actions                 | CI/CD automation               |
| Terraform                      | Infrastructure as Code         |
| AWS (ECS, RDS, S3, CloudFront) | Cloud hosting                  |
| nginx                          | Reverse proxy & static serving |
| PM2                            | Node.js process manager        |

---

## 📝 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

| Software   | Minimum Version | Check Command    |
| ---------- | --------------- | ---------------- |
| Node.js    | v14.0.0         | `node --version` |
| npm        | v6.0.0          | `npm --version`  |
| PostgreSQL | v17.5           | `psql --version` |
| Git        | v2.0.0          | `git --version`  |

### Optional (for deployment)

| Software       | Purpose              | Check Command              |
| -------------- | -------------------- | -------------------------- |
| Docker         | Containerization     | `docker --version`         |
| Docker Compose | Multi-container apps | `docker-compose --version` |
| AWS CLI        | Cloud deployment     | `aws --version`            |
| Terraform      | Infrastructure       | `terraform --version`      |

---

## 🚀 Quick Start

For those who want to get started quickly:

```bash
# 1. Clone the repository
git clone <repository-url>
cd PSO-pipeline

# 2. Setup backend
cd backend
cp .env.example .env  # Edit with your database credentials
npm install

# 3. Setup database
psql -U postgres -c "CREATE DATABASE material_management;"
psql -U postgres -d material_management -f schema.sql

# 4. Start backend
node server.js  # Keep this terminal open

# 5. Setup frontend (new terminal)
cd ../frontend
npm install
npm start

# 6. Access the application
# Open http://localhost:3000 in your browser
```

---

## 📖 Step-by-Step Installation

### Phase 1: Repository Setup

#### Step 1.1: Clone the Repository

```bash
# Using HTTPS
git clone https://github.com/your-username/PSO-pipeline.git

# Using SSH (recommended for development)
git clone git@github.com:your-username/PSO-pipeline.git

# Navigate into the project
cd PSO-pipeline
```

#### Step 1.2: Verify Project Structure

Ensure you have the following directories:

```bash
ls -la
# Should show: backend/  frontend/  INFRA/  testing/  dokumentasi/
```

---

### Phase 2: Database Setup

#### Step 2.1: Install PostgreSQL

**macOS (using Homebrew):**

```bash
brew install postgresql@17
brew services start postgresql@17
```

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download installer from [PostgreSQL Official Website](https://www.postgresql.org/download/windows/)

#### Step 2.2: Create Database User (Optional)

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Create a new user
CREATE USER material_user WITH PASSWORD 'your_secure_password';

# Grant privileges
ALTER USER material_user CREATEDB;

# Exit
\q
```

#### Step 2.3: Create Database

```bash
# Option A: Using psql command
createdb -U postgres material_management

# Option B: Using SQL command
psql -U postgres -c "CREATE DATABASE material_management;"
```

#### Step 2.4: Initialize Schema

```bash
cd backend
psql -U postgres -d material_management -f schema.sql
```

**Verify the schema:**

```bash
psql -U postgres -d material_management -c "\dt"
# Should show: users, materials, dropdowns, session tables
```

> 📚 For detailed PostgreSQL setup, see [POSTGRESQL_SETUP.md](./POSTGRESQL_SETUP.md)

---

### Phase 3: Backend Setup

#### Step 3.1: Navigate to Backend Directory

```bash
cd backend
```

#### Step 3.2: Install Dependencies

```bash
npm install
```

#### Step 3.3: Configure Environment Variables

Create the `.env` file:

```bash
# Copy example file
cp .env.example .env

# Edit with your favorite editor
nano .env  # or vim, code, etc.
```

Add the following configuration:

```env
# Database Configuration
DB_USER=postgres
DB_HOST=localhost
DB_NAME=material_management
DB_PASSWORD=your_postgres_password
DB_PORT=5432

# Server Configuration
PORT=5001
NODE_ENV=development

# Session Configuration
SESSION_SECRET=your_random_secret_key_here_make_it_long_and_secure

# CORS Configuration (for local development)
CORS_ORIGIN=http://localhost:3000
```

**Generate a secure session secret:**

```bash
# macOS/Linux
openssl rand -hex 32

# Use the output as SESSION_SECRET
```

#### Step 3.4: Verify Backend Configuration

```bash
# Test database connection
node -e "require('./config/database').pool.query('SELECT NOW()').then(r => console.log('✅ Database connected:', r.rows[0].now)).catch(e => console.error('❌ Connection failed:', e.message))"
```

---

### Phase 4: Frontend Setup

#### Step 4.1: Navigate to Frontend Directory

```bash
cd ../frontend
# or from project root: cd frontend
```

#### Step 4.2: Install Dependencies

```bash
npm install
```

#### Step 4.3: Configure Environment (Optional)

Create `.env` file for custom API URL:

```env
REACT_APP_API_BASE_URL=http://localhost:5001
```

> **Note:** This is optional for local development as the default URL is `http://localhost:5001`

---

### Phase 5: Verification

#### Step 5.1: Checklist

- [ ] PostgreSQL is running (`pg_isready`)
- [ ] Database `material_management` exists
- [ ] Schema tables created (users, materials, dropdowns, session)
- [ ] Backend `.env` file configured
- [ ] Dependencies installed in both `backend/` and `frontend/`

#### Step 5.2: Test Database Tables

```bash
psql -U postgres -d material_management -c "
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';"
```

Expected output:

```
 table_name
------------
 users
 materials
 dropdowns
 session
(4 rows)
```

---

## ⚙️ Configuration

### Environment Variables Reference

#### Backend (`backend/.env`)

| Variable         | Required | Default               | Description            |
| ---------------- | -------- | --------------------- | ---------------------- |
| `DB_USER`        | ✅       | -                     | PostgreSQL username    |
| `DB_HOST`        | ✅       | localhost             | Database host          |
| `DB_NAME`        | ✅       | -                     | Database name          |
| `DB_PASSWORD`    | ✅       | -                     | Database password      |
| `DB_PORT`        | ❌       | 5432                  | Database port          |
| `PORT`           | ❌       | 5001                  | Backend server port    |
| `SESSION_SECRET` | ✅       | -                     | Session encryption key |
| `NODE_ENV`       | ❌       | development           | Environment mode       |
| `CORS_ORIGIN`    | ❌       | http://localhost:3000 | Allowed CORS origin    |

#### Frontend (`frontend/.env`)

| Variable                 | Required | Default               | Description     |
| ------------------------ | -------- | --------------------- | --------------- |
| `REACT_APP_API_BASE_URL` | ❌       | http://localhost:5001 | Backend API URL |

---

## 🏃 Running the Application

### Development Mode

You need **two terminal windows** to run both servers:

#### Terminal 1: Start Backend Server

```bash
cd backend
node server.js
```

**Expected output:**

```
🚀 Server running on http://localhost:5001
✅ PostgreSQL connected successfully
📦 Session store connected
```

#### Terminal 2: Start Frontend Server

```bash
cd frontend
npm start
```

**Expected output:**

```
Compiled successfully!

You can now view material-management in the browser.

  Local:            http://localhost:3000
  On Your Network:  http://192.168.x.x:3000
```

The application will automatically open in your browser at `http://localhost:3000`

### Using Helper Scripts

```bash
# Start backend using script
cd testing
bash start-server.sh
```

### Docker Mode (Alternative)

```bash
# From project root
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

---

## 🔐 Default Credentials

### Admin Account

| Field    | Value               |
| -------- | ------------------- |
| Email    | `admin@example.com` |
| Password | `admin123`          |

### Test User Account

| Field    | Value              |
| -------- | ------------------ |
| Email    | `test@example.com` |
| Password | `test123`          |

> ⚠️ **Security Warning:** Change these default credentials in production!

---

## 📡 API Reference

### Base URL

- **Development:** `http://localhost:5001/api`
- **Production:** `https://your-domain.com/api`

### Authentication Endpoints

| Method | Endpoint         | Description          | Auth Required |
| ------ | ---------------- | -------------------- | ------------- |
| `POST` | `/auth/register` | Register new user    | ❌            |
| `POST` | `/auth/login`    | User login           | ❌            |
| `POST` | `/auth/logout`   | User logout          | ✅            |
| `GET`  | `/auth/check`    | Check session status | ❌            |

#### Register User

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123",
  "confirmPassword": "securePassword123"
}
```

#### Login User

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

### Materials Endpoints

| Method   | Endpoint                         | Description                   | Auth Required |
| -------- | -------------------------------- | ----------------------------- | ------------- |
| `GET`    | `/materials`                     | Get all materials (paginated) | ✅            |
| `GET`    | `/materials/:id`                 | Get single material           | ✅            |
| `POST`   | `/materials`                     | Create new material           | ✅            |
| `PUT`    | `/materials/:id`                 | Update material               | ✅            |
| `DELETE` | `/materials/:id`                 | Soft delete material          | ✅            |
| `PATCH`  | `/materials/:id/toggle-status`   | Toggle active/inactive        | ✅            |
| `POST`   | `/materials/:id/images`          | Upload images                 | ✅            |
| `DELETE` | `/materials/:id/images/:imageId` | Delete image                  | ✅            |

#### Get Materials with Filters

```http
GET /api/materials?page=1&limit=10&search=keyword&division_id=1&placement_id=2
Authorization: Cookie session
```

#### Create Material

```http
POST /api/materials
Content-Type: multipart/form-data

{
  "name": "Material Name",
  "number": "MAT-001",
  "division_id": 1,
  "placement_id": 2,
  "function": "Description of material function",
  "images": [file1, file2, ...]
}
```

### Dropdowns Endpoints

| Method   | Endpoint                   | Description            | Auth Required |
| -------- | -------------------------- | ---------------------- | ------------- |
| `GET`    | `/dropdowns/:type`         | Get dropdown options   | ✅            |
| `POST`   | `/dropdowns`               | Create dropdown option | ✅            |
| `PUT`    | `/dropdowns/:id`           | Update dropdown option | ✅            |
| `DELETE` | `/dropdowns/:id`           | Soft delete dropdown   | ✅            |
| `PUT`    | `/dropdowns/:id/toggle`    | Toggle active status   | ✅            |
| `DELETE` | `/dropdowns/:id/permanent` | Permanent delete       | ✅            |

**Type Parameter Values:**

- `division` - Material owner divisions
- `placement` - Material placement locations

### Dashboard Endpoints

| Method | Endpoint           | Description              | Auth Required |
| ------ | ------------------ | ------------------------ | ------------- |
| `GET`  | `/dashboard/stats` | Get dashboard statistics | ✅            |

---

## 📁 Project Structure

```
PSO-pipeline/
│
├── 📁 backend/                     # Express.js Backend Server
│   ├── 📁 config/
│   │   └── database.js            # PostgreSQL connection & session store
│   ├── 📁 middleware/
│   │   └── auth.js                # Authentication middleware
│   ├── 📁 models/                 # Database models
│   │   ├── User.js                # User model with bcrypt
│   │   ├── Material.js            # Material CRUD operations
│   │   └── Dropdown.js            # Dropdown with soft delete
│   ├── 📁 routes/                 # API route handlers
│   │   ├── auth.js                # Authentication routes
│   │   ├── materials.js           # Material CRUD routes
│   │   ├── dropdowns.js           # Dropdown management routes
│   │   └── dashboard.js           # Dashboard statistics
│   ├── 📁 uploads/                # Uploaded files storage
│   │   └── materials/             # Material images
│   ├── 📁 tests/                  # Backend tests
│   ├── server.js                  # Main server entry point
│   ├── schema.sql                 # Database schema
│   ├── Dockerfile                 # Backend container config
│   ├── .env.example               # Environment template
│   └── package.json               # Dependencies
│
├── 📁 frontend/                    # React Frontend Application
│   ├── 📁 public/
│   │   ├── index.html             # HTML template
│   │   ├── manifest.json          # PWA manifest
│   │   └── BG.webp                # Auth background image
│   ├── 📁 src/
│   │   ├── 📁 components/         # Reusable components
│   │   │   ├── Navbar.jsx         # Navigation bar
│   │   │   └── MaterialForm.jsx   # Material form component
│   │   ├── 📁 pages/              # Page components
│   │   │   ├── Login.jsx          # Login page
│   │   │   ├── Register.jsx       # Registration page
│   │   │   ├── Dashboard.jsx      # Dashboard with stats
│   │   │   ├── Materials.jsx      # Material management
│   │   │   └── Dropdowns.jsx      # Dropdown settings
│   │   ├── 📁 utils/              # Utility functions
│   │   │   ├── api.js             # API calls
│   │   │   └── dropdownFilter.js  # Hidden dropdown utilities
│   │   ├── App.js                 # Root component
│   │   ├── index.js               # Entry point
│   │   └── index.css              # Global styles
│   ├── Dockerfile                 # Frontend container config
│   ├── nginx.conf                 # Nginx configuration
│   └── package.json               # Dependencies
│
├── 📁 INFRA/                       # Terraform Infrastructure
│   ├── main.tf                    # Provider configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── vpc.tf                     # VPC & subnets
│   ├── security_groups.tf         # Security groups
│   ├── rds.tf                     # PostgreSQL RDS
│   ├── ecs.tf                     # ECS Fargate
│   ├── alb.tf                     # Load balancer
│   ├── s3_cloudfront.tf           # Static hosting & CDN
│   └── README.md                  # Infrastructure docs
│
├── 📁 .github/
│   ├── 📁 workflows/              # CI/CD Pipelines
│   │   ├── staging-tests.yml      # Test pipeline
│   │   ├── staging-deploy.yml     # Staging deployment
│   │   ├── production-deploy.yml  # Production deployment
│   │   ├── backend-deploy.yml     # Backend-only deploy
│   │   └── frontend-deploy.yml    # Frontend-only deploy
│   ├── README.md                  # CI/CD documentation
│   └── SECRETS.md                 # Secrets configuration guide
│
├── 📁 testing/                     # Test Scripts
│   ├── start-server.sh            # Backend server starter
│   ├── test-soft-delete.sh        # Soft delete tests
│   ├── test-correlation.sh        # Data correlation tests
│   ├── test-frontend-workflow.sh  # Frontend workflow tests
│   └── consistency-test.sh        # Consistency tests
│
├── 📁 dokumentasi/                 # Documentation
│   ├── API_TEST_RESULTS.md
│   ├── SOFT_DELETE_IMPLEMENTATION.md
│   ├── REGISTRATION_FEATURE.md
│   └── audit-report.md
│
├── docker-compose.yml             # Docker orchestration
├── GUIDE.md                       # Developer guide
├── POSTGRESQL_SETUP.md            # Database setup guide
├── DEVELOPMENT_WORKFLOW.md        # Development workflow
└── README.md                      # This file
```

---

## 🧪 Testing

### Running Backend Tests

```bash
cd backend

# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- tests/auth.test.js
```

### Running Test Scripts

```bash
cd testing

# Test soft delete functionality
bash test-soft-delete.sh

# Test data correlation
bash test-correlation.sh

# Test frontend workflows
bash test-frontend-workflow.sh

# Run consistency tests
bash consistency-test.sh
```

### Manual API Testing

Test with curl:

```bash
# Health check
curl http://localhost:5001/health

# Login
curl -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

---

## 🚀 Deployment

### Option 1: Docker Compose (Recommended for Staging)

#### Step 1: Configure Environment

```bash
# Review docker-compose.yml and update environment variables if needed
nano docker-compose.yml
```

#### Step 2: Build and Start

```bash
# Build and start all services
docker-compose up -d --build

# View logs
docker-compose logs -f
```

#### Step 3: Verify Deployment

```bash
# Check container status
docker-compose ps

# Test endpoints
curl http://localhost:5001/health
curl http://localhost/  # Frontend
```

### Option 2: Manual EC2 Deployment

#### Step 1: Connect to EC2

```bash
ssh -i pso-key.pem ubuntu@<EC2_IP_ADDRESS>
```

#### Step 2: Deploy Backend

```bash
cd PSO-pipeline
git pull origin main
cd backend
npm install
pm2 restart pso-backend
```

#### Step 3: Deploy Frontend

```bash
cd ../frontend
npm install
npm run build
sudo cp -r build/* /var/www/html/
```

### Option 3: AWS Infrastructure (Terraform)

See detailed instructions in [INFRA/README.md](./INFRA/README.md)

```bash
cd INFRA
terraform init
terraform plan
terraform apply
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

| Workflow                | Trigger                    | Description                   |
| ----------------------- | -------------------------- | ----------------------------- |
| `staging-tests.yml`     | Push to any branch         | Run tests on all code changes |
| `staging-deploy.yml`    | Push to `staging` branch   | Deploy to staging environment |
| `production-deploy.yml` | Push to `main` branch      | Deploy to production          |
| `backend-deploy.yml`    | Backend changes on `main`  | Backend-only deployment       |
| `frontend-deploy.yml`   | Frontend changes on `main` | Frontend-only deployment      |

### Required GitHub Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret        | Description                                    |
| ------------- | ---------------------------------------------- |
| `EC2_HOST`    | EC2 server IP address (e.g., `13.212.157.243`) |
| `EC2_USER`    | SSH username (e.g., `ubuntu`)                  |
| `EC2_SSH_KEY` | Contents of private SSH key                    |

### Pipeline Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Push to Repo   │────▶│   Run Tests     │────▶│  Build App      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Notify Team    │◀────│  Health Check   │◀────│   Deploy        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue: Cannot connect to PostgreSQL

**Symptoms:** Server fails to start with database connection error

**Solutions:**

```bash
# 1. Check PostgreSQL is running
pg_isready

# 2. Start PostgreSQL
brew services start postgresql@17  # macOS
sudo systemctl start postgresql    # Linux

# 3. Verify database exists
psql -U postgres -c "\l" | grep material_management

# 4. Check credentials in .env file
cat backend/.env | grep DB_
```

#### Issue: Port already in use

**Symptoms:** `Error: listen EADDRINUSE: address already in use`

**Solutions:**

```bash
# Find and kill process on port 5001 (backend)
lsof -ti:5001 | xargs kill -9

# Find and kill process on port 3000 (frontend)
lsof -ti:3000 | xargs kill -9

# Alternative: Change port in .env
# PORT=5002
```

#### Issue: Session expires immediately

**Symptoms:** Login works but immediately logged out

**Solutions:**

1. Check `SESSION_SECRET` is set in `.env`
2. Verify CORS configuration matches frontend URL
3. Clear browser cookies
4. Check database session table exists

```bash
psql -U postgres -d material_management -c "SELECT * FROM session LIMIT 1;"
```

#### Issue: Images not uploading

**Symptoms:** Upload fails or images not displayed

**Solutions:**

```bash
# Create uploads directory
cd backend
mkdir -p uploads/materials

# Check permissions
chmod 755 uploads/materials

# Verify multer configuration
cat server.js | grep multer
```

#### Issue: CORS errors

**Symptoms:** Browser shows CORS blocked errors

**Solutions:**

1. Check `CORS_ORIGIN` in backend `.env`
2. Ensure frontend URL matches exactly (including port)
3. Restart backend server after changing `.env`

```javascript
// In backend/server.js - verify CORS config
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "http://localhost:3000",
    credentials: true,
  })
);
```

#### Issue: Docker containers not starting

**Symptoms:** `docker-compose up` fails or containers exit

**Solutions:**

```bash
# View detailed logs
docker-compose logs -f

# Rebuild containers
docker-compose build --no-cache

# Check disk space
df -h

# Reset Docker volumes
docker-compose down -v
docker-compose up -d
```

---

## 🔒 Security

### Best Practices Implemented

| Security Measure         | Implementation                         |
| ------------------------ | -------------------------------------- |
| Password Hashing         | bcrypt with salt rounds                |
| Session Security         | HTTP-only cookies, secure sessions     |
| Input Validation         | Server-side validation on all inputs   |
| File Upload Security     | Type & size validation, secure storage |
| SQL Injection Prevention | Parameterized queries                  |
| CORS                     | Configured for specific origins only   |
| Environment Variables    | Sensitive data stored in `.env`        |

### Recommendations for Production

1. **Enable HTTPS** - Use SSL/TLS certificates
2. **Use Strong Secrets** - Generate long, random session secrets
3. **Change Default Credentials** - Never use default admin passwords
4. **Enable Rate Limiting** - Prevent brute force attacks
5. **Regular Updates** - Keep dependencies updated
6. **Audit Logging** - Enable and monitor access logs
7. **Database Encryption** - Enable encryption at rest
8. **WAF** - Configure AWS WAF for public endpoints

---

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Run tests**
   ```bash
   npm test
   ```
5. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request**

### Commit Message Guidelines

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/modifications
- `chore:` Maintenance tasks

---

## 👥 Team

| Name                             | Student ID | Role        |
| -------------------------------- | ---------- | ----------- |
| Rifqi Aufa Thufail               | 5026231058 | Team Member |
| Akhtar Fattan Widodo             | 5026231044 | Team Member |
| Muhammad Abyansyah Putra Dewanto | 5026231052 | Team Lead   |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📚 Additional Documentation

- [GUIDE.md](./GUIDE.md) - Developer customization guide
- [POSTGRESQL_SETUP.md](./POSTGRESQL_SETUP.md) - Detailed database setup
- [INFRA/README.md](./INFRA/README.md) - AWS infrastructure guide
- [.github/README.md](./.github/README.md) - CI/CD documentation
- [dokumentasi/](./dokumentasi/) - Technical documentation

---

## 📞 Contact

For questions or support, please contact:

- **Email:** berkasaby@gmail.com
- **Repository Issues:** [GitHub Issues](https://github.com/your-username/PSO-pipeline/issues)

---

<div align="center">

**Made with ❤️ by PSO Team**

_Last updated: December 2025_

</div>
