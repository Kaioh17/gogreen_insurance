# GoGreen Insurance AWS Infrastructure

This Terraform project creates a complete AWS infrastructure for GoGreen Insurance, a regional insurance company migrating from on-premises to the cloud.

## Architecture Overview

![GoGreen Insurance AWS Architecture](GoGreen%20Insurance%20copy.png)

The infrastructure includes:
- **VPC**: Multi-AZ VPC with public, private, and database subnets
- **Web Tier**: Auto-scaling EC2 instances behind Application Load Balancer
- **Application Tier**: Auto-scaling EC2 instances in private subnets
- **Database Tier**: RDS MySQL with Multi-AZ deployment and read replica
- **Storage**: S3 buckets with lifecycle policies for document storage
- **Security**: IAM, Security Groups, KMS encryption
- **Monitoring**: CloudWatch, SNS, CloudTrail, AWS Backup

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **S3 bucket** for Terraform state storage
4. **DynamoDB table** for state locking

## AWS Credentials Setup

### Option 1: Environment Variables (Recommended)
The project includes pre-configured AWS credentials in `aws-credentials.env`:

**Windows (PowerShell):**
```powershell
# Load credentials
.\load-credentials.ps1

# Then run Terraform
terraform init
terraform plan
terraform apply
```

**WSL Ubuntu/Linux (Bash):**
```bash
# Make scripts executable
chmod +x *.sh

# Option 1: Quick setup (recommended)
./wsl-setup.sh

# Option 2: Manual setup
# Load credentials
source ./load-credentials.sh

# Test credentials
./test-credentials.sh

# If credentials are valid, run Terraform
terraform init
terraform plan
terraform apply
```

### Option 2: AWS CLI Configuration
```bash
aws configure
# Enter your access key, secret key, and region
```

### Option 3: AWS Credentials File
Create `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = AKIAZQDfdffds2O7VQLT6DDM7M
aws_secret_access_key = nM3ZaNYfdfdcsdsdsdsQQdFRa9EFn6PCQGwFo41UtL47dsdsddsnN6k7GF
```

### Required AWS Resources (Create before running Terraform)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://gogreen-terraform-state --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name gogreen-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

## Project Structure

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tf            # Terraform version and backend
├── providers.tf            # Provider configurations
├── README.md               # This file
└── modules/
    ├── vpc/                # VPC and networking
    ├── security/           # IAM, Security Groups, KMS
    ├── web_tier/           # Web tier with ALB and Auto Scaling
    ├── app_tier/           # Application tier with Auto Scaling
    ├── database/           # RDS MySQL with read replica
    ├── storage/            # S3 buckets and lifecycle policies
    └── monitoring/         # CloudWatch, SNS, CloudTrail
```

## Usage

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan the deployment

```bash
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply
```

### 4. Destroy the infrastructure (when needed)

```bash
terraform destroy
```

## Configuration

### Key Variables

- `aws_region`: AWS region (default: us-east-1)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `web_instance_type`: Web tier instance type (default: t3.large)
- `app_instance_type`: App tier instance type (default: r5a.xlarge)
- `db_instance_class`: Database instance class (default: db.r5.2xlarge)

### Instance Configuration

- **Web Tier**: 6 t3.large instances (3 per AZ) with RHEL 8
- **App Tier**: 4 r5a.xlarge instances (2 per AZ) with RHEL 8
- **Database**: db.r5.2xlarge with 21,000 IOPS and Multi-AZ

## Security Features

- **Encryption**: All data encrypted at rest and in transit
- **IAM**: Role-based access control with MFA
- **Security Groups**: Tier-specific network access controls
- **VPC**: Private subnets for application and database tiers
- **CloudTrail**: Comprehensive API logging

## Monitoring and Alerting

- **CloudWatch**: Custom dashboards and alarms
- **SNS**: Email notifications for critical events
- **Auto Scaling**: CPU and memory-based scaling policies
- **AWS Backup**: Automated backup and recovery

## Cost Optimization

- **S3 Lifecycle**: Automatic transition to cheaper storage classes
- **Auto Scaling**: Right-size resources based on demand
- **Reserved Instances**: Available for predictable workloads
- **Managed Services**: Reduced operational overhead

## Outputs

After deployment, the following outputs are available:

- `alb_dns_name`: Application Load Balancer DNS name
- `rds_endpoint`: Primary database endpoint
- `rds_read_replica_endpoint`: Read replica endpoint
- `documents_bucket_name`: S3 bucket for documents
- `kms_key_id`: KMS key for encryption

## Route 53 Configuration

**Note**: Configure Route 53 to point your domain to the ALB DNS name provided in the outputs.

## Troubleshooting

### Common Issues

1. **State Lock**: If Terraform gets stuck, check DynamoDB for lock entries
2. **Permissions**: Ensure AWS credentials have sufficient permissions
3. **Resource Limits**: Check AWS service limits for your account
4. **Dependencies**: Some resources may take time to provision

### Useful Commands

```bash
# Check Terraform state
terraform state list

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Refresh state
terraform refresh

# Show current state
terraform show
```

## Support

For issues or questions, refer to:
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Service Documentation](https://docs.aws.amazon.com/)
- [GoGreen Insurance Architecture Documentation](../aws_architecture_documentation.md)
