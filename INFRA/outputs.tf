# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "RDS PostgreSQL address"
  value       = aws_db_instance.postgres.address
}

output "db_credentials_secret_arn" {
  description = "ARN of Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = true
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.backend.name
}

output "ecr_repository_url" {
  description = "ECR Repository URL for backend"
  value       = aws_ecr_repository.backend.repository_url
}

# ALB Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "alb_url" {
  description = "ALB URL"
  value       = "http://${aws_lb.main.dns_name}"
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_url" {
  description = "CloudFront URL for frontend"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

# S3 Outputs
output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "uploads_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.uploads.id
}

# Application URLs
output "application_url" {
  description = "Main application URL (CloudFront)"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "api_url" {
  description = "Backend API URL"
  value       = "http://${aws_lb.main.dns_name}/api"
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = <<-EOT
    
    ============================================
    Material Management System - Deployment Info
    ============================================
    
    1. Build and push backend Docker image:
       cd backend
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.backend.repository_url}
       docker build -t ${aws_ecr_repository.backend.repository_url}:latest .
       docker push ${aws_ecr_repository.backend.repository_url}:latest
    
    2. Update ECS service to use new image:
       aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.backend.name} --force-new-deployment --region ${var.aws_region}
    
    3. Build and deploy frontend:
       cd frontend
       REACT_APP_API_URL=https://${aws_cloudfront_distribution.frontend.domain_name}/api npm run build
       aws s3 sync build/ s3://${aws_s3_bucket.frontend.id}/ --delete
       aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.frontend.id} --paths "/*"
    
    4. Access your application:
       Frontend: https://${aws_cloudfront_distribution.frontend.domain_name}
       Backend API: http://${aws_lb.main.dns_name}/api
    
    5. Database connection:
       Host: ${aws_db_instance.postgres.address}
       Port: ${aws_db_instance.postgres.port}
       Database: ${var.db_name}
       Credentials stored in Secrets Manager: ${aws_secretsmanager_secret.db_credentials.name}
    
    6. CloudWatch Logs:
       Log Group: ${aws_cloudwatch_log_group.backend.name}
    
    ============================================
  EOT
}
