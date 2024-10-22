terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.region
  default_tags {
    tags = {
      created-by  = "terraform"
      environment = var.environment
    }
  }
}
