provider "aws" {
  region = var.region
}

# Variables
locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project}-${var.environment}-key"
  public_key = var.ssh_public_key

  lifecycle {
    ignore_changes = [public_key]
  }
}

# VPC et réseau
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Économie de coûts
  
  # Activer la résolution DNS et les noms d'hôtes DNS pour RDS
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

# Groupe de sécurité pour les instances EC2
resource "aws_security_group" "instances" {
  name        = "${var.project}-instances-sg"
  description = "Security group for EC2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # À restreindre en production
  }

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

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# GitHub Runner
resource "aws_instance" "github_runner" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023 pour ca-central-1
  instance_type = "t3a.small" # Bon équilibre coût/performance
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  # Script de démarrage pour configurer l'accès SSH
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/ec2-user/.ssh
    echo "${var.ssh_public_key}" >> /home/ec2-user/.ssh/authorized_keys
    chmod 700 /home/ec2-user/.ssh
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    chown -R ec2-user:ec2-user /home/ec2-user/.ssh
    systemctl restart sshd
  EOF

  tags = merge(local.tags, {
    Name = "${var.project}-github-runner"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# SonarQube Server
resource "aws_instance" "sonarqube" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023 pour ca-central-1
  instance_type = "t3a.medium" # SonarQube nécessite plus de RAM
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  # Script de démarrage pour configurer l'accès SSH
  user_data = <<-EOF
    #!/bin/bash
    echo "${var.ssh_public_key}" >> /home/ec2-user/.ssh/authorized_keys
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
    systemctl restart sshd
  EOF

  tags = merge(local.tags, {
    Name = "${var.project}-sonarqube"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Monitoring Server (Prometheus + Grafana)
resource "aws_instance" "monitoring" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023 pour ca-central-1
  instance_type = "t3a.small"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  # Script de démarrage pour configurer l'accès SSH
  user_data = <<-EOF
    #!/bin/bash
    echo "${var.ssh_public_key}" >> /home/ec2-user/.ssh/authorized_keys
    chmod 600 /home/ec2-user/.ssh/authorized_keys
    chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
    systemctl restart sshd
  EOF

  tags = merge(local.tags, {
    Name = "${var.project}-monitoring"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Base de données RDS
resource "aws_db_subnet_group" "default" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [subnet_ids]
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "Security group for database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.instances.id]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Pour permettre l'initialisation depuis le pipeline
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.small" # Économique pour dev/test
  identifier             = "${var.project}-db"
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  multi_az               = false # Économie de coûts en dev
  publicly_accessible    = true  # Pour faciliter l'initialisation depuis le pipeline

  tags = local.tags

  lifecycle {
    ignore_changes = [password]
    prevent_destroy = true
  }
}

# Cluster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project}-cluster"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Économie de coûts avec un cluster minimal
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Node groups optimisés pour les coûts
  eks_managed_node_groups = {
    workers = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT" # Utilisation des instances Spot pour réduire les coûts
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