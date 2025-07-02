# Cluster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project}-eks"
  cluster_version = "1.27"
  
  vpc_id     = aws_vpc.projet-c.id
  subnet_ids = aws_subnet.private[*].id

  # Économie de coûts avec un cluster minimal
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Node groups optimisés pour les coûts
  eks_managed_node_groups = var.instances_running ? {
    workers = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT" # Utilisation des instances Spot pour réduire les coûts
    }
  } : {
    workers = {
      desired_size = 0
      min_size     = 0
      max_size     = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT"
    }
  }

  tags = local.tags

  # Ignorer les changements dans les groupes de nœuds pour éviter les recréations inutiles
  cluster_timeouts = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}