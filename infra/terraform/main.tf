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
# Utilisation d'un VPC existant au lieu d'en créer un nouveau
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["${var.project}-vpc*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Groupe de sécurité pour les instances EC2
# Groupe de sécurité pour le bastion
resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg-${var.environment}"
  description = "Security group for bastion host"
  vpc_id      = data.aws_vpc.existing.id

  # Autoriser SSH uniquement depuis Internet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Idéalement, restreindre à votre IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-bastion-sg-${var.environment}"
  })
}

# Groupe de sécurité pour les instances EC2
resource "aws_security_group" "instances" {
  name        = "${var.project}-instances-sg-${var.environment}"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.existing.id

  # SSH uniquement depuis le bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # HTTP et HTTPS pour l'application
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

  # Ports internes accessibles uniquement depuis le VPC
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
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
  subnet_id     = tolist(data.aws_subnets.public.ids)[0]
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
  subnet_id     = tolist(data.aws_subnets.public.ids)[0]
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
  subnet_id     = tolist(data.aws_subnets.public.ids)[0]
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
  subnet_ids = data.aws_subnets.public.ids  # Utilisation des sous-réseaux publics pour une instance RDS accessible publiquement

  tags = local.tags
}

resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg-${var.environment}"
  description = "Security group for database"
  vpc_id      = data.aws_vpc.existing.id

  # Accès MySQL depuis les instances d'application
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.instances.id]
  }

  # Accès MySQL depuis le bastion uniquement
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
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
  allocated_storage      = 10  # Réduit à 10 pour économiser des ressources
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Réduit à micro pour économiser des ressources
  identifier             = "${var.project}-db-${var.environment}"
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  multi_az               = false # Économie de coûts en dev
  publicly_accessible    = false # Accès uniquement via le bastion et les instances

  tags = local.tags
}

# Cluster EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.project}-cluster-${var.environment}"
  cluster_version = "1.27"
  
  vpc_id     = data.aws_vpc.existing.id
  subnet_ids = data.aws_subnets.private.ids

  # Économie de coûts avec un cluster minimal
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  # Désactiver la création du groupe de logs CloudWatch
  create_cloudwatch_log_group = false

  # Node groups optimisés pour les coûts
  eks_managed_node_groups = {
    main = {
      desired_size = 1  # Réduit à 1 pour économiser des ressources
      min_size     = 1
      max_size     = 2  # Réduit à 2 pour économiser des ressources

      instance_types = ["t3a.small"]  # Réduit à small pour économiser des ressources
      capacity_type  = "SPOT" # Utilisation des instances Spot pour réduire les coûts
    }
  }

  tags = local.tags
}