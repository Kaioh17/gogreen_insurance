# Database Module Outputs

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.primary.port
}

output "rds_read_replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = aws_db_instance.read_replica.endpoint
}

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.primary.identifier
}

output "rds_read_replica_identifier" {
  description = "RDS read replica identifier"
  value       = aws_db_instance.read_replica.identifier
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.primary.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.primary.username
}

output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "secrets_manager_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_password.name
}
