output "s3_bucket_name" {
  description = "Nom du bucket S3 pour le backend Terraform"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Nom de la table DynamoDB pour les verrous"
  value       = aws_dynamodb_table.terraform_locks.name
}