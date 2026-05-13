output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "Public hostname for the application"
}

output "bastion_public_ip" {
  value       = module.bastion.public_ip
  description = "Bastion public IP for SSH tunneling"
}

output "nat_instance_public_ip" {
  value       = module.nat_instance.public_ip
  description = "NAT instance public IP (debugging only)"
}

output "rds_endpoint" {
  value       = module.db.endpoint
  description = "RDS hostname (reach via bastion tunnel)"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repo URI for docker push"
}

output "gha_app_role_arn" {
  value       = module.security.gha_app_role_arn
  description = "OIDC role ARN for the app.yml GitHub Actions workflow"
}

output "gha_infra_role_arn" {
  value       = module.security.gha_infra_role_arn
  description = "OIDC role ARN for the infra.yml GitHub Actions workflow"
}

output "asg_name" {
  value       = module.compute.asg_name
  description = "ASG name for instance refresh from CI"
}

output "log_group_name" {
  value       = module.compute.log_group_name
  description = "CloudWatch Logs group with container stdout/stderr"
}
