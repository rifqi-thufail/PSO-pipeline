# PostgreSQL Migration Setup Guide

## Prerequisites
- PostgreSQL installed on your system
- Node.js and npm installed

## Setup Steps

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Setup PostgreSQL Database

Login to PostgreSQL:
```bash
psql -U postgres
```

Create database:
```sql
CREATE DATABASE material_management;
```

Exit psql and run schema:
```bash
psql -U postgres -d material_management -f schema.sql
```

### 3. Configure Environment Variables

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` and update with your PostgreSQL credentials:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=material_management
DB_USER=postgres
DB_PASSWORD=your_password
```

### 4. Start Backend Server
```bash
npm run dev
```

### 5. Default Admin Account
- Email: admin@example.com
- Password: admin123

## Database Structure

### Tables:
- `users` - User authentication and profiles
- `materials` - Material records with images stored as JSONB
- `dropdowns` - Division and placement options
- `session` - Express session storage

### Key Changes from MongoDB:
- MongoDB `_id` replaced with PostgreSQL `id` (serial)
- Snake_case field names (material_name, division_id, etc.)
- JSONB for images array
- Foreign keys for relationships
- Indexes for performance

## Field Name Mapping

MongoDB → PostgreSQL:
- `_id` → `id`
- `materialName` → `material_name`
- `materialNumber` → `material_number`
- `divisionId` → `division_id`
- `placementId` → `placement_id`
- `isActive` → `is_active`
- `createdAt` → `created_at`
- `updatedAt` → `updated_at`

Backend responses are formatted to match frontend expectations (camelCase).
