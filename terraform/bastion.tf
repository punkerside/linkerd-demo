# ami
data "aws_ami" "main" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# security group
resource "aws_security_group" "main" {
  name        = "${var.project}-${var.env}-${var.service}"
  description = "${var.project}-${var.env}-${var.service}"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
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
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.project}-${var.env}-${var.service}"
  role = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.main.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.main.id

  root_block_device {
    volume_size = 15
    volume_type = "gp2"
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.service}"
  }
}