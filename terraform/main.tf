# vpc
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}

# eip
resource "aws_eip" "main" {
  count = length(var.cidr_block_pri)
  vpc   = true

  tags = {
    Name = "${var.project}-${var.env}-${var.service}-${element(local.aws_availability_zones, count.index)}"
  }
}

# internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}

# subnets
resource "aws_subnet" "private" {
  count                   = length(var.cidr_block_pri)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.cidr_block_pri, count.index)
  availability_zone       = element(local.aws_availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name                                                             = "${var.project}-${var.env}-${var.service}-private-${element(local.aws_availability_zones, count.index)}"
    Tier                                                             = "private"
    "kubernetes.io/role/internal-elb"                                = "1"
    "kubernetes.io/cluster/${var.project}-${var.env}-${var.service}" = "shared"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.cidr_block_pub)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.cidr_block_pub, count.index)
  availability_zone       = element(local.aws_availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name                                                             = "${var.project}-${var.env}-${var.service}-public-${element(local.aws_availability_zones, count.index)}"
    Tier                                                             = "public"
    "kubernetes.io/role/elb"                                         = "1"
    "kubernetes.io/cluster/${var.project}-${var.env}-${var.service}" = "shared"
  }
}

# nat gateway
resource "aws_nat_gateway" "main" {
  count         = length(var.cidr_block_pri)
  allocation_id = element(aws_eip.main.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${var.project}-${var.env}-${var.service}-${element(local.aws_availability_zones, count.index)}"
  }
}

# route table
resource "aws_route_table" "private" {
  count  = length(var.cidr_block_pri)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main.*.id, count.index)
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}-private-${element(local.aws_availability_zones, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.cidr_block_pri)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.cidr_block_pub)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}