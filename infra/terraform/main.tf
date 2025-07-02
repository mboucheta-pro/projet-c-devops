provider "aws" {
  region = var.region
}

# Variables
locals {
  tags = {
    Project   = "${var.project}"
    ManagedBy = "Terraform"
  }
}


