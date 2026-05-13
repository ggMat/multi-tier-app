# -------- ALB SG -----------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB tier"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project_name}-alb-sg" })
}

resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
}

resource "aws_security_group_rule" "alb_to_app_out" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.app.id
  description              = "Forward to app tier"
}

# -------- App SG -----------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "App tier"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project_name}-app-sg" })
}

resource "aws_security_group_rule" "app_from_alb_in" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Receive from ALB"
}

resource "aws_security_group_rule" "app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "All egress (via NAT instance) for ECR/SSM/CW Logs/RDS"
}

# -------- DB SG ------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "DB tier"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project_name}-db-sg" })
}

resource "aws_security_group_rule" "db_from_app_in" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
  description              = "Receive from app tier"
}

resource "aws_security_group_rule" "db_from_bastion_in" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.bastion.id
  description              = "Receive from bastion for psql admin"
}

# -------- Bastion SG -------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion host"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project_name}-bastion-sg" })
}

resource "aws_security_group_rule" "bastion_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_cidr]
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from operator"
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "All egress (DB tunnel, package updates)"
}

# -------- NAT SG -----------------------------------------------------------
resource "aws_security_group" "nat" {
  name        = "${var.project_name}-nat-sg"
  description = "NAT instance"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project_name}-nat-sg" })
}

resource "aws_security_group_rule" "nat_from_vpc_in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] # restricted by route table; VPC-only in practice
  security_group_id = aws_security_group.nat.id
  description       = "Accept traffic from private subnets to NAT"
}

resource "aws_security_group_rule" "nat_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
  description       = "All egress to internet"
}
