# VPC et réseau
resource "aws_vpc" "projet-c" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.project}-vpc"
  })
}

# Sous-réseaux publics
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.projet-c.id
  cidr_block              = "10.0.${count.index + 101}.0/24"
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project}-public-${count.index + 1}"
  })
}

# Sous-réseaux privés
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.projet-c.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = "${var.region}${count.index == 0 ? "a" : "b"}"

  tags = merge(local.tags, {
    Name = "${var.project}-private-${count.index + 1}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.projet-c.id

  tags = merge(local.tags, {
    Name = "${var.project}-igw"
  })
}

# EIP pour NAT Gateway
resource "aws_eip" "nat" {
  tags = merge(local.tags, {
    Name = "${var.project}-nat-eip"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.tags, {
    Name = "${var.project}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route table pour les sous-réseaux publics
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.projet-c.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-public-rt"
  })
}

# Route table pour les sous-réseaux privés
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.projet-c.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-private-rt"
  })
}

# Association des sous-réseaux publics à la route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Association des sous-réseaux privés à la route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}