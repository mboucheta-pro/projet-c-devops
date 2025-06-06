# Groupe de sécurité pour l'ALB (Application Load Balancer)
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg-${var.environment}"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  # Autoriser HTTP et HTTPS depuis Internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-alb-sg-${var.environment}"
  })
}

# Mise à jour du groupe de sécurité des instances pour n'autoriser que l'ALB
resource "aws_security_group_rule" "instances_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.instances.id
}

resource "aws_security_group_rule" "instances_https_from_alb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.instances.id
}

# Règles pour autoriser les instances à communiquer entre elles
resource "aws_security_group_rule" "instances_internal_communication" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.instances.id
  security_group_id        = aws_security_group.instances.id
}

# Règles pour autoriser les instances à communiquer avec le cluster EKS
resource "aws_security_group_rule" "instances_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.instances.id
  security_group_id        = module.eks.cluster_security_group_id
}

# Règles pour autoriser le bastion à accéder au cluster EKS
resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = module.eks.cluster_security_group_id
}

# Règles pour autoriser le bastion à accéder aux nœuds EKS
resource "aws_security_group_rule" "bastion_to_eks_nodes" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = module.eks.node_security_group_id
}