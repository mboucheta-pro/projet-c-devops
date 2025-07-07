# Configuration générale
variable "project" {
  description = "Nom du projet"
  type        = string
  default = "projet-c-devops"
}

variable "region" {
  description = "Région AWS"
  type        = string
  default = "ca-central-1"
}

# Configuration réseau
variable "vpc_infra_cidr" {
  description = "CIDR du VPC Infrastructure CI/CD"
  type        = string
  default = "10.1.0.0/16"
}

variable "ubuntu_ami" {
  description = "AMI Ubuntu 24.04 LTS"
  type        = string
  default = "ami-0c0a551d0459e9d39"  # Ubuntu 24.04 LTS ca-central-1
}

variable "tf_backend_bucket" {
  description = "Nom du bucket S3 pour le backend Terraform"
  type        = string
  default = "projet-c-mohamed"
}

variable "tf_backend_dynamodb" {
  description = "Nom de la table DynamoDB pour les verrous Terraform"
  type        = string
  default = "terraform-locks"
}