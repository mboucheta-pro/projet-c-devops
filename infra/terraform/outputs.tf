output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.projet-c.id
}

output "private_subnets" {
  description = "IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "sonarqube_ip" {
  description = "Adresse IP publique de SonarQube"
  value       = aws_instance.sonarqube.public_ip
}

output "sonarqube_url" {
  description = "URL d'accès à SonarQube"
  value       = "http://${aws_instance.sonarqube.public_ip}:9000"
}

output "monitoring_ip" {
  description = "Adresse IP publique du monitoring"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_url" {
  description = "URL d'accès au monitoring (Grafana)"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "github_runner_ip" {
  description = "Adresse IP publique du runner GitHub"
  value       = aws_instance.github_runner.public_ip
}