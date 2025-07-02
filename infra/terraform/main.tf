provider "aws" {
  region = var.region
}

# Variables
locals {
  tags = {
    Project   = "${var.project}"
    ManagedBy = "Terraform"
  }
}

# Utiliser la key-pair AWS existante
data "aws_key_pair" "projet-c" {
  key_name = "projet-c"
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
    from_port   = 8080
    to_port     = 8080
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

# Jenkins Server
resource "aws_instance" "jenkins" {
  count = var.instances_running ? 1 : 0
  
  ami           = "ami-0a7154091c5c6623e" # Ubuntu 22.04 LTS pour ca-central-1
  instance_type = "t3a.medium" # Jenkins nécessite plus de ressources
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = data.aws_key_pair.projet-c.key_name
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  tags = merge(local.tags, {
    Name = "${var.project}-jenkins"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# SonarQube Server
resource "aws_instance" "sonarqube" {
  count = var.instances_running ? 1 : 0
  
  ami           = "ami-0a7154091c5c6623e" # Ubuntu 22.04 LTS pour ca-central-1
  instance_type = "t3a.medium" # SonarQube nécessite plus de RAM
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = data.aws_key_pair.projet-c.key_name
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  tags = merge(local.tags, {
    Name = "${var.project}-sonarqube"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# Monitoring Server (Prometheus + Grafana)
resource "aws_instance" "monitoring" {
  count = var.instances_running ? 1 : 0
  
  ami           = "ami-0a7154091c5c6623e" # Ubuntu 22.04 LTS pour ca-central-1
  instance_type = "t3a.small"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = data.aws_key_pair.projet-c.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  tags = merge(local.tags, {
    Name = "${var.project}-monitoring"
  })

  lifecycle {
    ignore_changes = [ami]
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

# Secret pour le mot de passe DB
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project}/db/password"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
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

  cluster_name    = "${var.project}-eks"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

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