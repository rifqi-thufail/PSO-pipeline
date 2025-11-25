# Terraform AWS Infrastructure for Material Management System

This directory contains Terraform configuration files to deploy the Material Management System to AWS.

## Architecture Overview

The infrastructure includes:

- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **RDS PostgreSQL**: Managed PostgreSQL 17.2 database in private subnets
- **ECS Fargate**: Containerized backend application
- **Application Load Balancer**: HTTP/HTTPS load balancer for backend
- **S3 + CloudFront**: Static hosting for React frontend with CDN
- **ECR**: Docker container registry for backend images
- **Secrets Manager**: Secure storage for database credentials and session secrets
- **CloudWatch**: Logging and monitoring
- **IAM**: Roles and policies for secure access

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials:
   ```bash
   aws configure
   ```
3. **Terraform** installed (v1.0 or higher):
   ```bash
   brew install terraform  # macOS
   ```
4. **Docker** installed for building backend image

## File Structure

```
INFRA/
├── main.tf                 # Provider and data sources
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── vpc.tf                  # VPC, subnets, NAT gateways
├── security_groups.tf      # Security groups for ALB, ECS, RDS
├── rds.tf                  # PostgreSQL database
├── ecs.tf                  # ECS cluster, task definition, service
├── alb.tf                  # Application Load Balancer
├── s3_cloudfront.tf        # S3 buckets and CloudFront distribution
├── terraform.tfvars        # Variable values (create this)
└── README.md               # This file
```

## Setup Instructions

### 1. Create `terraform.tfvars` file

Create a file named `terraform.tfvars` in the INFRA directory:

```hcl
aws_region              = "ap-southeast-1"  # Change to your preferred region
environment             = "prod"
project_name            = "material-mgmt"
db_password             = "YourSecurePassword123!"  # Change this!
session_secret          = "YourRandomSessionSecret456!"  # Change this!

# Optional: Uncomment and configure for production
# enable_db_multi_az      = true
# enable_deletion_protection = true
# domain_name             = "yourdomain.com"
# certificate_arn         = "arn:aws:acm:region:account:certificate/xxx"
```

**Important**: Never commit `terraform.tfvars` to git! Add it to `.gitignore`.

Alternatively, set via environment variables:
```bash
export TF_VAR_db_password="YourSecurePassword123!"
export TF_VAR_session_secret="YourRandomSessionSecret456!"
```

### 2. Initialize Terraform

```bash
cd INFRA
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

Review all resources that will be created. Estimated AWS costs:
- **Development**: ~$25-40/month (t3.micro RDS, 2 Fargate tasks, minimal traffic)
- **Production**: ~$80-150/month (multi-AZ RDS, more compute, CloudFront traffic)

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will take **10-15 minutes** to complete.

### 5. Note the Outputs

After completion, Terraform will display important outputs:
- **cloudfront_url**: Frontend URL
- **alb_url**: Backend API URL
- **ecr_repository_url**: Docker registry URL
- **rds_endpoint**: Database endpoint

## Deploying Your Application

### Backend Deployment

1. **Build and push Docker image**:

First, create a `Dockerfile` in the `backend/` directory:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 5001

CMD ["node", "server.js"]
```

Then build and push:

```bash
# Get ECR login
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>

# Build image
cd ../backend
docker build -t material-mgmt-backend:latest .

# Tag and push
docker tag material-mgmt-backend:latest <ECR_REPOSITORY_URL>:latest
docker push <ECR_REPOSITORY_URL>:latest
```

2. **Update ECS service**:

```bash
aws ecs update-service \
  --cluster material-mgmt-cluster-prod \
  --service material-mgmt-backend-service-prod \
  --force-new-deployment \
  --region ap-southeast-1
```

3. **Run database migrations**:

Connect to RDS and run `schema.sql`:

```bash
# Get database password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id material-mgmt-db-credentials-prod \
  --query SecretString --output text | jq -r .password)

# Connect to database (from bastion or via VPN)
psql -h <RDS_ENDPOINT> -U postgres -d material_management -f ../backend/schema.sql
```

### Frontend Deployment

1. **Build React app**:

Create `.env.production` in `frontend/`:

```env
REACT_APP_API_URL=https://<CLOUDFRONT_DOMAIN>/api
```

Then build:

```bash
cd ../frontend
npm run build
```

2. **Upload to S3**:

```bash
aws s3 sync build/ s3://<FRONTEND_BUCKET_NAME>/ --delete
```

3. **Invalidate CloudFront cache**:

```bash
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

## Backend Code Changes for AWS

Update `backend/server.js` to support S3 uploads instead of local filesystem:

```javascript
// Add AWS SDK
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'ap-southeast-1' });

