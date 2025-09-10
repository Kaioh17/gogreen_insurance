# Security Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "system_admin_users" {
  description = "List of system administrator usernames"
  type        = list(string)
}

variable "db_admin_users" {
  description = "List of database administrator usernames"
  type        = list(string)
}

variable "monitoring_users" {
  description = "List of monitoring user usernames"
  type        = list(string)
}

variable "notification_email" {
  description = "Email domain for notifications"
  type        = string
}
