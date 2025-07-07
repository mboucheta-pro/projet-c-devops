# Table DynamoDB pour les verrous Terraform
resource "aws_dynamodb_table" "terraform_locks" {
  name           = var.tf_backend_dynamodb
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = var.project
    ManagedBy = "Terraform"
  }
}
