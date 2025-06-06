#!/bin/bash
# Script pour importer les ressources existantes dans l'état Terraform

# Importer le groupe de sous-réseaux de base de données
terraform import -no-color aws_db_subnet_group.default projet-c-db-subnet-group || echo "DB subnet group not imported"

# Importer le groupe de logs CloudWatch pour EKS
terraform import -no-color module.eks.aws_cloudwatch_log_group.this[0] /aws/eks/projet-c-cluster/cluster || echo "CloudWatch log group not imported"

# Importer d'autres ressources potentiellement existantes
terraform import -no-color aws_security_group.alb projet-c-alb-sg-${1:-dev} || echo "ALB security group not imported"
terraform import -no-color aws_security_group.instances projet-c-instances-sg || echo "Instances security group not imported"
terraform import -no-color aws_security_group.db projet-c-db-sg || echo "DB security group not imported"
terraform import -no-color aws_security_group.bastion projet-c-bastion-sg-${1:-dev} || echo "Bastion security group not imported"

echo "Import process completed"