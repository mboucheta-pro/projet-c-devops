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

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Nom d'utilisateur pour la base de données"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "github_token" {
  description = "Token GitHub pour l'enregistrement du runner"
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "Repository GitHub (format: owner/repo)"
  type        = string
}
