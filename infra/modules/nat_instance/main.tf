data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_network_interface" "this" {
  subnet_id         = var.public_subnet_id
  security_groups   = [var.security_group_id]
  source_dest_check = false
  tags              = merge(var.tags, { Name = "${var.project_name}-nat-eni" })
}

resource "aws_instance" "this" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = "t2.micro"
  iam_instance_profile = var.instance_profile_name
  key_name             = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }

  user_data = templatefile("${path.module}/user_data.sh", {})

  tags = merge(var.tags, { Name = "${var.project_name}-nat" })

  lifecycle {
    ignore_changes = [ami]
  }
}
