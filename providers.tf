# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # compatible with TF 0.15.x code.
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "awesome-challenge-terraform"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }  
}

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}
