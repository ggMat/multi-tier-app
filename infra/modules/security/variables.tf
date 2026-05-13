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
