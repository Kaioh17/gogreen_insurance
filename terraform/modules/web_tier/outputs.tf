# Web Tier Module Outputs

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

output "autoscaling_group_az1_name" {
  description = "Name of the Auto Scaling Group in AZ-1"
  value       = aws_autoscaling_group.web_az1.name
}

output "autoscaling_group_az2_name" {
  description = "Name of the Auto Scaling Group in AZ-2"
  value       = aws_autoscaling_group.web_az2.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.web.id
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  value       = aws_lb.main.arn_suffix
}
