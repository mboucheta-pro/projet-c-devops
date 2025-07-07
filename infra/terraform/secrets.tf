# Génération automatique des mots de passe
resource "random_password" "jenkins_admin" {
  length  = 16
  special = true
}

resource "random_password" "gitlab_root" {
  length  = 16
  special = true
}

resource "random_password" "sonarqube_admin" {
  length  = 16
  special = true
}



# Secrets AWS avec mots de passe générés automatiquement
resource "aws_secretsmanager_secret" "jenkins_credentials" {
  name                    = "${var.project}-jenkins-credentials"
  description             = "Credentials pour Jenkins"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jenkins_credentials" {
  secret_id = aws_secretsmanager_secret.jenkins_credentials.id
  secret_string = jsonencode({
    admin_username = "admin"
    admin_password = random_password.jenkins_admin.result
  })
}

resource "aws_secretsmanager_secret" "gitlab_credentials" {
  name                    = "${var.project}-gitlab-credentials"
  description             = "Credentials pour GitLab"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "gitlab_credentials" {
  secret_id = aws_secretsmanager_secret.gitlab_credentials.id
  secret_string = jsonencode({
    root_username = "root"
    root_password = random_password.gitlab_root.result
  })
}

resource "aws_secretsmanager_secret" "sonarqube_credentials" {
  name                    = "${var.project}-sonarqube-credentials"
  description             = "Credentials pour SonarQube"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "sonarqube_credentials" {
  secret_id = aws_secretsmanager_secret.sonarqube_credentials.id
  secret_string = jsonencode({
    admin_username = "admin"
    admin_password = random_password.sonarqube_admin.result
  })
}



# Référence au secret AWS existant pour le token GitHub Runner
data "aws_secretsmanager_secret" "github_runner_token" {
  name = "GITHUB_RUNNER_TOKEN"
}

data "aws_secretsmanager_secret_version" "github_runner_token" {
  secret_id = data.aws_secretsmanager_secret.github_runner_token.id
}

# Référence au secret AWS existant pour la clé SSH privée
data "aws_secretsmanager_secret" "ssh_private_key" {
  name = "SSH_PRIVATE_KEY"
}

data "aws_secretsmanager_secret_version" "ssh_private_key" {
  secret_id = data.aws_secretsmanager_secret.ssh_private_key.id
}