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

# -------- EC2 instance role (app + bastion + NAT) --------------------------
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cw_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "ec2_ssm_read" {
  statement {
    sid     = "ReadAppParams"
    effect  = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = [
      "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter${var.ssm_param_prefix}*"
    ]
  }

  statement {
    sid       = "DecryptSecureStrings"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_ssm_read" {
  name   = "${var.project_name}-ec2-ssm-read"
  policy = data.aws_iam_policy_document.ec2_ssm_read.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_read_attach" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_ssm_read.arn
}

data "aws_iam_policy_document" "ec2_ecr_pull" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [var.ecr_repo_arn]
  }
}

resource "aws_iam_policy" "ec2_ecr_pull" {
  name   = "${var.project_name}-ec2-ecr-pull"
  policy = data.aws_iam_policy_document.ec2_ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_pull_attach" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_ecr_pull.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# -------- GitHub OIDC provider ---------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# -------- GHA app role (build/push/deploy) ---------------------------------
data "aws_iam_policy_document" "gha_app_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha_app" {
  name               = "${var.project_name}-gha-app-role"
  assume_role_policy = data.aws_iam_policy_document.gha_app_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "gha_app" {
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "EcrPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [var.ecr_repo_arn]
  }
  statement {
    sid     = "SsmImageTag"
    effect  = "Allow"
    actions = ["ssm:PutParameter", "ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter${var.ssm_param_prefix}app/image_tag"
    ]
  }
  statement {
    sid       = "AsgRefreshStart"
    effect    = "Allow"
    actions   = ["autoscaling:StartInstanceRefresh"]
    resources = [var.asg_arn]
  }
  statement {
    # Describe* actions do not support resource-level restrictions in IAM
    sid       = "AsgRefreshDescribe"
    effect    = "Allow"
    actions   = ["autoscaling:DescribeInstanceRefreshes"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_app" {
  name   = "${var.project_name}-gha-app"
  policy = data.aws_iam_policy_document.gha_app.json
}

resource "aws_iam_role_policy_attachment" "gha_app" {
  role       = aws_iam_role.gha_app.name
  policy_arn = aws_iam_policy.gha_app.arn
}

# -------- GHA infra role (Terraform apply) ---------------------------------
data "aws_iam_policy_document" "gha_infra_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "gha_infra" {
  name               = "${var.project_name}-gha-infra-role"
  assume_role_policy = data.aws_iam_policy_document.gha_infra_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "gha_infra_power" {
  role       = aws_iam_role.gha_infra.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "gha_infra_iam" {
  statement {
    effect = "Allow"
    actions = [
      "iam:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_infra_iam" {
  name   = "${var.project_name}-gha-infra-iam"
  policy = data.aws_iam_policy_document.gha_infra_iam.json
}

resource "aws_iam_role_policy_attachment" "gha_infra_iam_attach" {
  role       = aws_iam_role.gha_infra.name
  policy_arn = aws_iam_policy.gha_infra_iam.arn
}
