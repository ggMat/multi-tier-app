resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.tags["Project"]}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.tags["Project"]}-igw" })
}

resource "aws_subnet" "public" {
  for_each                = { for i, cidr in var.public_subnet_cidrs : i => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = var.azs[tonumber(each.key)]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${var.tags["Project"]}-public-${var.azs[tonumber(each.key)]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each          = { for i, cidr in var.private_subnet_cidrs : i => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.azs[tonumber(each.key)]
  tags = merge(var.tags, {
    Name = "${var.tags["Project"]}-private-${var.azs[tonumber(each.key)]}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.tags["Project"]}-public-rt" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.tags["Project"]}-private-rt" })
}

# Note: the 0.0.0.0/0 default route in the private RT is added at the ROOT
# level (root main.tf) via an aws_route resource that targets the NAT
# instance's ENI. Done at root to avoid a circular dependency between
# networking and nat_instance modules.

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
