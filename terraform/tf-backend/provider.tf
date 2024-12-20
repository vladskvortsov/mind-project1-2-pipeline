terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.78.0"
    }
  }
  backend "s3" {
    bucket = "project1-2-resources"
    key    = "tf-backend/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = var.AWS_REGION
}
