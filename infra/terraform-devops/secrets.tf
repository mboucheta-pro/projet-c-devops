# Secrets AWS pour les credentials
resource "aws_secretsmanager_secret" "jenkins_credentials" {
  name        = "${var.project}-jenkins-credentials"
  description = "Credentials pour Jenkins"
}

resource "aws_secretsmanager_secret_version" "jenkins_credentials" {
  secret_id = aws_secretsmanager_secret.jenkins_credentials.id
  secret_string = jsonencode({
    admin_username = "admin"
    admin_password = var.jenkins_admin_password
  })
}

resource "aws_secretsmanager_secret" "gitlab_credentials" {
  name        = "${var.project}-gitlab-credentials"
  description = "Credentials pour GitLab"
}

resource "aws_secretsmanager_secret_version" "gitlab_credentials" {
  secret_id = aws_secretsmanager_secret.gitlab_credentials.id
  secret_string = jsonencode({
    root_username = "root"
    root_password = var.gitlab_root_password
  })
}

resource "aws_secretsmanager_secret" "sonarqube_credentials" {
  name        = "${var.project}-sonarqube-credentials"
  description = "Credentials pour SonarQube"
}

resource "aws_secretsmanager_secret_version" "sonarqube_credentials" {
  secret_id = aws_secretsmanager_secret.sonarqube_credentials.id
  secret_string = jsonencode({
    admin_username = "admin"
    admin_password = var.sonarqube_admin_password
  })
}

resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "${var.project}-database-credentials"
  description = "Credentials pour la base de données"
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
  })
}

resource "aws_secretsmanager_secret" "github_credentials" {
  name        = "${var.project}-github-credentials"
  description = "Credentials pour GitHub"
}

resource "aws_secretsmanager_secret_version" "github_credentials" {
  secret_id = aws_secretsmanager_secret.github_credentials.id
  secret_string = jsonencode({
    token = var.github_token
    repo  = var.github_repo
  })
}