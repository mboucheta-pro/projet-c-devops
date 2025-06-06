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
  key_name   = "${var.project}-${var.environment}-key-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  public_key = var.ssh_public_key
}

# VPC et réseau
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.project}-vpc-${var.environment}"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Économie de coûts
  
  # Activation des paramètres DNS requis pour RDS public
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
}

# GitHub Runner
resource "aws_instance" "github_runner" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023
  instance_type = "t3a.small" # Bon équilibre coût/performance
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.tags, {
    Name = "${var.project}-github-runner"
  })
}

# SonarQube Server
resource "aws_instance" "sonarqube" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023
  instance_type = "t3a.medium" # SonarQube nécessite plus de RAM
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = merge(local.tags, {
    Name = "${var.project}-sonarqube"
  })
}

# Monitoring Server (Prometheus + Grafana)
resource "aws_instance" "monitoring" {
  ami           = "ami-0a2e7efb4257c0907" # Amazon Linux 2023
  instance_type = "t3a.small"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.tags, {
    Name = "${var.project}-monitoring"
  })
}

# Base de données RDS
resource "aws_db_subnet_group" "default" {
  name       = "${var.project}-db-subnet-group-${var.environment}"
  subnet_ids = module.vpc.public_subnets  # Utilisation des sous-réseaux publics pour une instance RDS accessible publiquement

  tags = local.tags
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
}

resource "aws_db_instance" "database" {
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.small" # Économique pour dev/test
  identifier             = "${var.project}-db-${var.environment}"
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  multi_az               = false # Économie de coûts en dev
  publicly_accessible    = true  # Pour faciliter l'initialisation depuis le pipeline

  tags = local.tags
}

# Cluster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project}-cluster-${var.environment}"
  cluster_version = "1.27"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Économie de coûts avec un cluster minimal
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  # Désactiver la création du groupe de logs CloudWatch
  create_cloudwatch_log_group = false

  # Node groups optimisés pour les coûts
  eks_managed_node_groups = {
    main = {
      desired_size = 2
      min_size     = 1
      max_size     = 3

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT" # Utilisation des instances Spot pour réduire les coûts
    }
  }

  tags = local.tags
}