// Modify multer to use S3
const multerS3 = require('multer-s3');

const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: process.env.UPLOADS_BUCKET,
    key: function (req, file, cb) {
      cb(null, `materials/${Date.now()}-${file.originalname}`);
    }
  }),
  limits: { fileSize: 5 * 1024 * 1024 }
});
```

Install required packages:

```bash
cd backend
npm install @aws-sdk/client-s3 multer-s3
```

## Monitoring and Maintenance

### View Backend Logs

```bash
aws logs tail /ecs/material-mgmt-backend-prod --follow
```

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster material-mgmt-cluster-prod \
  --services material-mgmt-backend-service-prod
```

### Database Backups

RDS automatically creates daily backups with 7-day retention (configurable via `backup_retention_period`).

To create manual snapshot:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier material-mgmt-db-prod \
  --db-snapshot-identifier material-mgmt-manual-backup-$(date +%Y%m%d)
```

## Scaling

### Scale Backend Tasks

```bash
# Scale to 4 tasks
aws ecs update-service \
  --cluster material-mgmt-cluster-prod \
  --service material-mgmt-backend-service-prod \
  --desired-count 4
```

Or update `backend_desired_count` variable and run `terraform apply`.

### Scale RDS Instance

Update `db_instance_class` in `terraform.tfvars`:

```hcl
db_instance_class = "db.t3.small"  # or db.t3.medium
```

Then apply:

```bash
terraform apply
```

## Cost Optimization

### Development Environment

For development/testing, use these settings in `terraform.tfvars`:

```hcl
environment              = "dev"
db_instance_class        = "db.t3.micro"
backend_desired_count    = 1
enable_db_multi_az       = false
enable_deletion_protection = false
backup_retention_period  = 1
```

### Stop Resources When Not in Use

```bash
# Stop ECS tasks
aws ecs update-service \
  --cluster material-mgmt-cluster-dev \
  --service material-mgmt-backend-service-dev \
  --desired-count 0

# Stop RDS (creates automatic snapshot)
aws rds stop-db-instance --db-instance-identifier material-mgmt-db-dev
```

## Security Best Practices

1. **Enable HTTPS**: Configure ACM certificate and set `certificate_arn` variable
2. **Restrict Access**: Update `allowed_cidr_blocks` to specific IPs in production
3. **Enable MFA**: Enable MFA delete on S3 buckets
4. **Rotate Secrets**: Regularly rotate database password and session secret
5. **Enable WAF**: Add AWS WAF to CloudFront distribution for DDoS protection
6. **VPN/Bastion**: Set up VPN or bastion host for database access

## Disaster Recovery

### Backup Strategy

1. **RDS**: Automated daily backups with 7-day retention
2. **S3**: Versioning enabled on both frontend and uploads buckets
3. **Terraform State**: Store in S3 with versioning (add backend configuration)

### Restore Procedure

1. **Database**: Restore from RDS snapshot
2. **Frontend**: Restore from S3 version history
3. **Infrastructure**: Recreate with Terraform

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all data including the database. Make sure you have backups!

To keep data safe, export database first:

```bash
pg_dump -h <RDS_ENDPOINT> -U postgres material_management > backup.sql
```

## Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch logs: `/ecs/material-mgmt-backend-prod`
2. Verify Docker image was pushed successfully to ECR
3. Check security group rules allow traffic from ALB to ECS
4. Verify Secrets Manager secrets are accessible

### Database Connection Issues

1. Verify security group allows PostgreSQL (5432) from ECS tasks
2. Check RDS instance is in `available` state
3. Verify credentials in Secrets Manager
4. Test connection from ECS task using `psql`

### Frontend Not Loading

1. Check S3 bucket has files: `aws s3 ls s3://<BUCKET_NAME>/`
2. Verify CloudFront distribution is deployed (wait 10-15 minutes)
3. Check CloudFront invalidation completed
4. Verify API URL in frontend build is correct

### High Costs

1. Review CloudWatch metrics for unused resources
2. Check NAT Gateway data transfer (expensive)
3. Consider removing NAT Gateway if backend doesn't need internet access
4. Enable S3 lifecycle policies to archive old objects

## Support and Documentation

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **ECS Best Practices**: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/
- **RDS PostgreSQL**: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/
- **CloudFront**: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/

## CI/CD Integration

For automated deployments, see `../testing/deploy-to-aws.sh` script (create this based on deployment instructions above).

Consider using:
- **GitHub Actions** for CI/CD pipeline
- **AWS CodePipeline** for native AWS integration
- **Terraform Cloud** for remote state management

## License

See main project LICENSE file.
