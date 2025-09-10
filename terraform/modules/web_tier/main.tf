# Web Tier Module - GoGreen Insurance
# Creates Application Load Balancer, Launch Template, and Auto Scaling Groups

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

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "gogreen-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "gogreen-web-alb"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Target Group for Web Instances
resource "aws_lb_target_group" "web" {
  name     = "gogreen-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "gogreen-web-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Launch Template for Web Instances
resource "aws_launch_template" "web" {
  name_prefix   = "gogreen-web-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    tier = "web"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-tier"
    }
  }

  tags = {
    Name = "gogreen-web-launch-template"
  }
}

# Auto Scaling Group for Web Tier (AZ-1)
resource "aws_autoscaling_group" "web_az1" {
  name                = "gogreen-web-asg-az1"
  vpc_zone_identifier = [var.public_subnet_ids[0]]
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Private Web Tier-1"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Web"
    propagate_at_launch = true
  }

  tag {
    key                 = "AvailabilityZone"
    value               = "us-east-1a"
    propagate_at_launch = true
  }
}

# Auto Scaling Group for Web Tier (AZ-2)
resource "aws_autoscaling_group" "web_az2" {
  name                = "gogreen-web-asg-az2"
  vpc_zone_identifier = [var.public_subnet_ids[1]]
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Private Web Tier-2"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Web"
    propagate_at_launch = true
  }

  tag {
    key                 = "AvailabilityZone"
    value               = "us-east-1b"
    propagate_at_launch = true
  }
}

# Auto Scaling Policy - Scale Out
resource "aws_autoscaling_policy" "web_scale_out" {
  name                   = "gogreen-web-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_az1.name
}

resource "aws_autoscaling_policy" "web_scale_out_az2" {
  name                   = "gogreen-web-scale-out-az2"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_az2.name
}

# Auto Scaling Policy - Scale In
resource "aws_autoscaling_policy" "web_scale_in" {
  name                   = "gogreen-web-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_az1.name
}

resource "aws_autoscaling_policy" "web_scale_in_az2" {
  name                   = "gogreen-web-scale-in-az2"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_az2.name
}

# CloudWatch Alarm - High CPU
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "gogreen-web-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors web tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.web_scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_az1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_high_az2" {
  alarm_name          = "gogreen-web-cpu-high-az2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors web tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.web_scale_out_az2.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_az2.name
  }
}

# CloudWatch Alarm - Low CPU
resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  alarm_name          = "gogreen-web-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors web tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.web_scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_az1.name
  }
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_low_az2" {
  alarm_name          = "gogreen-web-cpu-low-az2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors web tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.web_scale_in_az2.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_az2.name
  }
}

# CloudWatch Alarm - HTTP 400 Errors
resource "aws_cloudwatch_metric_alarm" "web_http_400_errors" {
  alarm_name          = "gogreen-web-http-400-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors web tier HTTP 400 errors"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
