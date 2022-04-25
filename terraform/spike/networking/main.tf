terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "Lab"
      Owner       = "DevSecOps"
    }
  }
}

# module "destroy-default-vpc" {
#   source  = "trussworks/destroy-default-vpc/aws"
#   version = "2.1.0"
# }

#Force destroy default vpc
resource "aws_default_vpc" "default" {
  force_destroy = true
}




