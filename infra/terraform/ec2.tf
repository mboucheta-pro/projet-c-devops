# Utiliser la key-pair AWS existante
data "aws_key_pair" "projet-c" {
  key_name = "projet-c"
}

# Jenkins Server
resource "aws_instance" "jenkins" {
  count = var.instances_running ? 1 : 0
  
  ami           = "ami-0c0a551d0459e9d39" # Ubuntu 24.04 LTS pour ca-central-1
  instance_type = "t3a.medium" # Jenkins nécessite plus de ressources
  subnet_id     = aws_subnet.private[0].id
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
  
  ami           = "ami-0c0a551d0459e9d39" # Ubuntu 24.04 LTS pour ca-central-1
  instance_type = "t3a.medium" # SonarQube nécessite plus de RAM
  subnet_id     = aws_subnet.private[0].id
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
  
  ami           = "ami-0c0a551d0459e9d39" # Ubuntu 24.04 LTS pour ca-central-1
  instance_type = "t3a.small"
  subnet_id     = aws_subnet.private[1].id
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

# Secrets pour Jenkins
resource "aws_secretsmanager_secret" "jenkins_admin" {
  name = "${var.project}/jenkins/admin"
  description = "Credentials admin pour Jenkins"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "jenkins_admin" {
  secret_id = aws_secretsmanager_secret.jenkins_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.jenkins_admin.result
  })
}

resource "random_password" "jenkins_admin" {
  length  = 16
  special = true
}

# Secrets pour SonarQube
resource "aws_secretsmanager_secret" "sonarqube_admin" {
  name = "${var.project}/sonarqube/admin"
  description = "Credentials admin pour SonarQube"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "sonarqube_admin" {
  secret_id = aws_secretsmanager_secret.sonarqube_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.sonarqube_admin.result
  })
}

resource "random_password" "sonarqube_admin" {
  length  = 16
  special = true
}