# Configuration générale
variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "region" {
  description = "Région AWS"
  type        = string
}

# Configuration réseau
variable "vpc_infra_cidr" {
  description = "CIDR du VPC Infrastructure CI/CD"
  type        = string
}

variable "vpc_app_cidr" {
  description = "CIDR du VPC Application (EKS)"
  type        = string
}

variable "ubuntu_ami" {
  description = "AMI Ubuntu 24.04 LTS"
  type        = string
}

# Configuration CI/CD




variable "tf_backend_bucket" {
  description = "Nom du bucket S3 pour le backend Terraform"
  type        = string
}

variable "tf_backend_dynamodb" {
  description = "Nom de la table DynamoDB pour les verrous Terraform"
  type        = string
}

