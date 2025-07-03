# Utiliser la key-pair AWS existante
data "aws_key_pair" "projet-c" {
  key_name = "projet-c"
}

# Jenkins Server
resource "aws_instance" "jenkins" {
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
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
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
  recovery_window_in_days = 0
  force_overwrite_replica_secret = true
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

# GitHub Runner Server
resource "aws_instance" "github_runner" {
  ami           = "ami-0c0a551d0459e9d39" # Ubuntu 24.04 LTS
  instance_type = "t3a.medium"
  subnet_id     = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.instances.id]
  key_name      = data.aws_key_pair.projet-c.key_name
  iam_instance_profile = aws_iam_instance_profile.github_runner.name
  
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

# Variables
GITHUB_TOKEN="${var.github_token}"
GITHUB_REPO="${var.github_repo}"
RUNNER_NAME="${var.project}-runner-${random_id.runner_suffix.hex}"
RUNNER_USER="runner"

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation des dépendances
apt-get install -y curl wget jq git docker.io

# Démarrage de Docker
systemctl start docker
systemctl enable docker

# Création de l'utilisateur runner
useradd -m -s /bin/bash $RUNNER_USER
usermod -aG docker $RUNNER_USER

# Téléchargement du runner GitHub
cd /home/$RUNNER_USER
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
wget -O actions-runner-linux-x64.tar.gz https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
tar xzf actions-runner-linux-x64.tar.gz
rm actions-runner-linux-x64.tar.gz

# Changement de propriétaire
chown -R $RUNNER_USER:$RUNNER_USER /home/$RUNNER_USER

# Obtention du token d'enregistrement
REGISTRATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$GITHUB_REPO/actions/runners/registration-token | jq -r '.token')

# Configuration du runner
sudo -u $RUNNER_USER ./config.sh \
  --url https://github.com/$GITHUB_REPO \
  --token $REGISTRATION_TOKEN \
  --name $RUNNER_NAME \
  --work _work \
  --labels self-hosted,linux,x64,aws \
  --unattended

# Installation du service
./svc.sh install $RUNNER_USER
./svc.sh start

# Installation d'outils supplémentaires
apt-get install -y nodejs npm python3 python3-pip
npm install -g yarn

echo "GitHub Runner installé et configuré avec succès"
EOF
  )
  
  tags = merge(local.tags, {
    Name = "${var.project}-github-runner"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "random_id" "runner_suffix" {
  byte_length = 4
}

# IAM Role pour le runner GitHub
resource "aws_iam_role" "github_runner" {
  name = "${var.project}-github-runner-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.tags
}

resource "aws_iam_role_policy" "github_runner" {
  name = "${var.project}-github-runner-policy"
  role = aws_iam_role.github_runner.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "github_runner" {
  name = "${var.project}-github-runner-profile"
  role = aws_iam_role.github_runner.name
  tags = local.tags
}