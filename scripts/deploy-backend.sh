#!/bin/bash

# Backend Deployment Script for EC2
# This script matches exactly what we deployed manually

set -e

echo "Starting backend deployment..."

# Navigate to project directory
cd ~/PSO-pipeline

# Update repository
echo "Updating repository..."
git pull origin main

# Install dependencies
echo "Installing dependencies..."
cd backend
npm ci --omit=dev

# Restart PM2 process
echo "Restarting PM2 process..."
pm2 restart pso-backend || {
    echo "Starting new PM2 process..."
    pm2 start server.js --name "pso-backend"
}

# Save PM2 configuration
pm2 save

# Check status
echo "Checking PM2 status..."
pm2 status

echo "Backend deployment completed successfully!"