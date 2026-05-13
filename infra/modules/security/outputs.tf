output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id" { value = aws_security_group.db.id }
output "bastion_sg_id" { value = aws_security_group.bastion.id }
output "nat_sg_id" { value = aws_security_group.nat.id }

output "ec2_instance_profile_name" { value = aws_iam_instance_profile.ec2.name }
output "ec2_role_arn" { value = aws_iam_role.ec2.arn }
output "gha_app_role_arn" { value = aws_iam_role.gha_app.arn }
output "gha_infra_role_arn" { value = aws_iam_role.gha_infra.arn }
output "github_oidc_provider_arn" { value = aws_iam_openid_connect_provider.github.arn }
