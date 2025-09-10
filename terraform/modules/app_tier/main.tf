# Application Tier Module - GoGreen Insurance
# Creates Launch Template and Auto Scaling Groups for application tier

# Data source for latest RHEL AMI
data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat AMI owner ID
  
  filter {
    name   = "name"
    values = ["RHEL-8*HVM-*"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Launch Template for App Instances
resource "aws_launch_template" "app" {
  name_prefix   = "gogreen-app-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    tier = "app"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-tier"
    }
  }

  tags = {
    Name = "gogreen-app-launch-template"
  }
}

# Auto Scaling Group for App Tier (AZ-1)
resource "aws_autoscaling_group" "app_az1" {
  name                = "gogreen-app-asg-az1"
  vpc_zone_identifier = [var.private_subnet_ids[0]]
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Private App-1"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Application"
    propagate_at_launch = true
  }

  tag {
    key                 = "AvailabilityZone"
    value               = "us-east-1a"
    propagate_at_launch = true
  }
}

# Auto Scaling Group for App Tier (AZ-2)
resource "aws_autoscaling_group" "app_az2" {
  name                = "gogreen-app-asg-az2"
  vpc_zone_identifier = [var.private_subnet_ids[1]]
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Private App-2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Application"
    propagate_at_launch = true
  }

  tag {
    key                 = "AvailabilityZone"
    value               = "us-east-1b"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy - Scale Out (CPU)
resource "aws_autoscaling_policy" "app_cpu_scale_out" {
  name                   = "gogreen-app-cpu-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az1.name
}

resource "aws_autoscaling_policy" "app_cpu_scale_out_az2" {
  name                   = "gogreen-app-cpu-scale-out-az2"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az2.name
}

# Auto Scaling Policy - Scale In (CPU)
resource "aws_autoscaling_policy" "app_cpu_scale_in" {
  name                   = "gogreen-app-cpu-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az1.name
}

resource "aws_autoscaling_policy" "app_cpu_scale_in_az2" {
  name                   = "gogreen-app-cpu-scale-in-az2"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az2.name
}

# Auto Scaling Policy - Scale Out (Memory)
resource "aws_autoscaling_policy" "app_memory_scale_out" {
  name                   = "gogreen-app-memory-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az1.name
}

resource "aws_autoscaling_policy" "app_memory_scale_out_az2" {
  name                   = "gogreen-app-memory-scale-out-az2"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az2.name
}

# Auto Scaling Policy - Scale In (Memory)
resource "aws_autoscaling_policy" "app_memory_scale_in" {
  name                   = "gogreen-app-memory-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az1.name
}

resource "aws_autoscaling_policy" "app_memory_scale_in_az2" {
  name                   = "gogreen-app-memory-scale-in-az2"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_az2.name
}

# CloudWatch Alarm - High CPU
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "gogreen-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors app tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.app_cpu_scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_high_az2" {
  alarm_name          = "gogreen-app-cpu-high-az2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors app tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.app_cpu_scale_out_az2.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az2.name
  }
}

# CloudWatch Alarm - Low CPU
resource "aws_cloudwatch_metric_alarm" "app_cpu_low" {
  alarm_name          = "gogreen-app-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors app tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.app_cpu_scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_low_az2" {
  alarm_name          = "gogreen-app-cpu-low-az2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors app tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.app_cpu_scale_in_az2.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az2.name
  }
}

# CloudWatch Alarm - High Memory
resource "aws_cloudwatch_metric_alarm" "app_memory_high" {
  alarm_name          = "gogreen-app-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "GoGreen/AppTier"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors app tier memory utilization"
  alarm_actions       = [aws_autoscaling_policy.app_memory_scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "app_memory_high_az2" {
  alarm_name          = "gogreen-app-memory-high-az2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "GoGreen/AppTier"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors app tier memory utilization"
  alarm_actions       = [aws_autoscaling_policy.app_memory_scale_out_az2.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az2.name
  }
}

# CloudWatch Alarm - Low Memory
resource "aws_cloudwatch_metric_alarm" "app_memory_low" {
  alarm_name          = "gogreen-app-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "GoGreen/AppTier"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors app tier memory utilization"
  alarm_actions       = [aws_autoscaling_policy.app_memory_scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "app_memory_low_az2" {
  alarm_name          = "gogreen-app-memory-low-az2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "GoGreen/AppTier"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors app tier memory utilization"
  alarm_actions       = [aws_autoscaling_policy.app_memory_scale_in_az2.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_az2.name
  }
}
