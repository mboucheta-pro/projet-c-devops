data "aws_vpc" "existing" {
  id = module.vpc.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.project}-vpc-public-*"]
  }

  depends_on = [module.vpc]
}