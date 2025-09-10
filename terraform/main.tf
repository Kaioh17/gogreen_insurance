# GoGreen Insurance AWS Infrastructure
# Main Terraform configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  backend "s3" {
    bucket         = "gogreen-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "gogreen-terraform-locks"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "GoGreen-Insurance"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat AMI owner ID
  
  filter {
    name   = "name"
    values = ["RHEL-8*HVM-*"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name           = "prod-vpc"
  aws_region         = var.aws_region
  availability_zones = data.aws_availability_zones.available.names
  cidr_block         = var.vpc_cidr
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}

# Security Module
module "security" {
  source = "./modules/security"
  
  vpc_id = module.vpc.vpc_id
  
  # IAM Configuration
  system_admin_users     = var.system_admin_users
  db_admin_users        = var.db_admin_users
  monitoring_users      = var.monitoring_users
  
  # SNS Configuration
  notification_email = var.notification_email
}

# Web Tier Module
module "web_tier" {
  source = "./modules/web_tier"
  
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  ami_id              = data.aws_ami.rhel.id
  instance_type       = var.web_instance_type
  min_size           = var.web_min_size
  max_size           = var.web_max_size
  desired_capacity   = var.web_desired_capacity
  
  security_group_ids = [
    module.security.web_security_group_id,
    module.security.web_security_group_2_id
  ]
  
  sns_topic_arn = module.security.sns_topic_arn
  
  depends_on = [module.vpc, module.security]
}

# Application Tier Module
module "app_tier" {
  source = "./modules/app_tier"
  
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  ami_id              = data.aws_ami.rhel.id
  instance_type       = var.app_instance_type
  min_size           = var.app_min_size
  max_size           = var.app_max_size
  desired_capacity   = var.app_desired_capacity
  
  security_group_ids = [
    module.security.app_security_group_id,
    module.security.app_security_group_2_id
  ]
  
  depends_on = [module.vpc]
}

# Database Module
module "database" {
  source = "./modules/database"
  
  vpc_id                = module.vpc.vpc_id
  database_subnet_ids   = module.vpc.database_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  iops                 = var.db_iops
  
  security_group_ids = [
    module.security.db_security_group_id,
    module.security.db_security_group_2_id
  ]
  
  kms_key_id = module.security.kms_key_id
  sns_topic_arn = module.security.sns_topic_arn
  
  depends_on = [module.vpc, module.security]
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  kms_key_id = module.security.kms_key_id
  
  depends_on = [module.security]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  vpc_id = module.vpc.vpc_id
  
  # SNS Topics
  sns_topic_arn = module.security.sns_topic_arn
  
  # CloudTrail S3 bucket
  cloudtrail_bucket = module.storage.cloudtrail_bucket_name
  cloudtrail_bucket_arn = module.storage.cloudtrail_bucket_arn
  
  # Load Balancer ARN for monitoring
  alb_arn = module.web_tier.alb_arn
  alb_arn_suffix = module.web_tier.alb_arn_suffix
  
  # Auto Scaling Group names
  web_asg_az1_name = module.web_tier.autoscaling_group_az1_name
  web_asg_az2_name = module.web_tier.autoscaling_group_az2_name
  app_asg_az1_name = module.app_tier.autoscaling_group_az1_name
  app_asg_az2_name = module.app_tier.autoscaling_group_az2_name
  
  # Database identifiers
  rds_identifier = module.database.rds_identifier
  rds_read_replica_identifier = module.database.rds_read_replica_identifier
  
  # KMS key ARN
  kms_key_arn = module.security.kms_key_arn
  
  depends_on = [module.storage, module.security, module.web_tier, module.app_tier, module.database]
}
