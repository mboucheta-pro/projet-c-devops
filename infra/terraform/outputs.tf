output "github-runner_ip" {
  description = "Adresse IP publique du runner GitHub"
  value       = var.instances_running ? aws_instance.github-runner[0].public_ip : null
}

output "sonarqube_ip" {
  description = "Adresse IP publique du serveur SonarQube"
  value       = var.instances_running ? aws_instance.sonarqube[0].public_ip : null
}

output "monitoring_ip" {
  description = "Adresse IP publique du serveur de monitoring"
  value       = var.instances_running ? aws_instance.monitoring[0].public_ip : null
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
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs des subnets privés"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs des subnets publics"
  value       = module.vpc.public_subnets
}

output "bastion_public_ip" {
  description = "Adresse IP publique du bastion"
  value       = aws_eip.bastion.public_ip
}