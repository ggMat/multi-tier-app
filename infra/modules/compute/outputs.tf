output "alb_dns_name" { value = aws_lb.this.dns_name }
output "target_group_arn" { value = aws_lb_target_group.this.arn }
output "log_group_name" { value = aws_cloudwatch_log_group.app.name }
output "asg_name" { value = aws_autoscaling_group.this.name }
output "asg_arn" { value = aws_autoscaling_group.this.arn }
