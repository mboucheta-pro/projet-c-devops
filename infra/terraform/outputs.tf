# VPC Infra Outputs
output "vpc_infra_id" {
  description = "ID du VPC Infrastructure"
  value       = aws_vpc.infra.id
}

output "vpc_infra_public_subnets" {
  description = "IDs des subnets publics VPC Infra"
  value       = aws_subnet.infra_public[*].id
}

output "vpc_infra_cidr" {
  description = "CIDR du VPC Infrastructure"
  value       = aws_vpc.infra.cidr_block
}

# CI/CD Infrastructure Outputs


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



output "sonarqube_ip" {
  description = "Adresse IP publique de SonarQube"
  value       = aws_instance.sonarqube.public_ip
}

output "sonarqube_url" {
  description = "URL d'accès à SonarQube"
  value       = "http://${aws_instance.sonarqube.public_ip}:9000"
}



# Secrets ARNs
output "jenkins_secret_arn" {
  description = "ARN du secret Jenkins"
  value       = aws_secretsmanager_secret.jenkins_credentials.arn
}



output "sonarqube_secret_arn" {
  description = "ARN du secret SonarQube"
  value       = aws_secretsmanager_secret.sonarqube_credentials.arn
}







# Mots de passe générés automatiquement (sensibles)
output "jenkins_admin_password" {
  description = "Mot de passe administrateur Jenkins généré automatiquement"
  value       = random_password.jenkins_admin.result
  sensitive   = true
}



output "sonarqube_admin_password" {
  description = "Mot de passe administrateur SonarQube généré automatiquement"
  value       = random_password.sonarqube_admin.result
  sensitive   = true
}





output "s3_bucket_name" {
  description = "Nom du bucket S3 pour le backend Terraform"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Nom de la table DynamoDB pour les verrous"
  value       = aws_dynamodb_table.terraform_locks.name
}