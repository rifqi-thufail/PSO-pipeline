# Material Management System - AWS Infrastructure
# This Terraform configuration deploys the application to AWS using:
# - VPC with public/private subnets
# - RDS PostgreSQL for database
# - ECS Fargate for containerized backend
# - S3 + CloudFront for frontend static hosting
# - Application Load Balancer
# - Security Groups and IAM roles

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MaterialManagement"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
