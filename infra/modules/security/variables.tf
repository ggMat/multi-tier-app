variable "tags" { type = map(string) }
variable "vpc_id" { type = string }
variable "admin_cidr" { type = string }
variable "app_port" { type = number }
variable "db_port" {
  type    = number
  default = 5432
}
variable "github_repo" { type = string }
variable "project_name" {
  type = string
}

variable "ecr_repo_arn" {
  description = "ARN of the ECR repo, used to scope gha_app_role."
  type        = string
}

variable "asg_arn" {
  description = "ARN of the app ASG, used to scope gha_app_role."
  type        = string
}

variable "ssm_param_prefix" {
  description = "SSM Parameter Store prefix this app's role can read/write."
  type        = string
}

variable "aws_account_id" {
  description = "Current AWS account ID, used in SSM resource ARNs."
  type        = string
}

variable "region" { type = string }
