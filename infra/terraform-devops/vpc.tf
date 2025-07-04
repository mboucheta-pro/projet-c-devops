# =============================================================================
# VPC INFRA - Pour les outils CI/CD
# =============================================================================

resource "aws_vpc" "infra" {
  cidr_block           = var.vpc_infra_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-infra"
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
    Name = "vpc-infra-public-${count.index + 1}"
  }
}

# Internet Gateway VPC Infra
resource "aws_internet_gateway" "infra" {
  vpc_id = aws_vpc.infra.id

  tags = {
    Name = "vpc-infra-igw"
  }
}

# Route table VPC Infra
resource "aws_route_table" "infra_public" {
  vpc_id = aws_vpc.infra.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infra.id
  }

  route {
    cidr_block                = var.vpc_app_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.infra_to_app.id
  }

  tags = {
    Name = "vpc-infra-public-rt"
  }
}

# Association sous-réseaux publics VPC Infra
resource "aws_route_table_association" "infra_public" {
  count          = 2
  subnet_id      = aws_subnet.infra_public[count.index].id
  route_table_id = aws_route_table.infra_public.id
}

# =============================================================================
# VPC APP - Pour le cluster EKS
# =============================================================================

resource "aws_vpc" "app" {
  cidr_block           = var.vpc_app_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-app"
  }
}

# Sous-réseaux publics VPC App
resource "aws_subnet" "app_public" {
  count                   = 2
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.2.${count.index + 101}.0/24"
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-app-public-${count.index + 1}"
  }
}

# Sous-réseaux privés VPC App
resource "aws_subnet" "app_private" {
  count             = 2
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.2.${count.index + 1}.0/24"
  availability_zone = "${var.region}${count.index == 0 ? "a" : "b"}"

  tags = {
    Name = "vpc-app-private-${count.index + 1}"
  }
}

# Internet Gateway VPC App
resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "vpc-app-igw"
  }
}

# EIP pour NAT Gateway VPC App
resource "aws_eip" "app_nat" {
  tags = {
    Name = "vpc-app-nat-eip"
  }
}

# NAT Gateway VPC App
resource "aws_nat_gateway" "app" {
  allocation_id = aws_eip.app_nat.id
  subnet_id     = aws_subnet.app_public[0].id

  tags = {
    Name = "vpc-app-nat"
  }

  depends_on = [aws_internet_gateway.app]
}

# Route table publique VPC App
resource "aws_route_table" "app_public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

  route {
    cidr_block                = var.vpc_infra_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.infra_to_app.id
  }

  tags = {
    Name = "vpc-app-public-rt"
  }
}

# Route table privée VPC App
resource "aws_route_table" "app_private" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app.id
  }

  route {
    cidr_block                = var.vpc_infra_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.infra_to_app.id
  }

  tags = {
    Name = "vpc-app-private-rt"
  }
}

# Associations sous-réseaux publics VPC App
resource "aws_route_table_association" "app_public" {
  count          = 2
  subnet_id      = aws_subnet.app_public[count.index].id
  route_table_id = aws_route_table.app_public.id
}

# Associations sous-réseaux privés VPC App
resource "aws_route_table_association" "app_private" {
  count          = 2
  subnet_id      = aws_subnet.app_private[count.index].id
  route_table_id = aws_route_table.app_private.id
}

# =============================================================================
# VPC PEERING - Communication entre les VPC
# =============================================================================

resource "aws_vpc_peering_connection" "infra_to_app" {
  vpc_id      = aws_vpc.infra.id
  peer_vpc_id = aws_vpc.app.id
  auto_accept = true

  tags = {
    Name = "vpc-infra-to-vpc-app"
  }
}

resource "aws_vpc_peering_connection_accepter" "infra_to_app" {
  vpc_peering_connection_id = aws_vpc_peering_connection.infra_to_app.id
  auto_accept               = true

  tags = {
    Name = "vpc-infra-to-vpc-app-accepter"
  }
}