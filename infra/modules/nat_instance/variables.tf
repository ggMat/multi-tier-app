variable "tags" { type = map(string) }
variable "project_name" { type = string }
variable "public_subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "instance_profile_name" { type = string }
variable "private_subnet_cidrs" { type = list(string) }
variable "key_name" { type = string }
