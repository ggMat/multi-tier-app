locals {
  project_name     = var.tags["Project"]
  ssm_param_prefix = "/${var.tags["Project"]}/"
  log_group_name   = "/${var.tags["Project"]}/app"
}

data "aws_caller_identity" "current" {}

resource "aws_key_pair" "operator" {
  key_name   = "${local.project_name}-key"
  public_key = var.ssh_public_key
  tags       = var.tags
}

# 1. Networking ---------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  tags                 = var.tags
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# 2. ECR ----------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  name = local.project_name
  tags = var.tags
}

# 3. Security (SGs + IAM) -----------------------------------------------------
module "security" {
  source = "./modules/security"

  tags             = var.tags
  vpc_id           = module.networking.vpc_id
  admin_cidr       = var.admin_cidr
  app_port         = var.app_port
  github_repo      = var.github_repo
  project_name     = local.project_name
  ecr_repo_arn     = module.ecr.repository_arn
  asg_arn          = "arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.project_name}-asg"
  ssm_param_prefix = local.ssm_param_prefix
  aws_account_id   = data.aws_caller_identity.current.account_id
  region           = var.region
}

# 4. NAT instance ------------------------------------------------------------
module "nat_instance" {
  source = "./modules/nat_instance"

  tags                  = var.tags
  project_name          = local.project_name
  public_subnet_id      = module.networking.public_subnet_ids[0]
  security_group_id     = module.security.nat_sg_id
  instance_profile_name = module.security.ec2_instance_profile_name
  private_subnet_cidrs  = var.private_subnet_cidrs
  key_name              = aws_key_pair.operator.key_name
}

# Route private subnets' 0.0.0.0/0 to the NAT instance ENI
resource "aws_route" "private_default" {
  route_table_id         = module.networking.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nat_instance.network_interface_id
}

# 5. Database ----------------------------------------------------------------
module "db" {
  source = "./modules/db"

  tags               = var.tags
  project_name       = local.project_name
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.security.db_sg_id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  ssm_param_prefix   = local.ssm_param_prefix
}

# 6. Bastion -----------------------------------------------------------------
module "bastion" {
  source = "./modules/bastion"

  tags                  = var.tags
  project_name          = local.project_name
  public_subnet_id      = module.networking.public_subnet_ids[0]
  security_group_id     = module.security.bastion_sg_id
  instance_profile_name = module.security.ec2_instance_profile_name
  key_name              = aws_key_pair.operator.key_name
}

# 7. Compute (ALB + ASG) -----------------------------------------------------
module "compute" {
  source = "./modules/compute"

  tags                  = var.tags
  project_name          = local.project_name
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.security.alb_sg_id
  app_security_group_id = module.security.app_sg_id
  app_port              = var.app_port
  instance_profile_name = module.security.ec2_instance_profile_name
  ecr_repo_url          = module.ecr.repository_url
  ssm_param_prefix      = local.ssm_param_prefix
  region                = var.region
  log_group_name        = local.log_group_name
  key_name              = aws_key_pair.operator.key_name

  depends_on = [
    module.db,
    aws_route.private_default
  ]
}

# Seed the image_tag SSM param so user_data has something to read on first boot
resource "aws_ssm_parameter" "image_tag_seed" {
  name      = "${local.ssm_param_prefix}app/image_tag"
  type      = "String"
  value     = "latest"
  overwrite = true
  tags      = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}
