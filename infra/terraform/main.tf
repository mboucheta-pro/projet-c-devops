provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      student   = "Mohamed"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "projet-c-mohamed"
    key            = "devops/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

