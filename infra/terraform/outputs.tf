output "jenkins_ip" {
  description = "Adresse IP publique de Jenkins"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_agent_ip" {
  description = "Adresse IP publique de l'agent Jenkins"
  value       = aws_instance.jenkins_agent.public_ip
}

output "sonarqube_ip" {
  description = "Adresse IP publique de SonarQube"
  value       = aws_instance.sonarqube.public_ip
}

output "tf_backend_bucket" {
  description = "Nom du bucket S3 pour le backend Terraform"
  value = aws_s3_bucket.tf_backend.bucket
}

output "tf_backend_dynamodb" {
  description = "Nom de la table DynamoDB pour les verrous Terraform"
  value = aws_dynamodb_table.tf_backend.name
}

output "vpc_infra_id" {
  description = "ID du VPC Infrastructure CI/CD"
  value = aws_vpc.vpc_infra.id
}