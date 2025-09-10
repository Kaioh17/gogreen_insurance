# Monitoring Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  type        = string
}

variable "cloudtrail_bucket" {
  description = "Name of the CloudTrail S3 bucket"
  type        = string
}

variable "cloudtrail_bucket_arn" {
  description = "ARN of the CloudTrail S3 bucket"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "web_asg_az1_name" {
  description = "Name of the web tier Auto Scaling Group in AZ-1"
  type        = string
}

variable "web_asg_az2_name" {
  description = "Name of the web tier Auto Scaling Group in AZ-2"
  type        = string
}

variable "app_asg_az1_name" {
  description = "Name of the app tier Auto Scaling Group in AZ-1"
  type        = string
}

variable "app_asg_az2_name" {
  description = "Name of the app tier Auto Scaling Group in AZ-2"
  type        = string
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "rds_read_replica_identifier" {
  description = "RDS read replica identifier"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key"
  type        = string
}
