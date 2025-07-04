# VPC Infra Outputs
output "vpc_infra_id" {
  description = "ID du VPC Infrastructure"
  value       = aws_vpc.infra.id
}

output "vpc_infra_public_subnets" {
  description = "IDs des subnets publics VPC Infra"
  value       = aws_subnet.infra_public[*].id
}

# VPC App Outputs
output "vpc_app_id" {
  description = "ID du VPC Application"
  value       = aws_vpc.app.id
}

output "vpc_app_private_subnets" {
  description = "IDs des subnets privés VPC App"
  value       = aws_subnet.app_private[*].id
}

output "vpc_app_public_subnets" {
  description = "IDs des subnets publics VPC App"
  value       = aws_subnet.app_public[*].id
}

# CI/CD Infrastructure Outputs
output "github_runner_ip" {
  description = "Adresse IP publique du runner GitHub"
  value       = aws_instance.github_runner.public_ip
}

output "jenkins_ip" {
  description = "Adresse IP publique de Jenkins"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "URL d'accès à Jenkins"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_agent_ip" {
  description = "Adresse IP publique de l'agent Jenkins"
  value       = aws_instance.jenkins_agent.public_ip
}

output "gitlab_ip" {
  description = "Adresse IP publique de GitLab"
  value       = aws_instance.gitlab.public_ip
}

output "gitlab_url" {
  description = "URL d'accès à GitLab"
  value       = "http://${aws_instance.gitlab.public_ip}"
}

output "gitlab_runner_ip" {
  description = "Adresse IP publique du runner GitLab"
  value       = aws_instance.gitlab_runner.public_ip
}

output "sonarqube_ip" {
  description = "Adresse IP publique de SonarQube"
  value       = aws_instance.sonarqube.public_ip
}

output "sonarqube_url" {
  description = "URL d'accès à SonarQube"
  value       = "http://${aws_instance.sonarqube.public_ip}:9000"
}

# VPC Peering
output "vpc_peering_connection_id" {
  description = "ID de la connexion VPC Peering"
  value       = aws_vpc_peering_connection.infra_to_app.id
}

# Secrets ARNs
output "jenkins_secret_arn" {
  description = "ARN du secret Jenkins"
  value       = aws_secretsmanager_secret.jenkins_credentials.arn
}

output "gitlab_secret_arn" {
  description = "ARN du secret GitLab"
  value       = aws_secretsmanager_secret.gitlab_credentials.arn
}

output "sonarqube_secret_arn" {
  description = "ARN du secret SonarQube"
  value       = aws_secretsmanager_secret.sonarqube_credentials.arn
}

output "database_secret_arn" {
  description = "ARN du secret base de données"
  value       = aws_secretsmanager_secret.database_credentials.arn
}

output "github_runner_token_arn" {
  description = "ARN du secret GitHub Runner Token"
  value       = data.aws_secretsmanager_secret.github_runner_token.arn
}

output "ssh_private_key_arn" {
  description = "ARN du secret SSH Private Key"
  value       = data.aws_secretsmanager_secret.ssh_private_key.arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "Port de la base de données RDS"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.main.db_name
}

# Mots de passe générés automatiquement (sensibles)
output "jenkins_admin_password" {
  description = "Mot de passe administrateur Jenkins généré automatiquement"
  value       = random_password.jenkins_admin.result
  sensitive   = true
}

output "gitlab_root_password" {
  description = "Mot de passe root GitLab généré automatiquement"
  value       = random_password.gitlab_root.result
  sensitive   = true
}

output "sonarqube_admin_password" {
  description = "Mot de passe administrateur SonarQube généré automatiquement"
  value       = random_password.sonarqube_admin.result
  sensitive   = true
}

output "database_password" {
  description = "Mot de passe de la base de données généré automatiquement"
  value       = random_password.database.result
  sensitive   = true
}