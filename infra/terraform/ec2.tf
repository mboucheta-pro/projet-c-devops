# Utiliser la key-pair AWS existante
data "aws_key_pair" "projet-c" {
  key_name = "projet-c"
}

# Jenkins Server
resource "aws_instance" "jenkins" {
  ami                         = var.ubuntu_ami
  instance_type               = "t3a.medium"
  subnet_id                   = aws_subnet.infra_public[0].id
  vpc_security_group_ids      = [aws_security_group.infra_instances.id]
  key_name                    = data.aws_key_pair.projet-c.key_name
  iam_instance_profile        = aws_iam_instance_profile.cicd_instances.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins-master"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Jenkins Agent
resource "aws_instance" "jenkins_agent" {
  ami                         = var.ubuntu_ami
  instance_type               = "t3a.medium"
  subnet_id                   = aws_subnet.infra_public[1].id
  vpc_security_group_ids      = [aws_security_group.infra_instances.id]
  key_name                    = data.aws_key_pair.projet-c.key_name
  iam_instance_profile        = aws_iam_instance_profile.cicd_instances.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-jenkins-agent"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# SonarQube Server
resource "aws_instance" "sonarqube" {
  ami                         = var.ubuntu_ami
  instance_type               = "t3a.medium"
  subnet_id                   = aws_subnet.infra_public[1].id
  vpc_security_group_ids      = [aws_security_group.infra_instances.id]
  key_name                    = data.aws_key_pair.projet-c.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-sonarqube"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}