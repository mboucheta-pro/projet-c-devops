terraform {
  backend "s3" {
    bucket         = "projet-c-terraform-state"
    key            = "terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    dynamodb_table = "projet-c-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0.0"
}