#!/bin/bash

# AWS Deployment Script for Material Management System
# This script automates the deployment of both backend and frontend to AWS

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (update these values)
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
PROJECT_NAME="material-mgmt"
ENVIRONMENT="prod"
TERRAFORM_DIR="../INFRA"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Material Management System - AWS Deploy${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install it first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "Docker not found. Please install it first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq not found. Please install it: brew install jq"
    exit 1
fi

print_info "All prerequisites met ✓"

# Get Terraform outputs
print_info "Retrieving infrastructure information..."

cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfstate" ]; then
    print_error "Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

ECR_REPO=$(terraform output -raw ecr_repository_url)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)
S3_FRONTEND=$(terraform output -raw frontend_bucket_name)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)

cd - > /dev/null

print_info "Infrastructure:"
print_info "  ECR Repository: $ECR_REPO"
print_info "  ECS Cluster: $ECS_CLUSTER"
print_info "  ECS Service: $ECS_SERVICE"
print_info "  Frontend Bucket: $S3_FRONTEND"
print_info "  CloudFront: $CLOUDFRONT_URL"

# Deploy Backend
print_info ""
print_info "========================================<br>"
print_info "Deploying Backend..."
print_info "========================================"

cd ../backend

# Login to ECR
print_info "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REPO

# Build Docker image
print_info "Building Docker image..."
docker build -t $PROJECT_NAME-backend:latest .

# Tag image
print_info "Tagging image..."
docker tag $PROJECT_NAME-backend:latest $ECR_REPO:latest
docker tag $PROJECT_NAME-backend:latest $ECR_REPO:$(git rev-parse --short HEAD 2>/dev/null || echo "manual")

# Push to ECR
print_info "Pushing image to ECR..."
docker push $ECR_REPO:latest
docker push $ECR_REPO:$(git rev-parse --short HEAD 2>/dev/null || echo "manual")

# Update ECS service
print_info "Updating ECS service..."
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --force-new-deployment \
    --region $AWS_REGION \
    --no-cli-pager

print_info "Waiting for ECS service to stabilize..."
aws ecs wait services-stable \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE \
    --region $AWS_REGION

print_info "Backend deployment completed ✓"

cd ..

# Deploy Frontend
print_info ""
print_info "========================================"
print_info "Deploying Frontend..."
print_info "========================================"

cd frontend

# Create production environment file
print_info "Creating production environment configuration..."
cat > .env.production << EOF
REACT_APP_API_URL=https://$CLOUDFRONT_URL/api
EOF

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    print_info "Installing dependencies..."
    npm install
fi

# Build React app
print_info "Building React application..."
npm run build

# Upload to S3
print_info "Uploading to S3..."
aws s3 sync build/ s3://$S3_FRONTEND/ --delete --region $AWS_REGION

# Invalidate CloudFront cache
print_info "Invalidating CloudFront cache..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_ID \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

print_info "CloudFront invalidation created: $INVALIDATION_ID"
print_info "Waiting for invalidation to complete..."

aws cloudfront wait invalidation-completed \
    --distribution-id $CLOUDFRONT_ID \
    --id $INVALIDATION_ID

print_info "Frontend deployment completed ✓"

cd ..

# Summary
print_info ""
print_info "========================================"
print_info "Deployment Summary"
print_info "========================================"
print_info "✓ Backend deployed to ECS"
print_info "✓ Frontend deployed to S3 + CloudFront"
print_info ""
print_info "Application URL: https://$CLOUDFRONT_URL"
print_info ""
print_info "To view backend logs:"
print_info "  aws logs tail /ecs/$PROJECT_NAME-backend-$ENVIRONMENT --follow"
print_info ""
print_info "To check ECS service status:"
print_info "  aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE"
print_info ""
print_info "${GREEN}Deployment completed successfully!${NC}"
