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