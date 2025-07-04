# Cluster EKS dans VPC App
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project}-eks"
  cluster_version = "1.27"
  
  vpc_id     = aws_vpc.app.id
  subnet_ids = aws_subnet.app_private[*].id

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    workers = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT"
    }
  }

  cluster_timeouts = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}