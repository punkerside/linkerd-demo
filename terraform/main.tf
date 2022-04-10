module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.10"
  name    = var.name
}

module "eks" {
  source  = "punkerside/eks/aws"
  version = "0.0.5"

  name        = var.name
  eks_version = "1.22"

  subnet_public_ids  = module.vpc.subnet_public_ids
  subnet_private_ids = module.vpc.subnet_private_ids

  tags = {
    Name = var.name
  }
}