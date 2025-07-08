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
