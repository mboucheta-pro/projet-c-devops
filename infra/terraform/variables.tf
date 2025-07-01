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

variable "db_password" {
  description = "Mot de passe pour la base de données"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique pour les instances EC2"
  type        = string
}