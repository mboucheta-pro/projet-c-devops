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
variable "github_repo" {
  description = "Repository GitHub (format: owner/repo)"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  sensitive   = true
  default     = "admin"
}