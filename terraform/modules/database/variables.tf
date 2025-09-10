# Database Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of database subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Initial allocated storage for RDS (GB)"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for RDS (GB)"
  type        = number
}

variable "storage_type" {
  description = "RDS storage type"
  type        = string
}

variable "iops" {
  description = "RDS IOPS for provisioned storage"
  type        = number
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  type        = string
}
