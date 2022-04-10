module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.10"
  name    = var.name
}