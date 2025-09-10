# GoGreen Insurance - Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.web_tier.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.web_tier.alb_zone_id
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.rds_endpoint
}

output "rds_read_replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = module.database.rds_read_replica_endpoint
}

# S3 Outputs
output "documents_bucket_name" {
  description = "Name of the documents S3 bucket"
  value       = module.storage.documents_bucket_name
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket"
  value       = module.storage.cloudtrail_bucket_name
}

# Security Outputs
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.security.kms_key_id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = module.security.sns_topic_arn
}

# IAM Outputs
output "system_admin_group_name" {
  description = "Name of the system administrators group"
  value       = module.security.system_admin_group_name
}

output "db_admin_group_name" {
  description = "Name of the database administrators group"
  value       = module.security.db_admin_group_name
}

output "monitoring_group_name" {
  description = "Name of the monitoring group"
  value       = module.security.monitoring_group_name
}

# Route 53 Output (placeholder)
output "route53_instructions" {
  description = "Instructions for Route 53 configuration"
  value       = "Configure Route 53 to point your domain to the ALB DNS name: ${module.web_tier.alb_dns_name}"
}
