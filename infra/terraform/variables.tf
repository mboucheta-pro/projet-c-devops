# Configuration générale
variable "project" {
  description = "Nom du projet"
  type        = string
  default     = "projet-c"
}

variable "region" {
  description = "Région AWS"
  type        = string
  default     = "ca-central-1"
}

# Configuration réseau
variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ubuntu_ami" {
  description = "AMI Ubuntu 24.04 LTS"
  type        = string
  default     = "ami-0c0a551d0459e9d39"
}

# Configuration CI/CD
variable "github_token" {
  description = "Token GitHub pour l'enregistrement du runner"
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "Repository GitHub (format: owner/repo)"
  type        = string
}