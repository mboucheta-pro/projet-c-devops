provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "Terraform"
      student   = "mohamed"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "projet-c-terraform-state-devops"
    key            = "devops/terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    dynamodb_table = "projet-c-terraform-locks-devops"
  }
}

