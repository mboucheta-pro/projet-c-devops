variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "region" {
  description = "Région AWS"
  type        = string
}

variable "tf_backend_bucket" {
  description = "Nom du bucket S3 pour le backend Terraform"
  type        = string
}

variable "tf_backend_dynamodb" {
  description = "Nom de la table DynamoDB pour les verrous Terraform"
  type        = string
}