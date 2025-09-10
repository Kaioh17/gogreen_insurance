# Application Tier Module Outputs

output "autoscaling_group_az1_name" {
  description = "Name of the Auto Scaling Group in AZ-1"
  value       = aws_autoscaling_group.app_az1.name
}

output "autoscaling_group_az2_name" {
  description = "Name of the Auto Scaling Group in AZ-2"
  value       = aws_autoscaling_group.app_az2.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}
