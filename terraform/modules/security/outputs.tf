# Security Module Outputs

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.main.name
}

# IAM Group Names
output "system_admin_group_name" {
  description = "Name of the system administrators group"
  value       = aws_iam_group.system_admins.name
}

output "db_admin_group_name" {
  description = "Name of the database administrators group"
  value       = aws_iam_group.db_admins.name
}

output "monitoring_group_name" {
  description = "Name of the monitoring group"
  value       = aws_iam_group.monitoring.name
}

# Security Group IDs
output "web_security_group_id" {
  description = "ID of the web tier security group (AZ-1)"
  value       = aws_security_group.web.id
}

output "web_security_group_2_id" {
  description = "ID of the web tier security group (AZ-2)"
  value       = aws_security_group.web_2.id
}

output "app_security_group_id" {
  description = "ID of the application tier security group (AZ-1)"
  value       = aws_security_group.app.id
}

output "app_security_group_2_id" {
  description = "ID of the application tier security group (AZ-2)"
  value       = aws_security_group.app_2.id
}

output "db_security_group_id" {
  description = "ID of the database security group (Primary)"
  value       = aws_security_group.db.id
}

output "db_security_group_2_id" {
  description = "ID of the database security group (Read Replica)"
  value       = aws_security_group.db_2.id
}

# SNS Topic
output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}
