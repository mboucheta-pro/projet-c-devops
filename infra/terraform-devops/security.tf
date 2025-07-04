# Groupe de sécurité pour les instances du VPC Infra
resource "aws_security_group" "infra_instances" {
  name        = "${var.project}-infra-instances-sg"
  description = "Security group for CI/CD instances in VPC Infra"
  vpc_id      = aws_vpc.infra.id

  # SSH - Accès depuis les VPC internes et Internet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_infra_cidr, var.vpc_app_cidr, "0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # GitLab HTTP/HTTPS
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

  # SonarQube
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Communication inter-VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_app_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-infra-instances-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Groupe de sécurité pour le VPC App (EKS)
resource "aws_security_group" "app_instances" {
  name        = "${var.project}-app-instances-sg"
  description = "Security group for EKS nodes in VPC App"
  vpc_id      = aws_vpc.app.id

  # Communication inter-VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_infra_cidr]
  }

  # Communication interne VPC App
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_app_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-app-instances-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}