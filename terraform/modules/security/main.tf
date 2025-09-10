# Security Module - GoGreen Insurance
# Creates IAM users/groups, security groups, and KMS key

# KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for GoGreen Insurance encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "gogreen-insurance-kms-key"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/gogreen-insurance-key"
  target_key_id = aws_kms_key.main.key_id
}

# IAM Groups
resource "aws_iam_group" "system_admins" {
  name = "GoGreen-SystemAdmins"
  path = "/"
}

resource "aws_iam_group" "db_admins" {
  name = "GoGreen-DBAdmins"
  path = "/"
}

resource "aws_iam_group" "monitoring" {
  name = "GoGreen-Monitoring"
  path = "/"
}

# IAM Users for System Administrators
resource "aws_iam_user" "system_admins" {
  count = length(var.system_admin_users)
  name  = var.system_admin_users[count.index]
  path  = "/"

  tags = {
    Name = var.system_admin_users[count.index]
    Role = "System Administrator"
  }
}

# IAM Users for Database Administrators
resource "aws_iam_user" "db_admins" {
  count = length(var.db_admin_users)
  name  = var.db_admin_users[count.index]
  path  = "/"

  tags = {
    Name = var.db_admin_users[count.index]
    Role = "Database Administrator"
  }
}

# IAM Users for Monitoring
resource "aws_iam_user" "monitoring" {
  count = length(var.monitoring_users)
  name  = var.monitoring_users[count.index]
  path  = "/"

  tags = {
    Name = var.monitoring_users[count.index]
    Role = "Monitoring"
  }
}

# Group Memberships
resource "aws_iam_user_group_membership" "system_admins" {
  count = length(aws_iam_user.system_admins)
  user  = aws_iam_user.system_admins[count.index].name
  groups = [aws_iam_group.system_admins.name]
}

resource "aws_iam_user_group_membership" "db_admins" {
  count = length(aws_iam_user.db_admins)
  user  = aws_iam_user.db_admins[count.index].name
  groups = [aws_iam_group.db_admins.name]
}

resource "aws_iam_user_group_membership" "monitoring" {
  count = length(aws_iam_user.monitoring)
  user  = aws_iam_user.monitoring[count.index].name
  groups = [aws_iam_group.monitoring.name]
}

# IAM Policies
resource "aws_iam_policy" "system_admin_policy" {
  name        = "GoGreen-SystemAdminPolicy"
  description = "Policy for system administrators"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "iam:*",
          "cloudwatch:*",
          "sns:*",
          "kms:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "db_admin_policy" {
  name        = "GoGreen-DBAdminPolicy"
  description = "Policy for database administrators"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:*",
          "ec2:DescribeInstances",
          "s3:GetObject",
          "s3:PutObject",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "monitoring_policy" {
  name        = "GoGreen-MonitoringPolicy"
  description = "Policy for monitoring users"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "sns:ListTopics",
          "sns:Subscribe",
          "ec2:DescribeInstances",
          "rds:DescribeDBInstances",
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to groups
resource "aws_iam_group_policy_attachment" "system_admin_policy" {
  group      = aws_iam_group.system_admins.name
  policy_arn = aws_iam_policy.system_admin_policy.arn
}

resource "aws_iam_group_policy_attachment" "db_admin_policy" {
  group      = aws_iam_group.db_admins.name
  policy_arn = aws_iam_policy.db_admin_policy.arn
}

resource "aws_iam_group_policy_attachment" "monitoring_policy" {
  group      = aws_iam_group.monitoring.name
  policy_arn = aws_iam_policy.monitoring_policy.arn
}

# Password Policy
resource "aws_iam_account_password_policy" "main" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 3
  hard_expiry                    = false
}

# Security Groups
# Web Tier Security Group (AZ-1)
resource "aws_security_group" "web" {
  name        = "Web-SG"
  description = "Security group for web tier instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG"
  }
}

# Web Tier Security Group (AZ-2)
resource "aws_security_group" "web_2" {
  name        = "Web-SG-2"
  description = "Security group for web tier instances in AZ-2"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-SG-2"
  }
}

# Application Tier Security Group (AZ-1)
resource "aws_security_group" "app" {
  name        = "app-SG"
  description = "Security group for application tier instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Web Tier"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description = "HTTPS from Web Tier"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-SG"
  }
}

# Application Tier Security Group (AZ-2)
resource "aws_security_group" "app_2" {
  name        = "app-SG-2"
  description = "Security group for application tier instances in AZ-2"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Web Tier"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.web_2.id]
  }

  ingress {
    description = "HTTPS from Web Tier"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    security_groups = [aws_security_group.web_2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-SG-2"
  }
}

# Database Security Group (Primary)
resource "aws_security_group" "db" {
  name        = "dh-sg-private-db"
  description = "Security group for primary database"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from App Tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description = "MySQL from App Tier AZ-2"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dh-sg-private-db"
  }
}

# Database Security Group (Read Replica)
resource "aws_security_group" "db_2" {
  name        = "dh-sg-p-private-db"
  description = "Security group for read replica database"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from App Tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description = "MySQL from App Tier AZ-2"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dh-sg-p-private-db"
  }
}

# SNS Topic for notifications
resource "aws_sns_topic" "alerts" {
  name = "gogreen-insurance-alerts"
  
  tags = {
    Name = "gogreen-insurance-alerts"
  }
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "system_admins" {
  count     = length(var.system_admin_users)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "${var.system_admin_users[count.index]}${var.notification_email}"
}

resource "aws_sns_topic_subscription" "db_admins" {
  count     = length(var.db_admin_users)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "${var.db_admin_users[count.index]}${var.notification_email}"
}

resource "aws_sns_topic_subscription" "monitoring" {
  count     = length(var.monitoring_users)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "${var.monitoring_users[count.index]}${var.notification_email}"
}
