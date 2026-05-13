variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Tags applied to every resource that supports tagging."
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH the bastion. Find with: curl ifconfig.me/32"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path on the operator's laptop to the SSH public key used for the bastion."
  type        = string
  default     = "~/.ssh/multi-tier-app.pub"
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance."
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance."
  type        = string
  default     = "app_user"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "multitier"
}

variable "github_repo" {
  description = "GitHub repo in <owner>/<name> form, used for the OIDC role trust policy."
  type        = string
}

variable "app_port" {
  type    = number
  default = 8000
}
