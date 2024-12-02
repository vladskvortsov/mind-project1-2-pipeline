

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.78.0"
    }
  }
  backend "s3" {
    bucket = "project1-2-resources"
    key = "/terraform.tfstate"
    region = var.region
  }
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}
