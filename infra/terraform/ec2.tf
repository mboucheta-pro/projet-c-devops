# Utiliser la key-pair AWS existante
data "aws_key_pair" "projet-c" {
  key_name = "projet-c"
}

# GitHub Runner Server
resource "aws_instance" "github_runner" {
  ami                         = var.ubuntu_ami
  instance_type               = "t3a.medium"
  subnet_id                   = aws_subnet.infra_public[0].id
  vpc_security_group_ids      = [aws_security_group.infra_instances.id]
  key_name                    = data.aws_key_pair.projet-c.key_name
  iam_instance_profile        = aws_iam_instance_profile.github_runner.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/user_data/github-runner.sh", {
    github_token = var.github_token
    github_repo  = var.github_repo
    runner_name  = "${var.project}-runner-${random_id.runner_suffix.hex}"
  }))

  tags = {
    Name = "${var.project}-github-runner"
  }

  lifecycle {
    ignore_changes = [ami]
  }
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
    Name = "${var.project}-jenkins"
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
    Name = "${var.project}-jenkins-agent"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# GitLab Server
resource "aws_instance" "gitlab" {
  ami                         = var.ubuntu_ami
  instance_type               = "t3a.large"
  subnet_id                   = aws_subnet.infra_public[0].id
  vpc_security_group_ids      = [aws_security_group.infra_instances.id]
  key_name                    = data.aws_key_pair.projet-c.key_name
  iam_instance_profile        = aws_iam_instance_profile.cicd_instances.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project}-gitlab"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# GitLab Runner
resource "aws_instance" "gitlab_runner" {
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
    Name = "${var.project}-gitlab-runner"
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
    Name = "${var.project}-sonarqube"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "random_id" "runner_suffix" {
  byte_length = 4
}