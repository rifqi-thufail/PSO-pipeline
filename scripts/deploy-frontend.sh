#!/bin/bash

# Frontend Deployment Script for EC2
# This script matches exactly what we deployed manually

set -e

echo "Starting frontend deployment..."

# Clean previous deployment
echo "Cleaning previous deployment..."
sudo rm -rf /var/www/html/*

# Create temporary directory
rm -rf ~/deploy-frontend
mkdir -p ~/deploy-frontend

# Extract build archive
echo "Extracting build archive..."
if [ -f ~/build.zip ]; then
    unzip -q ~/build.zip -d ~/deploy-frontend/build
elif [ -f ~/production-build.zip ]; then
    unzip -q ~/production-build.zip -d ~/deploy-frontend/
fi

# Deploy to nginx directory
echo "Deploying to nginx..."
if [ -d ~/deploy-frontend/build ]; then
    sudo cp -r ~/deploy-frontend/build/* /var/www/html/
else
    sudo cp -r ~/deploy-frontend/* /var/www/html/
fi

# Set proper permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Restart nginx
echo "Restarting nginx..."
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager -l

# Cleanup
echo "Cleaning up..."
rm -f ~/build.zip ~/production-build.zip
rm -rf ~/deploy-frontend

echo "Frontend deployment completed successfully!"