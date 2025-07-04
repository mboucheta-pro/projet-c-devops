terraform {
  backend "s3" {
    bucket  = "projet-c-terraform-state"
    key     = "env/terraform.tfstate"
    region  = "ca-central-1"
    encrypt = true
  }
}