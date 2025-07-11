# Génération automatique des mots de passe

resource "random_password" "jenkins_admin" {
  length  = 16
  special = true
}

resource "random_password" "sonarqube_admin" {
  length           = 12
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

# Secrets AWS avec mots de passe générés automatiquement
resource "aws_secretsmanager_secret" "jenkins_credentials" {
  name                    = "${var.project_name}-jenkins-credentials"
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

resource "aws_secretsmanager_secret" "sonarqube_credentials" {
  name                    = "${var.project_name}-sonarqube-credentials"
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