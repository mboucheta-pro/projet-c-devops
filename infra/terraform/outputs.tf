output "github_runner_ip" {
  description = "Adresse IP publique du GitHub Runner"
  value       = aws_instance.github_runner.public_ip
}

output "sonarqube_ip" {
  description = "Adresse IP publique du serveur SonarQube"
  value       = aws_instance.sonarqube.public_ip
}

output "monitoring_ip" {
  description = "Adresse IP publique du serveur de monitoring"
  value       = aws_instance.monitoring.public_ip
}

output "bastion_ip" {
  description = "Adresse IP publique du bastion host"
  value       = aws_eip.bastion.public_ip
}

output "alb_dns_name" {
  description = "Nom DNS de l'Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "db_endpoint" {
  description = "Endpoint de la base de données"
  value       = aws_db_instance.database.endpoint
}

output "eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "ID du VPC utilisé"
  value       = data.aws_vpc.existing.id
}

output "connection_instructions" {
  description = "Instructions pour se connecter aux instances et à la base de données via le bastion"
  value       = <<-EOT
    # Pour se connecter au bastion:
    ssh -i path/to/private_key ec2-user@${aws_eip.bastion.public_ip}

    # Pour se connecter aux instances via le bastion:
    ssh -i path/to/private_key -J ec2-user@${aws_eip.bastion.public_ip} ec2-user@<PRIVATE_IP_OF_INSTANCE>

    # Pour se connecter à la base de données via le bastion:
    ssh -i path/to/private_key -L 3306:${aws_db_instance.database.address}:3306 ec2-user@${aws_eip.bastion.public_ip}
    # Puis dans un autre terminal:
    mysql -h 127.0.0.1 -u ${var.db_username} -p
    
    # Pour accéder à l'application:
    https://${aws_lb.main.dns_name}
  EOT
}