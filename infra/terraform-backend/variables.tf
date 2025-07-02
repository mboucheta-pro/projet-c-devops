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

variable "tf_backend_bucket" {
  description = "Nom du bucket S3 pour le backend Terraform"
  type        = string
  default     = "projet-c-terraform-state"
}

variable "tf_backend_dynamodb" {
  description = "Nom de la table DynamoDB pour les verrous Terraform"
  type        = string
  default     = "projet-c-terraform-locks"
}