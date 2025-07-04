# Cluster EKS dans VPC App
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project}-eks"
  cluster_version = "1.29"

  vpc_id     = aws_vpc.app.id
  subnet_ids = aws_subnet.app_private[*].id

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    workers = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT"

      subnet_ids = aws_subnet.app_private[*].id
      
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }

  cluster_timeouts = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}