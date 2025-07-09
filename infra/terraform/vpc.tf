# =============================================================================
# VPC INFRA - Pour les outils CI/CD
# =============================================================================

resource "aws_vpc" "infra" {
  cidr_block           = var.vpc_infra_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Sous-réseaux publics VPC Infra
resource "aws_subnet" "infra_public" {
  count                   = 2
  vpc_id                  = aws_vpc.infra.id
  cidr_block              = "10.1.${count.index + 101}.0/24"
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-vpc-public-${count.index + 1}"
  }
}

# Internet Gateway VPC Infra
resource "aws_internet_gateway" "infra" {
  vpc_id = aws_vpc.infra.id

  tags = {
    Name = "${var.project_name}-vpc-igw"
  }
}

# Route table VPC Infra
resource "aws_route_table" "infra_public" {
  vpc_id = aws_vpc.infra.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infra.id
  }
  tags = {
    Name = "${var.project_name}-vpc-public-rt"
  }
}

# Association sous-réseaux publics VPC Infra
resource "aws_route_table_association" "infra_public" {
  count          = 2
  subnet_id      = aws_subnet.infra_public[count.index].id
  route_table_id = aws_route_table.infra_public.id
}
