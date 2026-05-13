resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project_name}-db-subnets" })
}

resource "aws_db_instance" "this" {
  identifier              = "${var.project_name}-rds"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp2"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.security_group_ids
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 7
  storage_encrypted       = true
  apply_immediately       = true

  tags = merge(var.tags, { Name = "${var.project_name}-rds" })
}

resource "aws_ssm_parameter" "db_host" {
  name  = "${var.ssm_param_prefix}db/host"
  type  = "String"
  value = aws_db_instance.this.address
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_port" {
  name  = "${var.ssm_param_prefix}db/port"
  type  = "String"
  value = tostring(aws_db_instance.this.port)
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "${var.ssm_param_prefix}db/name"
  type  = "String"
  value = aws_db_instance.this.db_name
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_user" {
  name  = "${var.ssm_param_prefix}db/user"
  type  = "String"
  value = var.db_username
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_password" {
  name  = "${var.ssm_param_prefix}db/password"
  type  = "SecureString"
  value = var.db_password
  tags  = var.tags
}
