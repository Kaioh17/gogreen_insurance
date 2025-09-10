# Monitoring Module - GoGreen Insurance
# Creates CloudWatch dashboards, CloudTrail, and monitoring configurations

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "gogreen-insurance-cloudtrail"
  s3_bucket_name               = var.cloudtrail_bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${var.cloudtrail_bucket_arn}/*"]
    }
  }

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::RDS::DBInstance"
      values = ["*"]
    }
  }

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::EC2::Instance"
      values = ["*"]
    }
  }

  tags = {
    Name = "gogreen-insurance-cloudtrail"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "GoGreen-Insurance-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.web_asg_az1_name],
            [".", ".", ".", var.web_asg_az2_name],
            [".", ".", ".", var.app_asg_az1_name],
            [".", ".", ".", var.app_asg_az2_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CPU Utilization by Tier"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."],
            [".", "FreeStorageSpace", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Database Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["GoGreen/WebTier", "MemoryUtilization", "AutoScalingGroupName", var.web_asg_az1_name],
            [".", ".", ".", var.web_asg_az2_name],
            ["GoGreen/AppTier", "MemoryUtilization", "AutoScalingGroupName", var.app_asg_az1_name],
            [".", ".", ".", var.app_asg_az2_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Memory Utilization by Tier"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "web_tier" {
  name              = "/aws/ec2/gogreen/web-tier"
  retention_in_days = 7

  tags = {
    Name = "gogreen-web-tier-logs"
  }
}

resource "aws_cloudwatch_log_group" "app_tier" {
  name              = "/aws/ec2/gogreen/app-tier"
  retention_in_days = 7

  tags = {
    Name = "gogreen-app-tier-logs"
  }
}

resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/applicationloadbalancer/gogreen"
  retention_in_days = 7

  tags = {
    Name = "gogreen-alb-logs"
  }
}

# CloudWatch Log Stream for Web Tier
resource "aws_cloudwatch_log_stream" "web_tier" {
  name           = "web-tier-stream"
  log_group_name = aws_cloudwatch_log_group.web_tier.name
}

# CloudWatch Log Stream for App Tier
resource "aws_cloudwatch_log_stream" "app_tier" {
  name           = "app-tier-stream"
  log_group_name = aws_cloudwatch_log_group.app_tier.name
}

# CloudWatch Log Stream for ALB
resource "aws_cloudwatch_log_stream" "alb" {
  name           = "alb-stream"
  log_group_name = aws_cloudwatch_log_group.alb.name
}

# CloudWatch Alarms for Overall System Health
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "gogreen-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "This metric monitors high error rate"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "gogreen-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors high response time"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "low_healthy_hosts" {
  alarm_name          = "gogreen-low-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors low healthy host count"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# CloudWatch Composite Alarm for Critical Issues
resource "aws_cloudwatch_metric_alarm" "critical_system_health" {
  alarm_name          = "gogreen-critical-system-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors critical system health"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_az1_name
  }
}

# AWS Backup Vault
resource "aws_backup_vault" "main" {
  name        = "gogreen-insurance-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = {
    Name = "gogreen-insurance-backup-vault"
  }
}

# AWS Backup Plan
resource "aws_backup_plan" "main" {
  name = "gogreen-insurance-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM

    lifecycle {
      cold_storage_after = 30
      delete_after       = 90
    }

    recovery_point_tags = {
      Environment = "Production"
      Project     = "GoGreen-Insurance"
    }
  }

  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * SUN *)" # Weekly on Sunday at 3 AM

    lifecycle {
      cold_storage_after = 7
      delete_after       = 365
    }

    recovery_point_tags = {
      Environment = "Production"
      Project     = "GoGreen-Insurance"
    }
  }

  tags = {
    Name = "gogreen-insurance-backup-plan"
  }
}

# AWS Backup Selection
resource "aws_backup_selection" "main" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "gogreen-insurance-backup-selection"
  plan_id      = aws_backup_plan.main.id

  resources = [
    "arn:aws:rds:us-east-1:${data.aws_caller_identity.current.account_id}:db:${var.rds_identifier}",
    "arn:aws:rds:us-east-1:${data.aws_caller_identity.current.account_id}:db:${var.rds_read_replica_identifier}"
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Project"
      value = "GoGreen-Insurance"
    }
  }
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "gogreen-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "gogreen-backup-role"
  }
}

# Attach AWS Backup service role policy
resource "aws_iam_role_policy_attachment" "backup_role" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
