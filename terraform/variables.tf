# GoGreen Insurance - Variables Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}

# Web Tier Configuration
variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.large"
}

variable "web_min_size" {
  description = "Minimum number of web instances"
  type        = number
  default     = 3
}

variable "web_max_size" {
  description = "Maximum number of web instances"
  type        = number
  default     = 6
}

variable "web_desired_capacity" {
  description = "Desired number of web instances"
  type        = number
  default     = 6
}

# Application Tier Configuration
variable "app_instance_type" {
  description = "EC2 instance type for application tier"
  type        = string
  default     = "r5a.xlarge"
}

variable "app_min_size" {
  description = "Minimum number of app instances"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of app instances"
  type        = number
  default     = 8
}

variable "app_desired_capacity" {
  description = "Desired number of app instances"
  type        = number
  default     = 4
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r5.2xlarge"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS (GB)"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS (GB)"
  type        = number
  default     = 1000
}

variable "db_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "io1"
}

variable "db_iops" {
  description = "RDS IOPS for provisioned storage"
  type        = number
  default     = 21000
}

# IAM User Configuration
variable "system_admin_users" {
  description = "List of system administrator usernames"
  type        = list(string)
  default     = ["sysadmin1", "sysadmin2"]
}

variable "db_admin_users" {
  description = "List of database administrator usernames"
  type        = list(string)
  default     = ["dbadmin1", "dbadmin2"]
}

variable "monitoring_users" {
  description = "List of monitoring user usernames"
  type        = list(string)
  default     = ["monitor1", "monitor2", "monitor3", "monitor4"]
}

# Notification Configuration
variable "notification_email" {
  description = "Email domain for notifications (e.g., @gogreen.com)"
  type        = string
  default     = "@gogreen.com"
}

# Environment Configuration
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "gogreen-insurance"
}
