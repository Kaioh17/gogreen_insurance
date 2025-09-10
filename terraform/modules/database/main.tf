# Database Module - GoGreen Insurance
# Creates RDS MySQL primary and read replica with EBS storage

# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "gogreen-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "gogreen-db-subnet-group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "gogreen-mysql-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "1000"
  }

  parameter {
    name  = "innodb_log_file_size"
    value = "268435456"
  }

  tags = {
    Name = "gogreen-mysql-params"
  }
}

# RDS Primary Instance
resource "aws_db_instance" "primary" {
  identifier = "gogreen-db-primary"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id           = var.kms_key_id

  # IOPS configuration
  iops = var.iops

  # Database configuration
  db_name  = "gogreen_insurance"
  username = "admin"
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  delete_automated_backups = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  # Multi-AZ for high availability
  multi_az = true

  # Deletion protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "gogreen-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = "primary"
    Type = "Primary"
  }

  depends_on = [aws_cloudwatch_log_group.rds_enhanced_monitoring]
}

# RDS Read Replica
resource "aws_db_instance" "read_replica" {
  identifier = "gogreen-db-read-replica"

  # Replica configuration
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.instance_class

  # Storage configuration
  storage_encrypted = true
  kms_key_id       = var.kms_key_id

  # Network configuration
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Deletion protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "gogreen-db-read-replica-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = "read replica"
    Type = "Read Replica"
  }

  depends_on = [aws_db_instance.primary]
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "gogreen-rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "gogreen-rds-enhanced-monitoring-role"
  }
}

# Attach policy to RDS monitoring role
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Group for RDS Enhanced Monitoring
resource "aws_cloudwatch_log_group" "rds_enhanced_monitoring" {
  name              = "/aws/rds/instance/gogreen-db-primary/mysql"
  retention_in_days = 7

  tags = {
    Name = "gogreen-rds-enhanced-monitoring-logs"
  }
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "gogreen-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "gogreen-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "800"
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  alarm_name          = "gogreen-rds-freeable-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000" # 1GB in bytes
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
}

# Store database password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "gogreen-db-password"
  description = "Password for GoGreen Insurance database"
  kms_key_id  = var.kms_key_id

  tags = {
    Name = "gogreen-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = aws_db_instance.primary.username
    password = random_password.db_password.result
    engine   = aws_db_instance.primary.engine
    host     = aws_db_instance.primary.endpoint
    port     = aws_db_instance.primary.port
    dbname   = aws_db_instance.primary.db_name
  })
}
