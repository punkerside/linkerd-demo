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

# iam
resource "aws_iam_role" "main" {
  name = "${var.project}-${var.env}-${var.service}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["eks.amazonaws.com", "ec2.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "AutoScalingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforSSM" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.main.name
}

# eks
resource "aws_eks_cluster" "main" {
  name     = "${var.project}-${var.env}-${var.service}"
  role_arn = aws_iam_role.main.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = concat(sort(aws_subnet.private.*.id), sort(aws_subnet.public.*.id), )
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name         = aws_eks_cluster.main.name
  node_group_name      = "default"
  node_role_arn        = aws_iam_role.main.arn
  subnet_ids           = aws_subnet.private.*.id
  ami_type             = "AL2_x86_64"
  disk_size            = 30
  force_update_version = false
  instance_types       = ["r5a.large"]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ecr
resource "aws_ecr_repository" "main" {
  name                 = "${var.project}-${var.env}-${var.service}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}