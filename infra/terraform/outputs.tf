output "devops_alb_dns_name" {
  description = "DNS name du Load Balancer DevOps"
  value       = aws_lb.devops.dns_name
}

output "jenkins_url" {
  description = "URL d'accès à Jenkins"
  value       = "http://${aws_lb.devops.dns_name}:8080"
}

output "sonarqube_url" {
  description = "URL d'accès à SonarQube"
  value       = "http://${aws_lb.devops.dns_name}:9000"
}

output "monitoring_url" {
  description = "URL d'accès au monitoring (Grafana)"
  value       = "http://${aws_lb.devops.dns_name}:3000"
}

output "db_endpoint" {
  description = "Point de terminaison de la base de données RDS"
  value       = aws_db_instance.database.endpoint
}

output "eks_cluster_endpoint" {
  description = "Point de terminaison du cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_id
}

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

output "db_secret_arn" {
  description = "ARN du secret contenant les credentials de la base de données"
  value       = aws_db_instance.database.master_user_secret[0].secret_arn
  sensitive   = true
}

output "jenkins_secret_arn" {
  description = "ARN du secret contenant les credentials Jenkins"
  value       = aws_secretsmanager_secret.jenkins_admin.arn
  sensitive   = true
}

output "sonarqube_secret_arn" {
  description = "ARN du secret contenant les credentials SonarQube"
  value       = aws_secretsmanager_secret.sonarqube_admin.arn
  sensitive   = true
}