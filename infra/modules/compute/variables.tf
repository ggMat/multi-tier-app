variable "tags" { type = map(string) }
variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "app_security_group_id" { type = string }
variable "app_port" { type = number }
variable "instance_profile_name" { type = string }
variable "ecr_repo_url" { type = string }
variable "ssm_param_prefix" { type = string }
variable "region" { type = string }
variable "log_group_name" { type = string }
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
variable "desired_capacity" {
  type    = number
  default = 1
}
variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 1
}
variable "key_name" { type = string }
