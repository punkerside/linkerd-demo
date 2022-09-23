data "aws_region" "main" {}
data "aws_caller_identity" "main" {}

data "aws_availability_zones" "this" {
  state = "available"
}

locals {
  aws_availability_zones = slice(data.aws_availability_zones.this.names, 0, length(var.cidr_block_pri))
}